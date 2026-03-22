#!/bin/bash
# =============================================================================
# Linux Server Audit Script
# Collects comprehensive server infrastructure data in structured format
# Output: JSON-like sections separated by markers for easy parsing
# =============================================================================

set -euo pipefail

SECTION_START="===SECTION_START==="
SECTION_END="===SECTION_END==="

print_section() {
    local name="$1"
    echo ""
    echo "${SECTION_START}${name}"
}

end_section() {
    echo "${SECTION_END}"
}

# =============================================================================
# 1. OS & SYSTEM INFO
# =============================================================================
print_section "OS_INFO"

echo "--- Basic OS ---"
cat /etc/os-release 2>/dev/null || echo "N/A"

echo ""
echo "--- Kernel ---"
uname -a 2>/dev/null || echo "N/A"

echo ""
echo "--- Hostname ---"
hostname -f 2>/dev/null || hostname 2>/dev/null || echo "N/A"

echo ""
echo "--- Uptime ---"
uptime 2>/dev/null || echo "N/A"

echo ""
echo "--- Timezone ---"
timedatectl 2>/dev/null | grep -E "Time zone|Local time|NTP" || date +%Z 2>/dev/null || echo "N/A"

echo ""
echo "--- Last Reboot ---"
last reboot 2>/dev/null | head -5 || echo "N/A"

echo ""
echo "--- LSB Release ---"
lsb_release -a 2>/dev/null || echo "N/A"

echo ""
echo "--- EOL / Support Status ---"
if command -v ubuntu-support-status &>/dev/null; then
    ubuntu-support-status 2>/dev/null || true
fi
if [ -f /etc/debian_version ]; then
    echo "Debian version: $(cat /etc/debian_version)"
fi
# Check if hwe-support-status exists (Ubuntu)
if command -v hwe-support-status &>/dev/null; then
    hwe-support-status --verbose 2>/dev/null || true
fi

end_section

# =============================================================================
# 2. HARDWARE INFO
# =============================================================================
print_section "HARDWARE_INFO"

echo "--- CPU ---"
lscpu 2>/dev/null || cat /proc/cpuinfo 2>/dev/null | head -30 || echo "N/A"

echo ""
echo "--- Memory ---"
free -h 2>/dev/null || echo "N/A"

echo ""
echo "--- Memory Details ---"
cat /proc/meminfo 2>/dev/null | head -10 || echo "N/A"

echo ""
echo "--- Disk Layout ---"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,ROTA,MODEL 2>/dev/null || lsblk 2>/dev/null || echo "N/A"

echo ""
echo "--- Disk Usage ---"
df -hT 2>/dev/null || df -h 2>/dev/null || echo "N/A"

echo ""
echo "--- Disk I/O Scheduler (SSD detection) ---"
for disk in /sys/block/sd* /sys/block/vd* /sys/block/nvme*; do
    if [ -d "$disk" ]; then
        DNAME=$(basename "$disk")
        ROTATIONAL=$(cat "$disk/queue/rotational" 2>/dev/null || echo "?")
        SCHEDULER=$(cat "$disk/queue/scheduler" 2>/dev/null || echo "?")
        echo "$DNAME: rotational=$ROTATIONAL (0=SSD, 1=HDD), scheduler=$SCHEDULER"
    fi
done 2>/dev/null || echo "N/A"

echo ""
echo "--- Virtualization ---"
systemd-detect-virt 2>/dev/null || echo "N/A"
if [ -f /sys/class/dmi/id/product_name ]; then
    echo "Product: $(cat /sys/class/dmi/id/product_name 2>/dev/null)"
fi
if [ -f /sys/class/dmi/id/sys_vendor ]; then
    echo "Vendor: $(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)"
fi

echo ""
echo "--- Network Interfaces ---"
ip -br addr 2>/dev/null || ifconfig 2>/dev/null | grep -E "^[a-z]|inet " || echo "N/A"

