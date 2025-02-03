# templates

- `templates`は基本的なインフラを含むプロジェクトに必要なテンプレートファイル群が配置されています。これらのテンプレートに基づくコード生成は、monorepo toolの1つである `moon`コマンドを利用します。
- `moon`はテンプレートエンジンのバックエンドに [tera](https://keats.github.io/tera/) を採用しています。テンプレートファイルの記法についての詳細は、[moon のコード生成](https://moonrepo.dev/docs/guides/codegen) や [tera](https://keats.github.io/tera/docs/) の公式ドキュメントを参照してください。

## devcontainer を利用する場合の初回セットアップ

- multipass を介さずに devcontainer を利用して開発環境を用意する場合は、モノレポリポジトリルートに`top-level`ディレクトリ下の`.devcontainer/devcontainer.json`を`.devcontainer`ディレクトリごとモノリポジトリルートにコピーします。

## moon コマンドを利用するための初回セットアップ

- `moon`コマンドを利用するため、モノレポリポジトリルート上に `top-level`ディレクトリ下の`.moon/workspace.yml`を`.moon`ディレクトリごとコピーします。

## モノレポリポジトリルート上に必要なファイルの生成

```sh
# モノレポリポジトリルート上で実施
moon generate top-level
```

## フロントエンドに vite と バックエンドに rust を利用するプロジェクトの生成

```sh
# モノレポリポジトリルート上で実施
moon generate vite-rust
```
