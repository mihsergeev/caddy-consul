echo "INSTALL caddy + consul in DOCKER (HA)"

echo "`cat <<YOLLOPUKKI

 ██████╗ █████╗ ██████╗ ██████╗ ██╗   ██╗
██╔════╝██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝
██║     ███████║██║  ██║██║  ██║ ╚████╔╝
██║     ██╔══██║██║  ██║██║  ██║  ╚██╔╝
╚██████╗██║  ██║██████╔╝██████╔╝   ██║
 ╚═════╝╚═╝  ╚═╝╚═════╝ ╚═════╝    ╚═╝

 ██████╗ ██████╗ ███╗   ██╗███████╗██╗   ██╗██╗
██╔════╝██╔═══██╗████╗  ██║██╔════╝██║   ██║██║
██║     ██║   ██║██╔██╗ ██║███████╗██║   ██║██║
██║     ██║   ██║██║╚██╗██║╚════██║██║   ██║██║
╚██████╗╚██████╔╝██║ ╚████║███████║╚██████╔╝███████╗
 ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚══════╝

YOLLOPUKKI`"


echo "!!! for HA need 3/5/7/9 etc servers"

read -p "Enter number of servers: " server_count

if ! [[ "$server_count" =~ ^[0-9]+$ ]]; then
echo "Error: enter a number."
exit 1
fi


declare -a server_ips

echo "The first ip must be the address of the current server"
for (( i=1; i<=$server_count; i++ )); do
  read -p "Enter external IP server #$i: " server_ip
  server_ips+=("$server_ip")
done

command="agent -server -data-dir=/consul/data -bind ${server_ips[0]} -client 0.0.0.0"


mkdir -p /app/caddyconsul -p
cd /app/caddyconsul || exit

mkdir caddy_config consul-data sites
touch Caddyfile consul-config.json

##### ADD docker-compose.yml
cat << EOF > docker-compose.yml
version: "3.7"
services:
  caddy:
    network_mode: host
    hostname: caddy
    container_name: caddy
    restart: always
    build:
     context: .
     dockerfile: Dockerfile
    volumes:
      - ./caddy_config:/config
      - ./sites:/sites
      - ./Caddyfile:/etc/caddy/Caddyfile

  consul-$HOSTNAME:
    image: consul
    hostname: consul-$HOSTNAME
    container_name: consul-$HOSTNAME
    restart: always
    command: $command
    network_mode: host
    volumes:
      - "./consul-data:/consul/data"
      - "./consul-config.json:/consul/config/consul-config.json"
EOF

##### ADD Caddyfile
cat << EOF > Caddyfile
{
    email noreply@myemail.com

    storage consul {
           address      "${server_ips[0]}:8500"
           token        "consul-access-token"
           timeout      10
           prefix       "caddytls"
           value_prefix "myprefix"
           aes_key      "consultls-1234567890-caddytls-32"
           tls_enabled  "false"
           tls_insecure "true"
                  }

}
    import /sites/*
{
}
EOF

cat << EOF > sites/test
test.${server_ips[0]}.sslip.io  {
respond 200
}
EOF


##### ADD Dockerfile
cat << \EOF > Dockerfile
FROM caddy:2.6.4-builder AS builder

RUN xcaddy build \
    --with github.com/pteich/caddy-tlsconsul \
    --with github.com/hundertzehn/caddy-ratelimit

FROM caddy:2.6.4

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

EXPOSE 80
EXPOSE 443
EXPOSE 2019

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
EOF



##### ADD consul-config.json
cat << EOF > consul-config.json
{
    "bootstrap_expect": $server_count,
    "client_addr": "0.0.0.0",
    "datacenter": "Mydc",
    "data_dir": "/var/consul",
    "domain": "consul",
    "enable_script_checks": true,
    "dns_config": {
        "enable_truncate": true,
        "only_passing": true
    },
    "encrypt": "CONSULKEY",
    "leave_on_terminate": true,
    "log_level": "INFO",
    "rejoin_after_leave": true,
    "server": true,
EOF

echo '    "start_join": [' >> consul-config.json
for server_ip in "${server_ips[@]}"; do
  echo "    \"$server_ip\"," >> consul-config.json
done
sed -i '$ s/,$/\n    \],/' consul-config.json
echo '    "ui": true' >> consul-config.json
echo '}' >> consul-config.json



docker compose up -d --build

sleep 10

echo "if multiple server - go to next server and run script there"


echo "open browser and check https://test.${server_ips[0]}.sslip.io - for caddy test"
echo "open browser and check http://${server_ips[0]}:8500/ui/ - for consul test"


#### clean
# cd /app/caddyconsul && docker compose stop
# cd / && rm -rf /app/caddyconsul
# docker system prune -a