echo ""
echo "--- Public IP ---"
curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || curl -s --connect-timeout 5 icanhazip.com 2>/dev/null || echo "N/A"

end_section

# =============================================================================
# 3. INSTALLED APPLICATIONS
# =============================================================================
print_section "INSTALLED_APPS"

# --- PHP ---
echo "=== PHP ==="
if command -v php &>/dev/null; then
    echo "Path: $(which php)"
    echo "Version: $(php -v 2>/dev/null | head -1)"
    echo "Modules: $(php -m 2>/dev/null | tr '\n' ', ')"
    echo ""
    echo "PHP INI: $(php -i 2>/dev/null | grep 'Loaded Configuration File' || echo 'N/A')"
    echo "Additional INI dir: $(php -i 2>/dev/null | grep 'Scan this dir' || echo 'N/A')"
    # Check for PHP-FPM
    if command -v php-fpm &>/dev/null || systemctl list-units --type=service 2>/dev/null | grep -q php.*fpm; then
        echo "PHP-FPM: Active"
        systemctl status php*-fpm* 2>/dev/null | head -5 || true
        # Find FPM config
        find /etc/php* -name "www.conf" -o -name "php-fpm.conf" 2>/dev/null | head -5 || true
    fi
    # Check for multiple PHP versions
    echo "All PHP binaries:"
    ls -la /usr/bin/php* 2>/dev/null || true
    update-alternatives --list php 2>/dev/null || true
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Node.js ---
echo "=== NODE.JS ==="
if command -v node &>/dev/null; then
    echo "Path: $(which node)"
    echo "Version: $(node -v 2>/dev/null)"
    echo "NPM: $(npm -v 2>/dev/null || echo 'N/A')"
    echo "NPM global prefix: $(npm config get prefix 2>/dev/null || echo 'N/A')"
    echo "Global packages:"
    npm list -g --depth=0 2>/dev/null || true
    # Check for nvm
    if [ -d "$HOME/.nvm" ] || [ -d "/root/.nvm" ]; then
        echo "NVM detected"
        export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" 2>/dev/null
        nvm list 2>/dev/null || true
    fi
    # Check for n
    if command -v n &>/dev/null; then
        echo "n version manager detected"
        n list 2>/dev/null || true
    fi
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Python ---
echo "=== PYTHON ==="
for pybin in python3 python python2; do
    if command -v $pybin &>/dev/null; then
        echo "Path: $(which $pybin)"
        echo "Version: $($pybin --version 2>&1)"
    fi
done
if command -v pip3 &>/dev/null; then
    echo "pip3: $(pip3 --version 2>/dev/null)"
    echo "pip3 packages (site):"
    pip3 list --format=columns 2>/dev/null | head -30 || true
elif command -v pip &>/dev/null; then
    echo "pip: $(pip --version 2>/dev/null)"
fi
# Check for pyenv
if command -v pyenv &>/dev/null || [ -d "$HOME/.pyenv" ]; then
    echo "pyenv detected"
    pyenv versions 2>/dev/null || true
fi
# Check for virtualenvs
echo "Virtual environments:"
find / -maxdepth 5 -name "pyvenv.cfg" -o -name "activate" -path "*/bin/activate" 2>/dev/null | head -10 || true
if [ "$(which $pybin 2>/dev/null)" = "" ]; then
    echo "NOT INSTALLED"
fi
echo ""

