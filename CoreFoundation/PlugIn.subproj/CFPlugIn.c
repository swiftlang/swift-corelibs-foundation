/*      CFPlugIn.c
	Copyright (c) 1999-2019, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2019, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
        Responsibility: Tony Parker
*/

#include "CFBundle_Internal.h"
#include "CFInternal.h"
#include "CFRuntime_Internal.h"


// MARK: - Declarations

static os_log_t _CFBundlePluginLogger(void);

static _CFPFactoryRef _CFPFactoryCommonCreateLocked(CFAllocatorRef allocator, CFUUIDRef factoryID);

static _CFPFactoryRef _CFPFactoryFindLocked(CFUUIDRef factoryID, Boolean enabled);

static CFUUIDRef _CFPFactoryCopyFactoryIDLocked(_CFPFactoryRef factory);
static CFPlugInRef _CFPFactoryCopyPlugInLocked(_CFPFactoryRef factory);

static void _CFPlugInRegisterFactoryFunctionByNameLocked(CFUUIDRef factoryID, CFPlugInRef plugIn, CFStringRef functionName);
static void _CFPlugInRegisterPlugInTypeLocked(CFUUIDRef factoryID, CFUUIDRef typeID);

static void *_CFPFactoryCreateInstanceLocked(CFAllocatorRef allocator, _CFPFactoryRef factory, CFUUIDRef typeID);
static void _CFPFactoryDisableLocked(_CFPFactoryRef factory);

static void _CFPFactoryAddTypeLocked(_CFPFactoryRef factory, CFUUIDRef typeID);
static void _CFPFactoryRemoveTypeLocked(_CFPFactoryRef factory, CFUUIDRef typeID);
static Boolean _CFPFactorySupportsTypeLocked(_CFPFactoryRef factory, CFUUIDRef typeID);

/* These methods are called by CFPlugInInstance when an instance is created or destroyed.  If a factory's instance count goes to 0 and the factory has been disabled, the factory is destroyed. */
static void _CFPFactoryAddInstanceLocked(_CFPFactoryRef factory);
static void _CFPFactoryRemoveInstanceLocked(_CFPFactoryRef factory);

static void _CFPlugInAddPlugInInstanceLocked(CFPlugInRef plugIn);
static void _CFPlugInRemovePlugInInstanceLocked(CFPlugInRef plugIn);

static void _CFPlugInAddFactoryLocked(CFPlugInRef plugIn, _CFPFactoryRef factory);
static void _CFPlugInRemoveFactoryLocked(CFPlugInRef plugIn, _CFPFactoryRef factory);

CONST_STRING_DECL(kCFPlugInDynamicRegistrationKey, "CFPlugInDynamicRegistration")
CONST_STRING_DECL(kCFPlugInDynamicRegisterFunctionKey, "CFPlugInDynamicRegisterFunction")
CONST_STRING_DECL(kCFPlugInUnloadFunctionKey, "CFPlugInUnloadFunction")
CONST_STRING_DECL(kCFPlugInFactoriesKey, "CFPlugInFactories")
CONST_STRING_DECL(kCFPlugInTypesKey, "CFPlugInTypes")

struct __CFPlugInInstance {
    CFRuntimeBase _base;
    
    _CFPFactoryRef factory;
    
    CFPlugInInstanceGetInterfaceFunction getInterfaceFunction;
    CFPlugInInstanceDeallocateInstanceDataFunction deallocateInstanceDataFunction;
    
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable : 4200)
#endif //_MSC_VER
    uint8_t _instanceData[0];
#ifdef _MSC_VER
#pragma warning(pop)
#endif //_MSC_VER
};


struct __CFPFactory {
    CFRuntimeBase _base;
    
    // All protected by CFPlugInGlobalDataLock
    CFUUIDRef _uuid;
    Boolean _enabled;
    char _padding[3];
    
    CFPlugInFactoryFunction _func;
    
    CFPlugInRef _plugIn;
    CFStringRef _funcName;
    
    CFMutableArrayRef _types;
};

// Plugin state is stored in several places:
// 1. The following factories by factory/typeID tables
// 2. The list of supported types in each factory instance
// 3. The enabled flag in each factory instance
// 4. The plugInData inside each bundle instance (except isPlugIn, which is constant after init)
// In order to synchronize all of this, there is one global lock for all of it.
#if __has_include(<os/lock_private.h>)
static os_unfair_recursive_lock CFPlugInGlobalDataLock = OS_UNFAIR_RECURSIVE_LOCK_INIT;
#define _CFPlugInGlobalDataLockAcquire() os_unfair_recursive_lock_lock_with_options(&CFPlugInGlobalDataLock, OS_UNFAIR_LOCK_DATA_SYNCHRONIZATION)
#define _CFPlugInGlobalDataLockRelease() os_unfair_recursive_lock_unlock(&CFPlugInGlobalDataLock)
#else
static _CFRecursiveMutex CFPlugInGlobalDataLock;

static void _CFPlugInGlobalDataLockAcquire() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _CFRecursiveMutexCreate(&CFPlugInGlobalDataLock);
    });
    _CFRecursiveMutexLock(&CFPlugInGlobalDataLock);
}

static void _CFPlugInGlobalDataLockRelease() {
    _CFRecursiveMutexUnlock(&CFPlugInGlobalDataLock);
}

#endif

static CFMutableDictionaryRef _factoriesByFactoryID = NULL; /* Value is _CFPFactoryRef */
static CFMutableDictionaryRef _factoriesByTypeID = NULL; /* Value is array of _CFPFactoryRef */

