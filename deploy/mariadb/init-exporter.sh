#!/bin/bash
set -euo pipefail

: "${MYSQL_HOST:?}" "${MYSQL_PWD:?}" "${MYSQLD_EXPORTER_PASSWORD:?}"
password_hex=$(printf '%s' "$MYSQLD_EXPORTER_PASSWORD" | od -An -v -tx1 | tr -d ' \n')
mariadb --host="$MYSQL_HOST" --user=root <<SQL
CREATE USER IF NOT EXISTS 'exporter'@'%' WITH MAX_USER_CONNECTIONS 3;
SET @password = CONVERT(0x${password_hex} USING utf8mb4);
SET @statement = CONCAT('ALTER USER ''exporter''@''%'' IDENTIFIED BY ', QUOTE(@password));
PREPARE password_update FROM @statement;
EXECUTE password_update;
DEALLOCATE PREPARE password_update;
GRANT PROCESS, REPLICATION CLIENT, SLAVE MONITOR, SELECT ON *.* TO 'exporter'@'%';
SQL
