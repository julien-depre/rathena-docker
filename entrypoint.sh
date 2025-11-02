#!/bin/sh
set -euo pipefail

if [ ! -d /rathena/conf/import ]; then
  echo "[rAthena] Creating /rathena/conf/import directory..."
  mkdir -p /rathena/conf/import
fi

echo "[rAthena] Creating import files..."

cat > /rathena/conf/import/inter_conf.txt << EOF
login_server_ip: mariadb
char_server_ip: mariadb
map_server_ip: mariadb
web_server_ip: mariadb
ipban_db_ip: mariadb
log_db_ip: mariadb
use_sql_db: no
EOF

# Create battle_conf.txt
cat > /rathena/conf/import/battle_conf.txt << EOF
feature.mesitemicon: off
feature.privateairship: off
feature.barter: off
feature.barter_extended: off
EOF

# Create map_conf.txt
cat > /rathena/conf/import/map_conf.txt << EOF
userid: ${RATHENA_USR:-s1}
passwd: ${RATHENA_PWD:-p1}
char_ip: char-server
bind_ip: 0.0.0.0
EOF

# Create packet_conf.txt
cat > /rathena/conf/import/packet_conf.txt << EOF
enable_ip_rules: no
EOF

# Create login_conf.txt
cat > /rathena/conf/import/login_conf.txt << EOF
bind_ip: 0.0.0.0
new_account: yes
ipban_enable: no
time_allowed: 0
EOF

# Create char_conf.txt
cat > /rathena/conf/import/char_conf.txt << EOF
userid: ${RATHENA_USR:-s1}
passwd: ${RATHENA_PWD:-p1}
server_name: ${RATHENA_NAME:-rAthena}
login_ip: login-server
bind_ip: 0.0.0.0
EOF

# Create web_conf.txt
cat > /rathena/conf/import/web_conf.txt << EOF
bind_ip: 0.0.0.0
EOF

if [ -n "${SET_MOTD:-}" ]; then
  printf "%s\n" "${SET_MOTD}" > /rathena/conf/motd.txt
fi

# Declare public IP
if [ -z "${DOMAIN:-}" ]; then
  echo "Missing DOMAIN environment variable. Unable to continue."
  exit 1
fi
printf "char_ip: %s\n" "${DOMAIN}" >> /rathena/conf/import/char_conf.txt
printf "map_ip: %s\n" "${DOMAIN}" >> /rathena/conf/import/map_conf.txt

case "${MODE:-}" in
  login) BIN="/rathena/login-server";;
  char)  BIN="/rathena/char-server";;
  map)   BIN="/rathena/map-server";;
  web)   BIN="/rathena/web-server";;
  all)   BIN="/bin/sh";;
  *) echo "Unknown MODE: ${MODE:-}"; exit 2 ;;
esac

echo "[rAthena] mode=${MODE} -> $BIN"
exec "$BIN"