// MARK: - Plugin

static os_log_t _CFBundlePluginLogger(void) {
    static os_log_t _log;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _log = os_log_create("com.apple.CFBundle", "plugin");
    });
    return _log;
}

CF_EXPORT void *CFPlugInInstanceCreate(CFAllocatorRef allocator, CFUUIDRef factoryID, CFUUIDRef typeID) {
    _CFPlugInGlobalDataLockAcquire();

    _CFPFactoryRef factory = _CFPFactoryFindLocked(factoryID, true);
    void *result = NULL;
    if (!factory) {
        os_log_error(_CFBundlePluginLogger(), "Cannot find factory %{public}@", factoryID);
    } else {
        if (!_CFPFactorySupportsTypeLocked(factory, typeID)) {
            os_log_error(_CFBundlePluginLogger(), "Factory %{public}@ does not support type %{public}@", factoryID, typeID);
        } else {
            result = _CFPFactoryCreateInstanceLocked(allocator, factory, typeID);
        }
    }
    
    _CFPlugInGlobalDataLockRelease();

    os_log_debug(_CFBundlePluginLogger(), "Created instance of plugin for factory %{public}@ type %{public}@", factoryID, typeID);
    return result;
}

/* ===================== Registering factories and types ===================== */
/* For plugIn writers who must dynamically register things. */
/* Functions to register factory functions and to associate factories with types. */

CF_EXPORT Boolean CFPlugInRegisterFactoryFunction(CFUUIDRef factoryID, CFPlugInFactoryFunction func) {
    // Create factories without plugIns from default allocator
    // MF:!!! Should probably check that this worked, and maybe do some pre-checking to see if it already exists
    
    _CFPlugInGlobalDataLockAcquire();

    _CFPFactoryRef factory = _CFPFactoryCommonCreateLocked(kCFAllocatorSystemDefault, factoryID);
    factory->_func = func;
    factory->_plugIn = NULL;
    factory->_funcName = NULL;
    
    _CFPlugInGlobalDataLockRelease();

    return true;
}

CF_EXPORT Boolean CFPlugInRegisterFactoryFunctionByName(CFUUIDRef factoryID, CFPlugInRef plugIn, CFStringRef functionName) {
    // Create factories with plugIns from plugIn's allocator
    // MF:!!! Should probably check that this worked, and maybe do some pre-checking to see if it already exists
    _CFPlugInGlobalDataLockAcquire();
    _CFPlugInRegisterFactoryFunctionByNameLocked(factoryID, plugIn, functionName);
    _CFPlugInGlobalDataLockRelease();

    return true;
}

static void _CFPlugInRegisterFactoryFunctionByNameLocked(CFUUIDRef factoryID, CFPlugInRef plugIn, CFStringRef functionName) {
    _CFPFactoryRef factory = _CFPFactoryCommonCreateLocked(kCFAllocatorSystemDefault, factoryID);
    factory->_func = NULL;
    factory->_plugIn = (CFPlugInRef)CFRetain(plugIn);
    if (plugIn) _CFPlugInAddFactoryLocked(plugIn, factory);
    factory->_funcName = (functionName ? (CFStringRef)CFStringCreateCopy(kCFAllocatorSystemDefault, functionName) : NULL);
}


CF_EXPORT Boolean CFPlugInUnregisterFactory(CFUUIDRef factoryID) {
    _CFPlugInGlobalDataLockAcquire();

    _CFPFactoryRef factory = _CFPFactoryFindLocked(factoryID, true);
    
    if (!factory) {
        /* MF:!!! Error.  No factory registered for this ID. */
        os_log_error(_CFBundlePluginLogger(), "UnregisterFactory: No factory registered for id %{public}@", factoryID);
    } else {
        _CFPFactoryDisableLocked(factory);
    }
    _CFPlugInGlobalDataLockRelease();

    return true;
}

CF_EXPORT Boolean CFPlugInRegisterPlugInType(CFUUIDRef factoryID, CFUUIDRef typeID) {
    _CFPlugInGlobalDataLockAcquire();
    _CFPlugInRegisterPlugInTypeLocked(factoryID, typeID);
    _CFPlugInGlobalDataLockRelease();

    return true;
}

static void _CFPlugInRegisterPlugInTypeLocked(CFUUIDRef factoryID, CFUUIDRef typeID) {
    _CFPFactoryRef factory = _CFPFactoryFindLocked(factoryID, true);
    
    if (!factory) {
        /* MF:!!! Error.  Factory must be registered (and not disabled) before types can be associated with it. */
        os_log_error(_CFBundlePluginLogger(), "RegisterPlugInType: No factory registered for id %{public}@", factoryID);
    } else {
        _CFPFactoryAddTypeLocked(factory, typeID);
    }
}


CF_EXPORT Boolean CFPlugInUnregisterPlugInType(CFUUIDRef factoryID, CFUUIDRef typeID) {
    _CFPlugInGlobalDataLockAcquire();

    _CFPFactoryRef factory = _CFPFactoryFindLocked(factoryID, true);

    if (!factory) {
        /* MF:!!! Error.  Could not find factory. */
        os_log_error(_CFBundlePluginLogger(), "UnregisterPlugInType: No factory registered for id %{public}@ type %{public}@", factoryID, typeID);
    } else {
        _CFPFactoryRemoveTypeLocked(factory, typeID);
    }
    
    _CFPlugInGlobalDataLockRelease();

    return true;
}


