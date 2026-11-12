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

# Golden Gate layout audit: renders the real QML scene offscreen and asserts
# that no item protrudes, gets clipped or overlaps another one.
add_executable(test_layout_audit
    test_layout_audit.cpp
    LayoutAuditor.cpp
    LayoutAuditor.h
    ../src/DeviceManager.cpp
    ../src/MirrorSession.cpp
    ../src/kphonemirroring.qrc
)

target_include_directories(test_layout_audit PRIVATE ../src)
target_link_libraries(test_layout_audit PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Test
)

add_test(NAME test_layout_audit COMMAND test_layout_audit)

# The audit needs the CachyOS.UI QML module; the path can be overridden with
# CACHYOS_UI_IMPORT_PATH for non standard installations.
set_tests_properties(test_layout_audit PROPERTIES
    ENVIRONMENT "CACHYOS_UI_IMPORT_PATH=$ENV{HOME}/.local/lib/qt6/qml"
)
