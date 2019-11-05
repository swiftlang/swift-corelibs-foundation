
add_executable(GenerateTestFixtures
  GenerateTestFixtures/main.swift
  GenerateTestFixtures/Utilities.swift
  ../../TestFoundation/FixtureValues.swift)
target_link_libraries(GenerateTestFixtures PRIVATE
  Foundation)