# --- Nginx ---
echo "=== NGINX ==="
if command -v nginx &>/dev/null; then
    echo "Path: $(which nginx)"
    echo "Version: $(nginx -v 2>&1)"
    echo "Config test: $(nginx -t 2>&1 | tail -1)"
    echo ""
    echo "Main config: $(nginx -V 2>&1 | grep -o 'conf-path=[^ ]*' || echo '/etc/nginx/nginx.conf')"
    echo ""
    echo "Enabled sites:"
    ls -la /etc/nginx/sites-enabled/ 2>/dev/null || ls -la /etc/nginx/conf.d/ 2>/dev/null || echo "N/A"
    echo ""
    echo "--- Virtual Hosts / Server Blocks ---"
    grep -rn "server_name\|listen\|root\|proxy_pass\|location" /etc/nginx/sites-enabled/ 2>/dev/null | head -50 || \
    grep -rn "server_name\|listen\|root\|proxy_pass\|location" /etc/nginx/conf.d/ 2>/dev/null | head -50 || echo "N/A"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Apache ---
echo "=== APACHE ==="
if command -v apache2 &>/dev/null || command -v httpd &>/dev/null; then
    APACHE_BIN=$(which apache2 2>/dev/null || which httpd 2>/dev/null)
    echo "Path: $APACHE_BIN"
    echo "Version: $($APACHE_BIN -v 2>/dev/null | head -1)"
    echo "Enabled sites:"
    ls -la /etc/apache2/sites-enabled/ 2>/dev/null || ls -la /etc/httpd/conf.d/ 2>/dev/null || echo "N/A"
    echo "Enabled modules:"
    apache2ctl -M 2>/dev/null | head -20 || httpd -M 2>/dev/null | head -20 || echo "N/A"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Redis ---
echo "=== REDIS ==="
if command -v redis-server &>/dev/null; then
    echo "Path: $(which redis-server)"
    echo "Version: $(redis-server --version 2>/dev/null)"
    echo "Config:"
    redis-cli CONFIG GET bind 2>/dev/null || true
    redis-cli CONFIG GET port 2>/dev/null || true
    redis-cli CONFIG GET maxmemory 2>/dev/null || true
    redis-cli CONFIG GET requirepass 2>/dev/null | head -1 && echo "(password hidden)"
    echo "Config file: $(find /etc -name 'redis.conf' -o -name 'redis*.conf' 2>/dev/null | head -3)"
    echo "Data dir: $(redis-cli CONFIG GET dir 2>/dev/null | tail -1)"
    echo "Info (key stats):"
    redis-cli INFO keyspace 2>/dev/null || true
    redis-cli INFO memory 2>/dev/null | grep -E "used_memory_human|maxmemory_human" || true
    echo "Databases:"
    redis-cli INFO keyspace 2>/dev/null || true
elif command -v redis-cli &>/dev/null; then
    echo "redis-cli found: $(which redis-cli)"
    echo "Version: $(redis-cli --version 2>/dev/null)"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- MariaDB / MySQL ---
echo "=== MARIADB / MYSQL ==="
if command -v mysql &>/dev/null; then
    echo "MySQL client path: $(which mysql)"
    echo "Version: $(mysql --version 2>/dev/null)"
fi
if command -v mariadb &>/dev/null; then
    echo "MariaDB client path: $(which mariadb)"
    echo "Version: $(mariadb --version 2>/dev/null)"
fi
if command -v mysqld &>/dev/null || command -v mariadbd &>/dev/null; then
    MYSQLD_BIN=$(which mysqld 2>/dev/null || which mariadbd 2>/dev/null)
    echo "Server path: $MYSQLD_BIN"
    echo "Server version: $($MYSQLD_BIN --version 2>/dev/null | head -1)"
fi
# Config files
echo "Config files:"
find /etc/mysql /etc/my.cnf /etc/my.cnf.d -type f 2>/dev/null | head -10 || echo "N/A"
# Data directory
echo "Data dir:"
grep -r "datadir" /etc/mysql/ /etc/my.cnf /etc/my.cnf.d/ 2>/dev/null | head -3 || echo "N/A"
# Try to list databases (may require auth)
echo "Databases:"
mysql -e "SHOW DATABASES;" 2>/dev/null || echo "(requires authentication - will need manual check)"
echo "Users:"
mysql -e "SELECT User, Host FROM mysql.user;" 2>/dev/null || echo "(requires authentication - will need manual check)"
echo "Database sizes:"
mysql -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.TABLES GROUP BY table_schema ORDER BY SUM(data_length + index_length) DESC;" 2>/dev/null || echo "(requires authentication)"
echo ""

