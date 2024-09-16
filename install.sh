#!/bin/bash
set -e -u


# クロスプラットフォーム対応のパス解決関数
resolve_path() {
    local path="$1"
    if [[ -z "$path" ]]; then
        echo "エラー: パスが指定されていません" >&2
        return 1
    fi
    
    # readlink -f が利用可能な場合（多くのLinux環境）
    if readlink -f "$path" &>/dev/null; then
        readlink -f "$path"
    else
        # macOSなど、readlink -f が使えない環境用
        local dir=$(cd -P -- "$(dirname -- "$path")" &>/dev/null && pwd -P)
        if [[ -z "$dir" ]]; then
            return 1
        fi
        echo "${dir%/}/${path##*/}"
    fi
}

SCRIPT_PATH=$(resolve_path "${BASH_SOURCE[0]}")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function show_usage {
    echo "Usage: $SCRIPT_NAME <version to install (e.g. v1.41.0)>" 1>&2
}

function show_error {
    echo "Error: $1" 1>&2
}

if [ $# -ne 1 ]; then
    show_error "Invalid arguments."
    show_usage
    exit 1
fi

GRPC_VERSION="$1"

if [ ! -d grpc-source ]; then
    git clone https://github.com/grpc/grpc.git grpc-source
fi

cd grpc-source
git fetch origin
git reset --hard $GRPC_VERSION
git submodule update -i --recursive

function select_cmake_generator() {
    case "$(uname -s)" in
        Darwin*)
            echo "Unix Makefiles"
            ;;
        Linux*)
            echo "Unix Makefiles"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if command -v ninja >/dev/null 2>&1; then
                echo "Ninja"
            elif command -v make >/dev/null 2>&1; then
                echo "Unix Makefiles"
            else
                echo "NMake Makefiles"
            fi
            ;;
        *)
            echo "Unix Makefiles"  # デフォルトのフォールバック
            ;;
    esac
}

CMAKE_GENERATOR=$(select_cmake_generator)

function build_grpc()
{
  local PLATFORM=$1
  local TARGET_ARCH=$2
  local INSTALL_SUFFIX=$3
  local DEPLOYMENT_TARGET=$4
  local CMAKE_OPTIONS=$5
  local DIRNAME_SUFFIX="${PLATFORM}-${INSTALL_SUFFIX}"
  BUILD_DIR=${SCRIPT_DIR}/${GRPC_VERSION}/build-${DIRNAME_SUFFIX}
  INSTALL_DIR=${SCRIPT_DIR}/${GRPC_VERSION}/install-${DIRNAME_SUFFIX}
  mkdir -p $BUILD_DIR
  cmake \
      -B $BUILD_DIR \
      -G "$CMAKE_GENERATOR" \
      -DgRPC_INSTALL=ON \
      -DOPENSSL_NO_ASM=1 \
      -UgRPC_SSL_PROVIDER \
      -DgRPC_SSL_PROVIDER=module \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DgRPC_PROTOBUF_PACKAGE_TYPE=MODULE \
      -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
      -DCMAKE_OSX_ARCHITECTURES=${TARGET_ARCH} \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET} \
      ${CMAKE_OPTIONS} \
      "${SCRIPT_DIR}/grpc-source"
  cmake --build $BUILD_DIR -j 8
  cmake --build $BUILD_DIR --target install
}

# プラットフォーム固有のビルド
case "$(uname -s)" in
    Darwin*)
        echo "Build macOS (universal binaries)"
        build_grpc "macOS" "x86_64;arm64" "universal" 10.11 "-DgRPC_BUILD_CODEGEN=ON"
        
        echo "Build iOS (arm64)"
        build_grpc "iOS" "arm64" "arm64" 13.0 \
            "-DCMAKE_SYSTEM_NAME=iOS -Dprotobuf_BUILD_PROTOC_BINARIES=ON -DgRPC_BUILD_CODEGEN=OFF -DCARES_INSTALL=OFF -DCMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE=YES"
        
        # iOS ビルドの修正
        # iOS ビルドだと、別のプロジェクトから find_package() で protobuf の情報を取得するときに、
        # 特定のターゲットの情報がうまく扱えなくてエラーになる。
        # これを回避するため、 find_package() で呼び出されるスクリプトを修正する。
        perl -0pi -e 's/^.*if.*NOT EXISTS.*file.*$/continue()\n$&/mg' "${SCRIPT_DIR}/$GRPC_VERSION/install-iOS-arm64/lib/cmake/protobuf/protobuf-targets.cmake"
        perl -0pi -e 's/REQUIRED_VARS Protobuf_PROTOC_EXECUTABLE/REQUIRED_VARS/mg' "${SCRIPT_DIR}/$GRPC_VERSION/install-iOS-arm64/lib/cmake/protobuf/protobuf-module.cmake"
        ;;
    Linux*)
        echo "Build Linux (x86_64)"
        build_grpc "Linux" "x86_64" "x86_64" "" "-DgRPC_BUILD_CODEGEN=ON"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "Build Windows (x86_64)"
        build_grpc "Windows" "x86_64" "x86_64" "" "-DgRPC_BUILD_CODEGEN=ON"
        ;;
    *)
        show_error "Unsupported operating system: $(uname -s)"
        exit 1
        ;;
esac

echo "Build completed successfully."