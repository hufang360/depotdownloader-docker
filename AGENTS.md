# AGENTS.md

本文件为在本仓库中工作的 AI 编码代理（及人类贡献者）提供指引。请先读完再改代码。

## 项目简介

本仓库把 [SteamRE/DepotDownloader](https://github.com/SteamRE/DepotDownloader)
（Steam 仓库 / 创意工坊下载器）打包成 Docker 镜像。

- 镜像仓库：Docker Hub `hufang360/depotdownloader`
- GitHub：<https://github.com/hufang360/depotdownloader-docker>
- 支持平台：`linux/amd64`、`linux/arm64`
- 当前内置版本：DepotDownloader **3.4.0**（.NET 9）

这不是上游源码仓库，只是打包项目。**不要**在这里改 DepotDownloader 的业务逻辑；
上游发布新版时，只需升级版本号并重新构建。

## 仓库结构

| 文件 | 说明 |
| ---- | ---- |
| `Dockerfile` | 多阶段构建：stage `fetch` 下载官方发布包，stage 2 基于 `mcr.microsoft.com/dotnet/runtime-deps:9.0-bookworm-slim` |
| `entrypoint.sh` | 入口脚本，丢弃旧版 `download` 子命令后启动 `/usr/local/bin/DepotDownloader` |
| `docker-compose.yml` | 本地运行配置 |
| `README.md` | 面向使用者的中文说明（含各类下载示例） |
| `.github/workflows/docker.yml` | 打 tag 时自动多架构构建并推送 Docker Hub |
| `.dockerignore` / `.gitignore` | 构建与 git 忽略规则 |

## 关键约定（改动时必须遵守）

1. **版本单一来源**：DepotDownloader 版本只写在 `Dockerfile` 的
   `ARG DD_VERSION=3.4.0`。升级只改这一处（或通过 `--build-arg` 覆盖）。
2. **镜像名固定**为 `hufang360/depotdownloader`。README 中的运行示例必须使用
   完整镜像名，不要写裸 `depotdownloader:3.4.0`（那是本地测试 tag）。
3. **必须保持双架构**：`linux/amd64,linux/arm64`。不要为了省事只构建单架构。
4. **`TARGETARCH` 映射**：Docker 的 `amd64/arm64/arm` 对应上游发布包的
   `x64/arm64/arm`。改这块时务必同步更新 README 的平台说明。
5. **工作目录 `/steam`**：`account.config`（凭据/2FA token）和默认 `depots/`
   都在这里，并用 `VOLUME ["/steam"]` 声明。不要把工作目录改到别处。
6. **向后兼容**：`entrypoint.sh` 会丢弃开头的 `download`，让旧镜像
   （`wurstmitdurst/depotdownloader`）的命令继续可用。不要移除该逻辑。
7. **语言**：README 与本文件以中文为主，代码与注释可用英文。
8. **凭据安全**：绝不提交 `steam/`（含 `account.config`），绝不在仓库里写
   Docker Hub token。密钥只通过 GitHub Secrets 注入。

## 本地构建

```bash
# 本机架构
docker build -t depotdownloader:3.4.0 .

# 指定版本
docker build --build-arg DD_VERSION=3.4.0 -t depotdownloader:3.4.0 .

# 网络无法访问 GitHub Release 时用镜像源
docker build --build-arg DD_RELEASE_BASE=https://<mirror>/... -t depotdownloader:3.4.0 .
```

## 多架构构建并推送

`docker buildx` 的默认 docker driver **不支持**多平台。需使用
`docker-container` 驱动的 builder（本机已建好名为 `multiarch` 的实例）：

```bash
# 仅需一次
docker buildx create --name multiarch --driver docker-container --bootstrap --use

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --provenance=false --sbom=false \
  --build-arg DD_VERSION=3.4.0 \
  -t hufang360/depotdownloader:3.4.0 \
  -t hufang360/depotdownloader:latest \
  --push .
```

多架构镜像不能 `--load` 到本地，只能 `--push`。

## 发布新版本

上游发布新版（例如 3.5.0）时：

1. 改 `Dockerfile` 里的 `ARG DD_VERSION=3.5.0`，提交。
2. 打 tag 并推送，触发 CI：

   ```bash
   git tag v3.5.0
   git push origin v3.5.0
   ```

   CI 会从 tag 推导 `DD_VERSION`（`v3.5.0` → `3.5.0`），构建
   `:3.5.0` 与 `:latest` 并推送。

3. 也可在 Actions 页面手动触发 `workflow_dispatch`（此时回退用
   Dockerfile 里的默认版本，只推 `:latest`）。

CI 需要仓库 Secrets：`DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN`
（Docker Hub Access Token，Read & Write）。

> 注意：不要把同一 tag 覆盖到不同版本。新版本用新 tag。

## 测试

```bash
# 版本 / 运行时
docker run --rm hufang360/depotdownloader:3.4.0 --version

# 无参数应打印用法
docker run --rm hufang360/depotdownloader:3.4.0

# 旧写法兼容
docker run --rm hufang360/depotdownloader:3.4.0 download --version

# 校验已推送的多架构 manifest
docker buildx imagetools inspect hufang360/depotdownloader:3.4.0

# 指定架构运行（Apple Silicon 上跑 amd64 会走模拟）
docker run --rm --platform linux/amd64 hufang360/depotdownloader:3.4.0 --version
docker run --rm --platform linux/arm64 hufang360/depotdownloader:3.4.0 --version
```

真实下载测试（可选，匿名可下载饥荒联机版专用服务器）：

```bash
docker run --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 -app 343050
```

## 不要做的事

- 不要提交 `steam/`、`depots/` 或个人凭据。
- 不要把 `linux/amd64,linux/arm64` 改成单平台。
- 不要移除 `DD_VERSION` 构建参数或 `-download` 兼容逻辑。
- 不要在 README 示例里使用未加命名空间的本地镜像名。
- 不要把 token / 密码硬编码进任何文件。