# --- PostgreSQL ---
echo "=== POSTGRESQL ==="
if command -v psql &>/dev/null; then
    echo "Path: $(which psql)"
    echo "Version: $(psql --version 2>/dev/null)"
    echo "Config files:"
    find /etc/postgresql -type f -name "*.conf" 2>/dev/null | head -5 || echo "N/A"
    echo "Data dir:"
    find /var/lib/postgresql -maxdepth 2 -name "PG_VERSION" 2>/dev/null | head -3 || echo "N/A"
    echo "Databases:"
    sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database ORDER BY pg_database_size(datname) DESC;" 2>/dev/null || echo "(requires authentication)"
    echo "Users:"
    sudo -u postgres psql -c "SELECT usename, usesuper FROM pg_user;" 2>/dev/null || echo "(requires authentication)"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- MongoDB ---
echo "=== MONGODB ==="
if command -v mongod &>/dev/null || command -v mongosh &>/dev/null || command -v mongo &>/dev/null; then
    echo "mongod path: $(which mongod 2>/dev/null || echo 'N/A')"
    echo "Version: $(mongod --version 2>/dev/null | head -1 || echo 'N/A')"
    MONGO_CLI=$(which mongosh 2>/dev/null || which mongo 2>/dev/null || echo "")
    if [ -n "$MONGO_CLI" ]; then
        echo "Client: $MONGO_CLI"
        echo "Databases:"
        $MONGO_CLI --quiet --eval "db.adminCommand('listDatabases').databases.forEach(function(d){print(d.name + ' - ' + (d.sizeOnDisk/1024/1024).toFixed(2) + ' MB')})" 2>/dev/null || echo "(requires authentication)"
    fi
    echo "Config file:"
    find /etc -name "mongod.conf" -o -name "mongodb.conf" 2>/dev/null | head -3 || echo "N/A"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Docker ---
echo "=== DOCKER ==="
if command -v docker &>/dev/null; then
    echo "Path: $(which docker)"
    echo "Version: $(docker --version 2>/dev/null)"
    echo "Docker Compose: $(docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || echo 'N/A')"
    echo ""
    echo "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "(permission denied or docker not running)"
    echo ""
    echo "All containers:"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || true
    echo ""
    echo "Images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>/dev/null || true
    echo ""
    echo "Docker volumes:"
    docker volume ls 2>/dev/null || true
    echo ""
    echo "Docker networks:"
    docker network ls 2>/dev/null || true
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Git ---
echo "=== GIT ==="
if command -v git &>/dev/null; then
    echo "Path: $(which git)"
    echo "Version: $(git --version 2>/dev/null)"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Composer ---
echo "=== COMPOSER ==="
if command -v composer &>/dev/null; then
    echo "Path: $(which composer)"
    echo "Version: $(composer --version 2>/dev/null | head -1)"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Java ---
echo "=== JAVA ==="
if command -v java &>/dev/null; then
    echo "Path: $(which java)"
    echo "Version: $(java -version 2>&1 | head -3)"
    echo "JAVA_HOME: ${JAVA_HOME:-not set}"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Go ---
echo "=== GO ==="
if command -v go &>/dev/null; then
    echo "Path: $(which go)"
    echo "Version: $(go version 2>/dev/null)"
    echo "GOPATH: $(go env GOPATH 2>/dev/null || echo 'N/A')"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Rust ---
echo "=== RUST ==="
if command -v rustc &>/dev/null; then
    echo "Path: $(which rustc)"
    echo "Version: $(rustc --version 2>/dev/null)"
    echo "Cargo: $(cargo --version 2>/dev/null || echo 'N/A')"
