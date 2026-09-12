cmake_minimum_required(VERSION 3.20)

add_library(parakeet_sdk INTERFACE)

target_include_directories(parakeet_sdk INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
