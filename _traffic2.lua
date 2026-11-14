---@id 70e6a6a4-0f69-43ee-a459-809ebb947f9e

-- 城市自由人 · 车流与人流
local UnityEngine = CS.UnityEngine
local Vector3 = UnityEngine.Vector3
local Time = UnityEngine.Time

print("[city] module loaded")

local movers = {}
local inited = false
local lastErr = nil

local function classify(name)
  if name == "sedan" or name == "copcar" then return "car" end
  if name == "person" then return "person" end
  return nil
end

local function collectFrom(t, depth)
  if t == nil or depth > 12 then return end
  local ok, name = pcall(function() return t.name end)
  if ok and name ~= nil then
    local kind = classify(name)
    if kind ~= nil then
      local fwd = t.forward
      local axis, dir
      if math.abs(fwd.x) > math.abs(fwd.z) then
        axis = "x"; dir = fwd.x >= 0 and 1 or -1
      else
        axis = "z"; dir = fwd.z >= 0 and 1 or -1
      end
      local speed = (kind == "car") and (7.0 + math.random() * 4.0) or (1.2 + math.random() * 0.6)
      table.insert(movers, { t = t, kind = kind, axis = axis, dir = dir, speed = speed })
    end
  end
  local cnt = 0
  local okc, c = pcall(function() return t.childCount end)
  if okc and c ~= nil then cnt = c end
  for i = 0, cnt - 1 do
    local okk, child = pcall(function() return t:GetChild(i) end)
    if okk and child ~= nil then collectFrom(child, depth + 1) end
  end
end

local function rootOf(t)
  local guard = 0
  while t ~= nil and guard < 64 do
    local ok, p = pcall(function() return t.parent end)
    if not ok or p == nil then break end
    t = p; guard = guard + 1
  end
  return t
end

local function init()
  movers = {}
  if self == nil then print("[city] self is nil") return end
  local ok, t = pcall(function() return self.transform end)
  if not ok or t == nil then print("[city] self.transform nil") return end
  local root = rootOf(t)
  collectFrom(root, 0)
  inited = true
  local cars, people = 0, 0
  for i = 1, #movers do
    if movers[i].kind == "car" then cars = cars + 1 else people = people + 1 end
  end
  print(string.format("[city] traffic ready: %d cars, %d people", cars, people))
end

local function step(dt)
  if dt == nil or dt <= 0 then return end
  for i = 1, #movers do
    local m = movers[i]
    local tr = m.t
    if tr ~= nil then
      local ok, p = pcall(function() return tr.position end)
      if ok and p ~= nil then
        local d = m.speed * dt * m.dir
        local np
        if m.axis == "x" then
          if p.x > 205 then p = Vector3(-205, p.y, p.z) elseif p.x < -205 then p = Vector3(205, p.y, p.z) end
          np = Vector3(p.x + d, p.y, p.z)
        else
          if p.z > 205 then p = Vector3(p.x, p.y, -205) elseif p.z < -205 then p = Vector3(p.x, p.y, 205) end
          np = Vector3(p.x, p.y, p.z + d)
        end
        tr.position = np
      end
    end
  end
end

local function tick()
  if not inited then return end
  local ok, err = pcall(function() step(Time.deltaTime) end)
  if not ok and err ~= lastErr then lastErr = err; print("[city] step error: " .. tostring(err)) end
end

-- 兼容两种生命周期写法
function Start() local ok, err = pcall(init); if not ok then print("[city] init error: " .. tostring(err)) end end
function OnStart() Start() end
function Update() tick() end
function OnUpdate() tick() end
