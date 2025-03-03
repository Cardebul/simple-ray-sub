#!/usr/bin/python3

import argparse
import json

def_templ = 'server.template.json'
def_templ_usname = 'vpsadmin'
def_port = 8080

parser = argparse.ArgumentParser(description='replace: cert log uid')
parser.add_argument('--user', type=str, help='server user')
parser.add_argument('--uid', type=str, help='xray uuid')
parser.add_argument('--save', type=int, help='save new cnfg (0 or 1) default 0', default=False)
args = parser.parse_args()

user = args.user
uid = args.uid
save = bool(args.save)


if __name__ == '__main__':
    with open(def_templ, 'rb') as f: data = json.load(f)

    data['log']['access'] = data['log']['access'].replace(def_templ_usname, user)
    data['log']['error'] = data['log']['error'].replace(def_templ_usname, user)

    for i in data['inbounds'][0]['settings']['clients']: i['id'] = uid
    for i in data['inbounds'][0]['settings']['fallbacks']: i['dest'] = def_port

    for i in data['inbounds'][0]['streamSettings']['tlsSettings']['certificates']:
        i['certificateFile'] = i['certificateFile'].replace(def_templ_usname, user)
        i['keyFile'] = i['keyFile'].replace(def_templ_usname, user)
    
    
    if save:
        with open('config.json', 'w') as f:
            json.dump(data, f, ensure_ascii=True, indent=2)
    else: print(json.dumps(data, ensure_ascii=True, indent=2))