/* ================= Registering instances ================= */
/* When a new instance of a type is created, the instance is responsible for registering itself with the factory that created it and unregistering when it deallocates. */
/* This means that an instance must keep track of the CFUUIDRef of the factory that created it so it can unregister when it goes away. */

CF_EXPORT void CFPlugInAddInstanceForFactory(CFUUIDRef factoryID) {
    _CFPlugInGlobalDataLockAcquire();

    _CFPFactoryRef factory = _CFPFactoryFindLocked(factoryID, true);

    if (!factory) {
        /* MF:!!! Error.  Could not find factory. */
        os_log_error(_CFBundlePluginLogger(), "AddInstanceForFactory: No factory registered for id %{public}@", factoryID);
    } else {
        _CFPFactoryAddInstanceLocked(factory);
    }
    
    _CFPlugInGlobalDataLockRelease();
}

CF_EXPORT void CFPlugInRemoveInstanceForFactory(CFUUIDRef factoryID) {
    _CFPlugInGlobalDataLockAcquire();

    _CFPFactoryRef factory = _CFPFactoryFindLocked(factoryID, true);

    if (!factory) {
        /* MF:!!! Error.  Could not find factory. */
        os_log_error(_CFBundlePluginLogger(), "RemoveInstanceForFactory: No factory registered for id %{public}@", factoryID);
    } else {
        _CFPFactoryRemoveInstanceLocked(factory);
    }
    
    _CFPlugInGlobalDataLockRelease();
}

// MARK: Plugin - Internals

static void _registerFactoryLocked(const void *key, const void *val, void *context) {
    CFStringRef factoryIDStr = (CFStringRef)key;
    CFStringRef factoryFuncStr = (CFStringRef)val;
    CFBundleRef bundle = (CFBundleRef)context;
    CFUUIDRef factoryID = (CFGetTypeID(factoryIDStr) == CFStringGetTypeID()) ? CFUUIDCreateFromString(kCFAllocatorSystemDefault, factoryIDStr) : NULL;
    if (!factoryID) factoryID = (CFUUIDRef)CFRetain(factoryIDStr);
    if (CFGetTypeID(factoryFuncStr) != CFStringGetTypeID() || CFStringGetLength(factoryFuncStr) <= 0) factoryFuncStr = NULL;
    
    os_log_debug(_CFBundlePluginLogger(), "Registering static factory %{public}@ %{public}@ bundle %{public}p", factoryID, factoryFuncStr ?: CFSTR("<no func>"), bundle);
    
    _CFPlugInRegisterFactoryFunctionByNameLocked(factoryID, bundle, factoryFuncStr);
    if (factoryID) CFRelease(factoryID);
}

static void _registerTypeLocked(const void *key, const void *val, void *context) {
    CFStringRef typeIDStr = (CFStringRef)key;
    CFArrayRef factoryIDStrArray = (CFArrayRef)val;
    CFBundleRef bundle = (CFBundleRef)context;
    SInt32 i, c = (CFGetTypeID(factoryIDStrArray) == CFArrayGetTypeID()) ? CFArrayGetCount(factoryIDStrArray) : 0;
    CFStringRef curFactoryIDStr;
    CFUUIDRef typeID = (CFGetTypeID(typeIDStr) == CFStringGetTypeID()) ? CFUUIDCreateFromString(kCFAllocatorSystemDefault, typeIDStr) : NULL;
    CFUUIDRef curFactoryID;
    if (!typeID) typeID = (CFUUIDRef)CFRetain(typeIDStr);
    if (0 == c && CFGetTypeID(factoryIDStrArray) != CFArrayGetTypeID()) {
        curFactoryIDStr = (CFStringRef)val;
        curFactoryID = (CFGetTypeID(curFactoryIDStr) == CFStringGetTypeID()) ? CFUUIDCreateFromString(CFGetAllocator(bundle), curFactoryIDStr) : NULL;
        if (!curFactoryID) curFactoryID = (CFUUIDRef)CFRetain(curFactoryIDStr);
        os_log_debug(_CFBundlePluginLogger(), "Registering factory %{public}@ type %{public}@", curFactoryID, typeID);
        _CFPlugInRegisterPlugInTypeLocked(curFactoryID, typeID);
        if (curFactoryID) CFRelease(curFactoryID);
    } else for (i = 0; i < c; i++) {
        curFactoryIDStr = (CFStringRef)CFArrayGetValueAtIndex(factoryIDStrArray, i);
        curFactoryID = (CFGetTypeID(curFactoryIDStr) == CFStringGetTypeID()) ? CFUUIDCreateFromString(CFGetAllocator(bundle), curFactoryIDStr) : NULL;
        if (!curFactoryID) curFactoryID = (CFUUIDRef)CFRetain(curFactoryIDStr);
        os_log_debug(_CFBundlePluginLogger(), "Registering factory %{public}@ type %{public}@", curFactoryID, typeID);
        _CFPlugInRegisterPlugInTypeLocked(curFactoryID, typeID);
        if (curFactoryID) CFRelease(curFactoryID);
    }
    if (typeID) CFRelease(typeID);
}

