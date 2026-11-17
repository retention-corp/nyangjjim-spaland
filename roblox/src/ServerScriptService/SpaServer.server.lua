-- Nyangjjim Spaland server: data, economy, monetization, world interactions.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local C = require(RS:WaitForChild("SpaConfig"))
local Spa = workspace:WaitForChild("Spa")

-- remotes
local remotes = RS:FindFirstChild("SpaRemotes") or Instance.new("Folder")
remotes.Name = "SpaRemotes"; remotes.Parent = RS
local function remote(class, name) local r = remotes:FindFirstChild(name) or Instance.new(class); r.Name = name; r.Parent = remotes; return r end
local Action = remote("RemoteEvent", "Action")
local Notify = remote("RemoteEvent", "Notify")
local GetState = remote("RemoteFunction", "GetState")

-- data
-- DataStore only works once the place is published; fall back to memory so playtests still run.
local okStore, store = pcall(function() return DataStoreService:GetDataStore("NyangjjimSpa_v1") end)
if not okStore then
	warn("[Nyangjjim] DataStore unavailable (place not published yet) - progress will not be saved")
	local mem = {}
	store = {GetAsync = function(_, k) return mem[k] end, SetAsync = function(_, k, v) mem[k] = v end}
end
local DEFAULT = {coins = 30, gender = "", towel = "pink", outfit = "orange", jjim = true, owned = {}, receipts = {}, lastDay = 0, streak = 0, total = 0}
local data, passes, lastAction, saunaOpen = {}, {}, {}, {}

local function copy(t) local n = {} for k, v in pairs(t) do n[k] = type(v) == "table" and copy(v) or v end return n end
local function load(player)
	local ok, saved = pcall(function() return store:GetAsync("u" .. player.UserId) end)
	local d = copy(DEFAULT)
	if ok and type(saved) == "table" then for k, v in pairs(saved) do d[k] = v end end
	d._loaded = ok
	return d
end
local function save(player)
	local d = data[player]; if not d or not d._loaded then return end
	local out = {} for k, v in pairs(d) do if k:sub(1,1) ~= "_" then out[k] = v end end
	pcall(function() store:SetAsync("u" .. player.UserId, out) end)
end

local function hasPass(player, key) return passes[player] and passes[player][key] == true end
local function passId(key) for _, p in ipairs(C.GamePasses) do if p.key == key then return p.id end end return 0 end

local function state(player)
	local d = data[player]; if not d then return nil end
	return {coins = d.coins, gender = d.gender, towel = d.towel, outfit = d.outfit, jjim = d.jjim, owned = d.owned, passes = passes[player] or {}, streak = d.streak}
end
local function push(player) Notify:FireClient(player, "state", state(player)) end
local function toast(player, msg) Notify:FireClient(player, "toast", msg) end
local function bubble(player, msg) Notify:FireClient(player, "bubble", msg) end

local function addCoins(player, n, earned)
	local d = data[player]; if not d then return 0 end
	if earned and hasPass(player, "Double") then n *= 2 end
	d.coins += n; if n > 0 then d.total += n end
	local ls = player:FindFirstChild("leaderstats"); if ls then ls["냥전"].Value = d.coins end
	push(player); return n
end

-- ===== appearance =====
local function findItem(list, key) for _, it in ipairs(list) do if it.key == key then return it end end end
local function weldTo(part, target) part.Anchored = false; part.CanCollide = false; part.Massless = true; part.CanQuery = false
	local w = Instance.new("WeldConstraint"); w.Part0 = target; w.Part1 = part; w.Parent = part end
