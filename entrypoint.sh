#!/bin/sh
# Entrypoint for the DepotDownloader image.
#
# Modern DepotDownloader (>= 3.0) dropped the "download" subcommand:
#     old: DepotDownloader download -app 730
#     new: DepotDownloader -app 730
#
# The leading "download" argument is silently dropped so that commands written
# for the old image (wurstmitdurst/depotdownloader) keep working.
set -e

if [ "${1:-}" = "download" ]; then
    shift
fi

exec /usr/local/bin/DepotDownloader "$@"
