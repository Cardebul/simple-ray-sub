import os
import base64
import user_agents

from dotenv import load_dotenv
from fastapi import FastAPI, Request, Response
from fastapi.responses import FileResponse


load_dotenv()

app = FastAPI()

data = []
for key, value in os.environ.items():
    if 'VLESS' in key: data.append(value)

# vless = 'vless://28fbc9c2-8358-9bc7-8f32-2a5fkab7614b@asd.ca:443?security=tls&alpn=http%2F1.1&encryption=none&headerType=none&type=tcp&flow=xtls-rprx-vision#mp'.encode('utf-8')  ex
vlessiki = '\n'.join(data).encode('utf-8')

def conditional_ua_validation(ua: str):
    pua = user_agents.parse(ua)
    return any([pua.is_mobile, pua.is_pc, pua.is_tablet, pua.is_touch_capable])
    

@app.get("/")
async def read_root(request: Request):
    if conditional_ua_validation(request.headers.get('user-agent')): return FileResponse('index.html')
    return Response(content=base64.b64encode(vlessiki))
