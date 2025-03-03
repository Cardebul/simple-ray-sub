#!/bin/sh


ubuntu_checker() {
    if [ -f /etc/os-release ]; then . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            echo "OS: $NAME"
            return 0
        fi
    fi
    return 1
}


if ! ubuntu_checker; then
    exit 1
fi


if [ "$#" -lt 1 ]; then
    echo "usage: $0 domain main server_user"
    exit 1
fi

DOMAIN=$1
MAIN=$2
USERNAME=$3
home_dir="/home/$USERNAME"


echo "usage: $0 domain main server_user"
echo $DOMAIN $MAIN $USERNAME



mkdir -p /home/$USERNAME/www/app


# inst

# nginx setup

cp /tmp/index.html $home_dir/www/app/index.html
chmod -R 777 /home/$USERNAME/www/


sudo bash -c 'echo "server {
    listen 80;
    server_name '$DOMAIN';
    root /home/'$USERNAME'/www/app;
    index index.html;
}" > /etc/nginx/conf.d/new.conf'

sudo ufw allow 'Nginx Full'
sudo systemctl enable nginx
sudo systemctl reload nginx

# end nginx setup


acme_setup () {
    if [ -d "$home_dir/.acme.sh" ]; then
        if [ "$(ls -A $home_dir/.acme.sh)" ]; then
            return 0
        fi
    fi
    echo ACMEBLOCK $DOMAIN $home_dir

    wget -O -  https://get.acme.sh | sh
    . .bashrc
    .acme.sh/acme.sh --upgrade --auto-upgrade
    .acme.sh/acme.sh --issue --server letsencrypt -d $DOMAIN -w $home_dir/www/app --keylength ec-256 --force
    mkdir -p $home_dir/certs
    .acme.sh/acme.sh --installcert -d $DOMAIN --cert-file $home_dir/certs/cert.crt --key-file $home_dir/certs/cert.key --fullchain-file $home_dir/certs/fullchain.crt --ecc

    return 0
}


xray_setup () {
    if systemctl list-unit-files | grep -q xray; then
        return 0
    fi
    wget https://github.com/XTLS/Xray-install/raw/main/install-release.sh
    if ! sudo bash install-release.sh; then
        return 1
    fi
    rm install-release.sh


    mkdir -p ~/xray_cert
    .acme.sh/acme.sh --install-cert -d $DOMAIN --ecc \
           --fullchain-file ~/xray_cert/xray.crt \
           --key-file ~/xray_cert/xray.key
    chmod +r ~/xray_cert/xray.key

    # xray-cert-renew.sh
    mkdir -p ~/xray_log
    touch ~/xray_log/access.log && touch ~/xray_log/error.log
    chmod a+w ~/xray_log/*.log

    return 0
}

# cd $home_dir
cd "$home_dir"
sudo chmod 777 -R .


acme_setup
xray_setup

if [ $MAIN -ne 1 ]; then
    cp /tmp/index.html $home_dir/www/app/index.html
    cat <<EOL > new.conf
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        return 301 https://\$http_host\$request_uri;
    }
}

server {
    listen 127.0.0.1:8080;
    root /home/$USERNAME/www/app;
    index index.html;
    add_header Strict-Transport-Security "max-age=63072000" always;
}
EOL
else 
    echo inmain
    sudo apt-get install -y docker-compose
    cp -r /tmp/docker_pac $home_dir/www/app/docker_pac
    cd $home_dir/www/app/docker_pac
    sudo docker-compose down && sudo docker-compose up --build -d
    # sudo docker-compose down && sudo docker-compose up --build -d
    echo afterinmain

    cat <<EOL > new.conf
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        return 301 https://\$http_host\$request_uri;
    }
}

server {
    listen 127.0.0.1:8080;
    location / {
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

            proxy_pass http://127.0.0.1:8000/;

            proxy_pass_header Set-Cookie;
            proxy_read_timeout 90s;
    
    }
}
EOL
fi
sudo rm /etc/nginx/conf.d/new.conf
sudo mv new.conf /etc/nginx/conf.d/new.conf
sudo systemctl reload nginx