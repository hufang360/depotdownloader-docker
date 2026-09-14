# DepotDownloader（Docker）

DepotDownloader Docker镜像，非官方。

[SteamRE/DepotDownloader](https://github.com/SteamRE/DepotDownloader) 是 Steam 仓库 / 创意工坊下载器。

本项目是 [`wurstmitdurst/depotdownloader`](https://hub.docker.com/r/wurstmitdurst/depotdownloader)
（仍停留在 DepotDownloader 2.3.6 / .NET Core 2.1）的现代化替代方案。
本镜像内置 DepotDownloader **3.4.0**，运行于 .NET 9，支持 `linux/amd64`、`linux/arm64`。

Docker Hub：<https://hub.docker.com/r/hufang360/depotdownloader>

```bash
# 拉取镜像
docker pull hufang360/depotdownloader:3.4.0
# 或跟随最新版
docker pull hufang360/depotdownloader:latest
```

## 文件说明

| 文件                 | 作用                                         |
| -------------------- | -------------------------------------------- |
| `Dockerfile`         | 多阶段构建（下载官方发布包 → 精简运行时）    |
| `entrypoint.sh`      | 自动忽略旧版 `download` 子命令，然后启动程序 |
| `docker-compose.yml` | 便捷的运行配置                               |
| `README.md`          | 使用说明                                     |

## 构建

```bash
# 本机架构
docker build -t hufang360/depotdownloader:3.4.0 .

# 或指定其他上游版本
docker build --build-arg DD_VERSION=3.4.0 -t hufang360/depotdownloader:3.4.0 .

# 多架构构建
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t hufang360/depotdownloader:3.4.0 \
  -t hufang360/depotdownloader:latest \
  --push .
```

> 若网络无法访问 GitHub Release，可指定镜像源：
> `docker build --build-arg DD_RELEASE_BASE=https://<镜像源>/... -t hufang360/depotdownloader:3.4.0 .`

镜像基于 `mcr.microsoft.com/dotnet/runtime-deps:9.0-bookworm-slim`，
磁盘占用约 230 MB。

## 使用方法

登录时必须加 `-it`（交互式 TTY），因为 DepotDownloader 会提示输入 Steam
密码和 2FA 验证码 / 手机确认。不加该参数会导致登录循环，并可能触发
Steam 的限流。

```
docker run -it --rm \
  -v <下载目录>:/steam \
  --name dd \
  hufang360/depotdownloader:3.4.0 -app <app_id>
```

- `/steam` 是工作目录：`account.config`（保存的凭据 / 2FA token）和默认的
  `depots/` 下载目录都在这里。挂载宿主机目录或命名卷即可持久化。
- 新版 CLI **没有** `download` 子命令（用 `-app <id>`，而不是
  `download -app <id>`）。为了兼容旧镜像，entrypoint 会自动丢弃开头的
  `download`，因此两种写法都可用。

### 示例

```bash
# 匿名下载，输出到挂载目录
# https://store.steampowered.com/app/730/CounterStrike_2/
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 -app 730

# 登录并记住凭据，下载 Windows 版本到单独目录
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 \
  -app 730 -os windows -dir /steam/730 -username <用户名> -remember-password

# 指定 depot 与 manifest
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 \
  -app 730 -depot 731 -manifest 7617088375292372759

# 下载创意工坊物品
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 \
  -app 730 -pubfile 1885082371 -username <用户名>

# 旧写法同样可用
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 \
  download -app 730
```

#### 饥荒联机版专用服务器

饥荒联机版专用服务器（Don't Starve Together Dedicated Server）

```bash
# 参考链接：
# 专用服务器 无商店页面，mod见 联机版的创意工坊
# https://store.steampowered.com/app/322330
# https://steamcommunity.com/app/322330/workshop/
# https://steamdb.info/app/343050/
# https://steamdb.info/app/343050/depots/


# 下载（支持匿名下载，无需登录）
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 -app 343050

# 更新服务器
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 -app 343050 -validate
```

#### 泰拉瑞亚

```bash
# 参考链接：
# https://store.steampowered.com/app/105600
# https://steamdb.info/app/105600/
# https://steamdb.info/app/105600/depots/
# https://steamdb.info/depot/105601/manifests/

# 下载创意工坊物品
# 泰拉瑞亚需要购买，但创意工坊内容可免费下载
# https://steamcommunity.com/sharedfiles/filedetails/?id=2440470208
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 -app 105600 -pubfile 2440470208

# 下载 泰拉瑞亚 v1.4.5.7 Windows版
# 指定 depot 与 manifest
# https://steamdb.info/depot/105601/manifests/
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 -app 105600 -depot 105601 -manifest 6017787954815030231


# 指定要下载的文件
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader:3.4.0 \
  -app 105600 \
  -depot 105601 \
  -manifest 7114157149772065225 \
  -filelist <(cat <<EOF
Terraria.exe
TerrariaServer.exe
serverconfig.txt
changelog.txt
start-server-steam-friends.bat
start-server-steam-private.bat
start-server.bat
EOF
) \
  -username <用户名> -password <密码>
```

### 后台运行

按 `Ctrl+P` 再按 `Ctrl+Q` 可脱离容器但不停止运行：

```bash
docker logs dd      # 查看输出
docker attach dd    # 重新连接
```

### 注意事项

- 容器以 `root` 运行，写入绑定挂载的文件属主为 root。如希望使用宿主机
  用户，可加 `--user "$(id -u):$(id -g)"`，只要挂载目录可写即可。