CF_PRIVATE void _CFBundleInitPlugIn(CFBundleRef bundle) {
    CFArrayCallBacks _pluginFactoryArrayCallbacks = {0, NULL, NULL, NULL, NULL};
    Boolean doDynamicReg = false;
    CFDictionaryRef infoDict;
    CFDictionaryRef factoryDict;
    CFDictionaryRef typeDict;
    CFStringRef tempStr;
    
    infoDict = CFBundleGetInfoDictionary(bundle);
    if (!infoDict) return;
    
    factoryDict = (CFDictionaryRef)CFDictionaryGetValue(infoDict, kCFPlugInFactoriesKey);
    if (factoryDict && CFGetTypeID(factoryDict) != CFDictionaryGetTypeID()) factoryDict = NULL;
    tempStr = (CFStringRef)CFDictionaryGetValue(infoDict, kCFPlugInDynamicRegistrationKey);
    if (tempStr && CFGetTypeID(tempStr) == CFStringGetTypeID() && CFStringCompare(tempStr, CFSTR("YES"), kCFCompareCaseInsensitive) == kCFCompareEqualTo) doDynamicReg = true;
    if (!factoryDict && !doDynamicReg) return;  // This is not a plug-in.
    
    _CFPlugInGlobalDataLockAcquire();

    if (__CFBundleGetPlugInData(bundle)->_registeredFactory) {
        // We already registered - don't do it again
        _CFPlugInGlobalDataLockRelease();
        return;
    }
    
    /* loadOnDemand is true by default if the plugIn does not do dynamic registration.  It is false, by default if it does do dynamic registration.  The dynamic register function can set this. */
    __CFBundleGetPlugInData(bundle)->_isPlugIn = true;
    __CFBundleGetPlugInData(bundle)->_loadOnDemand = true;
    __CFBundleGetPlugInData(bundle)->_isDoingDynamicRegistration = false;
    __CFBundleGetPlugInData(bundle)->_needsDynamicRegistration = false;
    __CFBundleGetPlugInData(bundle)->_instanceCount = 0;
    __CFBundleGetPlugInData(bundle)->_registeredFactory = true;
    
    __CFBundleGetPlugInData(bundle)->_factories = CFArrayCreateMutable(CFGetAllocator(bundle), 0, &_pluginFactoryArrayCallbacks);
    
    /* Now do the registration */
    
    /* First do static registrations, if any. */
    if (factoryDict) CFDictionaryApplyFunction(factoryDict, _registerFactoryLocked, bundle);
    typeDict = (CFDictionaryRef)CFDictionaryGetValue(infoDict, kCFPlugInTypesKey);
    if (typeDict && CFGetTypeID(typeDict) != CFDictionaryGetTypeID()) typeDict = NULL;
    if (typeDict) CFDictionaryApplyFunction(typeDict, _registerTypeLocked, bundle);
    
    _CFPlugInGlobalDataLockRelease();

    /* Now set key for dynamic registration if necessary */
    if (doDynamicReg) {
        __CFBundleGetPlugInData(bundle)->_needsDynamicRegistration = true;
        if (CFBundleIsExecutableLoaded(bundle)) _CFBundlePlugInLoaded(bundle);
    }
}

static void __CFPLUGIN_IS_CALLING_OUT_TO_A_DYNAMIC_REGISTRATION_FUNCTION__(CFPlugInDynamicRegisterFunction f, CFBundleRef bundle) __attribute__((noinline));

static void __CFPLUGIN_IS_CALLING_OUT_TO_A_DYNAMIC_REGISTRATION_FUNCTION__(CFPlugInDynamicRegisterFunction f, CFBundleRef bundle) {
    f(bundle);
    __asm __volatile__(""); // thwart tail-call optimization
}

CF_PRIVATE void _CFBundlePlugInLoaded(CFBundleRef bundle) {
    _CFPlugInData *plugIn = __CFBundleGetPlugInData(bundle);
    if (!plugIn->_isPlugIn || !CFBundleIsExecutableLoaded(bundle)) {
        return;
    }
    
    _CFPlugInGlobalDataLockAcquire();

    if (plugIn->_isDoingDynamicRegistration) {
        _CFPlugInGlobalDataLockRelease();
        return;
    }
    
    if (plugIn->_needsDynamicRegistration) {
        plugIn->_needsDynamicRegistration = false;
        CFDictionaryRef infoDict = CFBundleGetInfoDictionary(bundle);
        CFStringRef tempStr = (CFStringRef)CFDictionaryGetValue(infoDict, kCFPlugInDynamicRegisterFunctionKey);
        if (!tempStr || CFGetTypeID(tempStr) != CFStringGetTypeID() || CFStringGetLength(tempStr) <= 0) tempStr = CFSTR("CFPlugInDynamicRegister");
        plugIn->_loadOnDemand = false;
        
        plugIn->_isDoingDynamicRegistration = true;
        
        CFPlugInDynamicRegisterFunction func = (CFPlugInDynamicRegisterFunction)CFBundleGetFunctionPointerForName(bundle, tempStr);
        if (func) {
            __CFPLUGIN_IS_CALLING_OUT_TO_A_DYNAMIC_REGISTRATION_FUNCTION__(func, bundle);
        }

        plugIn->_isDoingDynamicRegistration = false;
        
        if (plugIn->_loadOnDemand && plugIn->_instanceCount == 0) CFBundleUnloadExecutable(bundle);   // Unload now if we can/should.
    }
    
    _CFPlugInGlobalDataLockRelease();
}

