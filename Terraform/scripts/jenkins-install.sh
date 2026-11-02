#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root (for example, with sudo)." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot determine the operating system: /etc/os-release is unavailable." >&2
  exit 1
fi

. /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "This installer supports Ubuntu; detected '${ID:-unknown}'." >&2
  exit 1
fi

apt update
apt install fontconfig openjdk-21-jre

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt update
apt install jenkins


echo "Jenkins is installed and running."
