---@id b411ba56-fb7f-40bd-a5c3-5ec31257292c
---@referenceName traffic.lua
-- 城市车流：所有车辆沿自身前方匀速行驶，到边界绕回
local U = CS.UnityEngine
local V3 = U.Vector3
local T = U.Time
local LIMIT = 134.0
local cars = {}
local ready = false

local function isCar(n)
  local s = string.lower(n)
  if s == 'car' then return true end
  if string.find(s, 'moto', 1, true) then return true end
  if string.find(n, '摩托', 1, true) then return true end
  if string.find(n, '小汽车', 1, true) then return true end
  return false
end

local function scan(t, d)
  if t == nil or d > 16 then return end
  local ok, nm = pcall(function() return t.name end)
  if ok and nm ~= nil and isCar(nm) then
    pcall(function()
      local rb = t:GetComponent(typeof(U.Rigidbody))
      if rb ~= nil then rb.isKinematic = true; rb.useGravity = false end
    end)
    table.insert(cars, t)
  end
  local okc, c = pcall(function() return t.childCount end)
  if okc and c ~= nil then
    for i = 0, c - 1 do
      local okk, ch = pcall(function() return t:GetChild(i) end)
      if okk then scan(ch, d + 1) end
    end
  end
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
  ready = true
end

function Update()
  if not ready then return end
  local dt = T.deltaTime
  if dt == nil or dt <= 0 then return end
  for i = 1, #cars do
    local tr = cars[i]
    if tr ~= nil then
      local q = tr.position
      local z = q.z + 7.0 * dt
      if z > LIMIT then z = -LIMIT end
      tr.position = V3(q.x, q.y, z)
    end
  end
end
