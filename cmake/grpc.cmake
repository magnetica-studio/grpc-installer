cmake_minimum_required(VERSION 3.20.0)

if(MSVC)
  add_definitions(-D_WIN32_WINNT=0x600)
endif()

find_package(Threads REQUIRED)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
  set(PLATFORM_NAME "iOS")
else()
  set(PLATFORM_NAME "macOS")
endif()

if("arm64" IN_LIST CMAKE_OSX_ARCHITECTURES AND "x86_64" IN_LIST CMAKE_OSX_ARCHITECTURES)
  set(ARCH_NAME universal)
elseif(CMAKE_OSX_ARCHITECTURES STREQUAL arm64)
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
set(GRPC_INSTALL_DIR_MACOS "${GRPC_ROOT_DIR}/install-macOS-x86_64")
message(STATUS "GRPC_INSTALL_DIR: ${GRPC_INSTALL_DIR}")

set(protobuf_MODULE_COMPATIBLE ON CACHE BOOL "test" FORCE)
set(Protobuf_USE_STATIC_LIBS ON)
set(Protobuf_DIR ${GRPC_INSTALL_DIR}/lib/cmake/protobuf)
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

if(CMAKE_CROSSCOMPILING)
  message(STATUS "Cross compiling is enabled.")
  set(_PROTOBUF_PROTOC ${GRPC_INSTALL_DIR_MACOS}/bin/protoc)
  set(_GRPC_CPP_PLUGIN_EXECUTABLE ${GRPC_INSTALL_DIR_MACOS}/bin/grpc_cpp_plugin)
else()
  message(STATUS "Cross compiling is disabled.")
  set(_PROTOBUF_PROTOC ${Protobuf_PROTOC_EXECUTABLE})
  set(_GRPC_CPP_PLUGIN_EXECUTABLE ${GRPC_INSTALL_DIR}/bin/grpc_cpp_plugin)
endif()