else
    echo "NOT INSTALLED"
fi
echo ""

# --- Certbot / SSL ---
echo "=== SSL / CERTBOT ==="
if command -v certbot &>/dev/null; then
    echo "Path: $(which certbot)"
    echo "Version: $(certbot --version 2>&1)"
    echo "Certificates:"
    certbot certificates 2>/dev/null || echo "(requires root)"
else
    echo "NOT INSTALLED"
fi
echo "SSL Certificates in /etc/ssl:"
find /etc/ssl/certs /etc/letsencrypt/live -maxdepth 2 -name "*.pem" -o -name "*.crt" 2>/dev/null | head -20 || echo "N/A"
echo ""

end_section

# =============================================================================
# 4. CLOUDFLARED / CLOUDFLARE TUNNEL
# =============================================================================
print_section "CLOUDFLARE"

echo "=== CLOUDFLARED ==="
if command -v cloudflared &>/dev/null; then
    echo "Path: $(which cloudflared)"
    echo "Version: $(cloudflared --version 2>/dev/null)"
    echo ""

    # Find config files
    echo "Config files:"
    find /etc/cloudflared /root/.cloudflared /home/*/.cloudflared /usr/local/etc/cloudflared -name "*.yml" -o -name "*.yaml" -o -name "config*" 2>/dev/null | while read f; do
        echo ""
        echo "--- $f ---"
        cat "$f" 2>/dev/null
    done
    if [ $? -ne 0 ]; then
        echo "No config files found in standard locations"
    fi

    echo ""
    echo "Tunnel service status:"
    systemctl status cloudflared* 2>/dev/null | head -15 || true

    echo ""
    echo "Running tunnel processes:"
    ps aux 2>/dev/null | grep cloudflared | grep -v grep || echo "No running processes"

    echo ""
    echo "Tunnel credentials:"
    find /etc/cloudflared /root/.cloudflared /home/*/.cloudflared -name "*.json" -name "*cert*" 2>/dev/null | head -5 || echo "N/A"

else
    echo "NOT INSTALLED"
fi

end_section

# =============================================================================
# 5. SERVICES & PROCESSES
# =============================================================================
print_section "SERVICES"

echo "=== Systemd Services (enabled) ==="
systemctl list-unit-files --type=service --state=enabled 2>/dev/null || echo "N/A"

echo ""
echo "=== Systemd Services (running) ==="
systemctl list-units --type=service --state=running 2>/dev/null || echo "N/A"

echo ""
echo "=== Custom Services (non-vendor) ==="
# Find custom service files
echo "User-created service files:"
find /etc/systemd/system -name "*.service" -not -name "*.wants" -maxdepth 1 2>/dev/null | while read svc; do
    echo ""
    echo "--- $(basename $svc) ---"
    cat "$svc" 2>/dev/null
done

echo ""
echo "=== PM2 Processes ==="
if command -v pm2 &>/dev/null; then
    echo "Path: $(which pm2)"
    pm2 list 2>/dev/null || true
    echo ""
    echo "PM2 startup:"
    pm2 describe all 2>/dev/null | grep -E "name|script|cwd|exec_mode|instances" || true
else
    echo "PM2 NOT INSTALLED"
fi

echo ""
echo "=== Supervisor ==="
if command -v supervisorctl &>/dev/null; then
    echo "Path: $(which supervisorctl)"
    supervisorctl status 2>/dev/null || echo "(may require root)"
    echo "Config files:"
    find /etc/supervisor /etc/supervisord.d -name "*.conf" 2>/dev/null | head -10 || echo "N/A"
else
    echo "NOT INSTALLED"
fi

