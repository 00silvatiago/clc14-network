global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "ec2-nodes"
    static_configs:
      - targets:
%{ for ip in ips ~}
        - "${ip}:9100"
%{ endfor ~}
