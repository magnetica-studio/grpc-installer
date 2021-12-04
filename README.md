### このプロジェクトについて

このプロジェクトは、 macOS と iOS 用の GRPC をビルドするプロジェクトです。

### GRPC のインストール方法

```sh
cd /path/to/develop
git clone git@github.com:magnetica-studio/grpc-installer.git
cd grpc-installer

# 目的のバージョン（タグ名）を指定して install.sh スクリプトファイルを実行します。
./install.sh v1.42.0

# 指定したバージョン名のディレクトリで macOS 用と iOS 用それぞれの GRPC がビルド／インストールされます。
# `build-*` ディレクトリがビルドディレクトリ、 `install-*` ディレクトリがインストールディレクトリになります。
# `build-*` ディレクトリは、ビルド／インストール完了後には使用しないので、削除しても問題ありません。
ls -la ./v1.42.0
```

### インストールした GRPC の利用方法

GRPC を利用する C++ プロジェクトの CMakeLists.txt から、以下のように `cmake/grpc.cmake` をインクルードします。

```cmake
set(TARGET_GRPC_VERSION "v1.42.0")
include("/path/to/develop/grpc-installer/cmake/grpc.cmake")
```

これによって以下の変数が用意されます

* `_PROTOBUF_LIBPROTOBUF`: ProtocolBuffer のインクルード／リンク設定を含むターゲットを表す変数
* `_GRPC_GRPCPP`: GRPC の `gRPC::grpc++` ターゲットを表す変数
* `_PROTOBUF_PROTOC`: protoc コマンドのパス（iOS 向けのビルド時も macOS 用にビルドした方のコマンドのパスになる。）
* `_GRPC_CPP_PLUGIN_EXECUTABLE`: grpc_cpp_plugin コマンドのパス（iOS 向けのビルド時も macOS 用にビルドした方のコマンドのパスになる。）
