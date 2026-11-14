---@displayName 城市车流
---@referenceName traffic.lua
local U = CS.UnityEngine
local V3 = U.Vector3
local T = U.Time
local ready = false
local target = nil

local function pick(self)
  local t = self.transform
  local g = 0
  while t.parent ~= nil and g < 64 do t = t.parent; g = g + 1 end
  local found = nil
  local function walk(x, d)
    if x == nil or d > 14 or found ~= nil then return end
    local ok, nm = pcall(function() return x.name end)
    if ok and nm ~= nil then
      local n = string.lower(nm)
      if n == 'car' or string.find(n, 'moto', 1, true) or string.find(nm, '摩托', 1, true) or string.find(nm, '小汽车', 1, true) then
        found = x
        return
      end
    end
    local okc, c = pcall(function() return x.childCount end)
    if okc and c ~= nil then
      for i = 0, c - 1 do
        local okk, ch = pcall(function() return x:GetChild(i) end)
        if okk then walk(ch, d + 1) end
      end
    end
  end
  walk(t, 0)
  return found
end

function Start()
  ready = false
  pcall(function()
    target = pick(self)
    if target ~= nil then
      pcall(function()
        local rb = target:GetComponent(typeof(U.Rigidbody))
        if rb ~= nil then rb.isKinematic = true; rb.useGravity = false end
      end)
    end
  end)
  local function onOwn(ok) ready = true end
  local ok = pcall(function() self:RequestOwnership(onOwn) end)
  if not ok then ready = true end
end

function Update()
  if not ready or target == nil then return end
  local dt = T.deltaTime
  if dt == nil or dt <= 0 then return end
  pcall(function()
    local q = target.position
    target.position = V3(q.x, q.y, q.z + 6.0 * dt)
  end)
end