CF_PRIVATE void _CFBundleDeallocatePlugIn(CFBundleRef bundle) {
    _CFPlugInData *plugIn = __CFBundleGetPlugInData(bundle);
    _CFPlugInGlobalDataLockAcquire();
    if (plugIn->_isPlugIn) {
        /* Go through factories disabling them.  Disabling these factories should cause them to dealloc since we wouldn't be deallocating if any of the factories had outstanding instances.  So go backwards. */
        SInt32 c = CFArrayGetCount(plugIn->_factories);
        while (c-- > 0) _CFPFactoryDisableLocked((_CFPFactoryRef)CFArrayGetValueAtIndex(plugIn->_factories, c));
        CFRelease(plugIn->_factories);
        
        plugIn->_isPlugIn = false;
    }
    _CFPlugInGlobalDataLockRelease();
}

CF_EXPORT CFTypeID CFPlugInGetTypeID(void) {
    return CFBundleGetTypeID();
}

CF_EXPORT CFPlugInRef CFPlugInCreate(CFAllocatorRef allocator, CFURLRef plugInURL) {
    CFBundleRef bundle = CFBundleCreate(allocator, plugInURL);
    return (CFPlugInRef)bundle;
}

CF_EXPORT CFBundleRef CFPlugInGetBundle(CFPlugInRef plugIn) {
    return (CFBundleRef)plugIn;
}

CF_EXPORT void CFPlugInSetLoadOnDemand(CFPlugInRef plugIn, Boolean flag) {
    _CFPlugInData *plugInData = __CFBundleGetPlugInData(plugIn);
    if (plugInData->_isPlugIn) {
        _CFPlugInGlobalDataLockAcquire();

        plugInData->_loadOnDemand = flag;
        if (plugInData->_loadOnDemand && !plugInData->_isDoingDynamicRegistration && plugInData->_instanceCount == 0)
        {
            /* Unload now if we can/should. */
            /* If we are doing dynamic registration currently, do not unload.  The unloading will happen when dynamic registration is done, if necessary. */
            _CFPlugInGlobalDataLockRelease();

            CFBundleUnloadExecutable(plugIn);
        } else if (!plugInData->_loadOnDemand) {
            
            _CFPlugInGlobalDataLockRelease();

            /* Make sure we're loaded now. */
            CFBundleLoadExecutable(plugIn);
        } else {
            _CFPlugInGlobalDataLockRelease();
        }
    }
}

CF_EXPORT Boolean CFPlugInIsLoadOnDemand(CFPlugInRef plugIn) {
    if (__CFBundleGetPlugInData(plugIn)->_isPlugIn) {
        // Checking this is a race no matter what, so don't bother with the lock
        return __CFBundleGetPlugInData(plugIn)->_loadOnDemand;
    } else {
        return false;
    }
}

CF_PRIVATE void _CFPlugInWillUnload(CFPlugInRef plugIn) {
    if (__CFBundleGetPlugInData(plugIn)->_isPlugIn) {
        _CFPlugInGlobalDataLockAcquire();

        SInt32 c = CFArrayGetCount(__CFBundleGetPlugInData(plugIn)->_factories);
        /* First, flush all the function pointers that may be cached by our factories. */
        while (c-- > 0) {
            _CFPFactoryRef factory = (_CFPFactoryRef)CFArrayGetValueAtIndex(__CFBundleGetPlugInData(plugIn)->_factories, c);
            factory->_func = NULL;
        }
        
        _CFPlugInGlobalDataLockRelease();
    }
}

static void _CFPlugInAddPlugInInstanceLocked(CFPlugInRef plugIn) {
    if (__CFBundleGetPlugInData(plugIn)->_isPlugIn) {
        if (__CFBundleGetPlugInData(plugIn)->_instanceCount == 0 && __CFBundleGetPlugInData(plugIn)->_loadOnDemand) { _CFBundleUnscheduleForUnloading(CFPlugInGetBundle(plugIn));     // Make sure we are not scheduled for unloading
        }
        __CFBundleGetPlugInData(plugIn)->_instanceCount++;
        /* Instances also retain the CFBundle */
        CFRetain(plugIn);
    }
}

static void _CFPlugInRemovePlugInInstanceLocked(CFPlugInRef plugIn) {
    if (__CFBundleGetPlugInData(plugIn)->_isPlugIn) {
        /* MF:!!! Assert that instanceCount > 0. */
        __CFBundleGetPlugInData(plugIn)->_instanceCount--;
        if (__CFBundleGetPlugInData(plugIn)->_instanceCount == 0 && __CFBundleGetPlugInData(plugIn)->_loadOnDemand) {
            // We unload the code lazily because the code that caused this function to be called is probably code from the plugin itself.  If we unload now, we will hose things.
            _CFBundleScheduleForUnloading(CFPlugInGetBundle(plugIn));
        }
        /* Instances also retain the CFPlugIn */
        /* MF:!!! This will cause immediate unloading if it was the last ref on the plugin. */
        CFRelease(plugIn);
    }
}

static void _CFPlugInAddFactoryLocked(CFPlugInRef plugIn, _CFPFactoryRef factory) {
    if (__CFBundleGetPlugInData(plugIn)->_isPlugIn) CFArrayAppendValue(__CFBundleGetPlugInData(plugIn)->_factories, factory);
}

static void _CFPlugInRemoveFactoryLocked(CFPlugInRef plugIn, _CFPFactoryRef factory) {
    if (__CFBundleGetPlugInData(plugIn)->_isPlugIn) {
        SInt32 idx = CFArrayGetFirstIndexOfValue(__CFBundleGetPlugInData(plugIn)->_factories, CFRangeMake(0, CFArrayGetCount(__CFBundleGetPlugInData(plugIn)->_factories)), factory);
        if (idx >= 0) CFArrayRemoveValueAtIndex(__CFBundleGetPlugInData(plugIn)->_factories, idx);
    }
}

