# NAS Documentation

## System Info
- **OS**: TrueNAS Scale Goldeye 25.10.2.1
- **Container Runtime**: Docker (Fangtooth removed k3s/kubernetes)
- **IP**: 192.168.178.100
- **Hostname**: truenas
- **SSH Access**: `ssh nas`

## CLI Tools
```bash
# Query TrueNAS API (works without sudo)

# List all apps with status
ssh nas "midclt call app.query | jq -r '.[] | \"\(.name): \(.state)\"'"

# Get system info
ssh nas "midclt call system.info | jq ."

# List running apps only
ssh nas "midclt call app.query | jq '.[] | select(.state==\"RUNNING\") | .name'"

# Get detailed app info (containers, ports, volumes, images)
ssh nas "midclt call app.get_instance jellyfin | jq ."

# Get container IDs for an app
ssh nas "midclt call app.container_ids jellyfin"

# Start/stop/restart an app (returns job ID)
ssh nas "midclt call app.start factorio"
ssh nas "midclt call app.stop factorio"
ssh nas "midclt call app.redeploy jellyfin"

# Check job status (use job ID returned from start/stop/redeploy)
ssh nas "midclt call core.get_jobs | jq '.[] | select(.id==27894)'"

# List all available app methods
ssh nas "midclt call core.get_methods | jq -r 'keys[] | select(startswith(\"app.\"))'"

# Docker commands require sudo (use web GUI or direct terminal for these)
ssh nas "sudo docker ps"
```

## midclt Usage Rules
1. **Unfamiliar method?** Read the API definition first: `ssh nas "cat /usr/lib/python3/dist-packages/middlewared/api/v25_10_2/<method>.py"`
2. **Parameter error?** Check the API definition immediately - don't guess formats
3. **Use `-j` flag** for job progress (e.g., `midclt call -j app.create ...`)

### App Management via midclt (no sudo needed)
| Method | Description |
|--------|-------------|
| `app.query` | List all apps |
| `app.get_instance <name>` | Get detailed app info |
| `app.start <name>` | Start an app |
| `app.stop <name>` | Stop an app |
| `app.redeploy <name>` | Redeploy an app |
| `app.upgrade <name>` | Upgrade an app |
| `app.upgrade_summary <name> '{}'` | Check if upgrade available (returns `upgrade_version`) |
| `app.create` | Install a new app from catalog |
| `app.delete <name>` | Remove an app |
| `app.update <name>` | Update app configuration |
| `app.container_ids <name>` | Get container IDs |
| `app.used_ports` | List all used ports |
| `app.image.query` | List docker images |
| `catalog.apps` | List all available catalog apps |
| `catalog.trains` | List available trains (stable, community, etc.) |

## Installing Apps via CLI

### Discover Available Apps
```bash
# List all apps in catalog (by train)
ssh nas "midclt call catalog.apps {}" | jq '.stable | keys[]'      # stable train
ssh nas "midclt call catalog.apps {}" | jq '.community | keys[]'   # community train

# Check which train an app is in
ssh nas "midclt call catalog.apps {}" | jq '.community.navidrome'
```

### Install an App
```bash
ssh nas "midclt call -j app.create '{
  \"catalog_app\": \"<app_name>\",
  \"app_name\": \"<instance_name>\",
  \"train\": \"<train_name>\",
  \"version\": \"<chart_version>\",
  \"values\": {}
}'"
```

### app.create Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `catalog_app` | Yes* | - | App name in catalog (e.g., "navidrome") |
| `app_name` | Yes | - | Instance name (alphanumeric + hyphens, must start with letter) |
| `train` | No | `stable` | **Must set to `community` for community apps** |
| `version` | No | `latest` | Chart version |
| `values` | No | `{}` | Configuration overrides |

**GOTCHA**: The `train` parameter defaults to `stable`. If an app only exists in `community`, you MUST set `train: "community"` or installation will fail.