local function makeTowel(char, color)
	local old = char:FindFirstChild("Yangmeori"); if old then old:Destroy() end
	if not color then return end
	local head = char:FindFirstChild("Head"); if not head then return end
	for _, a in ipairs(char:GetChildren()) do
		if a:IsA("Accessory") and (a.AccessoryType == Enum.AccessoryType.Hat or a.AccessoryType == Enum.AccessoryType.Hair) then a:Destroy() end
	end
	local hs = head.Size; local m = Instance.new("Model"); m.Name = "Yangmeori"
	local function part(size, cf, col)
		local p = Instance.new("Part"); p.Size = size; p.Color = col; p.Material = Enum.Material.Fabric; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = head.CFrame * cf; weldTo(p, head); p.Parent = m; return p end
	local edge = color:Lerp(Color3.new(0,0,0), 0.18)
	part(Vector3.new(hs.X*1.18, hs.Y*0.42, hs.Z*1.16), CFrame.new(0, hs.Y*0.42, 0), color)
	part(Vector3.new(hs.X*0.8, hs.Y*0.12, hs.Z*0.8), CFrame.new(0, hs.Y*0.66, 0.05), color:Lerp(Color3.new(1,1,1), 0.3))
	for _, sx in ipairs({-1, 1}) do
		local r = part(Vector3.new(hs.Z*1.02, hs.Y*0.5, hs.Y*0.5), CFrame.new(sx*hs.X*0.6, hs.Y*0.36, 0) * CFrame.Angles(0, math.rad(90), 0), color)
		r.Shape = Enum.PartType.Cylinder
		local cap = part(Vector3.new(0.05, hs.Y*0.3, hs.Y*0.3), CFrame.new(sx*hs.X*0.6, hs.Y*0.36, hs.Z*0.52) * CFrame.Angles(0, math.rad(90), 0), edge)
		cap.Shape = Enum.PartType.Cylinder
	end
	m.Parent = char
end
local function applyJjim(char, color, on)
	local old = char:FindFirstChild("JjimLogo", true); if old then old:Destroy() end
	if not on then return end
	for _, c in ipairs(char:GetChildren()) do if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") then c:Destroy() end end
	for _, n in ipairs({"UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","Torso"}) do
		local p = char:FindFirstChild(n); if p then p.Color = n:find("Leg") and color:Lerp(Color3.new(0,0,0), 0.12) or color end
	end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if torso then
		local g = Instance.new("SurfaceGui"); g.Name = "JjimLogo"; g.Face = Enum.NormalId.Front; g.LightInfluence = 0; g.CanvasSize = Vector2.new(200, 160)
		local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 0.55); t.Position = UDim2.fromScale(0, 0.35); t.Text = "냥찜"; t.TextScaled = true; t.Font = Enum.Font.GothamBlack; t.TextColor3 = Color3.new(1,1,1); t.Parent = g
		g.Parent = torso
	end
end
local function applyLook(player)
	local char = player.Character; local d = data[player]; if not char or not d then return end
	local towel = findItem(C.Towels, d.towel)
	makeTowel(char, towel and towel.color or nil)
	local o = findItem(C.Outfits, d.outfit) or C.Outfits[1]
	applyJjim(char, o.color, d.jjim)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayName = player.DisplayName
		hum.NameDisplayDistance = 60
	end
	char:SetAttribute("VIP", hasPass(player, "VIP"))
end

