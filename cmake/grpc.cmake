cmake_minimum_required(VERSION 3.20.0)

if(MSVC)
  add_definitions(-D_WIN32_WINNT=0x600)
endif()

find_package(Threads REQUIRED)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
  set(PLATFORM_NAME "iOS")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(PLATFORM_NAME "macOS")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(PLATFORM_NAME "Linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(PLATFORM_NAME "Windows")
else()
  message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()
message(STATUS "PLATFORM_NAME: ${PLATFORM_NAME}")

# macOS 向けには grpc を universal binary としてビルドしているため、
# CMAKE_OSX_ARCHITECTURES によらず universal binary 用の
# インストールディレクトリを使用する。
if(${PLATFORM_NAME} STREQUAL "macOS")
  set(ARCH_NAME universal)
elseif(${PLATFORM_NAME} STREQUAL "iOS")
  set(ARCH_NAME arm64)
else()
  set(ARCH_NAME x86_64)
endif()

if(NOT DEFINED TARGET_GRPC_VERSION)
    message(FATAL_ERROR "TARGET_GRPC_VERSION not specified.")
endif()

set(GRPC_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../${TARGET_GRPC_VERSION}")
cmake_path(NORMAL_PATH GRPC_ROOT_DIR)
set(GRPC_INSTALL_DIR "${GRPC_ROOT_DIR}/install-${PLATFORM_NAME}-${ARCH_NAME}")
message(STATUS "GRPC_INSTALL_DIR: ${GRPC_INSTALL_DIR}")

set(protobuf_MODULE_COMPATIBLE ON CACHE BOOL "test" FORCE)
set(Protobuf_USE_STATIC_LIBS ON)

if(${PLATFORM_NAME} STREQUAL "Windows")
  set(Protobuf_DIR ${GRPC_INSTALL_DIR}/cmake)
else()
  set(Protobuf_DIR ${GRPC_INSTALL_DIR}/lib/cmake/protobuf)
endif()
message(STATUS "Protobuf_DIR: ${Protobuf_DIR}")

find_package(Protobuf CONFIG REQUIRED NO_DEFAULT_PATH)

set(absl_DIR ${GRPC_INSTALL_DIR}/lib/cmake/absl)
find_package(absl CONFIG REQUIRED NO_DEFAULT_PATH)

# Find gRPC installation
# Looks for gRPCConfig.cmake file installed by gRPC's cmake installation.
set(gRPC_DIR ${GRPC_INSTALL_DIR}/lib/cmake/grpc)
find_package(gRPC CONFIG REQUIRED NO_DEFAULT_PATH)

message(STATUS "Found gRPC version: ${gRPC_VERSION}")

set(_GRPC_GRPCPP gRPC::grpc++)
set(_PROTOBUF_LIBPROTOBUF protobuf::libprotobuf)
set(_PROTOBUF_PROTOC ${Protobuf_PROTOC_EXECUTABLE})
set(_GRPC_CPP_PLUGIN_EXECUTABLE ${GRPC_INSTALL_DIR}/bin/grpc_cpp_plugin)