// MARK: Plugin - Factory

static void _CFPFactoryDeallocate(CFTypeRef factory);

const CFRuntimeClass __CFPFactoryClass = {
    0,
    "_CFPFactory",
    NULL,    // init
    NULL,    // copy
    _CFPFactoryDeallocate,
    NULL,    // equal
    NULL,    // hash
    NULL,       // formatting desc
    NULL,       // debug desc
};

static CFTypeID _CFPFactoryGetTypeID(void) {
    return _kCFRuntimeIDCFPFactory;
}

static void _CFPFactoryAddToTableLocked(_CFPFactoryRef factory) {
    CFUUIDRef uuid = factory->_uuid;
    
    if (!_factoriesByFactoryID) {
        CFDictionaryValueCallBacks _factoryDictValueCallbacks = {0, NULL, NULL, NULL, NULL};
        _factoriesByFactoryID = CFDictionaryCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeDictionaryKeyCallBacks, &_factoryDictValueCallbacks);
    }
    CFDictionarySetValue(_factoriesByFactoryID, uuid, factory);
    
    os_log_debug(_CFBundlePluginLogger(), "Registered factory %{public}@ (%{public}@)", factory, uuid);
}

static void _CFPFactoryRemoveFromTableLocked(_CFPFactoryRef factory) {
    CFUUIDRef uuid = factory->_uuid;
    if (uuid && _factoriesByTypeID) CFDictionaryRemoveValue(_factoriesByFactoryID, uuid);
    
    os_log_debug(_CFBundlePluginLogger(), "Unregistered factory %{public}@ (%{public}@)", factory, uuid);
}

static _CFPFactoryRef _CFPFactoryFindLocked(CFUUIDRef factoryID, Boolean enabled) {
    _CFPFactoryRef result = NULL;
    
    if (_factoriesByFactoryID) {
        result = (_CFPFactoryRef )CFDictionaryGetValue(_factoriesByFactoryID, factoryID);
        if (result && result->_enabled != enabled) result = NULL;
    }

    return result;
}

static void _CFPFactoryDeallocate(CFTypeRef ty) {
    SInt32 c;
    _CFPFactoryRef factory = (_CFPFactoryRef)ty;
    
    _CFPlugInGlobalDataLockAcquire();

    _CFPFactoryRemoveFromTableLocked(factory);
    
    if (factory->_plugIn) {
        _CFPlugInRemoveFactoryLocked(factory->_plugIn, factory);
        CFRelease(factory->_plugIn);
    }
    
    /* Remove all types for this factory. */
    c = CFArrayGetCount(factory->_types);
    while (c-- > 0) _CFPFactoryRemoveTypeLocked(factory, (CFUUIDRef)CFArrayGetValueAtIndex(factory->_types, c));
    CFRelease(factory->_types);
    
    _CFPlugInGlobalDataLockRelease();

    if (factory->_funcName) CFRelease(factory->_funcName);
    if (factory->_uuid) CFRelease(factory->_uuid);
}

static _CFPFactoryRef _CFPFactoryCommonCreateLocked(CFAllocatorRef allocator, CFUUIDRef factoryID) {
    _CFPFactoryRef factory;
    uint32_t size;
    size = sizeof(struct __CFPFactory) - sizeof(CFRuntimeBase);
    factory = (_CFPFactoryRef)_CFRuntimeCreateInstance(allocator, _CFPFactoryGetTypeID(), size, NULL);
    if (!factory) return NULL;
    
    factory->_uuid = (CFUUIDRef)CFRetain(factoryID);
    factory->_enabled = true;
    factory->_types = CFArrayCreateMutable(allocator, 0, &kCFTypeArrayCallBacks);
    
    _CFPFactoryAddToTableLocked(factory);
    
    return factory;
}

static CFUUIDRef _CFPFactoryCopyFactoryIDLocked(_CFPFactoryRef factory) {
    CFUUIDRef uuid = factory->_uuid;
    if (uuid) CFRetain(uuid);
    return uuid;
}

static CFPlugInRef _CFPFactoryCopyPlugInLocked(_CFPFactoryRef factory) {
    CFPlugInRef result = factory->_plugIn;
    if (result) CFRetain(result);
    return result;
}

static void *__CFPLUGIN_IS_CALLING_OUT_TO_A_FACTORY_FUNCTION__(CFPlugInFactoryFunction, CFAllocatorRef, CFUUIDRef) __attribute__((noinline));

static void *__CFPLUGIN_IS_CALLING_OUT_TO_A_FACTORY_FUNCTION__(CFPlugInFactoryFunction f, CFAllocatorRef allocator, CFUUIDRef typeID) {
    FAULT_CALLBACK((void **)&(f));
    void *result = (void *)INVOKE_CALLBACK2(f, allocator, typeID);
    __asm __volatile__(""); // thwart tail-call optimization
    return result;
}

