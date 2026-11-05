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
plugin_manager_version=2.16.0
plugin_manager_sha256=b3e9704f8259ec3d0479703039e2ad5a0a15abb97808ad70d5a59ba2fdd73197
plugin_manager_tmp="$(mktemp)"
trap 'rm -f "$key_tmp" "$plugin_manager_tmp"' EXIT
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

curl -fsSL \
  "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/${plugin_manager_version}/jenkins-plugin-manager-${plugin_manager_version}.jar" \
  -o "$plugin_manager_tmp"
printf '%s  %s\n' "$plugin_manager_sha256" "$plugin_manager_tmp" | sha256sum --check --status
install -D -m 0644 "$plugin_manager_tmp" /usr/local/lib/jenkins-plugin-manager.jar

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
  java -jar /usr/local/lib/jenkins-plugin-manager.jar \
  --war /usr/share/java/jenkins.war \
  --plugin-download-directory /var/lib/jenkins/plugins \
  --plugins "${plugins[@]}"

systemctl start jenkins

if ! systemctl is-active --quiet jenkins; then
  echo "Jenkins was installed but its service is not active." >&2
  exit 1
fi

echo "Jenkins is installed and running."
