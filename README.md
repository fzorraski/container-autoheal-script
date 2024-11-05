## Container autoheal

The healthcheck will monitor the application service inside the container. Every minute, it will perform a simple check by sending a request to http://localhost:8080 (internally within the container) and waiting for a response to verify that the service is running. If the service does not respond within 10 seconds, it will be considered a failure, and a new attempt will be made.

If application fails to respond twice in a row, Docker will mark the container as unhealthy. Containers in this state will automatically be restarted, allowing them to recover and continue running without manual intervention. Before restarting, the script will log information about each container's CPU and memory usage, uptime, restart count, IP address, and recent logs, as well as the current state of the host system (free memory, CPU usage, and disk space). Logs are saved at `/var/log/restart_unhealthy_containers.log`.

### Required Configurations

1. Add the **healthcheck** configuration in docker-compose.yml
```
services:
    app1:
      healthcheck:
        test: ["CMD", "curl", "-f", "http://localhost:8080/"]
        interval: 1m
        timeout: 10s
        retries: 2
        start_period: 30s
```

2. Download the script and set up a cron job to run it every 1 minute
```
sudo bash -c "wget -O /usr/local/bin/restart_unhealthy_containers.sh https://raw.githubusercontent.com/fzorraski/container-autoheal-script/main/restart_unhealthy_containers.sh && \
chmod +x /usr/local/bin/restart_unhealthy_containers.sh && \
(crontab -l ; echo '* * * * * /usr/local/bin/restart_unhealthy_containers.sh') | crontab -"
```