static void *_CFPFactoryCreateInstanceLocked(CFAllocatorRef allocator, _CFPFactoryRef factory, CFUUIDRef typeID) {
    void *result = NULL;
    
    if (factory->_enabled) {
        if (!factory->_func) {
            factory->_func = (CFPlugInFactoryFunction)CFBundleGetFunctionPointerForName(factory->_plugIn, factory->_funcName);

            if (!factory->_func) {
                os_log_error(_CFBundlePluginLogger(), "Cannot find function pointer %{public}@ for factory %{public}@ in %{public}@", factory->_funcName, factory->_uuid, factory->_plugIn);
            }
        }
        if (factory->_func) {
            CFPlugInFactoryFunction f = factory->_func;            
            result = __CFPLUGIN_IS_CALLING_OUT_TO_A_FACTORY_FUNCTION__(f, allocator, typeID);
        }
    } else {
        os_log_debug(_CFBundlePluginLogger(), "Atempted to create instance, but factory %{public}@ is disabled", factory->_uuid);
    }
    
    return result;
}

static void _CFPFactoryDisableLocked(_CFPFactoryRef factory) {
    factory->_enabled = false;
    os_log_debug(_CFBundlePluginLogger(), "Factory %{public}@ has been disabled", factory->_uuid);
    CFRelease(factory);
}

static void _CFPFactoryAddTypeLocked(_CFPFactoryRef factory, CFUUIDRef typeID) {
    /* Add the type to the factory's type list */
    CFArrayAppendValue(factory->_types, typeID);
    
    if (!_factoriesByTypeID) _factoriesByTypeID = CFDictionaryCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableArrayRef array = (CFMutableArrayRef)CFDictionaryGetValue(_factoriesByTypeID, typeID);
    if (!array) {
        CFArrayCallBacks _factoryArrayCallbacks = {0, NULL, NULL, NULL, NULL};
        // Create this from default allocator
        array = CFArrayCreateMutable(kCFAllocatorSystemDefault, 0, &_factoryArrayCallbacks);
        CFDictionarySetValue(_factoriesByTypeID, typeID, array);
        CFRelease(array);
    }
    CFArrayAppendValue(array, factory);
    os_log_debug(_CFBundlePluginLogger(), "Type %{public}@ added to factory %{public}@", typeID, factory->_uuid);
}

static void _CFPFactoryRemoveTypeLocked(_CFPFactoryRef factory, CFUUIDRef typeID) {
    /* Remove it from the factory's type list */
    SInt32 idx = CFArrayGetFirstIndexOfValue(factory->_types, CFRangeMake(0, CFArrayGetCount(factory->_types)), typeID);
    if (idx >= 0) CFArrayRemoveValueAtIndex(factory->_types, idx);
    
    /* Remove the factory from the type's list of factories */
    if (_factoriesByTypeID) {
        CFMutableArrayRef array = (CFMutableArrayRef)CFDictionaryGetValue(_factoriesByTypeID, typeID);
        if (array) {
            idx = CFArrayGetFirstIndexOfValue(array, CFRangeMake(0, CFArrayGetCount(array)), factory);
            if (idx >= 0) {
                CFArrayRemoveValueAtIndex(array, idx);
                if (CFArrayGetCount(array) == 0) CFDictionaryRemoveValue(_factoriesByTypeID, typeID);
            }
        }
    }
    os_log_debug(_CFBundlePluginLogger(), "Type %{public}@ removed from factory %{public}@", typeID, factory->_uuid);
}

static Boolean _CFPFactorySupportsTypeLocked(_CFPFactoryRef factory, CFUUIDRef typeID) {
    SInt32 idx = CFArrayGetFirstIndexOfValue(factory->_types, CFRangeMake(0, CFArrayGetCount(factory->_types)), typeID);
    return (idx >= 0 ? true : false);
}

/* These methods are called by CFPlugInInstance when an instance is created or destroyed.  If a factory's instance count goes to 0 and the factory has been disabled, the factory is destroyed. */
static void _CFPFactoryAddInstanceLocked(_CFPFactoryRef factory) {
    CFPlugInRef plugin = factory->_plugIn;
    if (plugin) {
        _CFPlugInAddPlugInInstanceLocked(plugin);
    }
}

static void _CFPFactoryRemoveInstanceLocked(_CFPFactoryRef factory) {
    CFPlugInRef plugin = factory->_plugIn;
    if (plugin) {
        _CFPlugInRemovePlugInInstanceLocked(plugin);
    }
}

#pragma mark -

/* ===================== Finding factories and creating instances ===================== */
/* For plugIn hosts. */
/* Functions for finding factories to create specific types and actually creating instances of a type. */

CF_EXPORT CFArrayRef CFPlugInFindFactoriesForPlugInType(CFUUIDRef typeID) CF_RETURNS_RETAINED {
    _CFPlugInGlobalDataLockAcquire();
    CFArrayRef array = NULL;
    if (_factoriesByTypeID) {
        array = (CFArrayRef)CFDictionaryGetValue(_factoriesByTypeID, typeID);
    }
    
    CFMutableArrayRef result = NULL;
    if (array) {
        result = CFArrayCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeArrayCallBacks);
        
        CFIndex c = CFArrayGetCount(array);
        for (CFIndex i = 0; i < c; i++) {
            CFUUIDRef factoryId = _CFPFactoryCopyFactoryIDLocked((_CFPFactoryRef)CFArrayGetValueAtIndex(array, i));
            if (factoryId) {
                CFArrayAppendValue(result, factoryId);
                CFRelease(factoryId);
            }
        }
    }
    
    _CFPlugInGlobalDataLockRelease();
    os_log_debug(_CFBundlePluginLogger(), "%{public}ld factories found for requested plugin type %{public}@", result ? CFArrayGetCount(result) : 0, typeID);
    return result;
}

