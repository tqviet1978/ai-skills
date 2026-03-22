---
name: linux-server-audit
description: Audit toàn diện một Linux server và tạo infrastructure spec document chi tiết. Kích hoạt khi user muốn audit server, kiểm tra server, tạo infrastructure spec, server inventory, system audit, hoặc bất kỳ lúc nào cần thu thập thông tin đầy đủ về một Linux server — bao gồm OS, hardware, ứng dụng cài đặt (PHP, Node, Python, Nginx, Redis, MariaDB, MySQL, Docker, v.v.), databases, services, Cloudflare tunnels, cron jobs, firewall, networking, và security. Luôn dùng skill này khi user đề cập 'audit server', 'kiểm tra server', 'infrastructure spec', 'server info', 'server inventory', 'system documentation', 'what's on this server', hoặc bất cứ request nào liên quan đến việc khảo sát/document hạ tầng server.
---

# Linux Server Audit — Infrastructure Spec Generator

This skill audits a Linux server comprehensively and generates a professional infrastructure specification document.

## Prerequisites

This skill requires the **local-agent-api** skill to connect to the target server. Before starting, confirm:

| Parameter | Description |
|-----------|-------------|
| `REPO` | Repository code/ID for the server |
| `BASE_URL` | Local Agent API base URL |
| `TOKEN` | Bearer token for authentication |

If the user hasn't provided these, ask for them. Read the local-agent-api skill at `/mnt/skills/user/local-agent-api/SKILL.md` for API usage details.

---

## Workflow

### Phase 1: Upload & Run Audit Script

1. Copy the audit script from `/mnt/skills/user/linux-server-audit/scripts/audit-server.sh` to `/home/claude/audit-server.sh`
2. Upload it to the server via API 2 (upload file):
   ```bash
   curl --retry 5 --retry-delay 3 -X POST $BASE_URL/file/upload \
     -H "Authorization: Bearer $TOKEN" \
     -F "repository=$REPO" \
     -F "path=audit-server.sh" \
     -F "file=@/home/claude/audit-server.sh" \
     -F "post_cmd=chmod +x audit-server.sh"
   ```

3. Execute the script via API 3 (execute command):
   ```bash
   curl -s --retry 5 --retry-delay 3 -X POST $BASE_URL/command/execute \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $TOKEN" \
     -d '{
       "repository": "'$REPO'",
       "command": "sudo bash audit-server.sh 2>&1"
     }'
   ```

4. The output can be very large. If it gets truncated, break the audit into sections by running individual commands:
   ```bash
   # Run just a section at a time
   "command": "sudo bash audit-server.sh 2>&1 | sed -n '/===SECTION_START===OS_INFO/,/===SECTION_END===/p'"
   "command": "sudo bash audit-server.sh 2>&1 | sed -n '/===SECTION_START===HARDWARE_INFO/,/===SECTION_END===/p'"
   # ... etc for each section
   ```

   Alternatively, save output to file then download:
   ```bash
   "command": "sudo bash audit-server.sh > /tmp/audit-output.txt 2>&1 && wc -l /tmp/audit-output.txt"
   ```
   Then read in chunks:
   ```bash
   "command": "head -200 /tmp/audit-output.txt"
   "command": "sed -n '201,400p' /tmp/audit-output.txt"
   # ... etc
   ```

### Phase 2: Collect Database Details (if needed)

If the audit script couldn't access databases due to authentication, ask the user for credentials and run targeted queries:

**MariaDB/MySQL:**
```bash
"command": "mysql -u root -p'PASSWORD' -e \"SHOW DATABASES; SELECT User, Host FROM mysql.user; SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length)/1024/1024, 2) AS 'Size_MB' FROM information_schema.TABLES GROUP BY table_schema ORDER BY SUM(data_length+index_length) DESC;\""
```

**PostgreSQL:**
```bash
"command": "sudo -u postgres psql -c \"SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database ORDER BY pg_database_size(datname) DESC;\" && sudo -u postgres psql -c \"SELECT usename, usesuper FROM pg_user;\""
```

### Phase 3: Collect Cloudflare Route Details (if cloudflared found)

If cloudflared is installed, read the tunnel config for route/ingress details:
```bash
"command": "cat /etc/cloudflared/config.yml 2>/dev/null || cat /root/.cloudflared/config.yml 2>/dev/null || find / -maxdepth 4 -name 'config.yml' -path '*cloudflared*' -exec cat {} \\; 2>/dev/null"
```

