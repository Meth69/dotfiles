# NAS Documentation

## System Info
- **OS**: TrueNAS Scale Fangtooth 25.04
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

### App Management via midclt (no sudo needed)
| Method | Description |
|--------|-------------|
| `app.query` | List all apps |
| `app.get_instance <name>` | Get detailed app info |
| `app.start <name>` | Start an app |
| `app.stop <name>` | Stop an app |
| `app.redeploy <name>` | Redeploy an app |
| `app.upgrade <name>` | Upgrade an app |
| `app.container_ids <name>` | Get container IDs |
| `app.used_ports` | List all used ports |
| `app.image.query` | List docker images |

## Storage Pools
- **nvmepool** (~69GB NVMe SSD) - Primary/fast storage (preferred)
- **spinningpool** (HDD) - Bulk storage for long-term archives

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

### `/mnt/spinningpool/` - Archive/Bulk Storage
| Directory | Purpose |
|-----------|---------|
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
| nginx-proxy-manager | 80, 443, 81 |

### Stopped
wger, factorio, wg-easy, dockge, homepage, actual-budget, kosync, dnstt

### Crashed
paperless-ngx

## Access
- **TrueNAS Web UI**: `https://192.168.178.100:444` or `http://192.168.178.100:81`
- **Nginx Proxy Manager**: Handles domain routing (configs at `/mnt/nvmepool/nvmeshare/nginx-proxy-manager/`)

## Notes
- Most operations should be done via the TrueNAS web GUI
- CLI access via `ssh nas` works for file operations and app management
- Use `midclt` commands for app management (start/stop/restart/redeploy) - no sudo needed
- Direct `docker` commands require sudo with password (use web GUI or direct terminal)