### Example: Install Navidrome
```bash
ssh nas "midclt call -j app.create '{\"catalog_app\": \"navidrome\", \"app_name\": \"navidrome\", \"train\": \"community\", \"values\": {}}'"
```

## Storage Pools
- **nvmepool** (~896GB NVMe SSD, Samsung 980 1TB) - Primary/fast storage (preferred). **Keep below 80% usage** (ZFS performance degrades above this)
- **spinningpool** (~7.3TB HDD mirror, 2x Seagate Exos 8TB) - Bulk storage for long-term archives

## Media Storage Workflow (IMPORTANT)
- **NVMe is the default** - User prefers using NVMe as much as possible
- **Jellyseer downloads go to NVMe by default**
- `nvmeshare/medialibrary/` = NEW/TEMPORARY media (can be deleted, check here first)
- `spinningpool/movies/` and `spinningpool/tvshows/` = LONG-TERM keepers only

When looking for media:
1. Check `/mnt/nvmepool/nvmeshare/medialibrary/` first (new/temporary)
2. Then check `/mnt/spinningpool/` for archived content

## Fix Media Library Permissions
When user asks to fix permissions on movies/tvshows folders, run these commands:

**User/Group IDs**: lysergic=3000, apps=568

```bash
# Fix TV shows - all subfolders
ssh nas "for dir in /mnt/nvmepool/nvmeshare/medialibrary/tvshows/*/; do midclt call filesystem.chown \"{\\\"path\\\": \\\"\$dir\\\", \\\"uid\\\": 3000, \\\"gid\\\": 568}\" --job; midclt call filesystem.setperm \"{\\\"path\\\": \\\"\$dir\\\", \\\"mode\\\": \\\"775\\\"}\" --job; done"

# Fix Movies - all subfolders
ssh nas "for dir in /mnt/nvmepool/nvmeshare/medialibrary/movies/*/; do midclt call filesystem.chown \"{\\\"path\\\": \\\"\$dir\\\", \\\"uid\\\": 3000, \\\"gid\\\": 568}\" --job; midclt call filesystem.setperm \"{\\\"path\\\": \\\"\$dir\\\", \\\"mode\\\": \\\"775\\\"}\" --job; done"

# Fix single folder
ssh nas 'midclt call filesystem.chown "{\"path\": \"/mnt/nvmepool/nvmeshare/medialibrary/tvshows/FOLDER_NAME\", \"uid\": 3000, \"gid\": 568}" --job'
ssh nas 'midclt call filesystem.setperm "{\"path\": \"/mnt/nvmepool/nvmeshare/medialibrary/tvshows/FOLDER_NAME\", \"mode\": \"775\"}" --job'
```

This sets ownership to `lysergic:apps` and permissions to `775` (owner+group can write).

## Directory Structure

### `/mnt/nvmepool/nvmeshare/` - Application Data (PRIMARY)
| Directory | Purpose |
|-----------|---------|
| `medialibrary/movies/` | NEW movies - default Jellyseer download, temporary/deletable |
| `medialibrary/tvshows/` | NEW TV shows - default Jellyseer download, temporary/deletable |
| `downloads/movies/` | Active torrent downloads for movies |
| `downloads/tvshows/` | Active torrent downloads for TV shows |
| `jellyfin/` | Media server config, metadata, plugins |
| `qbittorrent/` | Torrent client data |
| `kavita/` | Manga/comic reader data |
| `jellyseer/` | Media request management |
| `paperless/` | Document management |
| `mealie/` | Recipe manager |
| `linkding/` | Bookmark manager |
| `syncthing/` | File sync config |
| `homarr/`, `homepage/` | Dashboard apps |
| `factorio/` | Game server data |
| `actualbudget/` | Budgeting app |
| `wger/` | Fitness app |
| `secondbrain/` | Notes/knowledge base |
| `recyclarr/` | Sonarr/Radarr config sync |
| `composefiles/` | Docker compose files |
| `nginx-proxy-manager/` | Reverse proxy configs |
| `scripts/` | Custom maintenance scripts (e.g. ntfy alert forwarder) |