-- ===== NPCs =====
local npcFolder = Instance.new("Folder"); npcFolder.Name = "NPCs"; npcFolder.Parent = workspace
local SKINS = {Color3.fromRGB(255,227,207), Color3.fromRGB(247,203,168), Color3.fromRGB(232,176,138), Color3.fromRGB(201,139,98), Color3.fromRGB(141,91,62)}
local function spawnNPC(spot)
	local id = spot:GetAttribute("NPC"); local def = C.NPCs[id]; if not def then return end
	local desc = Instance.new("HumanoidDescription")
	local skin = def.random and SKINS[math.random(#SKINS)] or def.skin
	desc.HeadColor = skin; desc.LeftArmColor = skin; desc.RightArmColor = skin; desc.LeftLegColor = skin; desc.RightLegColor = skin; desc.TorsoColor = skin
	local ok, rig = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not ok or not rig then warn("NPC spawn failed", id, rig) return end
	rig.Name = id
	local hrp = rig:WaitForChild("HumanoidRootPart"); hrp.Anchored = true
	rig:PivotTo(spot.CFrame * CFrame.new(0, 0, 0))
	local hum = rig:FindFirstChildOfClass("Humanoid")
	local title = def.title
	if def.random then title = (spot:GetAttribute("Gender") == "m") and "손님" or "손님" end
	hum.DisplayName = title; hum.NameDisplayDistance = 40; hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	local outfit = def.outfit or C.Outfits[math.random(#C.Outfits)].color
	applyJjim(rig, outfit, true)
	local towelColor = def.towel
	if def.random and math.random() < 0.7 then towelColor = C.Towels[math.random(2, 6)].color end
	if towelColor then makeTowel(rig, towelColor) end
	if id == "soaker" then hum.Sit = true end
	local pp = Instance.new("ProximityPrompt"); pp.Name = "TalkPrompt"; pp.ActionText = "대화하기"; pp.ObjectText = title; pp.HoldDuration = 0; pp.MaxActivationDistance = 12; pp.RequiresLineOfSight = false; pp.Parent = hrp
	rig:SetAttribute("NPC", id); rig.Parent = npcFolder
	pp.Triggered:Connect(function(player) Notify:FireClient(player, "talk", id, title) end)
end
task.spawn(function()
	for _, spot in ipairs(Spa:GetDescendants()) do
		if spot.Name == "NPCSpot" then task.spawn(spawnNPC, spot) end
	end
end)

-- ===== players =====
local function dailyBonus(player)
	local d = data[player]; local today = math.floor(os.time() / 86400)
	if d.lastDay == today then return end
	if d.lastDay == today - 1 then d.streak = math.min(d.streak + 1, #C.DailyBonus) else d.streak = 1 end
	d.lastDay = today
	local amount = C.DailyBonus[d.streak]
	addCoins(player, amount, false)
	Notify:FireClient(player, "daily", d.streak, amount)
end

Players.PlayerAdded:Connect(function(player)
	data[player] = load(player)
	passes[player] = {}
	for _, p in ipairs(C.GamePasses) do
		if p.id > 0 then
			local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, p.id) end)
			passes[player][p.key] = ok and owns or false
		end
	end
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"
	local v = Instance.new("IntValue"); v.Name = "냥전"; v.Value = data[player].coins; v.Parent = ls; ls.Parent = player
	player.CharacterAppearanceLoaded:Connect(function() task.wait(0.2); applyLook(player) end)
	if player.Character then applyLook(player) end
	task.delay(2, function() if data[player] then push(player); dailyBonus(player); if data[player].gender == "" then Notify:FireClient(player, "firsttime") end end end)
end)
Players.PlayerRemoving:Connect(function(player) save(player); data[player] = nil; passes[player] = nil; lastAction[player] = nil; saunaOpen[player] = nil end)
game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do save(p) end end)
task.spawn(function() while true do task.wait(120) for _, p in ipairs(Players:GetPlayers()) do save(p) end end end)
GetState.OnServerInvoke = function(player) return state(player) end

-- ===== elevator =====
local function floorModel(i) return Spa:FindFirstChild("Floor" .. i) end
for _, d in ipairs(Spa:GetDescendants()) do
	if d:IsA("ProximityPrompt") and d.Name == "ElevatorPrompt" then
		d.Triggered:Connect(function(player) Notify:FireClient(player, "elevator", d.Parent:GetAttribute("Floor")) end)
	end
end

-- ===== sauna prompts =====
for _, d in ipairs(Spa:GetDescendants()) do
	if d:IsA("ProximityPrompt") and d.Name == "SaunaPrompt" then
		d.Triggered:Connect(function(player)
			local kind = d.Parent:GetAttribute("Sauna"); saunaOpen[player] = {kind = kind, last = os.clock()}
			Notify:FireClient(player, "sauna", kind)
		end)
	end
end

-- ===== gates (men / women) =====
for _, g in ipairs(Spa:GetDescendants()) do
	if g.Name == "Gate" and g:IsA("BasePart") then
		local cooldown = {}
		g.Touched:Connect(function(hit)
			local char = hit.Parent; local player = Players:GetPlayerFromCharacter(char); if not player then return end
			local d = data[player]; if not d then return end
			local need = g:GetAttribute("Gender")
			if d.gender ~= need then
				local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame = CFrame.new(g.Position.X, g.Position.Y, g.Position.Z - 10) end
				if not cooldown[player] or os.clock() - cooldown[player] > 2 then
					cooldown[player] = os.clock()
					toast(player, d.gender == "" and "꾸미기에서 성별을 먼저 골라 주세요." or (need == "m" and "남탕은 남자 손님만 들어갈 수 있어요." or "여탕은 여자 손님만 들어갈 수 있어요."))
				end
			end
		end)
	end
end

-- ===== coins (playroom) =====
for _, c in ipairs(Spa:GetDescendants()) do
	if c.Name == "Coin" and c:IsA("BasePart") then
		local base = c.CFrame; local alive = true
		task.spawn(function() local t = math.random() * 6 while c.Parent do t += 0.05; if alive then c.CFrame = base * CFrame.new(0, math.sin(t*2)*0.4, 0) * CFrame.Angles(0, 0, 0) * CFrame.fromAxisAngle(Vector3.yAxis, t) end task.wait(0.05) end end)
		c.Touched:Connect(function(hit)
			if not alive then return end
			local player = Players:GetPlayerFromCharacter(hit.Parent); if not player then return end
			alive = false; c.Transparency = 1
			local got = addCoins(player, c:GetAttribute("CoinValue") or 1, true)
			bubble(player, "냥전 +" .. got)
			task.delay(12, function() alive = true; c.Transparency = 0 end)
		end)
	end
end

-- ===== trampoline =====
for _, t in ipairs(Spa:GetDescendants()) do
	if t:IsA("BasePart") and t:GetAttribute("Bounce") then
		t.Touched:Connect(function(hit)
			local hrp = hit.Parent and hit.Parent:FindFirstChild("HumanoidRootPart")
			if hrp and Players:GetPlayerFromCharacter(hit.Parent) then local v = hrp.AssemblyLinearVelocity; hrp.AssemblyLinearVelocity = Vector3.new(v.X, t:GetAttribute("Bounce"), v.Z) end
		end)
	end
end

-- ===== slide ride =====
local riding = {}
local function slide(player)
	if riding[player] then return end
	local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	riding[player] = true
	local b = floorModel(4):GetAttribute("Base")
	local pts = {Vector3.new(-37, b+17, 0), Vector3.new(0, b+5.5, 0), Vector3.new(16, b+3, 0)}
	hrp.Anchored = true; hum.Sit = true
	local look = CFrame.lookAt(Vector3.zero, Vector3.new(1, 0, 0))
	hrp.CFrame = CFrame.new(pts[1]) * look
	for i = 2, #pts do
		local tw = TweenService:Create(hrp, TweenInfo.new(i == 2 and 1.2 or 0.45, i == 2 and Enum.EasingStyle.Quad or Enum.EasingStyle.Sine, Enum.EasingDirection.In), {CFrame = CFrame.new(pts[i]) * look})
		tw:Play(); tw.Completed:Wait()
	end
	hrp.Anchored = false; hum.Sit = false
	local got = addCoins(player, 1, true); bubble(player, "슝~ 풍덩! 냥전 +" .. got)
	task.wait(1); riding[player] = nil
end
for _, d in ipairs(Spa:GetDescendants()) do
	if d:IsA("ProximityPrompt") and d.Name == "SlidePrompt" then d.Triggered:Connect(slide) end
end

-- ===== pools: passive income =====
local pools = {}
for _, p in ipairs(Spa:GetDescendants()) do if p:IsA("BasePart") and p:GetAttribute("Pool") then table.insert(pools, p) end end
local soak = {}
local function inside(part, pos) local lp = part.CFrame:PointToObjectSpace(pos); local h = part.Size / 2 return math.abs(lp.X) <= h.X and math.abs(lp.Z) <= h.Z and lp.Y <= h.Y + 3 and lp.Y >= -h.Y - 3 end
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local kind
			if hrp then for _, p in ipairs(pools) do if inside(p, hrp.Position) then kind = p:GetAttribute("Pool") break end end end
			local s = soak[player] or {kind = nil, t = 0}
			if kind ~= s.kind then
				if kind == "hot" then bubble(player, "따뜻해~ 녹는다") elseif kind == "cold" then bubble(player, "으아 차가워!") elseif kind == "vip" then bubble(player, "황금 온탕이다…!") end
				s = {kind = kind, t = 0}
			end
			if kind == "hot" or kind == "vip" then
				s.t += 1
				if s.t >= 4 then s.t = 0; local got = addCoins(player, kind == "vip" and 3 or 1, true); bubble(player, "뜨끈~ 냥전 +" .. got) end
			end
			soak[player] = s
		end
	end
end)

-- ===== actions from clients =====
local function rate(player, key, secs)
	lastAction[player] = lastAction[player] or {}
	local t = lastAction[player][key]; if t and os.clock() - t < secs then return false end
	lastAction[player][key] = os.clock(); return true
end
Action.OnServerEvent:Connect(function(player, kind, a, b)
	local d = data[player]; if not d then return end
	if kind == "elevator" then
		local i = tonumber(a); if not i or not floorModel(i) then return end
		if i == 5 and not hasPass(player, "VIP") then Notify:FireClient(player, "needpass", "VIP"); return end
		local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		local arrival = floorModel(i):FindFirstChild("Arrival")
		char:PivotTo(CFrame.new(arrival.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(180), 0))
	elseif kind == "sauna" then
		local s = saunaOpen[player]; if not s then return end
		local cfg = C.Sauna[s.kind]; if not cfg then return end
		local now = os.clock(); if now - s.last < 1.2 then return end; s.last = now
		local gain = 0
		if a == "perfect" then gain = cfg.prize elseif a == "near" then gain = math.ceil(cfg.prize / 2) elseif a == "early" then gain = 1 end
		local got = gain > 0 and addCoins(player, gain, true) or 0
		Notify:FireClient(player, "saunaResult", a, got)
	elseif kind == "saunaClose" then
		saunaOpen[player] = nil
	elseif kind == "gender" then
		if a == "m" or a == "f" then d.gender = a; push(player) end
	elseif kind == "towel" or kind == "outfit" then
		local it = findItem(kind == "towel" and C.Towels or C.Outfits, a); if not it then return end
		local ownedKey = kind .. ":" .. it.key
		if it.pass and not hasPass(player, it.pass) then Notify:FireClient(player, "needpass", it.pass); return end
		if (it.price or 0) > 0 and not d.owned[ownedKey] then
			if d.coins < it.price then toast(player, "냥전이 " .. (it.price - d.coins) .. "개 부족해요."); return end
			addCoins(player, -it.price, false); d.owned[ownedKey] = true; toast(player, it.name .. " 구매 완료!")
		end
		d[kind] = it.key; if kind == "outfit" then d.jjim = true end
		applyLook(player); push(player)
	elseif kind == "jjim" then
		d.jjim = a == true; if not d.jjim then player:LoadCharacter() else applyLook(player) end; push(player)
	elseif kind == "jjimkit" then
		d.jjim = true; if d.towel == "none" then d.towel = "pink" end; applyLook(player); push(player)
	elseif kind == "food" then
		if not rate(player, "food", 1) then return end
		local f; for _, x in ipairs(C.Foods) do if x.id == a then f = x end end; if not f then return end
		if d.coins < f.price then toast(player, "냥전이 부족해요. 사우나에서 땀 빼고 오세요!"); return end
		addCoins(player, -f.price, false); bubble(player, f.say)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = f.speed; task.delay(f.secs, function() if hum.Parent then hum.WalkSpeed = 16 end end) end
		toast(player, f.name .. " 냠냠! " .. f.secs .. "초 동안 빨라져요.")
	elseif kind == "scrub" then
		if d.coins < 30 then toast(player, "때밀이는 냥전 30개예요."); return end
		addCoins(player, -30, false)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then local sp = Instance.new("Sparkles"); sp.SparkleColor = Color3.fromRGB(255,246,176); sp.Parent = hrp; task.delay(120, function() sp:Destroy() end) end
		bubble(player, "반짝반짝!")
	end
end)

-- ===== monetization =====
local productById = {}
for _, p in ipairs(C.Products) do if p.id > 0 then productById[p.id] = p end end
MarketplaceService.ProcessReceipt = function(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player or not data[player] then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local d = data[player]
	if d.receipts[info.PurchaseId] then return Enum.ProductPurchaseDecision.PurchaseGranted end
	local p = productById[info.ProductId]; if not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
	addCoins(player, p.coins, false)
	d.receipts[info.PurchaseId] = true
	local n = 0 for k in pairs(d.receipts) do n += 1 end
	if n > 50 then d.receipts = {[info.PurchaseId] = true} end
	local ok = pcall(function() store:SetAsync("u" .. player.UserId, (function() local o = {} for k, v in pairs(d) do if k:sub(1,1) ~= "_" then o[k] = v end end return o end)()) end)
	if not ok then return Enum.ProductPurchaseDecision.NotProcessedYet end
	toast(player, p.name .. " 구매 완료! 냥전 +" .. p.coins)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, bought)
	if not bought then return end
	for _, p in ipairs(C.GamePasses) do if p.id == id then passes[player][p.key] = true; toast(player, p.name .. " 활성화!") end end
	applyLook(player); push(player)
end)
print("[Nyangjjim] server ready")
