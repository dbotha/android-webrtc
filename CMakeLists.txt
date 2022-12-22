cmake_minimum_required(VERSION 3.23)
project(AndroidWebRTC)

set(CMAKE_CXX_STANDARD 17)

add_executable(AndroidWebRTC src/main.cpp)

# Append current dir to the module path so CMake finds our FindWebRTC.cmake file
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

find_package(WebRTC REQUIRED)
target_link_libraries(AndroidWebRTC PRIVATE WebRTC::WebRTC)
