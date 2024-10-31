/*	CFURL.h
	Copyright (c) 1998-2019, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2019, Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

#if !defined(__COREFOUNDATION_CFURL__)
#define __COREFOUNDATION_CFURL__ 1

#include "CFBase.h"
#include "CFData.h"
#include "CFError.h"
#include "CFString.h"

CF_IMPLICIT_BRIDGING_ENABLED
CF_EXTERN_C_BEGIN

typedef CF_ENUM(CFIndex, CFURLPathStyle) {
    kCFURLPOSIXPathStyle = 0,
    kCFURLHFSPathStyle API_DEPRECATED("Carbon File Manager is deprecated, use kCFURLPOSIXPathStyle where possible", macos(10.0,10.9), ios(2.0,7.0), watchos(2.0,2.0), tvos(9.0,9.0)), /* The use of kCFURLHFSPathStyle is deprecated. The Carbon File Manager, which uses HFS style paths, is deprecated. HFS style paths are unreliable because they can arbitrarily refer to multiple volumes if those volumes have identical volume names. You should instead use kCFURLPOSIXPathStyle wherever possible. */
    kCFURLWindowsPathStyle
};
    
typedef const struct CF_BRIDGED_TYPE(NSURL) __CFURL * CFURLRef;

/* CFURLs are composed of two fundamental pieces - their string, and a */
/* (possibly NULL) base URL.  A relative URL is one in which the string */
/* by itself does not fully specify the URL (for instance "myDir/image.tiff"); */
/* an absolute URL is one in which the string does fully specify the URL */
/* ("file://localhost/myDir/image.tiff").  Absolute URLs always have NULL */
/* base URLs; however, it is possible for a URL to have a NULL base, and still */
/* not be absolute.  Such a URL has only a relative string, and cannot be */
/* resolved.  Two CFURLs are considered equal if and only if their strings */
/* are equal and their bases are equal.  In other words, */
/* "file://localhost/myDir/image.tiff" is NOT equal to the URL with relative */
/* string "myDir/image.tiff" and base URL "file://localhost/".  Clients that */
/* need these less strict form of equality should convert all URLs to their */
/* absolute form via CFURLCopyAbsoluteURL(), then compare the absolute forms. */

CF_EXPORT
CFTypeID CFURLGetTypeID(void);

/* encoding will be used both to interpret the bytes of URLBytes, and to */
/* interpret any percent-escapes within the bytes. */
/* Using a string encoding which isn't a superset of ASCII encoding is not */
/* supported because CFURLGetBytes and CFURLGetByteRangeForComponent require */
/* 7-bit ASCII characters to be stored in a single 8-bit byte. */
/* CFStringEncodings which are a superset of ASCII encoding include MacRoman, */
/* WindowsLatin1, ISOLatin1, NextStepLatin, ASCII, and UTF8. */
CF_EXPORT
CFURLRef CFURLCreateWithBytes(CFAllocatorRef allocator, const UInt8 *URLBytes, CFIndex length, CFStringEncoding encoding, CFURLRef baseURL);

/* Escapes any character that is not 7-bit ASCII with the byte-code */
/* for the given encoding.  If escapeWhitespace is true, whitespace */
/* characters (' ', '\t', '\r', '\n') will be escaped also (desirable */
/* if embedding the URL into a larger text stream like HTML) */
CF_EXPORT
CFDataRef CFURLCreateData(CFAllocatorRef allocator, CFURLRef url, CFStringEncoding encoding, Boolean escapeWhitespace);

/* Any percent-escape sequences in URLString will be interpreted via UTF-8. URLString must be a valid URL string. */
CF_EXPORT
CFURLRef CFURLCreateWithString(CFAllocatorRef allocator, CFStringRef URLString, CFURLRef baseURL);

/* Create an absolute URL directly, without requiring the extra step */
/* of calling CFURLCopyAbsoluteURL().  If useCompatibilityMode is  */
/* true, the rules historically used on the web are used to resolve */
/* relativeString against baseURL - these rules are generally listed */
/* in the RFC as optional or alternate interpretations.  Otherwise, */
/* the strict rules from the RFC are used.  The major differences are */
/* that in compatibility mode, we are lenient of the scheme appearing */
/* in relative portion, leading "../" components are removed from the */
/* final URL's path, and if the relative portion contains only */
/* resource specifier pieces (query, parameters, and fragment), then */
/* the last path component of the base URL will not be deleted.  */
/* Using a string encoding which isn't a superset of ASCII encoding is not */
/* supported because CFURLGetBytes and CFURLGetByteRangeForComponent require */
/* 7-bit ASCII characters to be stored in a single 8-bit byte. */
/* CFStringEncodings which are a superset of ASCII encoding include MacRoman, */
/* WindowsLatin1, ISOLatin1, NextStepLatin, ASCII, and UTF8. */
CF_EXPORT
CFURLRef CFURLCreateAbsoluteURLWithBytes(CFAllocatorRef alloc, const UInt8 *relativeURLBytes, CFIndex length, CFStringEncoding encoding, CFURLRef baseURL, Boolean useCompatibilityMode);

/* filePath should be the URL's path expressed as a path of the type */
/* fsType.  If filePath is not absolute, the resulting URL will be */
/* considered relative to the current working directory (evaluated */
/* at creation time).  isDirectory determines whether filePath is */
/* treated as a directory path when resolving against relative path */
/* components */
CF_EXPORT
CFURLRef CFURLCreateWithFileSystemPath(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory);

CF_EXPORT
CFURLRef CFURLCreateFromFileSystemRepresentation(CFAllocatorRef allocator, const UInt8 *buffer, CFIndex bufLen, Boolean isDirectory);

/* The path style of the baseURL must match the path style of the relative */
/* url or the results are undefined.  If the provided filePath looks like an */
/* absolute path ( starting with '/' if pathStyle is kCFURLPosixPathStyle, */
/* not starting with ':' for kCFURLHFSPathStyle, or starting with what looks */
/* like a drive letter and colon for kCFURLWindowsPathStyle ) then the baseURL */
/* is ignored. */
CF_EXPORT
CFURLRef CFURLCreateWithFileSystemPathRelativeToBase(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory, CFURLRef baseURL); 

CF_EXPORT
CFURLRef CFURLCreateFromFileSystemRepresentationRelativeToBase(CFAllocatorRef allocator, const UInt8 *buffer, CFIndex bufLen, Boolean isDirectory, CFURLRef baseURL);
                                                                         
/* Fills buffer with the file system's native representation of */
/* url's path. No more than maxBufLen bytes are written to buffer. */
/* The buffer should be at least the maximum path length for */
/* the file system in question to avoid failures for insufficiently */
/* large buffers.  If resolveAgainstBase is true, the url's relative */
/* portion is resolved against its base before the path is computed. */
/* Returns success or failure. */
CF_EXPORT
Boolean CFURLGetFileSystemRepresentation(CFURLRef url, Boolean resolveAgainstBase, UInt8 *buffer, CFIndex maxBufLen);

/* Creates a new URL by resolving the relative portion of relativeURL against its base. */
CF_EXPORT
CFURLRef CFURLCopyAbsoluteURL(CFURLRef relativeURL);

/* Returns the URL's string. Percent-escape sequences are not removed. */
CF_EXPORT
CFStringRef CFURLGetString(CFURLRef anURL);

/* Returns the base URL if it exists */
CF_EXPORT
CFURLRef CFURLGetBaseURL(CFURLRef anURL);

