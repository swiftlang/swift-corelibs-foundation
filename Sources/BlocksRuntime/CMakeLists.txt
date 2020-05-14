
add_library(BlocksRuntime
  data.c
  runtime.c)

target_include_directories(BlocksRuntime PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR})

set_target_properties(BlocksRuntime PROPERTIES
  POSITION_INDEPENDENT_CODE FALSE)

add_library(BlocksRuntime::BlocksRuntime ALIAS BlocksRuntime)

install(TARGETS BlocksRuntime
  ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>)
