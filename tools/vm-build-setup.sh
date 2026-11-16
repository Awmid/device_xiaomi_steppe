#!/usr/bin/env bash
# Steppe (Redmi 17 5G) - LineageOS 23.2 / Android 16 build VM bootstrap.
# Tested target: fresh Ubuntu 22.04 LTS VM (Google Cloud), >=8 vCPU, >=32 GB RAM, >=400 GB disk (balanced PD is fine).
# Usage:  bash vm-build-setup.sh deps     # once: packages, repo tool, git identity, swap
#         bash vm-build-setup.sh sync     # repo init (lineage-23.2) + local manifest + repo sync
#         bash vm-build-setup.sh recovery # breakfast + mka recoveryimage (proves the tree compiles; do this first)
#         bash vm-build-setup.sh rom      # full userdebug ROM; set STEPPE_PERMISSIVE=true for bring-up
# Rule: every reference branch is lineage-23.2 (NOT the lineage-24.0 default of the Lineage manifest).
set -euo pipefail

SRC="${SRC:-$HOME/android/lineage}"
BRANCH="lineage-23.2"
MANIFEST_URL="https://raw.githubusercontent.com/Awmid/device_xiaomi_steppe/lineage-23.2-undone/local_manifests/steppe.xml"
JOBS="${JOBS:-$(nproc)}"

deps() {
  sudo apt-get update
  sudo apt-get install -y bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs gnupg gperf \
    imagemagick protobuf-compiler python3-protobuf python3 lib32readline-dev lib32z1-dev libdw-dev libelf-dev \
    libgnutls28-dev lz4 libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip \
    zlib1g-dev unzip openjdk-17-jdk-headless
  mkdir -p "$HOME/bin"
  curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
  chmod a+x "$HOME/bin/repo"
  grep -q 'HOME/bin' "$HOME/.profile" || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.profile"
  git lfs install
  git config --global user.name  "${GIT_NAME:-Awmid}"
  git config --global user.email "${GIT_EMAIL:-you@example.com}"   # set GIT_EMAIL before running
  git config --global color.ui false
  if ! swapon --show | grep -q .; then            # linking steps spike memory, add swap as a safety net
    sudo fallocate -l 16G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
  fi
  echo "deps done. Re-login (or: source ~/.profile) so 'repo' is on PATH."
}

sync_src() {
  export PATH="$HOME/bin:$PATH"
  mkdir -p "$SRC" && cd "$SRC"
  [ -d .repo ] || repo init -u https://github.com/LineageOS/android.git -b "$BRANCH" --git-lfs --no-clone-bundle
  mkdir -p .repo/local_manifests
  curl -fsSL "$MANIFEST_URL" -o .repo/local_manifests/steppe.xml
  repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
  echo "Sanity checks:"
  for p in device/xiaomi/steppe device/xiaomi/steppe-kernel vendor/xiaomi/steppe hardware/xiaomi hardware/qcom-caf/common; do
    [ -d "$p" ] && echo "  ok  $p" || echo "  MISSING $p"
  done
  echo "Open items to grep now that the source exists:"
  grep -rn "TARGET_FORCE_PREBUILT_KERNEL" build/make vendor/lineage 2>/dev/null | head || true
}

setup_env() {
  export PATH="$HOME/bin:$PATH"
  cd "$SRC"
  export USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache
  ccache -M 50G >/dev/null || true
  export LC_ALL=C
  # shellcheck disable=SC1091
  source build/envsetup.sh
  breakfast steppe userdebug
}

recovery() { setup_env; mka recoveryimage -j"$JOBS" 2>&1 | tee "$HOME/build-recovery.log"; }
rom()      { setup_env; mka bacon -j"$JOBS" 2>&1 | tee "$HOME/build-rom.log"; }

case "${1:-}" in
  deps) deps ;;
  sync) sync_src ;;
  recovery) recovery ;;
  rom) rom ;;
  *) echo "usage: $0 {deps|sync|recovery|rom}"; exit 1 ;;
esac