/*
All URLs can be broken into two pieces - the scheme (preceding the
first colon) and the resource specifier (following the first colon).
Most URLs are also "standard" URLs conforming to RFC 1808 (available
from www.w3c.org).  This category includes URLs of the file, http,
https, and ftp schemes, to name a few.  Standard URLs start the
resource specifier with two slashes ("//"), and can be broken into
four distinct pieces - the scheme, the net location, the path, and
further resource specifiers (typically an optional parameter, query,
and/or fragment).  The net location appears immediately following
the two slashes and goes up to the next slash; it's format is
scheme-specific, but is usually composed of some or all of a username,
password, host name, and port.  The path is a series of path components
separated by slashes; if the net location is present, the path always
begins with a slash.  Standard URLs can be relative to another URL,
in which case at least the scheme and possibly other pieces as well
come from the base URL (see RFC 1808 for precise details when resolving
a relative URL against its base).  The full URL is therefore

<scheme> "://" <net location> <path, always starting with slash> <add'l resource specifiers>

If a given CFURL can be decomposed (that is, conforms to RFC 1808), you
can ask for each of the four basic pieces (scheme, net location, path,
and resource specifier) separately, as well as for its base URL.  The
basic pieces are returned with any percent-escape sequences still in
place (although note that the scheme may not legally include any
percent-escapes); this is to allow the caller to distinguish between
percent-escape sequences that may have syntactic meaning if replaced by the
character being escaped (for instance, a '/' in a path component).
Since only the individual schemes know which characters are
syntactically significant, CFURL cannot safely replace any percent-
escape sequences.  However, you can use
CFURLCreateStringByReplacingPercentEscapes() to create a new string with
the percent-escapes removed; see below.

If a given CFURL can not be decomposed, you can ask for its scheme and its
resource specifier; asking it for its net location or path will return NULL.

To get more refined information about the components of a decomposable
CFURL, you may ask for more specific pieces of the URL, expressed with
the percent-escapes removed.  The available functions are CFURLCopyHostName(),
CFURLGetPortNumber() (returns an Int32), CFURLCopyUserName(),
CFURLCopyPassword(), CFURLCopyQuery(), CFURLCopyParameters(), and
CFURLCopyFragment().  Because the parameters, query, and fragment of an
URL may contain scheme-specific syntaxes, these methods take a second
argument, giving a list of characters which should NOT be replaced if
percent-escaped.  For instance, the ftp parameter syntax gives simple
key-value pairs as "<key>=<value>;"  Clearly if a key or value includes
either '=' or ';', it must be escaped to avoid corrupting the meaning of
the parameters, so the caller may request the parameter string as

CFStringRef myParams = CFURLCopyParameters(ftpURL, CFSTR("=;%"));

requesting that all percent-escape sequences be replaced by the represented
characters, except for escaped '=', '%' or ';' characters.  Pass the empty
string (CFSTR("")) to request that all percent-escapes be replaced, or NULL
to request that none be.
*/

/* Returns true if anURL conforms to RFC 1808 */
CF_EXPORT
Boolean CFURLCanBeDecomposed(CFURLRef anURL); 

CF_EXPORT
CFStringRef CFURLCopyScheme(CFURLRef anURL);

/* Percent-escape sequences are not removed. NULL if CFURLCanBeDecomposed(anURL) is false */
CF_EXPORT
CFStringRef CFURLCopyNetLocation(CFURLRef anURL); 

/* NULL if CFURLCanBeDecomposed(anURL) is false; also does not resolve the URL */
/* against its base.  See also CFURLCopyAbsoluteURL().  Note that, strictly */
/* speaking, any leading '/' is not considered part of the URL's path, although */
/* its presence or absence determines whether the path is absolute. */
/* CFURLCopyPath()'s return value includes any leading slash (giving the path */
/* the normal POSIX appearance); CFURLCopyStrictPath()'s return value omits any */
/* leading slash, and uses isAbsolute to report whether the URL's path is absolute. */

/* Percent-escape sequences are not removed. */
CF_EXPORT
CFStringRef CFURLCopyPath(CFURLRef anURL);

/* Percent-escape sequences are not removed. */
CF_EXPORT
CFStringRef CFURLCopyStrictPath(CFURLRef anURL, Boolean *isAbsolute);

/* CFURLCopyFileSystemPath() returns the URL's path as a file system path for the */
/* given path style.  All percent-escape sequences are removed.  The URL is not */
/* resolved against its base before computing the path. */
CF_EXPORT
CFStringRef CFURLCopyFileSystemPath(CFURLRef anURL, CFURLPathStyle pathStyle);

/* Returns whether anURL's path represents a directory */
/* (true returned) or a simple file (false returned) */
CF_EXPORT
Boolean CFURLHasDirectoryPath(CFURLRef anURL);

/* Any additional resource specifiers after the path.  For URLs */
/* that cannot be decomposed, this is everything except the scheme itself. */
/* Percent-escape sequences are not removed. */
CF_EXPORT
CFStringRef CFURLCopyResourceSpecifier(CFURLRef anURL); 

/* Percent-escape sequences are removed. */
CF_EXPORT
CFStringRef CFURLCopyHostName(CFURLRef anURL);

CF_EXPORT
SInt32 CFURLGetPortNumber(CFURLRef anURL); /* Returns -1 if no port number is specified */

/* Percent-escape sequences are removed. */
CF_EXPORT
CFStringRef CFURLCopyUserName(CFURLRef anURL);

/* Percent-escape sequences are removed. */
CF_EXPORT
CFStringRef CFURLCopyPassword(CFURLRef anURL);

/* CFURLCopyParameterString, CFURLCopyQueryString, and CFURLCopyFragment */
/* remove all percent-escape sequences except those for */
/* characters in charactersToLeaveEscaped.  If charactersToLeaveEscaped */
/* is empty (""), all percent-escape sequences are replaced by their */
/* corresponding characters.  If charactersToLeaveEscaped is NULL, */
/* then no escape sequences are removed at all */
CF_EXPORT
CFStringRef CFURLCopyParameterString(CFURLRef anURL, CFStringRef charactersToLeaveEscaped) API_DEPRECATED("The CFURLCopyParameterString function is deprecated. Post deprecation for applications linked with or after the macOS 10.15, and for all iOS, watchOS, and tvOS applications, CFURLCopyParameterString will always return NULL, and the CFURLCopyPath(), CFURLCopyStrictPath(), and CFURLCopyFileSystemPath() functions will return the complete path including the semicolon separator and params component if the URL string contains them.", macosx(10.2,10.15), ios(2.0,13.0), watchos(2.0,6.0), tvos(9.0,13.0));
CF_EXPORT
CFStringRef CFURLCopyQueryString(CFURLRef anURL, CFStringRef charactersToLeaveEscaped);

CF_EXPORT
CFStringRef CFURLCopyFragment(CFURLRef anURL, CFStringRef charactersToLeaveEscaped);

/* Percent-escape sequences are removed. */
CF_EXPORT
CFStringRef CFURLCopyLastPathComponent(CFURLRef url);

/* Percent-escape sequences are removed. */
CF_EXPORT
CFStringRef CFURLCopyPathExtension(CFURLRef url);

CF_EXPORT
CFURLRef CFURLCreateCopyAppendingPathComponent(CFAllocatorRef allocator, CFURLRef url, CFStringRef pathComponent, Boolean isDirectory);

CF_EXPORT
CFURLRef CFURLCreateCopyDeletingLastPathComponent(CFAllocatorRef allocator, CFURLRef url);

CF_EXPORT
CFURLRef CFURLCreateCopyAppendingPathExtension(CFAllocatorRef allocator, CFURLRef url, CFStringRef extension);

CF_EXPORT
CFURLRef CFURLCreateCopyDeletingPathExtension(CFAllocatorRef allocator, CFURLRef url);

/* Fills buffer with the bytes for url, returning the number of bytes */
/* filled.  If buffer is of insufficient size, returns -1 and no bytes */
/* are placed in buffer.  If buffer is NULL, the needed length is */
/* computed and returned.  The returned bytes are the original bytes */ 
/* from which the URL was created; if the URL was created from a */
/* string, the bytes will be the bytes of the string encoded via UTF-8. */
/* */
/* Note: Due to incompatibilities between encodings, it might be impossible to */
/* generate bytes from the base URL in the encoding of the relative URL or relative bytes, */
/* which will cause this method to fail and return -1, even if a NULL buffer is passed.  */
/* To avoid this scenario, use UTF-8, UTF-16, or UTF-32 encodings exclusively, or */
/* use one non-Unicode encoding exclusively. */
CF_EXPORT
CFIndex CFURLGetBytes(CFURLRef url, UInt8 *buffer, CFIndex bufferLength);