Also check for DNS routes if possible:
```bash
"command": "cloudflared tunnel route ip show 2>/dev/null; cloudflared tunnel list 2>/dev/null"
```

### Phase 4: Collect Nginx/Apache Virtual Host Details

Get full virtual host configs for domain mapping:
```bash
# Nginx
"command": "for f in /etc/nginx/sites-enabled/*; do echo '=== '$f' ==='; cat $f; echo; done"

# Apache
"command": "for f in /etc/apache2/sites-enabled/*; do echo '=== '$f' ==='; cat $f; echo; done"
```

### Phase 5: Generate Infrastructure Spec Document

After collecting all data, generate a comprehensive Markdown document. Use the template structure below.

---

## Output Document Template

Generate a `.md` file (and optionally convert to `.docx`) with this structure:

```markdown
# Infrastructure Specification
## [Server Hostname] — [Public IP or Internal ID]

**Generated:** [Date]
**Audited by:** Claude AI (linux-server-audit)

---

## Table of Contents
1. Executive Summary
2. Operating System
3. Hardware & Resources
4. Network Configuration
5. Installed Applications
   - 5.1 Web Server (Nginx/Apache)
   - 5.2 PHP
   - 5.3 Node.js
   - 5.4 Python
   - 5.5 Database (MariaDB/MySQL/PostgreSQL/MongoDB)
   - 5.6 Redis / Cache
   - 5.7 Docker
   - 5.8 Other Applications
6. Domain & Routing
   - 6.1 Cloudflare Tunnel Routes
   - 6.2 Nginx Virtual Hosts
   - 6.3 SSL Certificates
7. Services & Process Management
   - 7.1 Systemd Services
   - 7.2 PM2 Processes
   - 7.3 Custom Services
   - 7.4 Cron Jobs
8. Security
   - 8.1 User Accounts
   - 8.2 SSH Configuration
   - 8.3 Firewall Rules
   - 8.4 Fail2ban
9. Backup & Recovery
   - 9.1 Backup Tools
   - 9.2 Backup Scripts & Schedules
   - 9.3 Database Backups
   - 9.4 Backup Destinations & Storage
   - 9.5 Backup Health Assessment
10. Storage & Disk
11. Recommendations

---

## 1. Executive Summary

Brief overview: what this server does, key services running, overall health.

## 2. Operating System

| Property | Value |
|----------|-------|
| Distribution | Ubuntu 22.04.3 LTS |
| Kernel | 5.15.0-xxx-generic |
| Architecture | x86_64 |
| Hostname | server.example.com |
| Uptime | X days |
| EOL / Support | Supported until April 2027 |
| Timezone | Asia/Ho_Chi_Minh |

## 3. Hardware & Resources

| Resource | Details |
|----------|---------|
| CPU | 4 vCPU (Intel Xeon / AMD EPYC) |
| RAM | 8 GB (X GB used) |
| Swap | 2 GB |
| Disk | 80 GB SSD (/dev/vda) |
| Disk Usage | X% used |
| Virtualization | KVM / VMware / Bare Metal |
| Public IP | x.x.x.x |

## 4. Network Configuration

- Listening ports table
- Firewall rules summary
- DNS resolvers

## 5. Installed Applications

### 5.1 Web Server — Nginx

| Property | Value |
|----------|-------|
| Version | 1.xx.x |
| Binary Path | /usr/sbin/nginx |
| Config Path | /etc/nginx/nginx.conf |
| Sites Enabled | /etc/nginx/sites-enabled/ |
| Status | Active (running) |

**Virtual Hosts:**

| Domain | Listen | Root / Proxy |
|--------|--------|-------------|
| example.com | 443 SSL | /var/www/example |
| api.example.com | 443 SSL | proxy_pass http://127.0.0.1:3000 |

### 5.2 PHP

| Property | Value |
|----------|-------|
| Version(s) | 8.2.x |
| Binary Path | /usr/bin/php8.2 |
| PHP-FPM | Active |
| FPM Config | /etc/php/8.2/fpm/pool.d/www.conf |
| php.ini | /etc/php/8.2/fpm/php.ini |
| Key Modules | curl, mbstring, mysql, gd, redis... |

(Repeat pattern for each application)

### 5.5 Database — MariaDB

| Property | Value |
|----------|-------|
| Version | 10.11.x |
| Binary Path | /usr/sbin/mariadbd |
| Config Path | /etc/mysql/mariadb.conf.d/ |
| Data Dir | /var/lib/mysql |
| Status | Active (running) |

**Databases:**

| Database | Size |
|----------|------|
| app_production | 245 MB |
| app_staging | 12 MB |

**Users:**

| User | Host | Notes |
|------|------|-------|
| root | localhost | Full access |
| app_user | localhost | Production app |

## 6. Domain & Routing

### 6.1 Cloudflare Tunnel Routes

| Tunnel Name | Route/Hostname | Service/Origin |
|-------------|---------------|----------------|
| my-tunnel | app.example.com | http://localhost:8080 |
| my-tunnel | api.example.com | http://localhost:3000 |
| my-tunnel | ssh.example.com | ssh://localhost:22 |

### 6.2 SSL Certificates

| Domain | Issuer | Expiry |
|--------|--------|--------|
| example.com | Let's Encrypt | 2024-06-15 |

## 7. Services & Process Management

### 7.1 Systemd Services (Custom)

| Service | Description | Status | ExecStart |
|---------|-------------|--------|-----------|
| myapp.service | Node.js API | Active | /usr/bin/node /opt/myapp/server.js |

### 7.3 Cron Jobs

| Schedule | User | Command |
|----------|------|---------|
| */5 * * * * | root | /opt/scripts/backup.sh |
| 0 2 * * * | www-data | php /var/www/app/artisan schedule:run |

## 8. Security

Summary of user accounts, SSH hardening, firewall rules, fail2ban jails.

## 9. Backup & Recovery

### 9.1 Backup Tools

| Tool | Version | Path |
|------|---------|------|
| restic | 0.16.x | /usr/bin/restic |
| rclone | 1.64.x | /usr/bin/rclone |

### 9.2 Backup Scripts & Schedules

| Script | Location | Schedule | What it backs up |
|--------|----------|----------|-----------------|
| db-backup.sh | /opt/scripts/db-backup.sh | Daily 2:00 AM | MySQL all databases |
| files-backup.sh | /opt/scripts/files-backup.sh | Weekly Sunday 3:00 AM | /var/www, /etc |

### 9.3 Database Backups

| Database | Last Backup | Size | Location |
|----------|------------|------|----------|
| app_production | 2024-01-15 02:00 | 45 MB | /backups/mysql/app_production.sql.gz |

### 9.4 Backup Destinations

| Destination | Type | Path/Remote |
|------------|------|-------------|
| /backups | Local disk | /dev/vdb1 |
| s3-backup: | Rclone remote (S3) | bucket: my-backups |

### 9.5 Backup Health Assessment

- Last successful backup: [date]
- Backup coverage: [which services/databases are covered]
- ⚠️ Missing backups: [services not covered]
- Retention policy: [if detectable]

## 10. Storage & Disk

Disk partitions, mount points, LVM layout, largest directories.

## 10. Recommendations

Based on the audit findings, list actionable recommendations:
- Security improvements
- Software updates needed (EOL versions)
- Performance optimizations
- Backup suggestions
- Missing monitoring
```

---

## Key Principles

1. **Be thorough but organized** — collect everything, present it cleanly in tables
2. **Flag issues** — if software is outdated, EOL, or misconfigured, call it out in Recommendations
3. **Handle auth failures gracefully** — if database or service requires auth, note it clearly and ask the user
4. **Respect sensitive data** — never expose passwords in the output; mask them with `****`
5. **Adapt to what's found** — only include sections for software that's actually installed; skip sections with "NOT INSTALLED"
6. **Large output handling** — if the audit output is huge, read it in chunks rather than trying to get it all in one API call
7. **Clean up after audit** — remove the audit script from the server when done:
   ```bash
   "command": "rm -f audit-server.sh /tmp/audit-output.txt"
   ```

## Output Format

Generate the spec as:
1. **Primary:** A well-formatted Markdown file saved to `/mnt/user-data/outputs/infrastructure-spec-[hostname].md`
2. **Optional:** If the user wants, also generate a `.docx` version using the docx skill

Always present the file to the user using the `present_files` tool after completion.
