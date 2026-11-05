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

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl fontconfig openjdk-21-jre

install -d -m 0755 /etc/apt/keyrings
key_tmp="$(mktemp)"
trap 'rm -f "$key_tmp"' EXIT
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key -o "$key_tmp"
install -m 0644 "$key_tmp" /etc/apt/keyrings/jenkins-keyring.asc

printf '%s\n' \
  'deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update

install -d -m 0755 /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/90-disable-setup-wizard.conf <<'EOF'
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
EOF
systemctl daemon-reload

apt-get install -y jenkins
systemctl enable jenkins
systemctl stop jenkins

plugins=(
  git
  github-branch-source
  workflow-aggregator
  pipeline-stage-view
  ws-cleanup
  timestamper
  credentials-binding
  matrix-auth
  pam-auth
  ldap
  ssh-slaves
  mailer
  ant
  gradle
  maven-plugin
  sonar
  slack
)

runuser -u jenkins -- env JENKINS_HOME=/var/lib/jenkins \
  jenkins-plugin-cli --plugins "${plugins[@]}"

systemctl start jenkins

if ! systemctl is-active --quiet jenkins; then
  echo "Jenkins was installed but its service is not active." >&2
  exit 1
fi

echo "Jenkins is installed and running."
