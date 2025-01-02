# hoge

## docker comoose による docker image の作成

### 環境変数に `compose.yml` のデフォルト値を利用する場合

```sh
docker compose --profile dev-hoge build
```

### `direnv` の環境変数を利用する場合

```sh
direnv allow .
docker compose --profile dev-hoge build
```

## docker comoose によるコンテナサービスの起動・終了
### サービス全体を起動

```sh
docker compose --profile dev-hoge-frontend --profile dev-hoge-backend up -d
```

### サービス全体を終了

```sh
docker compose --profile dev-hoge-frontend --profile dev-hoge-end down -v
```
### frontend サービスを起動

```sh
docker compose --profile dev-hoge-frontend up -d
```

### frontend サービスを終了

```sh
docker compose --profile dev-hoge-frontend down -v
```
### backend サービスを起動

```sh
docker compose --profile dev-hoge-backend up -d
```

### backend サービスを終了

```sh
docker compose --profile dev-hoge-backend down -v
```
