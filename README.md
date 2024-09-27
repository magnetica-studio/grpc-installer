# gRPC Installer

## このプロジェクトについて

このプロジェクトは、 GRPC をビルドしてインストールするプロジェクトです。

ビルドターゲットのプラットフォーム

- macOS
- iOS
- Windows
- Linux

macOS 用には、 x86_64 と arm64 の universal binary としてライブラリがビルドされます。
iOS 用には、 arm64 のバイナリのみがビルドされます。


## GRPC のインストール方法

### Prebuilt binary をダウンロードする

以下に必要なバイナリがあれば、それをダウンロードしてインストールするのが早い。

- [iOS v1.48.0](https://novonotes.s3.ap-northeast-1.amazonaws.com/libs/grpc-v1_48_0-install-iOS-arm64.zip)
- [macOS v1.48.0](https://novonotes.s3.ap-northeast-1.amazonaws.com/libs/grpc-v1_48_0-install-macOS-universal.zip)
- [Windows v1.48.0](https://ap-northeast-1.console.aws.amazon.com/s3/object/novonotes?region=ap-northeast-1&bucketType=general&prefix=libs/grpc-v1_48_0-install-Windows-x86_64.zip)
- [Linux v1.48.0](https://novonotes.s3.ap-northeast-1.amazonaws.com/libs/grpc-v1_48_0-install-Linux-x86_64.zip)

インストール手順:
1. 上記リンクから、必要なファイルをダウンロード
2. 解凍すると、`install-macOS-arm64` のようなフォルダになる。
3. `v1.48.0` のようにバージョン名でディレクトリを作る。
4. 3 で作ったディレクトリに 2 で解凍してできたフォルダを配置する。
5. 最終的には以下のようなディレクトリ構造になる。

```
grpc-installer
├── README.md
├── cmake
│   └── grpc.cmake
├── install.sh
└── v1.48.0
    ├── install-iOS-arm64
    └── install-macOS-universal
```


### スクリプトを実行してソースからビルドする

```sh
cd /path/to/develop
git clone git@github.com:magnetica-studio/grpc-installer.git
cd grpc-installer

# 目的のバージョン（タグ名）を指定して install.sh スクリプトファイルを実行します。
./install.sh v1.48.0

# 指定したバージョン名のディレクトリで macOS 用と iOS 用それぞれの GRPC がビルド／インストールされます。
# `build-*` ディレクトリがビルドディレクトリ、 `install-*` ディレクトリがインストールディレクトリになります。
# `build-*` ディレクトリは、ビルド／インストール完了後には使用しないので、削除しても問題ありません。
ls -la ./v1.48.0
```

## インストールした GRPC の CMake での利用方法

GRPC を利用する C++ プロジェクトの CMakeLists.txt から、以下のように `cmake/grpc.cmake` をインクルードします。

```cmake
set(TARGET_GRPC_VERSION "v1.48.0")
include("/path/to/develop/grpc-installer/cmake/grpc.cmake")
```

これによって以下の変数が用意されます

- `_PROTOBUF_LIBPROTOBUF`: ProtocolBuffer のインクルード／リンク設定を含むターゲットを表す変数
- `_GRPC_GRPCPP`: GRPC の `gRPC::grpc++` ターゲットを表す変数
- `_PROTOBUF_PROTOC`: protoc コマンドのパス（iOS 向けのビルド時も macOS 用にビルドした方のコマンドのパスになる。）
- `_GRPC_CPP_PLUGIN_EXECUTABLE`: grpc_cpp_plugin コマンドのパス（iOS 向けのビルド時も macOS 用にビルドした方のコマンドのパスになる。）
