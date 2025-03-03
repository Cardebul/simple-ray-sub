import json
import subprocess
import uuid
import random
def_template_name = 'main.template.json'

def_server_user = 'bolik'
def_passphrase = 123888

all_servs = []

def _validate_serv_data(data: dict):

    host = data.get('host')
    port = data.get('port')
    password = data.get('password')
    domain = data.get('domain')
    
    if not all(
        [isinstance(host, str), isinstance(port, int), isinstance(password, str), isinstance(domain, str),]
    ): raise Exception('non valid')
    sub = data.get('sub')
    if sub:
        del data['sub']
        data['main'] = True
    else: data['main'] = False
    all_servs.append(data)

    if sub: return all([_validate_serv_data(su) for su in sub])
    return True

def validate_main_template(data: dict):
    passphrase_for_rsa = data.get('passphrase_for_rsa')
    server_user = data.get('server_user')
    main = data.get('main')
    if not all(
        [isinstance(passphrase_for_rsa, int), isinstance(server_user, str), isinstance(main, dict), _validate_serv_data(main)]
    ): raise Exception('non valid')
    return True


if __name__ == '__main__':
    with open(def_template_name, 'rb') as f: data = json.load(f)
    if not validate_main_template(data): exit(1)
    # ./main.sh 89.169.36.143 22 '9UhCjPT7wM!T' kz.gekkkk.cc 0 223 bolik
    f_commands = []
    main_cmd = ''
    passphrase_for_rsa = data.get('passphrase_for_rsa')
    server_user = data.get('server_user')
    with open('docker_pac/.env', 'w') as f:
        for server in all_servs:
            main = server.get('main')
            host = server.get('host')
            port = server.get('port')
            password = server.get('password')
            domain = server.get('domain')
            uid = str(uuid.uuid4())
            name = int(random.random() * 100 // 1)

            cmd = f"./main.sh {host} {port} '{password}' {domain} {int(bool(main))} {passphrase_for_rsa} {server_user} {uid}"
            f.write(f'VLESS{name}=vless://{uid}@{domain}:443?security=tls&alpn=http%2F1.1&encryption=none&headerType=none&type=tcp&flow=xtls-rprx-vision#{name}\n')
            if main:
                main_cmd = cmd
                continue
            f_commands.append(cmd)

    cmnds = [subprocess.Popen(cmd, shell=True) for cmd in f_commands]
    ends = [p.wait() for p in cmnds]

    print('mainserv script ex')
    m = subprocess.Popen(main_cmd, shell=True)
    m.wait()
