#!/bin/bash
# Prepara a VPS para o moksha.com.br: chave SSH de publicação, fail2ban e backup
# diário do banco. Pode rodar de novo sem estragar nada.
#
#   PUBKEY="ssh-ed25519 AAAA... comentario" bash preparar_servidor.sh
#
# Não desliga o login por senha: isso é decisão do dono (ver LEIA-ME.md).
set -euo pipefail

# --- chave de publicação --------------------------------------------------------------
if [ -n "${PUBKEY:-}" ]; then
  install -d -m 700 /root/.ssh
  touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
  grep -qF "$PUBKEY" /root/.ssh/authorized_keys || echo "$PUBKEY" >> /root/.ssh/authorized_keys
  echo "chave de publicação instalada"
fi

# --- fail2ban: bane quem erra a senha do SSH várias vezes -------------------------------
if ! command -v fail2ban-client >/dev/null; then
  apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq fail2ban >/dev/null
fi
cat > /etc/fail2ban/jail.d/moksha-sshd.local <<'EOT'
[sshd]
enabled = true
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h
EOT
systemctl enable --now fail2ban >/dev/null 2>&1
systemctl restart fail2ban
echo "fail2ban: $(systemctl is-active fail2ban)"

# --- backup diário do banco das contas --------------------------------------------------
install -d -m 700 /var/backups/moksha
cat > /usr/local/bin/moksha-backup <<'EOT'
#!/bin/bash
# Dump diário do banco moksha. Fica 30 dias em /var/backups/moksha.
# Se /etc/moksha-backup.env tiver RCLONE_REMOTE (ex.: gdrive:moksha-backups),
# também manda uma cópia para fora do servidor com o rclone.
set -euo pipefail
DIR=/var/backups/moksha
F=$DIR/moksha-$(date +%Y%m%d-%H%M).dump
DBURL=$(grep ^DATABASE_URL= /etc/moksha-api.env | cut -d= -f2-)
pg_dump --format=custom --no-owner "$DBURL" > "$F.tmp" && mv "$F.tmp" "$F"
chmod 600 "$F"
find $DIR -name 'moksha-*.dump' -mtime +30 -delete
if [ -f /etc/moksha-backup.env ]; then
  . /etc/moksha-backup.env
  if [ -n "${RCLONE_REMOTE:-}" ] && command -v rclone >/dev/null; then
    rclone copy "$F" "$RCLONE_REMOTE" && rclone delete --min-age 30d "$RCLONE_REMOTE" || echo "cópia externa falhou" >&2
  fi
fi
echo "backup: $F ($(du -h "$F" | cut -f1))"
EOT
chmod 750 /usr/local/bin/moksha-backup
cat > /etc/systemd/system/moksha-backup.service <<'EOT'
[Unit]
Description=Backup do banco do MOKSHA
After=postgresql.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/moksha-backup
EOT
cat > /etc/systemd/system/moksha-backup.timer <<'EOT'
[Unit]
Description=Backup diário do banco do MOKSHA

[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true
RandomizedDelaySec=10m

[Install]
WantedBy=timers.target
EOT
systemctl daemon-reload
systemctl enable --now moksha-backup.timer >/dev/null 2>&1
/usr/local/bin/moksha-backup
systemctl list-timers moksha-backup.timer --no-pager | sed -n 2p
