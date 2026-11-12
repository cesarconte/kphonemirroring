cmake_minimum_required(VERSION 3.22)
project(kphonemirroring VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Test)

# The CachyOS.UI design system provides the QML module and the shared layout
# auditor. It is installed system wide or in the user prefix.
list(APPEND CMAKE_PREFIX_PATH "$ENV{HOME}/.local" "/usr/local")
find_package(CachyOSUITesting REQUIRED)

set(SOURCES
    src/main.cpp
    src/DeviceManager.h
    src/DeviceManager.cpp
    src/MirrorSession.h
    src/MirrorSession.cpp
    src/kphonemirroring.qrc
)

add_executable(kphonemirroring ${SOURCES})

target_link_libraries(kphonemirroring PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

target_include_directories(kphonemirroring PRIVATE src)

install(TARGETS kphonemirroring DESTINATION bin)
install(FILES data/org.cesar.kphonemirroring.desktop DESTINATION share/applications)
install(FILES src/resources/icons/kphonemirroring.svg DESTINATION share/icons/hicolor/scalable/apps)

enable_testing()
add_subdirectory(tests)
