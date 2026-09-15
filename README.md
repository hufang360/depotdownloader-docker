# DepotDownloader（Docker）

[DepotDownloader](https://github.com/SteamRE/DepotDownloader) Docker镜像，非官方！

借鉴了[wurstmitdurst/depotdownloader](https://hub.docker.com/r/wurstmitdurst/depotdownloader)，由于其停留在 2.3.6 版本，于是尝试打包一个。

## 拉取镜像

```bash
# 拉取镜像
# dockerhub链接：https://hub.docker.com/r/hufang360/depotdownloader
docker pull hufang360/depotdownloader:latest
```

## 使用

```bash
docker run -it --rm
  -v <下载目录>:/steam \
  hufang360/depotdownloader:latest \
  -app <app_id>
```

### 示例

```bash
# 匿名下载，输出到挂载目录
# https://store.steampowered.com/app/730/CounterStrike_2/
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader \
  -app 730

# 登录并记住凭据，下载 Windows 版本到单独目录
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader \
  -app 730 -os windows -dir /steam/730 -username <用户名> -remember-password

# 指定 depot 与 manifest
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader \
  -app 730 -depot 731 -manifest 7617088375292372759

# 下载创意工坊物品
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader \
  -app 730 -pubfile 1885082371 -username <用户名>

# 旧写法同样可用
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader \
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
docker run -it --rm -v "$PWD/steam:/steam" hufang360/depotdownloader -app 105600 -pubfile 2440470208

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
