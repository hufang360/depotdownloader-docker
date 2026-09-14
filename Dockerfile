# DepotDownloader - Steam depot downloader
#   Upstream project: https://github.com/SteamRE/DepotDownloader
#   Release assets:   https://github.com/SteamRE/DepotDownloader/releases
#
# The image is based on the official self-contained Linux release binaries,
# so it works on linux/amd64, linux/arm64 and linux/arm (v7).
#
# Build:
#   docker build -t depotdownloader:3.4.0 .
#   docker build --build-arg DD_VERSION=3.4.0 -t depotdownloader:3.4.0 .
#
# Multi-arch build:
#   docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 \
#     -t <user>/depotdownloader:3.4.0 --push .

# DepotDownloader release to package. Keep in sync with the upstream tag
# (the tag looks like "DepotDownloader_3.4.0", only the version goes here).
ARG DD_VERSION=3.4.0

################################################################################
# Stage 1 - download the prebuilt self-contained binary for the target arch
################################################################################
FROM debian:bookworm-slim AS fetch

ARG DD_VERSION
ARG TARGETARCH

# Optional: point this at a GitHub mirror/proxy if github.com is unreachable.
ARG DD_RELEASE_BASE=https://github.com/SteamRE/DepotDownloader/releases/download

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl unzip; \
    rm -rf /var/lib/apt/lists/*; \
    case "${TARGETARCH}" in \
        amd64) dd_arch="x64"   ;; \
        arm64) dd_arch="arm64" ;; \
        arm)   dd_arch="arm"   ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    url="${DD_RELEASE_BASE}/DepotDownloader_${DD_VERSION}/DepotDownloader-linux-${dd_arch}.zip"; \
    echo "Downloading ${url}"; \
    curl -fsSL -o /tmp/depotdownloader.zip "${url}"; \
    mkdir -p /out; \
    unzip -q /tmp/depotdownloader.zip -d /out; \
    chmod +x /out/DepotDownloader; \
    rm -f /tmp/depotdownloader.zip

################################################################################
# Stage 2 - minimal runtime image
################################################################################
FROM mcr.microsoft.com/dotnet/runtime-deps:9.0-bookworm-slim

ARG DD_VERSION

LABEL org.opencontainers.image.title="DepotDownloader" \
      org.opencontainers.image.description="Steam depot downloader (SteamRE/DepotDownloader)" \
      org.opencontainers.image.source="https://github.com/SteamRE/DepotDownloader" \
      org.opencontainers.image.version="${DD_VERSION}" \
      org.opencontainers.image.licenses="GPL-2.0"

COPY --from=fetch /out/DepotDownloader /usr/local/bin/DepotDownloader
COPY --from=fetch /out/LICENSE /licenses/DepotDownloader-LICENSE
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && DepotDownloader --version

# Downloaded content and account.config (credentials/2FA tokens) live here,
# so mount this path to persist data between runs.
WORKDIR /steam
VOLUME ["/steam"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
