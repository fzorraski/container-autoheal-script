#!/bin/bash

LOG_FILE="/var/log/restart_unhealthy_containers.log"

log() {
  local message="$1"
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

unhealthy_containers=$(docker ps --filter "health=unhealthy" --format "{{.ID}} {{.Names}}")

if [ -n "$unhealthy_containers" ]; then
  log "Unhealthy containers detected:"
  echo "$unhealthy_containers" | while read -r container_id container_name; do
    container_memory_usage=$(docker stats --no-stream --format "{{.MemUsage}}" "$container_id")
    container_cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container_id")
    container_uptime=$(docker inspect -f '{{ .State.StartedAt }}' "$container_id")
    container_restart_count=$(docker inspect -f '{{ .RestartCount }}' "$container_id")
    container_image=$(docker inspect -f '{{ .Config.Image }}' "$container_id")
    container_logs=$(docker logs --tail 20 "$container_id" 2>&1 | sed 's/^/    /')
    container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")

    system_memory_free=$(free -h | awk '/Mem:/ {print $4}')
    system_memory_total=$(free -h | awk '/Mem:/ {print $2}')
    system_cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8 "%"}')
    disk_usage=$(df -h / | awk 'NR==2 {print $4}')

    log "Restarting container: $container_name ($container_id)"
    log "Container image: $container_image"
    log "Container memory usage: $container_memory_usage"
    log "Container CPU usage: $container_cpu_usage"
    log "Container IP address: $container_ip"
    log "Container uptime: $container_uptime"
    log "Previous restart count: $container_restart_count"
    log "Available disk space: $disk_usage"
    log "System free memory: $system_memory_free / $system_memory_total"
    log "System CPU usage: $system_cpu_usage"
    log "Recent container logs:\n$container_logs"

    docker restart "$container_id"

    log "Container $container_name restarted successfully."
    log "###############################################"
  done
fi
