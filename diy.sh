#!/bin/bash
#
# Merged DIY script for OpenWrt build pipeline.
# Usage:
#   ./diy.sh pre   # before feeds update/install
#   ./diy.sh feeds # after feeds update, before feeds install
#   ./diy.sh post  # after feeds install, before build

set -euo pipefail

STAGE="${1:-pre}"

case "$STAGE" in
  pre)
    # Reserved for future pre-feed tweaks.
    ;;

  feeds)
    # Pin external sources for reproducible builds. Override via env if needed.
    PASSWALL2_REF="${PASSWALL2_REF:-cc074ed776579849ae68aec303eb85867b4dc4ee}"
    PASSWALL_PACKAGES_REF="${PASSWALL_PACKAGES_REF:-e13e4631699ef9f0e826d36d3be56a67a82924c9}"

    if [ -d feeds/passwall2/.git ]; then
      git -C feeds/passwall2 fetch --depth=1 origin "$PASSWALL2_REF"
      git -C feeds/passwall2 checkout --detach "$PASSWALL2_REF"
    fi
    if [ -d feeds/passwall_packages/.git ]; then
      git -C feeds/passwall_packages fetch --depth=1 origin "$PASSWALL_PACKAGES_REF"
      git -C feeds/passwall_packages checkout --detach "$PASSWALL_PACKAGES_REF"
    fi
    ;;

  post)
    # Default LAN IP 192.168.1.1 -> 192.168.3.1.
    cfg_file="package/base-files/files/bin/config_generate"
    if [ -f "$cfg_file" ]; then
      sed -i 's/192\.168\.1\.1/192.168.3.1/g' "$cfg_file"
    else
      echo "Missing file: $cfg_file" >&2
      exit 1
    fi
    ;;

  *)
    echo "Unknown stage: $STAGE (expected: pre|feeds|post)" >&2
    exit 1
    ;;
esac
