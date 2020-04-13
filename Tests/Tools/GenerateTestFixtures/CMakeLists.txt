add_executable(GenerateTestFixtures
  main.swift
  Utilities.swift
  ../../Foundation/FixtureValues.swift)
target_link_libraries(GenerateTestFixtures PRIVATE
  Foundation)
