# {{ project_name | kebab_case }}

## docker comoose による docker image の作成

### 環境変数に `compose.yml` のデフォルト値を利用する場合

```sh
docker compose --profile dev-{{ project_name | kebab_case }} build
```

### `direnv` の環境変数を利用する場合

```sh
direnv allow .
docker compose --profile dev-{{ project_name | kebab_case }} build
```

## docker comoose によるコンテナサービスの起動・終了

{%- if has_frontend && has_backend %}
### サービス全体を起動

```sh
docker compose --profile dev-{{ project_name | kebab_case }}-frontend --profile dev-{{ project_name | kebab_case }}-backend up -d
```

### サービス全体を終了

```sh
docker compose --profile dev-{{ project_name | kebab_case }}-frontend --profile dev-{{ project_name | kebab_case }}-end down -v
```
{%- endif %}

{%- if has_frontend %}
### frontend サービスを起動

```sh
docker compose --profile dev-{{ project_name | kebab_case }}-frontend up -d
```

### frontend サービスを終了

```sh
docker compose --profile dev-{{ project_name | kebab_case }}-frontend down -v
```
{%- endif %}

{%- if has_backend %}
### backend サービスを起動

```sh
docker compose --profile dev-{{ project_name | kebab_case }}-backend up -d
```

### backend サービスを終了

```sh
docker compose --profile dev-{{ project_name | kebab_case }}-backend down -v
```
{%- endif %}
