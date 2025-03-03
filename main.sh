#!/bin/sh

arch_checker() {
    if [ -f /etc/os-release ]; then . /etc/os-release
        if [ "$ID" = "arch" ]; then
            echo "OS: $NAME"
            return 0
        fi
    fi
    return 1
}

if ! arch_checker; then
    echo non arch
    exit 1
fi

if [ "$#" -lt 1 ]; then
    echo "usage: $0 host port passw domain main passphrase_for_rsa server_user"
    exit 1
fi

HOST=$1
PORT=$2
PASW=$3
DOMAIN=$4
ISMAIN=$5
PASSPHRASE=$6
USERNAME=$7
RAYUID=$8
USER="root"

echo "usage: $0 host port passw domain main passphrase_for_rsa server_user"
echo $HOST $PORT $PASW $DOMAIN $ISMAIN $PASSPHRASE $USERNAME

sshpass -p "$PASW" ssh -o StrictHostKeyChecking=no -p $PORT "$USER@$HOST" "exit"
sshpass -p "$PASW" scp -P $PORT index2.html "$USER@$HOST:/tmp/index.html"
if [ $ISMAIN -eq 1 ]; then
    sshpass -p "$PASW" scp -r -P $PORT docker_pac "$USER@$HOST:/tmp/docker_pac"
    sshpass -p "$PASW" ssh -p $PORT "$USER@$HOST" "apt-get install -y docker-compose sudo nginx"
fi

sshpass -p "$PASW" scp -P $PORT onserver.sh "$USER@$HOST:/tmp/onserver.sh"

sshpass -p "$PASW" ssh -p $PORT "$USER@$HOST" "
    useradd -m -s /bin/bash $USERNAME && \
    echo '$USERNAME:$PASW' | chpasswd && \
    echo '$USERNAME ALL=(ALL) NOPASSWD: ALL' | EDITOR='tee -a' visudo
" "exit"

    
echo afteruseradd

result=$(sshpass -p "$PASW" ssh "$USERNAME@$HOST" "bash /tmp/onserver.sh '$DOMAIN' '$ISMAIN' '$USERNAME'" "exit")
echo "$result"

json_conf=$( python3 editor.py --user=$USERNAME --uid=$RAYUID )
result2=$(sshpass -p "$PASW" ssh "$USER@$HOST" "echo '$json_conf' > /usr/local/etc/xray/config.json && systemctl restart xray && systemctl start xray && exit")
echo "$result2"




# security TODO (test)

# new_port=$((RANDOM % 2951 + 1050))
# ssh-keygen -t rsa -f $DOMAIN -N $PASSPHRASE

# sshpass -p "$PASW" ssh -p $PORT "$USER@$HOST" "mkdir -p /home/$USERNAME/.ssh && chmod 700 /home/$USERNAME/.ssh"
# sshpass -p "$PASW" scp -P $PORT "$DOMAIN.pub" "$USER@$HOST:/home/$USERNAME/.ssh/authorized_keys"

# sshpass -p "$PASW" ssh -p $PORT "$USER@$HOST" "
#     echo 'Port $new_port\nPermitRootLogin no\nPasswordAuthentication no\nPubkeyAuthentication yes' >> /etc/ssh/sshd_config.d/new_user.conf && \
#     ufw allow '$new_port/tcp' && systemctl restart ssh
# "

# endsecurity


echo "after"