### `/mnt/spinningpool/` - Archive/Bulk Storage
| Directory | Purpose |
|-----------|---------|
| `music/` | Music library for Navidrome |
| `movies/` | LONG-TERM movie keepers (62+ titles, includes 4K/HDR) |
| `tvshows/` | LONG-TERM TV keepers (Attack on Titan, Game of Thrones, Better Call Saul) |
| `aks/` | Photo archive (194 folders, personal/family photos by event/date) |
| `books/` | E-books (Health, Islam, Medicina Estetica, Novels, Self-Improvement, Trading) |
| `courses/` | Online courses (Affinity Photo, Procreate, iPhone Photography) |
| `generalstorage/` | General files (Audio, Backup, Books, Documenti, ECM courses, Games Backup, Photoshop, University, Videos) |
| `immich/` | Immich photo management data |
| `backup/` | Application backups (linkding, mealie, paperless, secondbrain) |
| `syncthing/` | Syncthing sync folder |
| `piwigo/` | Piwigo gallery data |

## Running Services
Apps run as Docker containers. Most management via web GUI; use CLI for AI tasks.

### Running
| App | Port |
|-----|------|
| jellyfin | 8096 |
| jellyseerr | 5055 |
| radarr | 7878 |
| sonarr | 8989 |
| bazarr | 6767 |
| prowlarr | 9696 |
| qbittorrent | 10189 (web), 51413 (torrent) |
| flaresolverr | 8191 |
| recyclarr | - |
| kavita | 2030 |
| linkding | 9090 |
| syncthing | 8384 (web), 22000 (sync) |
| immich | 2283 |
| piwigo | 8080 |
| open-webui | 3000 |
| navidrome | 30043 |
| nginx-proxy-manager | 80, 443, 81 |
| paperless-ngx | 8000 |

### Stopped
wger, factorio, wg-easy, dockge, homepage, actual-budget, kosync, dnstt

### Custom Apps (docker-compose deployed)
| App | Port | Containers |
|-----|------|------------|
| paperless-ngx | 8000 | paperless-ngx + postgres:17 + redis:7 |

## Access
- **TrueNAS Web UI**: `https://192.168.178.100:444` (HTTPS redirect enabled)
- **Nginx Proxy Manager**: Handles domain routing (configs at `/mnt/nvmepool/nvmeshare/nginx-proxy-manager/`)
  - `jelly.alcared.it` → Jellyfin (public)
  - `kavita.alcared.it` → Kavita (public)
  - `ding.alcared.it` → Navidrome (public)
  - `seer.alcared.it` → Jellyseerr (public, multi-user)
  - `fit.alcared.it` → wger (STOPPED — broken proxy, remove or update)


## Monitoring
- **ntfy.sh alerts** (topic: `lysacidnasalerts6-9`): TrueNAS WARNING/CRITICAL/EMERGENCY via cron every 5 min (`truenas-ntfy-alerts.sh`); NVMe >90% via cron every 30 min (`nvme-disk-alert.sh`, fires once until resolved). Scripts in `/mnt/nvmepool/nvmeshare/scripts/`
- **Weekly app auto-update** (cron ID 7, Sat 3AM): `app-auto-update.sh` — upgrades all RUNNING apps, logs to `scripts/app-update.log`, notifies ntfy on updates or failures (silent if nothing to do)
- **SMART tests**: Weekly SHORT (all disks, Sun 2AM), monthly LONG (HDDs, 1st 3AM)
- **ZFS snapshots**: nvmeshare every 4h (7d retention, recursive — covers all app data)
- **ZFS scrubs**: Both pools weekly (Sunday)

