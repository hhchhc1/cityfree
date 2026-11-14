---@displayName 城市车流
---@start
---@var speedScale:number=1.0
---@name 速度倍率
---@desc 整体移动速度倍率
---@group 车流
---@end

-- 节点脚本：让场景里 sedan / copcar / car / person 节点持续行走
local UnityEngine = CS.UnityEngine
local Vector3 = UnityEngine.Vector3
local Time = UnityEngine.Time

local movers = {}
local inited = false

local function classify(name)
  if name == "sedan" or name == "copcar" or name == "car" then return "car" end
  if name == "person" then return "person" end
  return nil
end

local function collect(t, depth)
  if t == nil or depth > 14 then return end
  local ok, name = pcall(function() return t.name end)
  if ok and name ~= nil then
    local kind = classify(name)
    if kind ~= nil then
      local fwd = t.forward
      local axis, dir
      if math.abs(fwd.x) > math.abs(fwd.z) then
        axis = "x"; dir = (fwd.x >= 0) and 1 or -1
      else
        axis = "z"; dir = (fwd.z >= 0) and 1 or -1
      end
      local base = (kind == "car") and (6.0 + math.random() * 3.0) or (1.1 + math.random() * 0.5)
      table.insert(movers, { t = t, n = kind, axis = axis, dir = dir, speed = base * (speedScale or 1.0) })
    end
  end
  local cnt = 0
  local okc, c = pcall(function() return t.childCount end)
  if okc and c ~= nil then cnt = c end
  for i = 0, cnt - 1 do
    local okk, child = pcall(function() return t:GetChild(i) end)
    if okk and child ~= nil then collect(child, depth + 1) end
  end
end

local function init()
  movers = {}
  local t = self.transform
  local guard = 0
  while t.parent ~= nil and guard < 64 do t = t.parent; guard = guard + 1 end
  collect(t, 0)
  inited = true
end

function Start()
  local ok, err = pcall(init)
  if not ok then print("[city] init error: " .. tostring(err)) end
end

function Update()
  if not inited then return end
  local dt = Time.deltaTime
  if dt == nil or dt <= 0 then return end
  local n = #movers
  for i = 1, n do
    local m = movers[i]
    local tr = m.t
    if tr ~= nil then
      local p = tr.position
      local d = m.speed * dt * m.dir
      local lim = 210
      local x, y, z = p.x, p.y, p.z
      if m.axis == "x" then
        x = x + d
        if x > lim then x = -lim elseif x < -lim then x = lim end
      else
        z = z + d
        if z > lim then z = -lim elseif z < -lim then z = lim end
      end
      tr.position = Vector3(x, y, z)
    end
  end
end
