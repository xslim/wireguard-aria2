import base64
import json
import os
import sys
import time
import urllib.request

def call(method, *args):
    with open("/state/rpc-secret") as f:
        secret = f.read().strip()
    data = json.dumps({"jsonrpc":"2.0","id":1,"method":"aria2."+method,
                       "params":["token:"+secret,*args]}).encode()
    req = urllib.request.Request("http://127.0.0.1:6800/jsonrpc", data=data,
                                 headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=10) as response:
        result = json.load(response)
    if "error" in result:
        raise RuntimeError(result["error"]["message"])
    return result["result"]

def show(item):
    total = int(item.get("totalLength",0))
    done = int(item.get("completedLength",0))
    percent = 100*done/total if total else 0
    name = item.get("bittorrent",{}).get("info",{}).get("name")
    if not name:
        name = next((os.path.basename(f["path"]) for f in item.get("files",[]) if f.get("path")), "(metadata pending)")
    print(f'{item["gid"]}  {item["status"]:10}  {percent:6.1f}%  {int(item.get("downloadSpeed",0))/1024:8.1f} KiB/s  {name}', flush=True)

def main():
    cmd,*args = sys.argv[1:]
    if cmd == "ready":
        call("getVersion")
    elif cmd == "add":
        kind,source,directory,interactive,*options = args
        opts = {"dir":directory}
        for option in options:
            if not option.startswith("--") or "=" not in option:
                raise ValueError("Options must use --name=value")
            key,value = option[2:].split("=",1)
            if key not in {"max-download-limit","max-upload-limit","seed-time","seed-ratio","select-file","bt-stop-timeout"}:
                raise ValueError("Unsupported option: "+key)
            opts[key] = value
        if kind == "file":
            gid = call("addTorrent",base64.b64encode(sys.stdin.buffer.read()).decode(),[],opts)
        else:
            gid = call("addUri",[source],opts)
        print(gid,flush=True)
        call("saveSession")
        if interactive == "true":
            while True:
                item = call("tellStatus",gid)
                show(item)
                if item["status"] in ("complete","error","removed"):
                    return 0 if item["status"] == "complete" else 1
                followed = item.get("followedBy",[])
                if followed:
                    gid = followed[0]
                time.sleep(2)
    elif cmd == "list":
        for item in call("tellActive")+call("tellWaiting",0,1000)+call("tellStopped",0,100):
            show(item)
    elif cmd == "status":
        show(call("tellStatus",args[0]))
    elif cmd in ("pause","resume","stop"):
        call({"pause":"pause","resume":"unpause","stop":"remove"}[cmd],args[0])
        call("saveSession")
    else:
        raise ValueError("Unknown command")
    return 0

try:
    sys.exit(main())
except KeyboardInterrupt:
    sys.exit(130)
except Exception as exc:
    print(str(exc),file=sys.stderr)
    sys.exit(1)