CF_EXPORT CFArrayRef CFPlugInFindFactoriesForPlugInTypeInPlugIn(CFUUIDRef typeID, CFPlugInRef plugIn) CF_RETURNS_RETAINED {
    _CFPlugInGlobalDataLockAcquire();
    CFArrayRef array = NULL;
    if (_factoriesByTypeID) {
        array = (CFArrayRef)CFDictionaryGetValue(_factoriesByTypeID, typeID);
    }
    
    
    CFMutableArrayRef result = NULL;
    if (array) {
        CFIndex c = CFArrayGetCount(array);
        result = CFArrayCreateMutable(kCFAllocatorSystemDefault, 0, &kCFTypeArrayCallBacks);
        for (CFIndex i = 0; i < c; i++) {
            _CFPFactoryRef factory = (_CFPFactoryRef)CFArrayGetValueAtIndex(array, i);
            CFPlugInRef factoryPlugIn = _CFPFactoryCopyPlugInLocked(factory);
            if (factoryPlugIn == plugIn) {
                CFUUIDRef factoryId = _CFPFactoryCopyFactoryIDLocked(factory);
                CFArrayAppendValue(result, factoryId);
                CFRelease(factoryId);
            }
            if (factoryPlugIn) CFRelease(factoryPlugIn);
        }
    }
    
    _CFPlugInGlobalDataLockRelease();
    os_log_debug(_CFBundlePluginLogger(), "%{public}ld factories found for requested plugin type %{public}@ in plugin %{public}@", result ? CFArrayGetCount(result) : 0, typeID, plugIn);
    return result;
}

// MARK: Plugin - Instance

static CFStringRef __CFPlugInInstanceCopyDescription(CFTypeRef cf) {
    /* MF:!!! Implement me */
    return CFSTR("Some CFPlugInInstance");
}

static void __CFPlugInInstanceDeallocate(CFTypeRef cf) {
    CFPlugInInstanceRef instance = (CFPlugInInstanceRef)cf;
    
    __CFGenericValidateType(cf, CFPlugInInstanceGetTypeID());

    _CFPlugInGlobalDataLockAcquire();

    if (instance->deallocateInstanceDataFunction) {
        FAULT_CALLBACK((void **)&(instance->deallocateInstanceDataFunction));
        (void)INVOKE_CALLBACK1(instance->deallocateInstanceDataFunction, (void *)(&instance->_instanceData[0]));
    }

    if (instance->factory) _CFPFactoryRemoveInstanceLocked(instance->factory);
    
    _CFPlugInGlobalDataLockRelease();
}

const CFRuntimeClass __CFPlugInInstanceClass = {
    0,
    "CFPlugInInstance",
    NULL,      // init
    NULL,      // copy
    __CFPlugInInstanceDeallocate,
    NULL,      // equal
    NULL,      // hash
    NULL,      //
    __CFPlugInInstanceCopyDescription
};

CFTypeID CFPlugInInstanceGetTypeID(void) {
    return _kCFRuntimeIDCFPlugInInstance;
}

CF_EXPORT CFPlugInInstanceRef CFPlugInInstanceCreateWithInstanceDataSize(CFAllocatorRef allocator, CFIndex instanceDataSize, CFPlugInInstanceDeallocateInstanceDataFunction deallocateInstanceFunction, CFStringRef factoryName, CFPlugInInstanceGetInterfaceFunction getInterfaceFunction) {
    CFPlugInInstanceRef instance;
    UInt32 size;
    size = sizeof(struct __CFPlugInInstance) + instanceDataSize - sizeof(CFRuntimeBase);
    instance = (CFPlugInInstanceRef)_CFRuntimeCreateInstance(allocator, CFPlugInInstanceGetTypeID(), size, NULL);
    if (!instance) return NULL;
    
    _CFPlugInGlobalDataLockAcquire();

    instance->factory = _CFPFactoryFindLocked((CFUUIDRef)factoryName, true);
    if (instance->factory) _CFPFactoryAddInstanceLocked(instance->factory);
    instance->getInterfaceFunction = getInterfaceFunction;
    instance->deallocateInstanceDataFunction = deallocateInstanceFunction;
    
    _CFPlugInGlobalDataLockRelease();
    
    return instance;
}

CF_EXPORT Boolean CFPlugInInstanceGetInterfaceFunctionTable(CFPlugInInstanceRef instance, CFStringRef interfaceName, void **ftbl) {
    void *myFtbl;
    Boolean result = false;
    
    if (instance->getInterfaceFunction) {
        FAULT_CALLBACK((void **)&(instance->getInterfaceFunction));
        result = INVOKE_CALLBACK3(instance->getInterfaceFunction, instance, interfaceName, &myFtbl) ? true : false;
    }
    if (ftbl) *ftbl = (result ? myFtbl : NULL);
    return result;
}

CF_EXPORT CFStringRef CFPlugInInstanceGetFactoryName(CFPlugInInstanceRef instance) {
    _CFPlugInGlobalDataLockAcquire();

    // This function leaks, but it's the only safe way to access the factory name (on 10.8 or later).
    // On 10.9 we added the CF_RETURNS_RETAINED annotation to the header.
    CFUUIDRef factoryId = _CFPFactoryCopyFactoryIDLocked(instance->factory);
    
    _CFPlugInGlobalDataLockRelease();

    return (CFStringRef)factoryId;
}

CF_EXPORT void *CFPlugInInstanceGetInstanceData(CFPlugInInstanceRef instance) {
    return (void *)(&instance->_instanceData[0]);
}