typedef CF_ENUM(CFIndex, CFURLComponentType) {
	kCFURLComponentScheme = 1,
	kCFURLComponentNetLocation = 2,
	kCFURLComponentPath = 3,
	kCFURLComponentResourceSpecifier = 4,

	kCFURLComponentUser = 5,
	kCFURLComponentPassword = 6,
	kCFURLComponentUserInfo = 7,
	kCFURLComponentHost = 8,
	kCFURLComponentPort = 9,
	kCFURLComponentParameterString = 10,
	kCFURLComponentQuery = 11,
	kCFURLComponentFragment = 12
};
 
/* 
Gets the  range of the requested component in the bytes of url, as
returned by CFURLGetBytes().  This range is only good for use in the
bytes returned by CFURLGetBytes!

If non-NULL, rangeIncludingSeparators gives the range of component
including the sequences that separate component from the previous and
next components.  If there is no previous or next component, that end of
rangeIncludingSeparators will match the range of the component itself.
If url does not contain the given component type, (kCFNotFound, 0) is
returned, and rangeIncludingSeparators is set to the location where the
component would be inserted.  Some examples -

For the URL http://www.apple.com/hotnews/

Component           returned range      rangeIncludingSeparators
scheme              (0, 4)              (0, 7)
net location        (7, 13)             (4, 16)
path                (20, 9)             (20, 9)    
resource specifier  (kCFNotFound, 0)    (29, 0)
user                (kCFNotFound, 0)    (7, 0)
password            (kCFNotFound, 0)    (7, 0)
user info           (kCFNotFound, 0)    (7, 0)
host                (7, 13)             (4, 16)
port                (kCFNotFound, 0)    (20, 0)
parameter           (kCFNotFound, 0)    (29, 0)
query               (kCFNotFound, 0)    (29, 0)
fragment            (kCFNotFound, 0)    (29, 0)


For the URL ./relPath/file.html#fragment

Component           returned range      rangeIncludingSeparators
scheme              (kCFNotFound, 0)    (0, 0)
net location        (kCFNotFound, 0)    (0, 0)
path                (0, 19)             (0, 20)
resource specifier  (20, 8)             (19, 9)
user                (kCFNotFound, 0)    (0, 0)
password            (kCFNotFound, 0)    (0, 0)
user info           (kCFNotFound, 0)    (0, 0)
host                (kCFNotFound, 0)    (0, 0)
port                (kCFNotFound, 0)    (0, 0)
parameter           (kCFNotFound, 0)    (19, 0)
query               (kCFNotFound, 0)    (19, 0)
fragment            (20, 8)             (19, 9)


For the URL scheme://user:pass@host:1/path/path2/file.html;params?query#fragment

Component           returned range      rangeIncludingSeparators
scheme              (0, 6)              (0, 9)
net location        (9, 16)             (6, 19)
path                (25, 21)            (25, 22) 
resource specifier  (47, 21)            (46, 22)
user                (9, 4)              (6, 8)
password            (14, 4)             (13, 6)
user info           (9, 9)              (6, 13)
host                (19, 4)             (18, 6)
port                (24, 1)             (23, 2)
parameter           (47, 6)             (46, 8)
query               (54, 5)             (53, 7)
fragment            (60, 8)             (59, 9)
*/
CF_EXPORT
CFRange CFURLGetByteRangeForComponent(CFURLRef url, CFURLComponentType component, CFRange *rangeIncludingSeparators);

/* Returns a string with any percent-escape sequences that do NOT */
/* correspond to characters in charactersToLeaveEscaped with their */
/* equivalent.  Returns NULL on failure (if an invalid percent-escape sequence */
/* is encountered), or the original string (retained) if no characters */
/* need to be replaced. Pass NULL to request that no percent-escapes be */
/* replaced, or the empty string (CFSTR("")) to request that all percent- */
/* escapes be replaced.  Uses UTF8 to interpret percent-escapes. */
CF_EXPORT
CFStringRef CFURLCreateStringByReplacingPercentEscapes(CFAllocatorRef allocator, CFStringRef originalString, CFStringRef charactersToLeaveEscaped);

/* As above, but allows you to specify the encoding to use when interpreting percent-escapes */
CF_EXPORT
CFStringRef CFURLCreateStringByReplacingPercentEscapesUsingEncoding(CFAllocatorRef allocator, CFStringRef origString, CFStringRef charsToLeaveEscaped, CFStringEncoding encoding) API_DEPRECATED("Use [NSString stringByRemovingPercentEncoding] or CFURLCreateStringByReplacingPercentEscapes() instead, which always uses the recommended UTF-8 encoding.", macos(10.0,10.11), ios(2.0,9.0), watchos(2.0,2.0), tvos(9.0,9.0));

/* Creates a copy or originalString, replacing certain characters with */
/* the equivalent percent-escape sequence based on the encoding specified. */
/* If the originalString does not need to be modified (no percent-escape */
/* sequences are missing), may retain and return originalString. */
/* If you are uncertain of the correct encoding, you should use UTF-8, */
/* which is the encoding designated by RFC 2396 as the correct encoding */
/* for use in URLs.  The characters so escaped are all characters that */
/* are not legal URL characters (based on RFC 2396), plus any characters */
/* in legalURLCharactersToBeEscaped, less any characters in */
/* charactersToLeaveUnescaped.  To simply correct any non-URL characters */
/* in an otherwise correct URL string, do: */
/*      newString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, origString, NULL, NULL, kCFStringEncodingUTF8); */
CF_EXPORT
CFStringRef CFURLCreateStringByAddingPercentEscapes(CFAllocatorRef allocator, CFStringRef originalString, CFStringRef charactersToLeaveUnescaped, CFStringRef legalURLCharactersToBeEscaped, CFStringEncoding encoding) API_DEPRECATED("Use [NSString stringByAddingPercentEncodingWithAllowedCharacters:] instead, which always uses the recommended UTF-8 encoding, and which encodes for a specific URL component or subcomponent (since each URL component or subcomponent has different rules for what characters are valid).", macos(10.0,10.11), ios(2.0,9.0), watchos(2.0,2.0), tvos(9.0,9.0));


#if TARGET_OS_MAC || CF_BUILDING_CF || NSBUILDINGFOUNDATION
CF_IMPLICIT_BRIDGING_DISABLED

/*
    CFURLIsFileReferenceURL

    Returns whether the URL is a file reference URL.

    Parameters
        url
            The URL specifying the resource.
 */
CF_EXPORT
Boolean CFURLIsFileReferenceURL(CFURLRef url) API_AVAILABLE(macos(10.9), ios(7.0), watchos(2.0), tvos(9.0));

