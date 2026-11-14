# 造世界编辑器 · 城市自由人导入 —— 交接文档

> 生成时间：2026-11-13 01:50（Asia/Shanghai）
> 工作目录：`C:\Users\lenovo\OneDrive\Desktop\10.13CITYFREE`

---

## 一、已完成（可复用，别重做）

| 项目 | 产物 | 状态 |
|---|---|---|
| 全城几何导出 | `export_all\tile_*.glb`（16 块，500m 网格） | ✅ 92.6 万面 |
| 碰撞数据 | `export_all\colliders.json` | ✅ 3244 个 AABB |
| 世界范围 | X −469..2222，Z −905..558 | ✅ 已记入 manifest |
| 编辑器导入通路 | 见下文「导入配方」 | ✅ 已打通 |
| 面数上限 | **单资产 ≤ 30,000 面** | ✅ 已实测（报错原文） |

## 二、编辑器控制配方（关键，照抄即可）

1. 建快捷方式 `%TEMP%\zaoshi_dbg.lnk`，目标 exe：`D:\ZAOSHIJIE\造世界编辑器\造世界编辑器.exe`，参数：
   `--remote-debugging-port=9222 --force-renderer-accessibility`
2. **必须通过 Explorer 启动**（直接 Start-Process exe 会秒退）：
   ```powershell
   Start-Process explorer.exe -ArgumentList '"%TEMP%\zaoshi_dbg.lnk"'
   ```
3. 等 15–30 秒，`fetch('http://127.0.0.1:9222/json/list')`，取 url 含 `/homepage/` 或 `/editor/` 的 page。
4. CDP 里 **`element.click()` 和 `Input.dispatchMouseEvent` 都可用**；`mouse_event`/SendKeys 被 UIPI 拦截，无效。

## 三、导入配方（已验证成功 2 次）

1. 主页点「去编辑」进入工程（或「新建空白项目」）
2. 编辑器内：真实鼠标点击 `项目` → `导入资产`
3. 弹窗出现后（文案「点击或拖拽文件到此处上传」），**拖拽上传**（没有 `input[type=file]`）：
   ```js
   // 先在 Node 起本地 HTTP 服务（带 CORS），再在页面里：
   const resp = await fetch('http://127.0.0.1:PORT/xxx.glb');
   const blob = await resp.blob();
   const file = new File([blob], 'xxx.glb', { type: 'model/gltf-binary' });
   const dz = [...document.querySelectorAll('div')].find(e => e.innerText.trim() === '点击或拖拽文件到此处上传');
   const dt = new DataTransfer(); dt.items.add(file);
   ['dragenter','dragover','drop'].forEach(t => dz.dispatchEvent(new DragEvent(t, { bubbles: true, cancelable: true, dataTransfer: dt })));
   ```
4. 填「资产名称」（`input[type=text]` 里 `maxLength===15` 的那个，要用原生 setter 设值再派发 `input` 事件）
5. 点「导入」，等 15 秒

**注意：一次导入成功后，「项目」菜单会失效**（点不开），必须重启编辑器才能再导一次。这是编辑器自身 bug。

## 四、已知限制（实测数据）

| 限制 | 数值 | 依据 |
|---|---|---|
| 单资产面数 | **≤ 30,000 面** | 报错原文：「上传模型最大面数限制为3w面（当前模型：92.638w面）」 |
| 导入资产是否占场景容量 | **不占** | 导入后容量一直 202/4000 |
| 支持格式 | 仅 `.glb` | 弹窗文案 |
| 场景容量 | 4000 | 顶部显示 |

> ⚠️ 早前误判为「文件体积上限」。**体积不是限制，面数是。** Draco 压缩只减体积不减面数，因此对绕开限制无效（但可用于减小传输体积）。

## 五、待做（按顺序）

### 步骤 1：带贴图重导（当前卡点）
文件 `_export2.js` 里的 `window.__GLB` 需要改三处：
- 第 26–31 行 `matFor()`：加 `baseColorTexture`
- 第 51–54 行顶点写入：追加 `TEXCOORD_0`（`o.geometry.attributes.uv`，UV 一直都在，只是没导）
- 第 68 行 GLB JSON：增加 `images`（PNG 以 bufferView 内嵌）、`textures`、`samplers`

参考实现（贴图内嵌）：
```js
var texCache = {}, imgs = [], texs = [];
function imgFor(canvas) {
  var key = canvas.__cfKey || (canvas.__cfKey = 'k' + Math.random());
  if (texCache[key] !== undefined) return texCache[key];
  var url = canvas.toDataURL('image/png');
  var b64 = url.slice(url.indexOf(',') + 1), bin = atob(b64), arr = new Uint8Array(bin.length);
  for (var i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  var vi = addView(arr);
  imgs.push({ bufferView: vi, mimeType: 'image/png' });
  texs.push({ sampler: 0, source: imgs.length - 1 });
  texCache[key] = texs.length - 1; return texCache[key];
}
```
并在 JSON 里加：`images: imgs, textures: texs, samplers: [{ magFilter: 9729, minFilter: 9987, wrapS: 10497, wrapT: 10497 }]`

### 步骤 2：按面数切包
脚本 `_split_packs.js` 目前按**体积**均衡分配，需改为按**面数**累计（每包 ≤ 29,000 面），预计切成 **31 包**。

### 步骤 3：逐包导入
每包导入前重启编辑器（见「导入配方」），约 1.5 分钟/包。

### 步骤 4：摆位拼接
每块几何已是**世界坐标**，导入后按 tile 原点偏移摆放即可无缝。

### 步骤 5：清理
删除重复资产：`cf_1500-500` ×4、`cf_1500-1000` ×2。

## 六、现有脚本清单

| 文件 | 用途 |
|---|---|
| `_export2.js` | **全城导出器**（注入 `window.__GLB`，自定义 GLB 写入） |
| `_split_packs.js` | 按体积切 4 包（需改面数版） |
| `_merge_glb.js` | 合并全部 tile 为 `cityfree_ALL.glb` |
| `_ed23.js` | 重启 → 进工程 → 导入指定文件（改 `NAME` 常量即可） |
| `_ed24.js` | 读取导入弹窗状态 + 报错原文 |
| `_probe_496.js` | 无头浏览器 harness 母版 |
| `_validate_glb.js` | 回读 GLB 验证 |

## 七、当前工程状态

- 工程：新建的空工程（用户已同意删除旧的「仔仔世界」测试工程）
- 资产库：`yamen_final`（12,701 面，✅ 合规）、`cf_1500-500` ×4、`cf_1500-1000` ×2（待删）
- 场景：空（仅地面 + 出生点），容量 202/4000
