#!/usr/bin/env bash
# Purpose: Install Java 21 (Temurin) and Jenkins on Ubuntu 22.04 in Azure
# Notes:
#  - Designed to be used as --custom-data jenkins-init.sh (cloud-init will run it on first boot)
#  - Safe to re-run (best-effort idempotency)
#  - Based on original cloud-init content provided (#cloud-config runcmd)  [ref]
set -euo pipefail

# Ensure non-interactive apt
export DEBIAN_FRONTEND=noninteractive

# --- Base tools ---------------------------------------------------------------
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl gnupg wget

# --- Install Java 21 (Temurin) from Adoptium APT repo ------------------------
install -d -m 0755 /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/adoptium.gpg ]]; then
  curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public \
    | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg
fi

CODENAME="$(awk -F= '/^VERSION_CODENAME/{print $2}' /etc/os-release)"
echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb ${CODENAME} main" \
  > /etc/apt/sources.list.d/adoptium.list

apt-get update -y
apt-get install -y temurin-21-jre

# Set Java 21 as default 'java' (so Jenkins uses it)
if update-alternatives --list java | grep -q temurin-21; then
  update-alternatives --set java "$(update-alternatives --list java | grep temurin-21 | head -n 1)"
fi

# --- Jenkins repo (key 2026) + install ---------------------------------------
if [[ ! -f /etc/apt/keyrings/jenkins-keyring.asc ]]; then
  wget -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
fi

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update -y
apt-get install -y jenkins

# --- Force Jenkins to use Java 21 explicitly (set JAVA_HOME) -----------------
JAVA_BIN="$(readlink -f "$(command -v java)")"
JAVA_HOME_DIR="$(dirname "$(dirname "$JAVA_BIN")")"
if ! grep -q '^JAVA_HOME=' /etc/default/jenkins 2>/dev/null; then
  echo "JAVA_HOME=$JAVA_HOME_DIR" >> /etc/default/jenkins
else
  sed -i "s|^JAVA_HOME=.*|JAVA_HOME=$JAVA_HOME_DIR|" /etc/default/jenkins
fi

# --- Enable and start Jenkins -------------------------------------------------
systemctl enable --now jenkins

echo "jenkins-init.sh completed successfully."