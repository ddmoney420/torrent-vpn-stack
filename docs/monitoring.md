# Monitoring and Observability Guide

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Components](#components)
- [Accessing Dashboards](#accessing-dashboards)
- [Available Dashboards](#available-dashboards)
- [Understanding Metrics](#understanding-metrics)
- [Custom Queries](#custom-queries)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [FAQ](#faq)

---

## Overview

The monitoring stack provides comprehensive visibility into your torrent VPN system using industry-standard observability tools:

- **Prometheus**: Time-series database for metrics collection
- **Grafana**: Visualization platform for creating dashboards
- **qBittorrent Exporter**: Torrent-specific metrics (speeds, peers, ratios)
- **cAdvisor**: Container resource metrics (CPU, memory, network)

### Benefits

- **Performance Monitoring**: Track download/upload speeds, bandwidth usage
- **Resource Management**: Monitor CPU, memory, and network usage per container
- **Health Tracking**: VPN uptime, container restarts, connection stability
- **Trend Analysis**: Historical data for capacity planning and optimization
- **Troubleshooting**: Identify bottlenecks and performance issues

---

## Quick Start

### 1. Enable Monitoring

Add to `.env` (or keep defaults from `.env.example`):

```bash
# Monitoring Configuration (Optional)
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin  # CHANGE THIS!

PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
CADVISOR_PORT=8081
```

### 2. Start with Monitoring Profile

```bash
# Start entire stack with monitoring enabled
docker compose --profile monitoring up -d

# Or start monitoring for existing stack
docker compose --profile monitoring up -d prometheus grafana qbittorrent-exporter cadvisor
```

### 3. Access Grafana

1. Open browser: http://localhost:3000
2. Login with credentials from `.env` (default: admin/admin)
3. Browse pre-configured dashboards:
   - **System - Container Resources**
   - **qBittorrent - Torrent Metrics**
   - **VPN - Gluetun Status**

### 4. Verify Prometheus

1. Open browser: http://localhost:9090
2. Go to **Status** → **Targets**
3. Verify all targets show "UP" status:
   - prometheus (self-monitoring)
   - cadvisor (container metrics)
   - qbittorrent (torrent metrics via exporter)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Monitoring Architecture                     │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │   Grafana    │ ← User accesses dashboards (port 3000)
    │  (Dashboards)│
    └──────┬───────┘
           │ Queries metrics
           ▼
    ┌──────────────┐
    │  Prometheus  │ ← Scrapes metrics every 15s (port 9090)
    │  (Metrics DB)│
    └──────┬───────┘
           │ Scrapes
           │
    ┌──────┴────────────────────────────────────────┐
    │                                               │
    ▼                                               ▼
┌─────────────┐                            ┌──────────────┐
│  cAdvisor   │                            │  qBittorrent │
│ (Container  │                            │   Exporter   │
│  Metrics)   │                            │  (Torrent    │
│             │                            │   Metrics)   │
└─────┬───────┘                            └──────┬───────┘
      │ Monitors                                  │ Queries
      │ Docker containers                         │ qBittorrent API
      ▼                                           ▼
┌─────────────────────────────────────────────────────────┐
│           Docker Containers (Gluetun, qBittorrent)      │
└─────────────────────────────────────────────────────────┘
```

### Data Flow

1. **cAdvisor** monitors all Docker containers (CPU, memory, network, disk)
2. **qBittorrent Exporter** polls qBittorrent's Web API for torrent metrics
3. **Prometheus** scrapes metrics from cAdvisor and qBittorrent Exporter every 15 seconds
4. **Grafana** queries Prometheus and displays metrics in dashboards
5. **User** views real-time and historical data in Grafana web UI

---

## Components

### Prometheus

**Purpose**: Metrics collection and storage

**Access**: http://localhost:9090

**Features**:
- Time-series database for metrics
- 30-day retention period (configurable)
- PromQL query language for analysis
- Built-in expression browser and graphing

**Configuration**: `config/prometheus/prometheus.yml`

**Data Location**: `prometheus-data` Docker volume

---

### Grafana

**Purpose**: Metrics visualization

**Access**: http://localhost:3000

**Default Credentials**: admin/admin (configured in `.env`)

**Features**:
- Pre-configured Prometheus datasource
- Three pre-built dashboards
- Dashboard customization and creation
- Alerting capabilities (optional)
- User management

**Configuration**:
- Datasources: `config/grafana/provisioning/datasources/`
- Dashboards: `config/grafana/provisioning/dashboards/`
- Dashboard JSON: `config/grafana/dashboards/`

**Data Location**: `grafana-data` Docker volume

---

### qBittorrent Exporter

**Purpose**: Export qBittorrent metrics to Prometheus format

**Image**: `caseyscarborough/qbittorrent-exporter`

**Metrics Endpoint**: `http://gluetun:17871/metrics` (runs on Gluetun's network)

**Metrics Provided**:
- `qbittorrent_torrents_count` - Total number of torrents
- `qbittorrent_download_speed_bytes` - Current download speed (bytes/sec)
- `qbittorrent_upload_speed_bytes` - Current upload speed (bytes/sec)
- `qbittorrent_total_download_bytes` - Total data downloaded
- `qbittorrent_total_upload_bytes` - Total data uploaded
- `qbittorrent_global_ratio` - Upload/download ratio

**Authentication**: Uses qBittorrent credentials from `.env`

---

### cAdvisor

**Purpose**: Container resource monitoring

**Image**: `gcr.io/cadvisor/cadvisor`

**Access**: http://localhost:8081

**Metrics Endpoint**: `http://cadvisor:8080/metrics`

**Metrics Provided**:
- `container_cpu_usage_seconds_total` - CPU usage per container
- `container_memory_usage_bytes` - Memory usage per container
- `container_network_receive_bytes_total` - Network RX per container
- `container_network_transmit_bytes_total` - Network TX per container
- `container_start_time_seconds` - Container start time (for uptime calculation)
- `container_last_seen` - Last time container was seen (for restart detection)

**Limitations**: Requires privileged mode on macOS for full disk metrics

---

## Accessing Dashboards

### First-Time Grafana Setup

1. **Access Grafana**: http://localhost:3000
2. **Login**: Use credentials from `.env` (default: admin/admin)
3. **Change Password** (recommended): Grafana will prompt on first login
4. **Browse Dashboards**:
   - Click **Dashboards** (icon on left sidebar)
   - Open folder: **Torrent VPN Monitoring**
   - Select a dashboard

### Dashboard URLs

- System Dashboard: http://localhost:3000/d/torrent-vpn-system
- qBittorrent Dashboard: http://localhost:3000/d/torrent-vpn-qbittorrent
- VPN Dashboard: http://localhost:3000/d/torrent-vpn-gluetun

### Prometheus UI

- Main UI: http://localhost:9090
- Targets Status: http://localhost:9090/targets
- Service Discovery: http://localhost:9090/service-discovery

---

## Available Dashboards

### System - Container Resources

**Purpose**: Monitor Docker container resource usage

**Panels**:
1. **Container CPU Usage (%)** - CPU utilization per container
2. **Container Memory Usage** - Memory consumption per container
3. **Container Network I/O** - Network RX/TX per container

**Use Cases**:
- Identify resource-heavy containers
- Plan Docker Desktop resource allocation
- Detect memory leaks or CPU spikes

**Key Metrics**:
- Gluetun CPU: Should be low (< 5%) during normal operation
- qBittorrent CPU: Higher during active downloads
- Memory: qBittorrent typically uses 200-500MB

---

### qBittorrent - Torrent Metrics

**Purpose**: Monitor torrent activity and performance

**Panels**:
1. **Total Torrents** - Number of torrents in qBittorrent
2. **Download Speed** - Current download rate
3. **Upload Speed** - Current upload rate
4. **Global Ratio** - Overall upload/download ratio
5. **Transfer Speeds Over Time** - Download/upload speed graph
6. **Torrent Count Over Time** - Historical torrent count
7. **Total Data Transferred** - Cumulative up/down totals

**Use Cases**:
- Monitor download/upload performance
- Track seeding ratios
- Identify bandwidth usage patterns
- Verify VPN speed impact

**Thresholds**:
- Global Ratio: Green > 1.0, Yellow 0.5-1.0, Red < 0.5
- Speeds: Varies by VPN provider and connection

---

### VPN - Gluetun Status

**Purpose**: Monitor VPN connection health and stability

**Panels**:
1. **VPN Connection Status** - UP/DOWN indicator
2. **VPN Uptime** - Time since last restart
3. **Container Restarts** - Number of recent restarts
4. **VPN Network Throughput** - RX/TX through VPN tunnel
5. **VPN Container CPU Usage** - Gluetun CPU utilization
6. **VPN Container Memory Usage** - Gluetun memory consumption

**Use Cases**:
- Verify VPN is connected and stable
- Detect frequent reconnections (potential VPN issues)
- Monitor VPN throughput vs. qBittorrent speeds
- Troubleshoot VPN performance

**Indicators**:
- Status GREEN = VPN connected and healthy
- Status RED = VPN down or container stopped
- Frequent restarts = Investigate VPN provider or config

---

## Understanding Metrics

### Metric Types

1. **Gauge**: Current value (e.g., CPU usage, memory usage)
   - Value can go up or down
   - Shows snapshot at query time

2. **Counter**: Cumulative value (e.g., total bytes downloaded)
   - Value only increases
   - Use `rate()` function to see per-second change

3. **Summary/Histogram**: Distribution of values (less common in this stack)

### Common Calculations

#### Rate (Per-Second Change)

Convert counter to per-second rate:
```promql
rate(container_cpu_usage_seconds_total[5m])
```
- `[5m]` = Look back 5 minutes
- Returns average per-second rate over that window

#### CPU Percentage

CPU usage as percentage:
```promql
rate(container_cpu_usage_seconds_total{name="gluetun"}[5m]) * 100
```

#### Network Bandwidth

Bytes per second to megabits per second:
```promql
rate(container_network_receive_bytes_total[5m]) * 8 / 1000000
```

---

## Custom Queries

### Prometheus Query Examples

Access Prometheus UI (http://localhost:9090) and try these queries:

#### VPN Uptime (seconds)

```promql
time() - container_start_time_seconds{name="gluetun"}
```

#### qBittorrent Download Speed (MB/s)

```promql
qbittorrent_download_speed_bytes / 1000000
```

#### Total Containers Running

```promql
count(container_last_seen > 0)
```

#### Container Memory as Percentage

```promql
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100
```

#### Network Throughput (Mbps)

```promql
rate(container_network_receive_bytes_total{name="gluetun"}[1m]) * 8 / 1000000
```

---

## Troubleshooting

### Prometheus Shows No Data

**Symptoms**: Dashboards are empty, Prometheus targets are "DOWN"

**Diagnosis**:
```bash
# Check Prometheus logs
docker logs prometheus

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

**Solutions**:

1. **Verify monitoring profile is active**:
   ```bash
   docker compose --profile monitoring ps
   # Should show prometheus, grafana, cadvisor, qbittorrent-exporter
   ```

2. **Check Prometheus configuration**:
   ```bash
   # Validate syntax
   docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
   ```

3. **Restart Prometheus**:
   ```bash
   docker restart prometheus
   ```

---

### qBittorrent Metrics Not Available

**Symptoms**: qBittorrent dashboard shows "No Data"

**Diagnosis**:
```bash
# Check exporter logs
docker logs qbittorrent-exporter

# Test qBittorrent API manually
docker exec -it gluetun wget -qO- http://localhost:8080/api/v2/app/version
```

**Solutions**:

1. **Verify qBittorrent credentials**:
   ```bash
   # Check .env file
   grep QBITTORRENT_USER .env
   grep QBITTORRENT_PASS .env
   ```

2. **Verify exporter can reach qBittorrent**:
   ```bash
   # Exporter runs on gluetun network, should reach localhost:8080
   docker logs qbittorrent-exporter 2>&1 | grep -i "error\|auth\|connection"
   ```

3. **Restart exporter**:
   ```bash
   docker restart qbittorrent-exporter
   ```

---

### Grafana "Data Source Not Found"

**Symptoms**: Dashboards show "Data source prometheus not found"

**Diagnosis**:
```bash
# Check Grafana logs
docker logs grafana

# Check datasource provisioning
docker exec grafana ls -la /etc/grafana/provisioning/datasources/
```

**Solutions**:

1. **Verify Prometheus datasource**:
   - Login to Grafana: http://localhost:3000
   - Go to **Configuration** → **Data Sources**
   - Should see "Prometheus" with green indicator

2. **Manually add datasource** (if missing):
   - **Configuration** → **Data Sources** → **Add data source**
   - Select **Prometheus**
   - URL: `http://prometheus:9090`
   - Click **Save & Test**

3. **Restart Grafana**:
   ```bash
   docker restart grafana
   ```

---

### cAdvisor Not Collecting Metrics

**Symptoms**: System dashboard shows no container metrics

**Diagnosis**:
```bash
# Check cAdvisor logs
docker logs cadvisor

# Test cAdvisor endpoint
curl -s http://localhost:8081/metrics | grep container_cpu_usage_seconds_total
```

**Solutions**:

1. **macOS-specific**: cAdvisor may have limited metrics on macOS Docker Desktop
   - Some metrics (disk I/O) are not available on macOS
   - CPU and memory should still work

2. **Verify privileged mode**:
   ```bash
   docker inspect cadvisor | grep Privileged
   # Should show "Privileged": true
   ```

3. **Restart cAdvisor**:
   ```bash
   docker restart cadvisor
   ```

---

### High Memory Usage

**Symptoms**: Prometheus or Grafana consuming excessive memory

**Solutions**:

1. **Reduce Prometheus retention**:
   Edit `docker-compose.yml`:
   ```yaml
   command:
     - '--storage.tsdb.retention.time=7d'  # Reduce from 30d to 7d
   ```

2. **Increase scrape interval**:
   Edit `config/prometheus/prometheus.yml`:
   ```yaml
   global:
     scrape_interval: 30s  # Increase from 15s to 30s
   ```

3. **Restart services**:
   ```bash
   docker compose --profile monitoring restart
   ```

---

## Advanced Configuration

### Adjust Scrape Intervals

Edit `config/prometheus/prometheus.yml`:

```yaml
# Global default (applies to all jobs unless overridden)
global:
  scrape_interval: 15s

# Per-job override
scrape_configs:
  - job_name: 'qbittorrent'
    scrape_interval: 10s  # More frequent for torrent metrics
```

### Change Retention Period

Edit `docker-compose.yml` → prometheus → command:

```yaml
command:
  - '--storage.tsdb.retention.time=7d'   # 7 days
  - '--storage.tsdb.retention.size=5GB'  # Or size-based
```

### Add Custom Dashboard

1. **Create dashboard in Grafana UI**
2. **Export JSON**:
   - Dashboard Settings → JSON Model → Copy
3. **Save to file**:
   ```bash
   # Save to config/grafana/dashboards/custom-dashboard.json
   ```
4. **Restart Grafana**:
   ```bash
   docker restart grafana
   ```

### Expose Metrics Externally

**Warning**: Only do this on trusted networks!

Edit `docker-compose.yml`:

```yaml
prometheus:
  ports:
    - "0.0.0.0:${PROMETHEUS_PORT:-9090}:9090"  # Expose to LAN

grafana:
  ports:
    - "0.0.0.0:${GRAFANA_PORT:-3000}:3000"  # Expose to LAN
```

Access from other devices: `http://YOUR_MAC_IP:3000`

---

## FAQ

### Q: How much disk space does monitoring use?

**A**: Depends on retention period and scrape interval:
- **Prometheus**: ~50-100MB per day (30-day retention = ~3GB)
- **Grafana**: ~50MB for dashboards and config
- **Total**: ~3-4GB for default configuration

### Q: Does monitoring slow down torrents?

**A**: No, monitoring overhead is minimal:
- cAdvisor: < 1% CPU, ~50MB RAM
- Prometheus: < 2% CPU, ~200MB RAM
- Grafana: < 1% CPU, ~100MB RAM
- qBittorrent Exporter: < 0.5% CPU, ~20MB RAM

### Q: Can I disable specific monitoring services?

**A**: Yes, stop individual services:

```bash
# Keep Prometheus/Grafana, disable cAdvisor
docker stop cadvisor

# Or remove from docker-compose.yml temporarily
```

### Q: How do I back up monitoring data?

**A**: Back up Docker volumes:

```bash
# Backup Grafana dashboards
docker run --rm -v torrent-vpn-stack_grafana-data:/data -v $(pwd):/backup ubuntu tar czf /backup/grafana-backup.tar.gz /data

# Backup Prometheus data
docker run --rm -v torrent-vpn-stack_prometheus-data:/data -v $(pwd):/backup ubuntu tar czf /backup/prometheus-backup.tar.gz /data
```

### Q: Can I set up alerts?

**A**: Yes, Grafana supports alerting:
1. **Grafana Alerting** (built-in): Configure in Grafana UI
2. **Prometheus Alertmanager** (advanced): Add alertmanager service

Example alert: Notify when VPN goes down
- See Grafana docs: https://grafana.com/docs/grafana/latest/alerting/

### Q: Why are Gluetun VPN metrics limited?

**A**: Gluetun's HTTP API returns JSON (not Prometheus metrics). For richer VPN metrics, consider:
- Custom Prometheus exporter for Gluetun
- Parse Gluetun logs for connection events
- Use cAdvisor container metrics as proxy

### Q: Can I use this monitoring with other stacks?

**A**: Yes! The monitoring stack is generic:
- Point Prometheus at any `/metrics` endpoint
- Create dashboards for any Prometheus data source
- Isolated in Docker network, can run alongside other services

---

## Additional Resources

- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Documentation**: https://grafana.com/docs/grafana/latest/
- **qBittorrent Exporter**: https://github.com/caseyscarborough/qbittorrent-exporter
- **cAdvisor**: https://github.com/google/cadvisor
- **PromQL Guide**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **Grafana Dashboards**: https://grafana.com/grafana/dashboards/

---

**Need Help?** Check the [main troubleshooting guide](../README.md#troubleshooting) or open an issue on GitHub.
