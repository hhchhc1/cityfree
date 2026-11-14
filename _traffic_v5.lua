---@id b411ba56-fb7f-40bd-a5c3-5ec31257292c
---@referenceName traffic.lua
-- 城市车流 + 黄色虚线中心线（Unlit 纯色材质）
local U = CS.UnityEngine
local V3 = U.Vector3
local T = U.Time
local ROAD = 26.0
local LIMIT = 128.0
local LANE = 3.2

local cars = {}
local ready = false
local built = false

local function isVeh(n)
  local s = string.lower(n)
  if s == 'car' then return true end
  if string.find(s, 'moto', 1, true) then return true end
  if string.find(n, '摩托', 1, true) then return true end
  if string.find(n, '小汽车', 1, true) then return true end
  return false
end
local function snap(v) return math.floor(v / ROAD + 0.5) * ROAD end

local function setup(t)
  pcall(function()
    local rb = t:GetComponent(typeof(U.Rigidbody))
    if rb ~= nil then rb.isKinematic = true; rb.useGravity = false end
  end)
  local q = t.position
  local dz = math.abs(q.z - snap(q.z))
  local dx = math.abs(q.x - snap(q.x))
  local e = { t = t, spd = 8.0 }
  if dz <= dx then
    e.axis = 'z'; e.road = snap(q.z); e.dir = (q.z >= 0) and -1 or 1
    t.position = V3(snap(q.x) + e.dir * LANE, q.y, e.road)
  else
    e.axis = 'x'; e.road = snap(q.x); e.dir = (q.x >= 0) and 1 or -1
    t.position = V3(e.road, q.y, snap(q.z) - e.dir * LANE)
  end
  table.insert(cars, e)
end

local function scan(t, d)
  if t == nil or d > 16 then return end
  local ok, nm = pcall(function() return t.name end)
  if ok and nm ~= nil and isVeh(nm) then setup(t) end
  local okc, c = pcall(function() return t.childCount end)
  if okc and c ~= nil then
    for i = 0, c - 1 do
      local okk, ch = pcall(function() return t:GetChild(i) end)
      if okk then scan(ch, d + 1) end
    end
  end
end

local function makeLine()
  local mat = nil
  pcall(function()
    local sh = U.Shader.Find('Unlit/Color')
    if sh == nil then sh = U.Shader.Find('Sprites/Default') end
    if sh ~= nil then
      mat = U.Material(sh)
      mat.color = U.Color(1.0, 0.78, 0.08, 1.0)
    end
  end)
  pcall(function()
    for k = -5, 5 do
      local road = k * ROAD
      for _, axis in ipairs({ 'x', 'z' }) do
        local p = -126.0
        while p < 126.0 do
          local go = U.GameObject.CreatePrimitive(U.PrimitiveType.Cube)
          if go ~= nil then
            go.name = 'dash'
            local tr = go.transform
            if axis == 'x' then
              tr.localScale = V3(3.0, 0.05, 0.2)
              tr.position = V3(p, 0.10, road)
            else
              tr.localScale = V3(0.2, 0.05, 3.0)
              tr.position = V3(road, 0.10, p)
            end
            if mat ~= nil then
              local r = go:GetComponent(typeof(U.Renderer))
              if r ~= nil then r.material = mat end
            end
          end
          p = p + 6.0
        end
      end
    end
  end)
end

function Start()
  cars = {}
  ready = false
  pcall(function()
    local t = self.transform
    local g = 0
    while t.parent ~= nil and g < 64 do t = t.parent; g = g + 1 end
    scan(t, 0)
  end)
  if not built then makeLine(); built = true end
  ready = true
end

function Update()
  if not ready then return end
  local dt = T.deltaTime
  if dt == nil or dt <= 0 then return end
  for i = 1, #cars do
    local c = cars[i]
    local tr = c.t
    if tr ~= nil then
      local q = tr.position
      local d = c.spd * dt * c.dir
      if c.axis == 'z' then
        local z = q.z + d
        if z > LIMIT then z = -LIMIT elseif z < -LIMIT then z = LIMIT end
        tr.position = V3(q.x, q.y, z)
      else
        local x = q.x + d
        if x > LIMIT then x = -LIMIT elseif x < -LIMIT then x = LIMIT end
        tr.position = V3(x, q.y, q.z)
      end
    end
  end
end
