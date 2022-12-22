cmake_minimum_required(VERSION 3.23)
project(AndroidWebRTC)

set(CMAKE_CXX_STANDARD 17)

add_executable(AndroidWebRTC src/main.cpp)
target_link_libraries(AndroidWebRTC PRIVATE ${WEBRTC_LIBRARY})
add_compile_definitions(WEBRTC_POSIX WEBRTC_ANDROID WEBRTC_LINUX)
include_directories(
        ${WEBRTC_INCLUDE_DIR}
        ${WEBRTC_INCLUDE_DIR}/third_party/abseil-cpp
        ${WEBRTC_INCLUDE_DIR}/third_party/boringssl/src/include
        ${WEBRTC_INCLUDE_DIR}/third_party/libyuv/include
        ${WEBRTC_INCLUDE_DIR}/third_party/zlib
)
