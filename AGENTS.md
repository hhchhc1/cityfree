# 给 AI 助手的工作约定（城市自由人）

> 这份文件是给接手这个项目的 AI 助手看的。用户明确要求：**每次改完代码都必须发布上线**。

## 一、每次改完代码，必须走完这 5 步（缺一不可）

1. **备份**：`copy "城市自由人.html" "城市自由人.html.bak-fixNN-说明"`
2. **改主文件** `城市自由人.html`（唯一真相来源）
3. **同步发布副本**：`copy "城市自由人.html" "index.html"` —— 网站加载的是 `index.html`，漏了这一步线上永远不变
4. **升版本号**：`const BUILD = 'YYYYMMDD-fixNN-短说明'`，右上角 HUD 会显示，用来判断线上是否已更新
5. **提交并推送**：
   ```bash
   git add "城市自由人.html" "index.html"
   git commit -m "fixNN: 改了什么"
   git push origin master
   ```

推送成功后 **30~60 秒** GitHub Pages 自动重建，访问线上地址确认右上角版本号变成新值（没变就 Ctrl+F5 强刷）。

## 二、推送失败怎么办

- **不要当作改完了**。本地提交只算一半，线上没变等于用户没拿到。
- 先判断是不是网络/代理问题：
  ```powershell
  curl.exe -x http://127.0.0.1:7897 -sS -o NUL -w "%{http_code}" --max-time 10 https://github.com
  ```
  返回 `000` 且报 `schannel` / TLS 握手失败 = 代理出口不通（常见于代理节点失效、订阅过期），不是代码问题。
- 网络恢复后**立刻补推**，并明确告诉用户"线上已更新/尚未更新"。
- 本机 Clash Verge 的系统代理为 `127.0.0.1:7897`，git 已配置同样的 http.proxy。

## 三、关键地址

- 线上：https://hhchhc1.github.io/cityfree/
- 仓库：https://github.com/hhchhc1/cityfree（master 分支根目录，Pages 自动构建）
- 本地工程：`C:\Users\lenovo\OneDrive\Desktop\10.13CITYFREE`

## 四、改代码前必读

见 `README.md` 第六节"代码维护提示"（TDZ、共享材质 `lodShared`、`scale` NaN 兜底、动态物体登记、构建顺序契约）。

## 五、验证手段

`_*.js` 脚本（已被 .gitignore 忽略）可用无头 Edge 载入游戏、传送到指定坐标、切昼夜、截图并读回像素亮度。
例：`_pitch.js`（球场夜间巡检）、`_lamp.js`（路灯占道检测）。
截图输出在 `shots/`。改动涉及画面时，**先截图对比再提交**，不要凭想象改数值。