## Security Hardening Applied
- SSH: Weak ciphers disabled (NONE, AES128-CBC removed), key-only auth
- NFS: All 16 exports restricted to `192.168.178.0/24`
- HTTPS redirect enabled for TrueNAS Web UI
- Audit log retention: 30 days (max)
- **CrowdSec** (custom app): Parses NPM logs, bans malicious IPs via iptables DOCKER-USER + INPUT chains. Notifies ntfy on ban. Config at `/mnt/nvmepool/nvmeshare/crowdsec/`
  - Engine: `crowdsecurity/crowdsec:latest`, API on `127.0.0.1:8085`
  - Bouncer: `ghcr.io/shgew/cs-firewall-bouncer-docker`, iptables mode, targets INPUT + DOCKER-USER
  - Collection: `crowdsecurity/nginx-proxy-manager`
  - **NOTE**: Do NOT add nftables `forward` hook — breaks Docker networking on TrueNAS (iptables-nft conflict)

### Still Needs Web UI Configuration
- Enable 2FA/TOTP for admin account (Credentials > Users > admin)
- Enable authentication on Radarr, Sonarr, Prowlarr, Bazarr (Settings > General > Authentication)
- Replace broad `nvmeshare` SMB share with purpose-specific shares
- Regenerate SSL certificate with proper SANs (192.168.178.100, truenas)

## Custom Apps (docker-compose)
Custom apps use `custom_compose_config_string` parameter in `app.create`/`app.update`:
```bash
# Create
ssh nas "midclt call -j app.create '{\"custom_app\": true, \"app_name\": \"<name>\", \"custom_compose_config_string\": \"<yaml-with-\\n>\"}'"
# Update compose
ssh nas "midclt call -j app.update \"<name>\" '{\"custom_compose_config_string\": \"<yaml-with-\\n>\"}'"
```

## Recyclarr / Quality Profiles
- Config: `/mnt/nvmepool/nvmeshare/recyclarr/configs/recyclarr.yml`
- Sync: `ssh nas "sudo docker exec ix-recyclarr-recyclarr-1 recyclarr sync"`
- **5 profiles** synced to both Radarr and Sonarr:
  - `HD 1080p [ITA/ENG]` / `1080p [ITA/ENG]` — Bluray > WEB, Italian+MULTi scored +1500
  - `4K [ITA/ENG]` — same but UHD/WEB-2160p
  - `HD 1080p [ENG]` / `1080p [ENG]` — ENG only
  - `4K [ENG]` — ENG only 4K
  - `HD 1080p [CHN]` / `1080p [CHN]` — Chinese+MULTi scored +1500
- **Italian/MULTi scores** (+1500 in ITA/ENG profiles): managed via API, protected by `reset_unmatched_scores.except`. If re-syncing after profile deletion, re-apply scores via Radarr/Sonarr API.
- **Minimum seeders**: 5 on all indexers in Radarr and Sonarr
- **Jellyseerr**: profiles appear automatically in the "Advanced" tab when requesting

## Notes
- Most operations should be done via the TrueNAS web GUI
- CLI access via `ssh nas` works for file operations and app management
- Use `midclt` commands for app management (start/stop/restart/redeploy) - no sudo needed
- Direct `docker` commands require sudo with password (use web GUI or direct terminal)
- **SSH user permissions**: `admin` (uid 950) is in groups: `admin`, `builtin_administrators`, `apps` (568), `lysergic` (3000). Can write to any 775 lysergic-group dirs on nvmeshare.
- **ZFS dataset ACL gotcha**: New datasets inherit NFSv4 ACL from pool. If a child dataset has NFSv4 but parent has POSIX, SMB will alert. Fix: `pool.dataset.update "<dataset>" '{"acltype": "POSIX", "aclmode": "DISCARD"}'`
- **Paperless-ngx**: Custom compose app (postgres:17 + redis:7). Data at `/mnt/nvmepool/nvmeshare/paperless/` (single dataset, no child datasets). Documents backed up to `spinningpool/backup/paperless`
- **ZFS replication**: secondbrain, linkding, paperless all replicate to spinningpool/backup/ using the main nvmeshare snapshot task
