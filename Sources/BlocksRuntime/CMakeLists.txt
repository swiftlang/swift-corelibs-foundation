
add_library(BlocksRuntime
  data.c
  runtime.c)

target_include_directories(BlocksRuntime PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR})

set_target_properties(BlocksRuntime PROPERTIES
  POSITION_INDEPENDENT_CODE FALSE)

add_library(BlocksRuntime::BlocksRuntime ALIAS BlocksRuntime)
