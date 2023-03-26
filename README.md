# Caddy high availability with Consul (docker compose)

## Description


The following plugins were included in the build:

- Caddy-TLSConsul (stores certificates in a distributed system using Consul TLS K/V): [caddy-tlsconsul](https://github.com/pteich/caddy-tlsconsul)
- Caddy-RateLimit (limits the number of requests): [caddy-ratelimit](https://github.com/hundertzehn/caddy-ratelimit).


 


#### INSTALL

1. Prepare

```
git clone https://github.com/mihsergeev/caddy-consul.git /tmp/caddy-consul-install
cd /tmp/caddy-consul-install
```

2. Generate secret key for consul sync


```
docker run -it consul consul keygen
```
3. replace **CONSULKEY** to secret in file **install.sh** (one on all servers) - 140 line

Each server must have a unique hostname (replace **SERVERNAME** with your name)

```
hostname=SERVERNAME
hostname $(echo $hostname)
hostnamectl set-hostname $(echo $hostname)
echo $(hostname -I | cut -d' ' -f1) $(echo $hostname) >> /etc/hosts
```


3. Install 
```
bash install.sh
```

#
#


####  Uninstall
```
# cd /app/caddyconsul && docker compose stop
# cd / && rm -rf /app/caddyconsul
# docker system prune -a
```