/*
    CFURLCreateFileReferenceURL
    
    Returns a new file reference URL that refers to the same resource as a specified URL.

    Parameters
        allocator
            The memory allocator for creating the new URL.
        url
            The file URL specifying the resource.
        error
            On output when the result is NULL, the error that occurred. This parameter is optional; if you do not wish the error returned, pass NULL here. The caller is responsible for releasing a valid output error.

    Return Value
        The new file reference URL, or NULL if an error occurs.

    Discussion
        File reference URLs use a URL path syntax that identifies a file system object by reference, not by path. This form of file URL remains valid when the file system path of the URL’s underlying resource changes. An error will occur if the url parameter is not a file URL. File reference URLs cannot be created to file system objects which do not exist or are not reachable. In some areas of the file system hierarchy, file reference URLs cannot be generated to the leaf node of the URL path. A file reference URL's path should never be persistently stored because is not valid across system restarts, and across remounts of volumes -- if you want to create a persistent reference to a file system object, use a bookmark (see CFURLCreateBookmarkData). If this function returns NULL, the optional error is populated. This function is currently applicable only to URLs for file system resources.
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
CFURLRef CFURLCreateFileReferenceURL(CFAllocatorRef allocator, CFURLRef url, CFErrorRef *error) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));


/*
    CFURLCreateFilePathURL
    
    Returns a new file path URL that refers to the same resource as a specified URL.

    Parameters
        allocator
            The memory allocator for creating the new URL.
        url
            The file URL specifying the resource.
        error
            On output when the result is NULL, the error that occurred. This parameter is optional; if you do not wish the error returned, pass NULL here. The caller is responsible for releasing a valid output error.

    Return Value
        The new file path URL, or NULL if an error occurs.

    Discussion
        File path URLs use a file system style path. An error will occur if the url parameter is not a file URL. A file reference URL's resource must exist and be reachable to be converted to a file path URL. If this function returns NULL, the optional error is populated. This function is currently applicable only to URLs for file system resources.
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
CFURLRef CFURLCreateFilePathURL(CFAllocatorRef allocator, CFURLRef url, CFErrorRef *error) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

CF_IMPLICIT_BRIDGING_ENABLED
#endif



#if TARGET_OS_MAC || CF_BUILDING_CF || NSBUILDINGFOUNDATION || DEPLOYMENT_RUNTIME_SWIFT
CF_IMPLICIT_BRIDGING_DISABLED

/* Resource access

    The behavior of resource value caching is slightly different between the NSURL and CFURL API.

    When the NSURL methods which get, set, or use cached resource values are used from the main thread, resource values cached by the URL (except those added as temporary properties) are invalidated the next time the main thread's run loop runs.

    The CFURL functions do not automatically clear any resource values cached by the URL. The client has complete control over the cache lifetime. If you are using CFURL API, you must use CFURLClearResourcePropertyCacheForKey or CFURLClearResourcePropertyCache to clear cached resource values.
 */


/*
    CFURLCopyResourcePropertyForKey
    
    Returns the resource value identified by a given resource key.

    Parameters
        url
            The URL specifying the resource.
        key
            The resource key that identifies the resource property.
        propertyValueTypeRefPtr
            On output when the result is true, the resource value or NULL.
        error
            On output when the result is false, the error that occurred. This parameter is optional; if you do not wish the error returned, pass NULL here. The caller is responsible for releasing a valid output error.

    Return Value
        true if propertyValueTypeRefPtr is successfully populated; false if an error occurs.

    Discussion
        CFURLCopyResourcePropertyForKey first checks if the URL object already caches the resource value. If so, it returns the cached resource value to the caller. If not, then CFURLCopyResourcePropertyForKey synchronously obtains the resource value from the backing store, adds the resource value to the URL object's cache, and returns the resource value to the caller. The type of the resource value varies by resource property (see resource key definitions). If this function returns true and propertyValueTypeRefPtr is populated with NULL, it means the resource property is not available for the specified resource and no errors occurred when determining the resource property was not available. If this function returns false, the optional error is populated. This function is currently applicable only to URLs for file system resources.
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
Boolean CFURLCopyResourcePropertyForKey(CFURLRef url, CFStringRef key, void *propertyValueTypeRefPtr, CFErrorRef *error) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));


/*
    CFURLCopyResourcePropertiesForKeys
    
    Returns the resource values identified by specified array of resource keys.

    Parameters
        url
            The URL specifying the resource.
        keys
            An array of resource keys that identify the resource properties.
        error
            On output when the result is NULL, the error that occurred. This parameter is optional; if you do not wish the error returned, pass NULL here. The caller is responsible for releasing a valid output error.

    Return Value
        A dictionary of resource values indexed by resource key; NULL if an error occurs.

    Discussion
        CFURLCopyResourcePropertiesForKeys first checks if the URL object already caches the resource values. If so, it returns the cached resource values to the caller. If not, then CFURLCopyResourcePropertyForKey synchronously obtains the resource values from the backing store, adds the resource values to the URL object's cache, and returns the resource values to the caller. The type of the resource values vary by property (see resource key definitions). If the result dictionary does not contain a resource value for one or more of the requested resource keys, it means those resource properties are not available for the specified resource and no errors occurred when determining those resource properties were not available. If this function returns NULL, the optional error is populated. This function is currently applicable only to URLs for file system resources.
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
CFDictionaryRef CFURLCopyResourcePropertiesForKeys(CFURLRef url, CFArrayRef keys, CFErrorRef *error) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));


/*
    CFURLSetResourcePropertyForKey
    
    Sets the resource value identified by a given resource key.

    Parameters
        url
            The URL specifying the resource.
        key
            The resource key that identifies the resource property.
        propertyValue
            The resource value.
        error
            On output when the result is false, the error that occurred. This parameter is optional; if you do not wish the error returned, pass NULL here. The caller is responsible for releasing a valid output error.

    Return Value
        true if the attempt to set the resource value completed with no errors; otherwise, false.

    Discussion
        CFURLSetResourcePropertyForKey writes the new resource value out to the backing store. Attempts to set a read-only resource property or to set a resource property not supported by the resource are ignored and are not considered errors. If this function returns false, the optional error is populated. This function is currently applicable only to URLs for file system resources.
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
Boolean CFURLSetResourcePropertyForKey(CFURLRef url, CFStringRef key, CFTypeRef propertyValue, CFErrorRef *error) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));


/*
    CFURLSetResourcePropertiesForKeys
    
    Sets any number of resource values of a URL's resource.

    Parameters
        url
            The URL specifying the resource.
        keyedPropertyValues
            A dictionary of resource values indexed by resource keys.
        error
            On output when the result is false, the error that occurred. This parameter is optional; if you do not wish the error returned, pass NULL here. The caller is responsible for releasing a valid output error.

    Return Value
        true if the attempt to set the resource values completed with no errors; otherwise, false.

    Discussion
        CFURLSetResourcePropertiesForKeys writes the new resource values out to the backing store. Attempts to set read-only resource properties or to set resource properties not supported by the resource are ignored and are not considered errors. If an error occurs after some resource properties have been successfully changed, the userInfo dictionary in the returned error contains an array of resource keys that were not set with the key kCFURLKeysOfUnsetValuesKey. The order in which the resource values are set is not defined. If you need to guarantee the order resource values are set, you should make multiple requests to CFURLSetResourcePropertiesForKeys or CFURLSetResourcePropertyForKey to guarantee the order. If this function returns false, the optional error is populated. This function is currently applicable only to URLs for file system resources.
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
Boolean CFURLSetResourcePropertiesForKeys(CFURLRef url, CFDictionaryRef keyedPropertyValues, CFErrorRef *error) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));


CF_EXPORT
const CFStringRef kCFURLKeysOfUnsetValuesKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* Key for the resource properties that have not been set after the CFURLSetResourcePropertiesForKeys function returns an error, returned as an array of of CFString objects. */


/*
    CFURLClearResourcePropertyCacheForKey
    
    Discards a cached resource value of a URL.

    Parameters
        url
            The URL specifying the resource.
        key
            The resource key that identifies the resource property.

    Discussion
        Discarding a cached resource value may discard other cached resource values, because some resource values are cached as a set of values and because some resource values depend on other resource values (temporary properties have no dependencies). This function is currently applicable only to URLs for file system resources.
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
void CFURLClearResourcePropertyCacheForKey(CFURLRef url, CFStringRef key) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));


/*
    CFURLClearResourcePropertyCache
    
    Discards all cached resource values of a URL.

    Parameters
        url
            The URL specifying the resource.

    Discussion
        All temporary properties are also cleared from the URL object's cache. This function is currently applicable only to URLs for file system resources.
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
void CFURLClearResourcePropertyCache(CFURLRef url) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));


/*
    CFURLSetTemporaryResourcePropertyForKey
    
    Sets a temporary resource value on the URL object.

    Parameters
        url
            The URL object.
        key
            The resource key that identifies the temporary resource property.
        propertyValue
            The resource value.

    Discussion
        Temporary properties are for client use. Temporary properties exist only in memory and are never written to the resource's backing store. Once set, a temporary value can be copied from the URL object with CFURLCopyResourcePropertyForKey and CFURLCopyResourcePropertiesForKeys. To remove a temporary value from the URL object, use CFURLClearResourcePropertyCacheForKey. Temporary values must be valid Core Foundation types, and will be retained by CFURLSetTemporaryResourcePropertyForKey. Care should be taken to ensure the key that identifies a temporary resource property is unique and does not conflict with system defined keys (using reverse domain name notation in your temporary resource property keys is recommended). This function is currently applicable only to URLs for file system resources.
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
void CFURLSetTemporaryResourcePropertyForKey(CFURLRef url, CFStringRef key, CFTypeRef propertyValue) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));


/*
    CFURLResourceIsReachable
    
    Returns whether the URL's resource exists and is reachable.

    Parameters
        url
            The URL object.
        error
            On output when the result is false, the error that occurred. This parameter is optional; if you do not wish the error returned, pass NULL here. The caller is responsible for releasing a valid output error.

    Return Value
        true if the resource is reachable; otherwise, false.

    Discussion
        CFURLResourceIsReachable synchronously checks if the resource's backing store is reachable. Checking reachability is appropriate when making decisions that do not require other immediate operations on the resource, e.g. periodic maintenance of UI state that depends on the existence of a specific document. When performing operations such as opening a file or copying resource properties, it is more efficient to simply try the operation and handle failures. This function is currently applicable only to URLs for file system resources. If this function returns false, the optional error is populated. For other URL types, false is returned. 
        Symbol is present in iOS 4, but performs no operation.
 */
