# HANDOFF4 — dsh版（33 个 GLB 包一次性正确摆位）

> 本文件记录 **dsh 版** 这条线的做法与结论。WorkBuddy 同时在同一个编辑器里做另一版，
> 为避免互相覆盖，本版单独复制成工程 `project_dsh01`（编辑器里显示名 **dsh版**），
> 原工程 `project_5giohe5q`（显示名 **wkbd版**）留给 WorkBuddy。

---

## 一、最关键结论：导入器的归一化规则（已验证）

**编辑器导入 GLB 时，只做「整体缩放 1/L」，不做重新居中。**
（L = 原始包围盒最长边；pivot 仍留在模型原本的世界原点）

因此：

```
把包摆回它的真实世界坐标  ==  position(0,0,0) + scale(L,L,L)
```

其中 `L` 就是资产库 `assets.entities` 里该资产的 `scale` 字段（导入时自动填的那个数）。

**旧做法（把包围盒中心填进 position / 或在编辑器里手拖）是错的**，
因为模型本来就在世界坐标里，平移会把整座城推飞。

证据（pack_29）：

| | 包围盒 center | size |
|---|---|---|
| 原始 `pack_29.glb` | (974.898, 45.7, -177.955) | (2491.595, 96.6, 1271.49) |
| 缓存后（导入后） | (0.391, 0.018, -0.071) | (1, 0.039, 0.51) |

`974.898 / 2491.595 = 0.39127` —— 纯缩放，无平移。缩放回去即复原。

---

## 二、scene.data 结构（离线改场景的唯一入口）

```
%APPDATA%\AI World Creator\projects\<proj>\scene.data     ← 是一个 ZIP
├── HeightMap_<id>.data
├── SplatMap_<id>_0.png / _1.png
├── MatCoverTex_<id>.png
└── SerializePcgData.json          ← 场景本体（UTF-8 无 BOM）
```

`SerializePcgData.json` 顶层：`version / spawnPointData / nodeTransformDatas[] / waterNetworks / runtimeScripts / envType …`

单个节点（pack 用得到的字段）：

```json
{
  "nodeName": "pk16", "pos": {x,y,z}, "rot": {x,y,z,w}, "scale": {x,y,z}, "tag": "Untagged",
  "aigcModelData":     { "uri": "<资产 uri>", "meshRefId": 0, "isShowTex": true, "opType": 4 },
  "assetData":         { "uri": "<资产 uri>", "assetID": "<资产 id>" },
  "glbSliceData":      { "sourceUri": "<资产 uri>", "sourceMeshRefId": 0, "slicePath": [], "debugSlicePath": "", "isShowTex": true, "opType": 4 },
  "appearanceData":    {…}, "physicsColliderData": {…},
  "editorOnlyData":    { "isLock": false, "isGroupRoot": false, "editorData": "" },
  "id": <随机 int>, "parentId": 0, "isActive": true, "layer": …, "isStatic": …
}
```

**编辑器不会主动写 scene.data**（没有保存按钮 / Ctrl+S，退出也不写）。
所以「直接改 ZIP 里的 json + 重启编辑器」是安全的，也是目前唯一能一次摆 33 个包的办法。

---

## 三、可复用的脚本（都在 `Desktop\10.13CITYFREE\`）

| 脚本 | 作用 |
|---|---|
| `pack_assets.json` | 33 个 `pkNN` → `{id, uri, scale(=L), faceCount}`，从 Redux `assets.entities` 抓的 |
| `_bb.js` / `_glbinfo.js` | 读 GLB 的 bbox / 网格清单（校验用） |
| `_build_pcg.js` | 用 `_pcg.json`（旧场景）+ `pack_assets.json` 生成 `_pcg_new.json`：33 个节点，pos 0、scale L |
| `_write_scene.ps1 -json <file>` | 把 JSON 塞回 `scene.data`（保留其它 ZIP 条目） |
| `_audit_world.js` | 逐包核对「缓存 bbox × L ≈ 原始 bbox」 |
| `_srv.js` + `_viewer.html` | 本地 three.js 预览：把 33 个包按 scale=1 拼起来看全城（`http://127.0.0.1:8811/viewer.html?scale1&fix`） |

复现步骤：

```powershell
cd Desktop\10.13CITYFREE
node _build_pcg.js                       # 生成 _pcg_new.json
powershell -File _write_scene.ps1 -json _pcg_new.json
# 重启编辑器 → 主页 → 打开工程
```

---

## 四、dsh版 当前状态

* 工程目录：`%APPDATA%\AI World Creator\projects\project_dsh01`（显示名 **dsh版**，worldId 11738596110851）
* `scene.data` = 40 个节点：地图 / 地形 / 湖泊 / 地形块×2 / 地表物体 / 出生点 + **pk01…pk33**
* 33 个包：`pos(0,0,0)`、`rot` 单位四元数、`scale = L`（各包不同：221 ~ 2639）
* `地形块` 设为 **隐藏**（那块 500×500 的白色大立方体挡住视线，WorkBuddy 先发现的问题，已继承）
* `physicsColliderData.enableCollision = false`（33 个 2.8 万面的 MeshCollider 会把编辑器拖死：
  开着时编辑器约 1 分钟就自动退回主页，关掉后能撑 4 分钟以上）
* 备份：`scene.data.bak-1113-0807`（原始 9 节点版）、`scene.data.bak-wkbd-1113`（有碰撞关闭、未隐藏地形）

## 五、还没解决 / 注意事项

1. **城市地面和马路不在导出的 GLB 里**。
   `export_all\cityfree_ALL.glb` 和 33 个包渲染出来都只有建筑/道具（一栋栋浮着），
   原游戏的地面应该是编辑器地形（`地图/地形块`）提供的。所以「全城俯视图」看起来会很空，
   但贴着地面看（编辑器里滚轮往下钻）是正常街区：路面、车位线、人行道、警车都在。
2. **相机很难操作**：`F` 是聚焦，滚轮方向实测不稳定（有时拉近有时推远），
   想拍全景建议先在树里选中一个 pk 节点再滚轮。
3. 编辑器窗口会在大约 1~4 分钟无操作后自己退回主页（不是崩溃，工程数据不受影响）。
4. 33 个包的三角面合计 917,953，其中 32 个 ≤29,000 面，`pk33` 只有 4,144 面。

## 六、和 WorkBuddy 的分工

* `project_5giohe5q` = **wkbd版**（WorkBuddy 在改，会覆盖 scene.data）
* `project_dsh01` = **dsh版**（本版，独立 scene.data，互不影响）
* 两版目前内容一致（都源于「33 包 pos0/scaleL」这套摆位），后续各自迭代。
