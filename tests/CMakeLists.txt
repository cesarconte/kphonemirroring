add_executable(test_phonemirroring
    test_phonemirroring.cpp
    ../src/DeviceManager.cpp
    ../src/MirrorSession.cpp
)

target_include_directories(test_phonemirroring PRIVATE ../src)
target_link_libraries(test_phonemirroring PRIVATE
    Qt6::Core
    Qt6::Test
)

add_test(NAME test_phonemirroring COMMAND test_phonemirroring)
