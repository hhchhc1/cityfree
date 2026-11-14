---@displayName 城市车流
---@referenceName traffic.lua
---@start
---@var speedScale:number=1.0
---@name 速度倍率
---@desc 整体移动速度倍率
---@range 0.2,4,0.1
---@group 车流
---@end

-- 靠右行驶的车流：节点名以 car / moto / 摩托 / person 开头即可被驱动
local UnityEngine = CS.UnityEngine
local Vector3 = UnityEngine.Vector3
local Time = UnityEngine.Time
local ROAD = 26.0
local LIMIT = 134.0
local LANE = 3.2

local movers = {}
local inited = false

local function kindOf(name)
  local n = string.lower(name)
  if string.find(n, 'moto', 1, true) or string.find(name, '摩托', 1, true) then return 'moto' end
  if string.sub(n, 1, 3) == 'car' or string.find(n, 'sedan', 1, true) or string.find(name, '车', 1, true) then return 'car' end
  if string.find(n, 'person', 1, true) or string.find(name, '人', 1, true) then return 'person' end
  return nil
end

local function snap(v)
  return math.floor(v / ROAD + 0.5) * ROAD
end

local function collect(t, depth)
  if t == nil or depth > 14 then return end
  local ok, name = pcall(function() return t.name end)
  if ok and name ~= nil then
    local k = kindOf(name)
    if k ~= nil then
      -- 关掉物理，避免 Rigidbody 把位置写回去
      pcall(function()
        local rb = t:GetComponent(typeof(UnityEngine.Rigidbody))
        if rb ~= nil then rb.isKinematic = true; rb.useGravity = false end
      end)
      local q = t.position
      local fwd = t.forward
      local axis, dir
      if math.abs(fwd.x) > math.abs(fwd.z) then axis = 'x'; dir = (fwd.x >= 0) and 1 or -1
      else axis = 'z'; dir = (fwd.z >= 0) and 1 or -1 end
      local lane
      if axis == 'x' then
        local rz = snap(q.z)
        lane = rz + dir * LANE
        t.position = Vector3(q.x, q.y, lane)
      else
        local rx = snap(q.x)
        lane = rx - dir * LANE
        t.position = Vector3(lane, q.y, q.z)
      end
      local base = (k == 'person') and 1.4 or 9.0
      table.insert(movers, { t = t, axis = axis, dir = dir, speed = base * (speedScale or 1.0) })
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

function Start()
  movers = {}
  local ok, err = pcall(function()
    local t = self.transform
    local guard = 0
    while t.parent ~= nil and guard < 64 do t = t.parent; guard = guard + 1 end
    collect(t, 0)
  end)
  inited = ok
end

function Update()
  if not inited then return end
  local dt = Time.deltaTime
  if dt == nil or dt <= 0 then return end
  for i = 1, #movers do
    local m = movers[i]
    local tr = m.t
    if tr ~= nil then
      local q = tr.position
      local d = m.speed * dt * m.dir
      local x, y, z = q.x, q.y, q.z
      if m.axis == 'x' then
        x = x + d
        if x > LIMIT then x = -LIMIT elseif x < -LIMIT then x = LIMIT end
      else
        z = z + d
        if z > LIMIT then z = -LIMIT elseif z < -LIMIT then z = LIMIT end
      end
      tr.position = Vector3(x, y, z)
    end
  end
end