echo ""
echo "=== Cron Jobs ==="
echo "System crontab:"
cat /etc/crontab 2>/dev/null || echo "N/A"
echo ""
echo "Cron.d:"
ls -la /etc/cron.d/ 2>/dev/null || echo "N/A"
for f in /etc/cron.d/*; do
    if [ -f "$f" ]; then
        echo "--- $(basename $f) ---"
        cat "$f" 2>/dev/null
    fi
done
echo ""
echo "User crontabs:"
for user in $(cut -f1 -d: /etc/passwd 2>/dev/null); do
    CRON=$(crontab -l -u "$user" 2>/dev/null)
    if [ -n "$CRON" ]; then
        echo "--- $user ---"
        echo "$CRON"
    fi
done

end_section

# =============================================================================
# 6. NETWORKING & FIREWALL
# =============================================================================
print_section "NETWORKING"

echo "=== Listening Ports ==="
ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null || echo "N/A"

echo ""
echo "=== Firewall (UFW) ==="
if command -v ufw &>/dev/null; then
    ufw status verbose 2>/dev/null || echo "(requires root)"
else
    echo "UFW NOT INSTALLED"
fi

echo ""
echo "=== Firewall (iptables) ==="
iptables -L -n 2>/dev/null | head -30 || echo "(requires root or N/A)"

echo ""
echo "=== DNS Resolvers ==="
cat /etc/resolv.conf 2>/dev/null || echo "N/A"

echo ""
echo "=== Hosts File ==="
cat /etc/hosts 2>/dev/null || echo "N/A"

end_section

# =============================================================================
# 7. SECURITY & USERS
# =============================================================================
print_section "SECURITY"

echo "=== User Accounts (with shell) ==="
grep -v '/nologin\|/false' /etc/passwd 2>/dev/null || echo "N/A"

echo ""
echo "=== Sudo Users ==="
grep -v '^#' /etc/sudoers 2>/dev/null | grep -v '^$' || echo "(requires root)"
echo ""
echo "Sudoers.d:"
ls -la /etc/sudoers.d/ 2>/dev/null || echo "N/A"
for f in /etc/sudoers.d/*; do
    if [ -f "$f" ]; then
        echo "--- $(basename $f) ---"
        grep -v '^#' "$f" 2>/dev/null | grep -v '^$' || true
    fi
done

echo ""
echo "=== SSH Config ==="
grep -v '^#' /etc/ssh/sshd_config 2>/dev/null | grep -v '^$' | head -20 || echo "N/A"

echo ""
echo "=== Authorized Keys ==="
for home_dir in /root /home/*; do
    if [ -f "$home_dir/.ssh/authorized_keys" ]; then
        echo "--- $home_dir ---"
        wc -l "$home_dir/.ssh/authorized_keys" 2>/dev/null || true
    fi
done

echo ""
echo "=== Fail2ban ==="
if command -v fail2ban-client &>/dev/null; then
    echo "Path: $(which fail2ban-client)"
    fail2ban-client status 2>/dev/null || echo "(may require root)"
else
    echo "NOT INSTALLED"
fi

end_section

# =============================================================================
# 8. PACKAGE MANAGERS & INSTALLED PACKAGES
# =============================================================================
print_section "PACKAGES"

echo "=== Package Manager ==="
if command -v apt &>/dev/null; then
    echo "APT (Debian/Ubuntu)"
    echo "Total packages: $(dpkg -l 2>/dev/null | grep '^ii' | wc -l)"
    echo ""
    echo "Manually installed (approximate):"
    apt-mark showmanual 2>/dev/null | head -50 || true
elif command -v yum &>/dev/null; then
    echo "YUM (RHEL/CentOS)"
    echo "Total packages: $(rpm -qa 2>/dev/null | wc -l)"
    yum list installed 2>/dev/null | head -50 || true
elif command -v dnf &>/dev/null; then
    echo "DNF (Fedora/RHEL)"
    echo "Total packages: $(rpm -qa 2>/dev/null | wc -l)"
fi

echo ""
echo "=== Snap Packages ==="
if command -v snap &>/dev/null; then
    snap list 2>/dev/null || echo "N/A"
else
    echo "NOT INSTALLED"
fi

echo ""
echo "=== Flatpak ==="
if command -v flatpak &>/dev/null; then
    flatpak list 2>/dev/null || echo "N/A"
else
    echo "NOT INSTALLED"
fi

end_section

# =============================================================================
# 9. STORAGE & BACKUP
# =============================================================================
print_section "STORAGE"

echo "=== Mount Points ==="
mount 2>/dev/null | grep -v "^proc\|^sys\|^dev\|^run\|^tmpfs\|^cgroup" || echo "N/A"

echo ""
echo "=== Fstab ==="
cat /etc/fstab 2>/dev/null | grep -v '^#' | grep -v '^$' || echo "N/A"

echo ""
echo "=== LVM ==="
if command -v lvs &>/dev/null; then
    echo "Logical Volumes:"
    lvs 2>/dev/null || echo "(requires root)"
    echo "Volume Groups:"
    vgs 2>/dev/null || echo "(requires root)"
    echo "Physical Volumes:"
    pvs 2>/dev/null || echo "(requires root)"
else
    echo "LVM NOT AVAILABLE"
fi

echo ""
echo "=== RAID ==="
cat /proc/mdstat 2>/dev/null || echo "No software RAID detected"

echo ""
echo "=== Large Directories (top 10 by size in /) ==="
du -h --max-depth=1 / 2>/dev/null | sort -rh | head -15 || echo "N/A"

end_section

# =============================================================================
# 10. BACKUP & RECOVERY
# =============================================================================
print_section "BACKUP"

echo "=== Backup Tools Installed ==="
for tool in restic borg borgmatic rsync rclone duplicity bacula bareos amanda rdiff-backup duplicati timeshift; do
    if command -v $tool &>/dev/null; then
        echo "$tool: $(which $tool) — $($tool --version 2>&1 | head -1)"
    fi
done
echo ""

echo "=== Backup Scripts (common locations) ==="
# Search common backup script locations
for dir in /opt/backup* /opt/scripts /root/scripts /root/backup* /usr/local/bin /home/*/scripts /home/*/backup* /srv/backup* /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
    if [ -d "$dir" ]; then
        echo "--- $dir ---"
        find "$dir" -maxdepth 2 -type f \( -name "*backup*" -o -name "*bak*" -o -name "*dump*" -o -name "*snapshot*" -o -name "*archive*" \) 2>/dev/null | while read f; do
            echo "  $f ($(stat -c '%s bytes, modified %y' "$f" 2>/dev/null || echo 'unknown'))"
        done
    fi
done
echo ""

echo "=== Backup-related Scripts (by content scan) ==="
# Find scripts that contain backup-related commands
grep -rl --include="*.sh" --include="*.bash" --include="*.py" \
    -e "mysqldump" -e "pg_dump" -e "mongodump" -e "redis-cli.*save\|redis-cli.*bgsave" \
    -e "rsync" -e "rclone" -e "restic backup" -e "borg create" -e "tar.*backup\|tar.*bak" \
    /opt /root /usr/local/bin /home /srv /etc/cron* 2>/dev/null | head -20 | while read f; do
    echo ""
    echo "--- $f ---"
    head -30 "$f" 2>/dev/null
    LINE_COUNT=$(wc -l < "$f" 2>/dev/null || echo "?")
    echo "... ($LINE_COUNT lines total)"
done
echo ""

echo "=== Cron Jobs with Backup Commands ==="
# Extract backup-related cron entries from all sources
{
    cat /etc/crontab 2>/dev/null
    cat /etc/cron.d/* 2>/dev/null
    for user in $(cut -f1 -d: /etc/passwd 2>/dev/null); do
        crontab -l -u "$user" 2>/dev/null | while read line; do
            echo "$line  # (user: $user)"
        done
    done
} | grep -iE "backup|dump|rsync|rclone|restic|borg|snapshot|archive|bak|replicate" 2>/dev/null || echo "No backup-related cron entries found"
echo ""

echo "=== Database Backup Evidence ==="
# Check for mysqldump / pg_dump scheduled or recent
echo "Recent MySQL/MariaDB dumps:"
find / -maxdepth 5 -name "*.sql" -o -name "*.sql.gz" -o -name "*.sql.bz2" -o -name "*.sql.zst" 2>/dev/null | while read f; do
    echo "  $f ($(stat -c '%s bytes, modified %y' "$f" 2>/dev/null))"
done | head -20 || echo "  None found"
echo ""

echo "Recent PostgreSQL dumps:"
find / -maxdepth 5 -name "*.pgdump" -o -name "*.pg_dump" -o -name "*pg_backup*" 2>/dev/null | while read f; do
    echo "  $f ($(stat -c '%s bytes, modified %y' "$f" 2>/dev/null))"
done | head -10 || echo "  None found"
echo ""

echo "Recent MongoDB dumps:"
find / -maxdepth 5 -type d -name "mongodump*" -o -name "mongo_backup*" 2>/dev/null | while read f; do
    echo "  $f ($(stat -c 'modified %y' "$f" 2>/dev/null))"
done | head -10 || echo "  None found"
echo ""

echo "=== Backup Destinations / Storage ==="
# Check for backup mount points
mount 2>/dev/null | grep -iE "backup|bak|nfs|cifs|s3|fuse" || echo "No dedicated backup mounts found"
echo ""

# Check for rclone remotes
if command -v rclone &>/dev/null; then
    echo "Rclone remotes:"
    rclone listremotes 2>/dev/null || echo "  (no config or error)"
fi

# Check for restic repos
if [ -f /root/.restic-env ] || [ -f /etc/restic/env ]; then
    echo "Restic environment files:"
    ls -la /root/.restic-env /etc/restic/env 2>/dev/null || true
fi
echo ""

echo "=== Backup Directories (size check) ==="
for dir in /backup /backups /var/backups /opt/backups /mnt/backup* /srv/backup* /root/backups; do
    if [ -d "$dir" ]; then
        SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
        FILE_COUNT=$(find "$dir" -type f 2>/dev/null | wc -l)
        NEWEST=$(find "$dir" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
        NEWEST_DATE=$(stat -c '%y' "$NEWEST" 2>/dev/null | cut -d'.' -f1)
        echo "  $dir — Size: $SIZE, Files: $FILE_COUNT, Newest: $NEWEST_DATE ($NEWEST)"
    fi
done || echo "  No standard backup directories found"
echo ""

echo "=== Backup Systemd Timers ==="
systemctl list-timers --all 2>/dev/null | grep -iE "backup|dump|restic|borg|rsync|snapshot|archive" || echo "No backup-related timers found"
echo ""

echo "=== Logrotate (backup-related) ==="
grep -rl "backup\|dump\|rotate" /etc/logrotate.d/ 2>/dev/null | while read f; do
    echo "--- $(basename $f) ---"
    cat "$f" 2>/dev/null
done | head -30 || echo "N/A"

end_section

# =============================================================================
# 11. SWAP & PERFORMANCE
# =============================================================================
print_section "PERFORMANCE"

echo "=== Swap ==="
swapon --show 2>/dev/null || cat /proc/swaps 2>/dev/null || echo "N/A"

echo ""
echo "=== Load Average ==="
cat /proc/loadavg 2>/dev/null || echo "N/A"

echo ""
echo "=== Top Processes (by CPU) ==="
ps aux --sort=-%cpu 2>/dev/null | head -15 || echo "N/A"

echo ""
echo "=== Top Processes (by Memory) ==="
ps aux --sort=-%mem 2>/dev/null | head -15 || echo "N/A"

end_section

echo ""
echo "============================================="
echo "  AUDIT COMPLETE - $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "============================================="
