# Oracle VPS Setup

## One-time setup

### 1. Port UDP 27015

Oracle Console: Networking -> VCN -> Security Lists -> Add Ingress Rule (Source 0.0.0.0/0, UDP, port 27015).

VPS:
```
sudo iptables -I INPUT -p udp --dport 27015 -j ACCEPT
sudo netfilter-persistent save
```

### 2. Dependencies

```
sudo apt update
sudo apt install -y rsync libgl1 libxcursor1 libxinerama1 libxrandr2 libxi6 libasound2
mkdir -p /home/ubuntu/fps-server/logs
```

### 3. Deploy from local

```
./deploy/deploy.sh <oracle-public-ip>
```

### 4. Status

```
ssh ubuntu@<ip> 'sudo systemctl status fps-server'
ssh ubuntu@<ip> 'tail -f /home/ubuntu/fps-server/logs/server.log'
```

### 5. Play

Run exports/fps-client.exe, enter Oracle IP + 27015, JOIN.
