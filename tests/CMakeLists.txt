# SPDX-FileCopyrightText: 2026 Cesar
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Golden Gate layout audit.
#
# The window is rendered offscreen at several sizes and in every UI state,
# and the resulting QQuickItem tree is audited for the classic design
# defects: protruding items, items sticking out of the window, texts cut
# without elision and the window title overlapping the header clusters.
#
# The auditor itself lives in the design system (CachyOS.UI) so that every
# application of the ecosystem shares the very same invariants.

include(CTest)

# ---------------------------------------------------------------------------
# Unit tests of the backend (device discovery, scrcpy arguments, options)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Golden Gate layout audit
# ---------------------------------------------------------------------------
add_executable(test_layout_audit
    test_layout_audit.cpp
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
    CachyOSUITesting::CachyOSUITesting
)

add_test(NAME test_layout_audit COMMAND test_layout_audit)

# The audit needs the CachyOS.UI QML module; the path can be overridden with
# CACHYOS_UI_IMPORT_PATH for non standard installations.
set_tests_properties(test_layout_audit PROPERTIES
    ENVIRONMENT "CACHYOS_UI_IMPORT_PATH=$ENV{HOME}/.local/lib/qt6/qml"
)