CF_EXPORT
Boolean CFURLResourceIsReachable(CFURLRef url, CFErrorRef *error) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

CF_IMPLICIT_BRIDGING_ENABLED


/* Properties of File System Resources */

CF_EXPORT 
const CFStringRef kCFURLNameKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* The resource name provided by the file system (Read-write, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLLocalizedNameKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* Localized or extension-hidden name as displayed to users (Read-only, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLIsRegularFileKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* True for regular files (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsDirectoryKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* True for directories (Read-only, CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsSymbolicLinkKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* True for symlinks (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsVolumeKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* True for the root directory of a volume (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsPackageKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* True for packaged directories (Read-only 10_6 and 10_7, read-write 10_8, value type CFBoolean). Note: You can only set or clear this property on directories; if you try to set this property on non-directory objects, the property is ignored. If the directory is a package for some other reason (extension type, etc), setting this property to false will have no effect. */

CF_EXPORT
const CFStringRef kCFURLIsApplicationKey API_AVAILABLE(macos(10.11), ios(9.0), watchos(2.0), tvos(9.0));
    /* True if resource is an application (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLApplicationIsScriptableKey API_AVAILABLE(macos(10.11)) API_UNAVAILABLE(ios, watchos, tvos);
    /* True if the resource is scriptable. Only applies to applications. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsSystemImmutableKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* True for system-immutable resources (Read-write, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsUserImmutableKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* True for user-immutable resources (Read-write, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsHiddenKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* True for resources normally not displayed to users (Read-write, value type CFBoolean). Note: If the resource is a hidden because its name starts with a period, setting this property to false will not change the property. */

CF_EXPORT
const CFStringRef kCFURLHasHiddenExtensionKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* True for resources whose filename extension is removed from the localized name property (Read-write, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLCreationDateKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* The date the resource was created (Read-write, value type CFDate) */

CF_EXPORT
const CFStringRef kCFURLContentAccessDateKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* The date the resource was last accessed (Read-write, value type CFDate) */

CF_EXPORT
const CFStringRef kCFURLContentModificationDateKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* The time the resource content was last modified (Read-write, value type CFDate) */

CF_EXPORT
const CFStringRef kCFURLAttributeModificationDateKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* The time the resource's attributes were last modified (Read-only, value type CFDate) */

CF_EXPORT
const CFStringRef kCFURLFileContentIdentifierKey API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0), tvos(14.0));
    /* A 64-bit value assigned by APFS that identifies a file's content data stream. Only cloned files and their originals can have the same identifier. (CFNumber) */

CF_EXPORT
const CFStringRef kCFURLMayShareFileContentKey API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0), tvos(14.0));
    /* True for cloned files and their originals that may share all, some, or no data blocks. (CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLMayHaveExtendedAttributesKey API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0), tvos(14.0));
    /* True if the file has extended attributes. False guarantees there are none. (CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsPurgeableKey API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0), tvos(14.0));
    /* True if the file can be deleted by the file system when asked to free space. (CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsSparseKey API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0), tvos(14.0));
    /* True if the file has sparse regions. (CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLLinkCountKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* Number of hard links to the resource (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLParentDirectoryURLKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* The resource's parent directory, if any (Read-only, value type CFURL) */

CF_EXPORT
const CFStringRef kCFURLVolumeURLKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* URL of the volume on which the resource is stored (Read-only, value type CFURL) */

CF_EXPORT
const CFStringRef kCFURLTypeIdentifierKey API_DEPRECATED("Use NSURLContentTypeKey instead", macos(10.6, API_TO_BE_DEPRECATED), ios(4.0, API_TO_BE_DEPRECATED), watchos(2.0, API_TO_BE_DEPRECATED), tvos(9.0, API_TO_BE_DEPRECATED));
    /* Uniform type identifier (UTI) for the resource (Read-only, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLLocalizedTypeDescriptionKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* User-visible type or "kind" description (Read-only, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLLabelNumberKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* The label number assigned to the resource (Read-write, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLLabelColorKey API_DEPRECATED("Use NSURLLabelColorKey", macosx(10.6, 10.12), ios(4.0,10.0), watchos(2.0,3.0), tvos(9.0,10.0));
    /* not implemented */

CF_EXPORT
const CFStringRef kCFURLLocalizedLabelKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* The user-visible label text (Read-only, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLEffectiveIconKey API_DEPRECATED("Use NSURLEffectiveIconKey", macosx(10.6, 10.12), ios(4.0,10.0), watchos(2.0,3.0), tvos(9.0,10.0));
    /* not implemented */

CF_EXPORT
const CFStringRef kCFURLCustomIconKey API_DEPRECATED("Use NSURLCustomIconKey", macosx(10.6, 10.12), ios(4.0,10.0), watchos(2.0,3.0), tvos(9.0,10.0));
    /* not implemented */

CF_EXPORT
const CFStringRef kCFURLFileResourceIdentifierKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* An identifier which can be used to compare two file system objects for equality using CFEqual (i.e, two object identifiers are equal if they have the same file system path or if the paths are linked to same inode on the same file system). This identifier is not persistent across system restarts. (Read-only, value type CFType) */

CF_EXPORT
const CFStringRef kCFURLVolumeIdentifierKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* An identifier that can be used to identify the volume the file system object is on. Other objects on the same volume will have the same volume identifier and can be compared using for equality using CFEqual. This identifier is not persistent across system restarts. (Read-only, value type CFType) */

CF_EXPORT
const CFStringRef kCFURLPreferredIOBlockSizeKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* The optimal block size when reading or writing this file's data, or NULL if not available. (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLIsReadableKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if this process (as determined by EUID) can read the resource. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsWritableKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if this process (as determined by EUID) can write to the resource. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLIsExecutableKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if this process (as determined by EUID) can execute a file resource or search a directory resource. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLFileSecurityKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* The file system object's security information encapsulated in a CFFileSecurity object. (Read-write, value type CFFileSecurity) */

CF_EXPORT
const CFStringRef kCFURLIsExcludedFromBackupKey API_AVAILABLE(macos(10.8), ios(5.1), watchos(2.0), tvos(9.0));
    /* true if resource should be excluded from backups, false otherwise (Read-write, value type CFBoolean). This property is only useful for excluding cache and other application support files which are not needed in a backup. Some operations commonly made to user documents will cause this property to be reset to false and so this property should not be used on user documents. */

CF_EXPORT
const CFStringRef kCFURLTagNamesKey API_AVAILABLE(macos(10.9)) API_UNAVAILABLE(ios, watchos, tvos);
    /* The array of Tag names (Read-write, value type CFArray of CFString) */
    
CF_EXPORT
const CFStringRef kCFURLPathKey API_AVAILABLE(macos(10.8), ios(6.0), watchos(2.0), tvos(9.0));
    /* the URL's path as a file system path (Read-only, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLCanonicalPathKey API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
    /* the URL's path as a canonical absolute file system path (Read-only, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLIsMountTriggerKey API_AVAILABLE(macos(10.7), ios(4.0), watchos(2.0), tvos(9.0));
    /* true if this URL is a file system trigger directory. Traversing or opening a file system trigger will cause an attempt to mount a file system on the trigger directory. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLGenerationIdentifierKey API_AVAILABLE(macos(10.10), ios(8.0), watchos(2.0), tvos(9.0));
    /* An opaque generation identifier which can be compared using CFEqual() to determine if the data in a document has been modified. For URLs which refer to the same file inode, the generation identifier will change when the data in the file's data fork is changed (changes to extended attributes or other file system metadata do not change the generation identifier). For URLs which refer to the same directory inode, the generation identifier will change when direct children of that directory are added, removed or renamed (changes to the data of the direct children of that directory will not change the generation identifier). The generation identifier is persistent across system restarts. The generation identifier is tied to a specific document on a specific volume and is not transferred when the document is copied to another volume. This property is not supported by all volumes. (Read-only, value type CFType) */

CF_EXPORT
const CFStringRef kCFURLDocumentIdentifierKey API_AVAILABLE(macos(10.10), ios(8.0), watchos(2.0), tvos(9.0));
    /* The document identifier -- a value assigned by the kernel to a document (which can be either a file or directory) and is used to identify the document regardless of where it gets moved on a volume. The document identifier survives "safe save” operations; i.e it is sticky to the path it was assigned to (-replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error: is the preferred safe-save API). The document identifier is persistent across system restarts. The document identifier is not transferred when the file is copied. Document identifiers are only unique within a single volume. This property is not supported by all volumes. (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLAddedToDirectoryDateKey API_AVAILABLE(macos(10.10), ios(8.0), watchos(2.0), tvos(9.0));
    /* The date the resource was created, or renamed into or within its parent directory. Note that inconsistent behavior may be observed when this attribute is requested on hard-linked items. This property is not supported by all volumes. (Read-only before macOS 10.15, iOS 13.0, watchOS 6.0, and tvOS 13.0; Read-write after, value type CFDate) */

CF_EXPORT
const CFStringRef kCFURLQuarantinePropertiesKey API_AVAILABLE(macos(10.10)) API_UNAVAILABLE(ios, watchos, tvos);
    /* The quarantine properties as defined in LSQuarantine.h. To remove quarantine information from a file, pass kCFNull as the value when setting this property. (Read-write, value type CFDictionary) */

CF_EXPORT
const CFStringRef kCFURLFileResourceTypeKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* Returns the file system object type. (Read-only, value type CFString) */

/* The file system object type values returned for the kCFURLFileResourceTypeKey */
CF_EXPORT
const CFStringRef kCFURLFileResourceTypeNamedPipe API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
CF_EXPORT
const CFStringRef kCFURLFileResourceTypeCharacterSpecial API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
CF_EXPORT
const CFStringRef kCFURLFileResourceTypeDirectory API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
CF_EXPORT
const CFStringRef kCFURLFileResourceTypeBlockSpecial API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
CF_EXPORT
const CFStringRef kCFURLFileResourceTypeRegular API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
CF_EXPORT
const CFStringRef kCFURLFileResourceTypeSymbolicLink API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
CF_EXPORT
const CFStringRef kCFURLFileResourceTypeSocket API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
CF_EXPORT
const CFStringRef kCFURLFileResourceTypeUnknown API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));

/* File Properties */

CF_EXPORT
const CFStringRef kCFURLFileSizeKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* Total file size in bytes (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLFileAllocatedSizeKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* Total size allocated on disk for the file in bytes (number of blocks times block size) (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLTotalFileSizeKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* Total displayable size of the file in bytes (this may include space used by metadata), or NULL if not available. (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLTotalFileAllocatedSizeKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* Total allocated size of the file in bytes (this may include space used by metadata), or NULL if not available. This can be less than the value returned by kCFURLTotalFileSizeKey if the resource is compressed. (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLIsAliasFileKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /*  true if the resource is a Finder alias file or a symlink, false otherwise ( Read-only, value type CFBooleanRef) */

CF_EXPORT
const CFStringRef kCFURLFileProtectionKey API_AVAILABLE(ios(9.0), watchos(2.0), tvos(9.0)) API_UNAVAILABLE(macos);
    /* The protection level for this file */

/* The protection level values returned for the kCFURLFileProtectionKey */
CF_EXPORT
const CFStringRef kCFURLFileProtectionNone API_AVAILABLE(ios(9.0), watchos(2.0), tvos(9.0)) API_UNAVAILABLE(macos); // The file has no special protections associated with it. It can be read from or written to at any time.

CF_EXPORT
const CFStringRef kCFURLFileProtectionComplete API_AVAILABLE(ios(9.0), watchos(2.0), tvos(9.0)) API_UNAVAILABLE(macos); // The file is stored in an encrypted format on disk and cannot be read from or written to while the device is locked or booting.

CF_EXPORT
const CFStringRef kCFURLFileProtectionCompleteUnlessOpen API_AVAILABLE(ios(9.0), watchos(2.0), tvos(9.0)) API_UNAVAILABLE(macos); // The file is stored in an encrypted format on disk. Files can be created while the device is locked, but once closed, cannot be opened again until the device is unlocked. If the file is opened when unlocked, you may continue to access the file normally, even if the user locks the device. There is a small performance penalty when the file is created and opened, though not when being written to or read from. This can be mitigated by changing the file protection to kCFURLFileProtectionComplete when the device is unlocked.

CF_EXPORT
const CFStringRef kCFURLFileProtectionCompleteUntilFirstUserAuthentication API_AVAILABLE(ios(9.0), watchos(2.0), tvos(9.0)) API_UNAVAILABLE(macos); // The file is stored in an encrypted format on disk and cannot be accessed until after the device has booted. After the user unlocks the device for the first time, your app can access the file and continue to access it even if the user subsequently locks the device.

/* Volume Properties */

/* As a convenience, volume properties can be requested from any file system URL. The value returned will reflect the property value for the volume on which the resource is located. */

CF_EXPORT
const CFStringRef kCFURLVolumeLocalizedFormatDescriptionKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* The user-visible volume format (Read-only, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLVolumeTotalCapacityKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* Total volume capacity in bytes (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLVolumeAvailableCapacityKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* Total free space in bytes (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLVolumeAvailableCapacityForImportantUsageKey API_AVAILABLE(macos(10.13), ios(11.0)) API_UNAVAILABLE(watchos, tvos);
    /* Total available capacity in bytes for "Important" resources, including space expected to be cleared by purging non-essential and cached resources. "Important" means something that the user or application clearly expects to be present on the local system, but is ultimately replaceable. This would include items that the user has explicitly requested via the UI, and resources that an application requires in order to provide functionality.
 
     Examples: A video that the user has explicitly requested to watch but has not yet finished watching or an audio file that the user has requested to download.
 
     This value should not be used in determining if there is room for an irreplaceable resource. In the case of irreplaceable resources, always attempt to save the resource regardless of available capacity and handle failure as gracefully as possible. (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLVolumeAvailableCapacityForOpportunisticUsageKey API_AVAILABLE(macos(10.13), ios(11.0)) API_UNAVAILABLE(watchos, tvos);
    /* Total available capacity in bytes for "Opportunistic" resources, including space expected to be cleared by purging non-essential and cached resources. "Opportunistic" means something that the user is likely to want but does not expect to be present on the local system, but is ultimately non-essential and replaceable. This would include items that will be created or downloaded without an explicit request from the user on the current device.
 
     Examples: A background download of a newly available episode of a TV series that a user has been recently watching, a piece of content explicitly requested on another device, or a new document saved to a network server by the current user from another device. (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLVolumeResourceCountKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* Total number of resources on the volume (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsPersistentIDsKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* true if the volume format supports persistent object identifiers and can look up file system objects by their IDs (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsSymbolicLinksKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* true if the volume format supports symbolic links (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsHardLinksKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* true if the volume format supports hard links (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsJournalingKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* true if the volume format supports a journal used to speed recovery in case of unplanned restart (such as a power outage or crash). This does not necessarily mean the volume is actively using a journal. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsJournalingKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* true if the volume is currently using a journal for speedy recovery after an unplanned restart. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsSparseFilesKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* true if the volume format supports sparse files, that is, files which can have 'holes' that have never been written to, and thus do not consume space on disk. A sparse file may have an allocated size on disk that is less than its logical length. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsZeroRunsKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* For security reasons, parts of a file (runs) that have never been written to must appear to contain zeroes. true if the volume keeps track of allocated but unwritten runs of a file so that it can substitute zeroes without actually writing zeroes to the media. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsCaseSensitiveNamesKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* true if the volume format treats upper and lower case characters in file and directory names as different. Otherwise an upper case character is equivalent to a lower case character, and you can't have two names that differ solely in the case of the characters. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsCasePreservedNamesKey API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    /* true if the volume format preserves the case of file and directory names.  Otherwise the volume may change the case of some characters (typically making them all upper or all lower case). (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsRootDirectoryDatesKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume supports reliable storage of times for the root directory. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsVolumeSizesKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume supports returning volume size values (kCFURLVolumeTotalCapacityKey and kCFURLVolumeAvailableCapacityKey). (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsRenamingKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume can be renamed. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsAdvisoryFileLockingKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume implements whole-file flock(2) style advisory locks, and the O_EXLOCK and O_SHLOCK flags of the open(2) call. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsExtendedSecurityKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume implements extended security (ACLs). (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsBrowsableKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume should be visible via the GUI (i.e., appear on the Desktop as a separate volume). (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeMaximumFileSizeKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* The largest file size (in bytes) supported by this file system, or NULL if this cannot be determined. (Read-only, value type CFNumber) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsEjectableKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume's media is ejectable from the drive mechanism under software control. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsRemovableKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume's media is removable from the drive mechanism. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsInternalKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume's device is connected to an internal bus, false if connected to an external bus, or NULL if not available. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsAutomountedKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume is automounted. Note: do not mistake this with the functionality provided by kCFURLVolumeSupportsBrowsingKey. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsLocalKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume is stored on a local device. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsReadOnlyKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if the volume is read-only. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeCreationDateKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* The volume's creation date, or NULL if this cannot be determined. (Read-only, value type CFDate) */

CF_EXPORT
const CFStringRef kCFURLVolumeURLForRemountingKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* The CFURL needed to remount a network volume, or NULL if not available. (Read-only, value type CFURL) */

CF_EXPORT
const CFStringRef kCFURLVolumeUUIDStringKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* The volume's persistent UUID as a string, or NULL if a persistent UUID is not available for the volume. (Read-only, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLVolumeNameKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* The name of the volume (Read-write, settable if kCFURLVolumeSupportsRenamingKey is true and permissions allow, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLVolumeLocalizedNameKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* The user-presentable name of the volume (Read-only, value type CFString) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsEncryptedKey API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
    /* true if the volume is encrypted. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeIsRootFileSystemKey API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
    /* true if the volume is the root filesystem. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsCompressionKey API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
    /* true if the volume supports transparent decompression of compressed files using decmpfs. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsFileCloningKey API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
    /* true if the volume supports clonefile(2) (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsSwapRenamingKey API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
    /* true if the volume supports renamex_np(2)'s RENAME_SWAP option (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsExclusiveRenamingKey API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
    /* true if the volume supports renamex_np(2)'s RENAME_EXCL option (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsImmutableFilesKey API_AVAILABLE(macosx(10.13), ios(11.0), watchos(4.0), tvos(11.0));
    /* true if the volume supports making files immutable with the kCFURLIsUserImmutableKey or kCFURLIsSystemImmutableKey properties (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsAccessPermissionsKey API_AVAILABLE(macosx(10.13), ios(11.0), watchos(4.0), tvos(11.0));
    /* true if the volume supports setting POSIX access permissions with the kCFURLFileSecurityKey property (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLVolumeSupportsFileProtectionKey API_AVAILABLE(macosx(10.16), ios(14.0), watchos(7.0), tvos(14.0));
    /* true if the volume supports data protection for files (see kCFURLFileProtectionKey). (Read-only, value type CFBoolean) */

/* UbiquitousItem Properties */

CF_EXPORT
const CFStringRef kCFURLIsUbiquitousItemKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if this item is synced to the cloud, false if it is only a local file. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemHasUnresolvedConflictsKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if this item has conflicts outstanding. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemIsDownloadedKey API_DEPRECATED("Use kCFURLUbiquitousItemDownloadingStatusKey instead", macos(10.7,10.9), ios(5.0,7.0), watchos(2.0,2.0), tvos(9.0,9.0));
    /* Equivalent to NSURLUbiquitousItemDownloadingStatusKey == NSURLUbiquitousItemDownloadingStatusCurrent. Has never behaved as documented in earlier releases, hence deprecated. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemIsDownloadingKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if data is being downloaded for this item. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemIsUploadedKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if there is data present in the cloud for this item. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemIsUploadingKey API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));
    /* true if data is being uploaded for this item. (Read-only, value type CFBoolean) */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemPercentDownloadedKey API_DEPRECATED("Use NSMetadataQuery and NSMetadataUbiquitousItemPercentDownloadedKey on NSMetadataItem instead", macos(10.7,10.8), ios(5.0,6.0), watchos(2.0,2.0), tvos(9.0,9.0));
    /* Use NSMetadataQuery and NSMetadataUbiquitousItemPercentDownloadedKey on NSMetadataItem instead */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemPercentUploadedKey API_DEPRECATED("Use NSMetadataQuery and NSMetadataUbiquitousItemPercentUploadedKey on NSMetadataItem instead", macos(10.7,10.8), ios(5.0,6.0), watchos(2.0,2.0), tvos(9.0,9.0));
    /* Use NSMetadataQuery and NSMetadataUbiquitousItemPercentUploadedKey on NSMetadataItem instead */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemDownloadingStatusKey API_AVAILABLE(macos(10.9), ios(7.0), watchos(2.0), tvos(9.0));
    /* Returns the download status of this item. (Read-only, value type CFString). Possible values below. */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemDownloadingErrorKey API_AVAILABLE(macos(10.9), ios(7.0), watchos(2.0), tvos(9.0));
    /* returns the error when downloading the item from iCloud failed. See the NSUbiquitousFile section in FoundationErrors.h. (Read-only, value type CFError) */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemUploadingErrorKey API_AVAILABLE(macos(10.9), ios(7.0), watchos(2.0), tvos(9.0));
    /* returns the error when uploading the item to iCloud failed. See the NSUbiquitousFile section in FoundationErrors.h. (Read-only, value type CFError) */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemIsExcludedFromSyncKey API_AVAILABLE(macos(11.3), ios(14.5), watchos(7.4), tvos(14.5));
    /* the item is excluded from sync, which means it is locally on disk but won't be available on the server. An excluded item is no longer ubiquitous. */

/* The values returned for kCFURLUbiquitousItemDownloadingStatusKey
 */
CF_EXPORT
const CFStringRef kCFURLUbiquitousItemDownloadingStatusNotDownloaded API_AVAILABLE(macos(10.9), ios(7.0), watchos(2.0), tvos(9.0));
    /* this item has not been downloaded yet. Use NSFileManager's startDownloadingUbiquitousItemAtURL:error: to download it */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemDownloadingStatusDownloaded API_AVAILABLE(macos(10.9), ios(7.0), watchos(2.0), tvos(9.0));
    /* there is a local version of this item available. The most current version will get downloaded as soon as possible. */

CF_EXPORT
const CFStringRef kCFURLUbiquitousItemDownloadingStatusCurrent API_AVAILABLE(macos(10.9), ios(7.0), watchos(2.0), tvos(9.0));
    /* there is a local version of this item and it is the most up-to-date version known to this device. */

#if !DEPLOYMENT_TARGET_SWIFT

typedef CF_OPTIONS(CFOptionFlags, CFURLBookmarkCreationOptions) {
    kCFURLBookmarkCreationMinimalBookmarkMask = ( 1UL << 9 ), // creates bookmark data with "less" information, which may be smaller but still be able to resolve in certain ways
    kCFURLBookmarkCreationSuitableForBookmarkFile = ( 1UL << 10 ), // include the properties required by CFURLWriteBookmarkDataToFile() in the bookmark data created
    kCFURLBookmarkCreationWithSecurityScope API_AVAILABLE(macos(10.7))  API_UNAVAILABLE(ios, watchos, tvos) = ( 1UL << 11 ), // Mac OS X 10.7.3 and later, include information in the bookmark data which allows the same sandboxed process to access the resource after being relaunched
    kCFURLBookmarkCreationSecurityScopeAllowOnlyReadAccess API_AVAILABLE(macos(10.7)) API_UNAVAILABLE(ios, watchos, tvos) = ( 1UL << 12 ), // Mac OS X 10.7.3 and later, if used with kCFURLBookmarkCreationWithSecurityScope, at resolution time only read access to the resource will be granted
    kCFURLBookmarkCreationWithoutImplicitSecurityScope  API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0)) = (1 << 29), // Disable automatic embedding of an implicit security scope. The resolving process will not be able gain access to the resource by security scope, either implicitly or explicitly, through the returned URL. Not applicable to security-scoped bookmarks.
    
    // deprecated
    kCFURLBookmarkCreationPreferFileIDResolutionMask
    API_DEPRECATED("kCFURLBookmarkCreationPreferFileIDResolutionMask does nothing and has no effect on bookmark resolution", macos(10.6,10.9), ios(4.0,7.0)) = ( 1UL << 8 ),
} API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

typedef CF_OPTIONS(CFOptionFlags, CFURLBookmarkResolutionOptions) {
    kCFURLBookmarkResolutionWithoutUIMask = ( 1UL << 8 ), // don't perform any user interaction during bookmark resolution
    kCFURLBookmarkResolutionWithoutMountingMask = ( 1UL << 9 ), // don't mount a volume during bookmark resolution
    kCFURLBookmarkResolutionWithSecurityScope API_AVAILABLE(macos(10.7)) API_UNAVAILABLE(ios, watchos, tvos) = ( 1UL << 10 ), // Mac OS X 10.7.3 and later, use the secure information included at creation time to provide the ability to access the resource in a sandboxed process.
    kCFURLBookmarkResolutionWithoutImplicitStartAccessing API_AVAILABLE(macos(11.2), ios(14.2), watchos(7.2), tvos(14.2)) = ( 1 << 15 ), // Disable implicitly starting access of the ephemeral security-scoped resource during resolution. Instead, call `CFURLStartAccessingSecurityScopedResource` on the returned URL when ready to use the resource. Not applicable to security-scoped bookmarks.

    kCFBookmarkResolutionWithoutUIMask = kCFURLBookmarkResolutionWithoutUIMask,
    kCFBookmarkResolutionWithoutMountingMask = kCFURLBookmarkResolutionWithoutMountingMask,
} API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

typedef CFOptionFlags CFURLBookmarkFileCreationOptions;

CF_IMPLICIT_BRIDGING_DISABLED

/* Returns bookmark data for the URL, created with specified options and resource properties. If this function returns NULL, the optional error is populated.
 */
CF_EXPORT
CFDataRef CFURLCreateBookmarkData ( CFAllocatorRef allocator, CFURLRef url, CFURLBookmarkCreationOptions options, CFArrayRef resourcePropertiesToInclude, CFURLRef relativeToURL, CFErrorRef* error ) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

/* Return a URL that refers to a location specified by resolving bookmark data. If this function returns NULL, the optional error is populated.
 */
CF_EXPORT
CFURLRef CFURLCreateByResolvingBookmarkData ( CFAllocatorRef allocator, CFDataRef bookmark, CFURLBookmarkResolutionOptions options, CFURLRef relativeToURL, CFArrayRef resourcePropertiesToInclude, Boolean* isStale, CFErrorRef* error ) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

/* Returns the resource properties identified by a specified array of keys contained in specified bookmark data. If the result dictionary does not contain a resource value for one or more of the requested resource keys, it means those resource properties are not available in the bookmark data.
 */
CF_EXPORT
CFDictionaryRef CFURLCreateResourcePropertiesForKeysFromBookmarkData ( CFAllocatorRef allocator, CFArrayRef resourcePropertiesToReturn, CFDataRef bookmark ) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

/*  Returns the resource property identified by a given resource key contained in specified bookmark data. If this function returns NULL, it means the resource property is not available in the bookmark data.
 */
CF_EXPORT
CFTypeRef  CFURLCreateResourcePropertyForKeyFromBookmarkData( CFAllocatorRef allocator, CFStringRef resourcePropertyKey, CFDataRef bookmark ) API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));

/* Returns bookmark data derived from an alias file referred to by fileURL. If fileURL refers to an alias file created prior to OS X v10.6 that contains Alias Manager information but no bookmark data, this method synthesizes bookmark data for the file. If this method returns NULL, the optional error is populated.
 */
CF_EXPORT
CFDataRef CFURLCreateBookmarkDataFromFile(CFAllocatorRef allocator, CFURLRef fileURL, CFErrorRef *errorRef ) API_AVAILABLE(macos(10.6), ios(5.0), watchos(2.0), tvos(9.0));

/* Creates an alias file on disk at a specified location with specified bookmark data. The bookmark data must have been created with the kCFURLBookmarkCreationSuitableForBookmarkFile option. fileURL must either refer to an existing file (which will be overwritten), or to location in an existing directory. If this method returns FALSE, the optional error is populated.
 */
CF_EXPORT
Boolean CFURLWriteBookmarkDataToFile( CFDataRef bookmarkRef, CFURLRef fileURL, CFURLBookmarkFileCreationOptions options, CFErrorRef *errorRef ) API_AVAILABLE(macos(10.6), ios(5.0), watchos(2.0), tvos(9.0));

/* Returns bookmark data derived from an alias record.
 */
CF_EXPORT
CFDataRef CFURLCreateBookmarkDataFromAliasRecord ( CFAllocatorRef allocatorRef, CFDataRef aliasRecordDataRef ) API_DEPRECATED("The Carbon Alias Manager is deprecated. This function should only be used to convert Carbon AliasRecords to bookmark data.", macos(10.6,10.16)) API_UNAVAILABLE(ios, watchos, tvos);

CF_IMPLICIT_BRIDGING_ENABLED

/* Given a CFURLRef created by resolving a bookmark data created with security scope, make the resource referenced by the url accessible to the process. When access to this resource is no longer needed the client must call CFURLStopAccessingSecurityScopedResource(). Each call to CFURLStartAccessingSecurityScopedResource() must be balanced with a call to CFURLStopAccessingSecurityScopedResource() (Note: this is not reference counted).
 */
CF_EXPORT
Boolean CFURLStartAccessingSecurityScopedResource(CFURLRef url) API_AVAILABLE(macos(10.7), ios(8.0), watchos(2.0), tvos(9.0)); // On OSX, available in MacOS X 10.7.3 and later

/* Revokes the access granted to the url by a prior successful call to CFURLStartAccessingSecurityScopedResource().
 */
CF_EXPORT
void CFURLStopAccessingSecurityScopedResource(CFURLRef url) API_AVAILABLE(macos(10.7), ios(8.0), watchos(2.0), tvos(9.0)); // On OSX, available in MacOS X 10.7.3 and later

#endif /* !DEPLOYMENT_TARGET_SWIFT */
#endif /*  TARGET_OS_MAC || CF_BUILDING_CF || NSBUILDINGFOUNDATION || DEPLOYMENT_RUNTIME_SWIFT */

CF_EXTERN_C_END
CF_IMPLICIT_BRIDGING_DISABLED

#endif /* ! __COREFOUNDATION_CFURL__ */

