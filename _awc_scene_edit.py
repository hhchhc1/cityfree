import json
import sys
import zipfile
import shutil

scene_path = sys.argv[1]
backup_path = scene_path + ".bak-python"

shutil.copyfile(scene_path, backup_path)

with zipfile.ZipFile(scene_path, "r") as zin:
    entries = [(info, zin.read(info.filename)) for info in zin.infolist()]

data = None
for info, raw in entries:
    if info.filename == "SerializePcgData.json":
        data = json.loads(raw.decode("utf-8"))
        break
if data is None:
    raise SystemExit("SerializePcgData.json not found")

changed = []
for node in data.get("nodeTransformDatas", []):
    basic = node.get("basic") or {}
    name = basic.get("nodeName")
    if name in ("地形块", "地形块(0,0)"):
        basic["isActive"] = False
        changed.append((name, "hidden"))
    if name == "出生点":
        basic.setdefault("pos", {})["y"] = 78.12
        changed.append((name, "y=78.12"))

new_raw = json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
with zipfile.ZipFile(scene_path, "w", zipfile.ZIP_DEFLATED) as zout:
    for info, raw in entries:
        if info.filename == "SerializePcgData.json":
            zout.writestr(info, new_raw)
        else:
            zout.writestr(info, raw)

print("changed", changed)
