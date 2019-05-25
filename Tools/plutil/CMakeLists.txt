
# FIXME(compnerd) workaround linker flag munging
set(CMAKE_EXE_LINKER_FLAGS "")
set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "")
# FIXME(compnerd) workaround the library search path flag
set(CMAKE_LIBRARY_PATH_FLAG -L)
set(CMAKE_LINK_LIBRARY_FLAG "-l")
set(CMAKE_CREATE_CONSOLE_EXE "")

add_executable(plutil
  main.swift)
target_link_libraries(plutil PRIVATE
  Foundation)

install(TARGETS plutil
        DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})

