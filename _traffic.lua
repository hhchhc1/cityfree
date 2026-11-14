---@id 70e6a6a4-0f69-43ee-a459-809ebb947f9e

-- 城市自由人 · 车流与人流
-- 作用：本地运行时让场景里名为 sedan / copcar / car / person 的节点沿各自的朝向持续行走，
--       走到城市边界后从另一头绕回来，形成"车流/人流"。
local UnityEngine = CS.UnityEngine
local Vector3 = UnityEngine.Vector3
local Time = UnityEngine.Time

local movers = {}
local inited = false

local function isPrefix(name, prefix)
  return string.sub(name, 1, #prefix) == prefix
end

local function classify(name)
  if name == "sedan" or name == "copcar" then
    return "car"
  end
  if name == "person" then
    return "person"
  end
  return nil
end

-- 从脚本自身向上找到世界根，再递归收集
local function collectFrom(t)
  local name = t.name
  local kind = classify(name)
  if kind ~= nil then
    local fwd = t.forward
    local axis, dir
    if math.abs(fwd.x) > math.abs(fwd.z) then
      axis = "x"
      dir = fwd.x >= 0 and 1 or -1
    else
      axis = "z"
      dir = fwd.z >= 0 and 1 or -1
    end
    local speed
    if kind == "car" then
      speed = 7.0 + math.random() * 4.0
    else
      speed = 1.2 + math.random() * 0.6
    end
    table.insert(movers, {
      t = t,
      kind = kind,
      axis = axis,
      dir = dir,
      speed = speed,
    })
  end
  local n = t.childCount
  for i = 0, n - 1 do
    local child = t:GetChild(i)
    if child ~= nil then
      collectFrom(child)
    end
  end
end

local function resetPosition(m)
  local p = m.t.position
  if m.axis == "x" then
    if p.x > 205 then
      m.t.position = Vector3(-205, p.y, p.z)
    elseif p.x < -205 then
      m.t.position = Vector3(205, p.y, p.z)
    end
  else
    if p.z > 205 then
      m.t.position = Vector3(p.x, p.y, -205)
    elseif p.z < -205 then
      m.t.position = Vector3(p.x, p.y, 205)
    end
  end
end

local function step(dt)
  local count = #movers
  for i = 1, count do
    local m = movers[i]
    local tr = m.t
    if tr ~= nil then
      local p = tr.position
      local d = m.speed * dt * m.dir
      if m.axis == "x" then
        tr.position = Vector3(p.x + d, p.y, p.z)
      else
        tr.position = Vector3(p.x, p.y, p.z + d)
      end
      resetPosition(m)
    end
  end
end

function Start()
  movers = {}
  local t = self.transform
  local guard = 0
  while t.parent ~= nil and guard < 64 do
    t = t.parent
    guard = guard + 1
  end
  collectFrom(t)
  inited = true
  local cars, people = 0, 0
  for i = 1, #movers do
    if movers[i].kind == "car" then cars = cars + 1 else people = people + 1 end
  end
  print(string.format("[city] traffic ready: %d cars, %d people", cars, people))
end

function Update()
  if not inited then return end
  step(Time.deltaTime)
end
