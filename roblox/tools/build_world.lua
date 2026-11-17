-- Nyangjjim Spaland world builder.
-- Paste into the Roblox Studio command bar (or run via the Studio MCP `execute_luau` tool, Edit datamodel).
-- It deletes the default Baseplate/SpawnLocation and any previous `workspace.Spa`, then builds
-- 5 floors (1F lobby, 2F baths, 3F jjimjil plaza, 4F playroom, 5F VIP lounge) with elevators,
-- NPC spots, sauna prompts, pools, coins, slide and trampoline that SpaServer wires up at runtime.

local V3, C3 = Vector3.new, Color3.fromRGB
local function P(parent, name, size, pos, color, mat, props)
	local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.Size = size; p.Position = pos; p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if props then for k, v in pairs(props) do p[k] = v end end
	p.Parent = parent; return p
end
local function sign(part, face, text, bg, fg)
	-- Layout below was written thinking "+Z is front"; Roblox's Front face is -Z, so swap Front/Back.
	if face == Enum.NormalId.Front then face = Enum.NormalId.Back elseif face == Enum.NormalId.Back then face = Enum.NormalId.Front end
	local g = Instance.new("SurfaceGui"); g.Face = face; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 30; g.LightInfluence = 0; g.Parent = part
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1,1); t.BackgroundColor3 = bg; t.TextColor3 = fg; t.Text = text; t.TextScaled = true; t.Font = Enum.Font.GothamBlack; t.Parent = g
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0.12,0); pad.PaddingBottom = UDim.new(0.12,0); pad.PaddingLeft = UDim.new(0.05,0); pad.PaddingRight = UDim.new(0.05,0); pad.Parent = t
	return g
end
local function npc(parent, pos, yawDeg, id, gender)
	local s = P(parent, "NPCSpot", V3(2,1,2), pos, C3(255,255,255), nil, {Transparency=1, CanCollide=false, CanQuery=false, CanTouch=false})
	s.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(yawDeg), 0); s:SetAttribute("NPC", id); s:SetAttribute("Gender", gender)
end
local function prompt(part, name, action, object)
	local pp = Instance.new("ProximityPrompt"); pp.Name = name; pp.ActionText = action; pp.ObjectText = object or ""; pp.HoldDuration = 0; pp.MaxActivationDistance = 12; pp.RequiresLineOfSight = false; pp.Parent = part; return pp
end

-- ===== shell: 5 floors, walls, lights, elevator =====
for _, n in ipairs({"Baseplate","SpawnLocation","Spa"}) do local o = workspace:FindFirstChild(n); if o then o:Destroy() end end
local L = game.Lighting
L.ClockTime = 13; L.Brightness = 2; L.Ambient = C3(160,160,165); L.OutdoorAmbient = C3(170,170,175); L.GlobalShadows = true

local Spa = Instance.new("Folder"); Spa.Name = "Spa"; Spa.Parent = workspace
local FLOORS = {
	{label="1F", name="로비", base=0, floor=C3(243,239,230), fmat=Enum.Material.Marble, wall=C3(251,247,240), trim=C3(201,154,102)},
	{label="2F", name="목욕탕", base=60, floor=C3(238,244,247), fmat=Enum.Material.Slate, wall=C3(246,250,252), trim=C3(159,195,216)},
	{label="3F", name="찜질광장", base=120, floor=C3(217,160,102), fmat=Enum.Material.WoodPlanks, wall=C3(255,244,228), trim=C3(185,123,69)},
	{label="4F", name="놀이방", base=180, floor=C3(255,215,226), fmat=Enum.Material.SmoothPlastic, wall=C3(253,246,255), trim=C3(183,155,232)},
	{label="5F", name="VIP 라운지", base=240, floor=C3(40,36,52), fmat=Enum.Material.Marble, wall=C3(58,52,74), trim=C3(242,194,48)},
}
for i, F in ipairs(FLOORS) do
	local f = Instance.new("Model"); f.Name = "Floor" .. i; f:SetAttribute("Label", F.label); f:SetAttribute("FloorName", F.name); f:SetAttribute("Base", F.base)
	local b = F.base
	P(f, "Floor", V3(140,2,110), V3(0,b-1,0), F.floor, F.fmat)
	P(f, "Ceiling", V3(140,1,110), V3(0,b+26.5,0), C3(250,250,250))
	P(f, "WallFront", V3(140,26,2), V3(0,b+13,56), F.wall)
	P(f, "WallLeft", V3(2,26,110), V3(-71,b+13,0), F.wall)
	P(f, "WallRight", V3(2,26,110), V3(71,b+13,0), F.wall)
	P(f, "WallBackL", V3(61,26,2), V3(-39.5,b+13,-56), F.wall)
	P(f, "WallBackR", V3(61,26,2), V3(39.5,b+13,-56), F.wall)
	local lintel = P(f, "Lintel", V3(18,10,2), V3(0,b+21,-56), C3(125,136,150), Enum.Material.Metal)
	sign(lintel, Enum.NormalId.Front, F.label .. "  " .. F.name, C3(29,39,49), C3(255,182,72))
	for _, w in ipairs({{V3(140,6,0.4),V3(0,b+3,54.8)},{V3(0.4,6,110),V3(-69.8,b+3,0)},{V3(0.4,6,110),V3(69.8,b+3,0)}}) do P(f,"Trim",w[1],w[2],F.trim,Enum.Material.Wood,{CanCollide=false}) end
	for x = -45, 45, 45 do for z = -30, 30, 30 do
		local lp = P(f, "Lamp", V3(10,0.4,10), V3(x,b+25.8,z), C3(255,250,235), Enum.Material.Neon, {CanCollide=false})
		local pl = Instance.new("PointLight"); pl.Range = 40; pl.Brightness = 1.4; pl.Color = C3(255,244,225); pl.Parent = lp
	end end
	local el = Instance.new("Model"); el.Name = "Elevator"; el.Parent = f
	P(el, "CabFloor", V3(18,2,14), V3(0,b-1,-64), C3(174,185,198), Enum.Material.DiamondPlate)
	P(el, "CabBack", V3(18,26,2), V3(0,b+13,-72), C3(201,210,220), Enum.Material.Metal)
	P(el, "CabL", V3(2,26,14), V3(-10,b+13,-64), C3(142,154,168), Enum.Material.Metal)
	P(el, "CabR", V3(2,26,14), V3(10,b+13,-64), C3(142,154,168), Enum.Material.Metal)
	P(el, "CabTop", V3(18,1,14), V3(0,b+16.5,-64), C3(220,226,232), Enum.Material.Metal)
	P(el, "DoorL", V3(3,16,0.6), V3(-7.5,b+8,-55), C3(184,195,207), Enum.Material.Metal, {CanCollide=false})
	P(el, "DoorR", V3(3,16,0.6), V3(7.5,b+8,-55), C3(184,195,207), Enum.Material.Metal, {CanCollide=false})
	local panel = P(el, "ElevatorPanel", V3(6,5,0.6), V3(0,b+6,-70.6), C3(61,139,253), Enum.Material.Neon)
	sign(panel, Enum.NormalId.Front, "엘리베이터", C3(61,139,253), C3(255,255,255))
	local pp = Instance.new("ProximityPrompt"); pp.Name = "ElevatorPrompt"; pp.ActionText = "층 선택하기"; pp.ObjectText = "엘리베이터"; pp.HoldDuration = 0; pp.MaxActivationDistance = 14; pp.RequiresLineOfSight = false; pp.Parent = panel
	panel:SetAttribute("Floor", i)
	P(f, "Arrival", V3(4,1,4), V3(0,b+3,-48), C3(255,255,255), nil, {Transparency=1, CanCollide=false, CanQuery=false, CanTouch=false})
	local props = Instance.new("Folder"); props.Name = "Props"; props.Parent = f
	f.Parent = Spa
	task.wait()
end

-- ===== 1F LOBBY =====
local p1 = Spa.Floor1.Props; local b = 0
local sp = Instance.new("SpawnLocation"); sp.Name = "LobbySpawn"; sp.Anchored = true; sp.Size = V3(12,1,12); sp.Position = V3(0,0.5,30); sp.Color = C3(61,139,253); sp.Material = Enum.Material.SmoothPlastic; sp.Duration = 0; sp.Parent = p1
local sg = P(p1, "MainSign", V3(44,7,0.6), V3(-36,b+19,-54.6), C3(61,139,253)); sign(sg, Enum.NormalId.Front, "냥찜 스파랜드", C3(61,139,253), C3(255,255,255))
local sg2 = P(p1, "SubSign", V3(44,7,0.6), V3(36,b+19,-54.6), C3(242,104,154)); sign(sg2, Enum.NormalId.Front, "♨ 24시 찜질 · 사우나", C3(242,104,154), C3(255,255,255))
local dir = P(p1, "Directory", V3(14,10,0.6), V3(22,b+7,-54.6), C3(255,255,255)); sign(dir, Enum.NormalId.Front, "5F VIP 라운지\n4F 놀이방\n3F 찜질광장 · 매점\n2F 목욕탕\n1F 로비", C3(255,255,255), C3(34,48,58))
P(p1, "Counter", V3(28,6,5), V3(32,b+3,8), C3(201,142,85), Enum.Material.Wood)
P(p1, "CounterTop", V3(30,0.6,6), V3(32,b+6.3,8), C3(234,210,176), Enum.Material.Marble)
local cs = P(p1, "CounterSign", V3(10,2.4,0.3), V3(32,b+3.5,10.6), C3(34,48,58)); sign(cs, Enum.NormalId.Front, "카운터", C3(34,48,58), C3(255,255,255))
npc(p1, V3(32,b+3,3), 0, "counter", "f")
P(p1, "Lockers", V3(3,18,46), V3(-68.5,b+9,0), C3(127,168,201), Enum.Material.Metal)
local lks = P(p1, "LockerSign", V3(0.3,3,14), V3(-66.8,b+20,0), C3(34,48,58)); sign(lks, Enum.NormalId.Right, "신발장", C3(34,48,58), C3(255,255,255))
for z = -20, 20, 4 do for y = 2, 16, 4 do P(p1, "LockerDoor", V3(0.3,3.4,3.4), V3(-66.9,b+y,z), C3(98,138,170), Enum.Material.Metal, {CanCollide=false}) end end
for _, x in ipairs({-36, -12}) do P(p1, "Bench", V3(18,2.4,5), V3(x,b+1.2,28), C3(201,142,85), Enum.Material.Wood) end
for _, c in ipairs({{-64,50},{64,50},{64,-50},{-64,-48}}) do
	P(p1, "Pot", V3(5,4,5), V3(c[1],b+2,c[2]), C3(232,225,211)); P(p1, "Leaf", V3(6,6,6), V3(c[1],b+7,c[2]), C3(95,179,107), Enum.Material.Grass); P(p1, "Leaf", V3(4,4,4), V3(c[1],b+11.5,c[2]), C3(127,204,134), Enum.Material.Grass)
end
P(p1, "EntranceGlass", V3(30,18,0.6), V3(0,b+9,54.6), C3(191,227,245), Enum.Material.Glass, {Transparency=0.4})
npc(p1, V3(-20,b+3,14), 30, "visitor", "m"); npc(p1, V3(-40,b+3,40), -60, "visitor", "f")
task.wait()

-- ===== 2F BATH (men / women separated) =====
local p2 = Spa.Floor2.Props; b = 60
local wc = C3(230,238,243)
for _, seg in ipairs({{28,-56},{60,0},{28,56}}) do P(p2, "Partition", V3(seg[1],26,2), V3(seg[2],b+13,-15), wc) end
P(p2, "Lintel", V3(12,12,2), V3(-36,b+20,-15), wc); P(p2, "Lintel", V3(12,12,2), V3(36,b+20,-15), wc)
P(p2, "Divider", V3(2,26,70), V3(0,b+13,20), wc)
for _, d in ipairs({{-36,"m",C3(61,139,253),"男  남탕"},{36,"f",C3(242,104,154),"女  여탕"}}) do
	local cur = P(p2, "Curtain", V3(12,6,0.3), V3(d[1],b+11,-15), d[3], Enum.Material.Fabric, {CanCollide=false})
	sign(cur, Enum.NormalId.Back, d[4], d[3], C3(255,255,255)); sign(cur, Enum.NormalId.Front, d[4], d[3], C3(255,255,255))
	local gate = P(p2, "Gate", V3(12,14,3), V3(d[1],b+7,-16.5), C3(255,255,255), nil, {Transparency=1, CanCollide=false})
	gate:SetAttribute("Gender", d[2])
end
npc(p2, V3(0,b+3,-32), 180, "guide", "m")
for _, s in ipairs({-1, 1}) do
	local men = s < 0
	P(p2, "BathTile", V3(68,0.2,68), V3(s*35,b+0.1,21), men and C3(232,242,252) or C3(252,236,242), Enum.Material.Slate)
	local hx = s*44
	for _, r in ipairs({{V3(30,1.6,1.5),V3(hx,b+0.8,14)},{V3(30,1.6,1.5),V3(hx,b+0.8,44)},{V3(1.5,1.6,30),V3(hx-15,b+0.8,29)},{V3(1.5,1.6,30),V3(hx+15,b+0.8,29)}}) do P(p2,"Rim",r[1],r[2],C3(221,230,236),Enum.Material.Marble,{CanCollide=false}) end
	local hot = P(p2, "HotPool", V3(28,3,28), V3(hx,b+1.5,29), C3(94,196,232), Enum.Material.Glass, {Transparency=0.45, CanCollide=false}); hot:SetAttribute("Pool","hot")
	local hs = P(p2, "Sign", V3(14,3,0.3), V3(hx,b+12,54.6), C3(233,87,63)); sign(hs, Enum.NormalId.Back, "온탕 41°C", C3(233,87,63), C3(255,255,255))
	local smoke = Instance.new("ParticleEmitter"); smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"; smoke.Rate = 6; smoke.Lifetime = NumberRange.new(3,5); smoke.Speed = NumberRange.new(1,3); smoke.Transparency = NumberSequence.new(0.7,1); smoke.Size = NumberSequence.new(3,8); smoke.Parent = hot
	local cx = s*16
	local cold = P(p2, "ColdPool", V3(14,3,14), V3(cx,b+1.5,44), C3(169,236,245), Enum.Material.Glass, {Transparency=0.4, CanCollide=false}); cold:SetAttribute("Pool","cold")
	for _, r in ipairs({{V3(16,1.6,1),V3(cx,b+0.8,36.5)},{V3(1,1.6,15),V3(cx-7.5,b+0.8,44)},{V3(1,1.6,15),V3(cx+7.5,b+0.8,44)}}) do P(p2,"Rim",r[1],r[2],C3(221,230,236),Enum.Material.Marble,{CanCollide=false}) end
	local cs2 = P(p2, "Sign", V3(12,3,0.3), V3(cx,b+12,54.6), C3(61,139,253)); sign(cs2, Enum.NormalId.Back, "냉탕 18°C", C3(61,139,253), C3(255,255,255))
	local sx = s*54
	P(p2, "SaunaBooth", V3(22,16,18), V3(sx,b+8,-3), C3(201,142,85), Enum.Material.WoodPlanks)
	local sd = P(p2, "SaunaDoor", V3(7,11,0.6), V3(sx,b+5.5,6.3), C3(138,90,48), Enum.Material.Wood)
	P(p2, "SaunaWindow", V3(4,3,0.2), V3(sx,b+8,6.7), C3(255,180,106), Enum.Material.Neon, {CanCollide=false})
	local ss = P(p2, "Sign", V3(14,2.6,0.3), V3(sx,b+13.5,6.2), C3(34,48,58)); sign(ss, Enum.NormalId.Front, "건식 사우나 85°C", C3(34,48,58), C3(255,255,255))
	prompt(sd, "SaunaPrompt", "사우나 들어가기", "건식 사우나"); sd:SetAttribute("Sauna", "dry")
	for z = -8, 20, 7 do P(p2, "Stool", V3(2.4,2,2.4), V3(s*6,b+1,z), C3(245,195,52)); P(p2, "Pipe", V3(0.6,10,0.6), V3(s*1.8,b+9,z), C3(174,185,198), Enum.Material.Metal, {CanCollide=false}); P(p2, "Head", V3(1.8,0.6,1.8), V3(s*2.8,b+14,z), C3(174,185,198), Enum.Material.Metal, {CanCollide=false}) end
	P(p2, "ScrubBed", V3(10,3,4.5), V3(s*22,b+1.5,-6), C3(125,196,184))
	npc(p2, V3(s*22,b+3,-1), men and 160 or -160, "scrub", men and "m" or "f")
	npc(p2, V3(hx+s*4,b+0.5,26), men and 120 or -120, "soaker", men and "m" or "f")
end
task.wait()

-- ===== 3F JJIMJIL PLAZA =====
local p3 = Spa.Floor3.Props; b = 120
local brick = C3(169,101,61)
P(p3, "Kiln1", V3(28,6,24), V3(-44,b+3,-20), brick, Enum.Material.Brick)
P(p3, "Kiln2", V3(22,5,19), V3(-44,b+8.5,-20), brick, Enum.Material.Brick)
P(p3, "Kiln3", V3(16,4,13), V3(-44,b+13,-20), brick, Enum.Material.Brick)
P(p3, "Kiln4", V3(10,3,7), V3(-44,b+16.5,-20), brick, Enum.Material.Brick)
local kd = P(p3, "KilnDoor", V3(7,5,0.6), V3(-44,b+2.6,-7.8), C3(255,138,61), Enum.Material.Neon)
local kl = Instance.new("PointLight"); kl.Color = C3(255,140,60); kl.Range = 18; kl.Brightness = 2; kl.Parent = kd
local ks = P(p3, "KilnSign", V3(14,2.6,0.3), V3(-44,b+7.4,-7.7), C3(194,65,12)); sign(ks, Enum.NormalId.Front, "불가마 98°C", C3(194,65,12), C3(255,255,255))
prompt(kd, "SaunaPrompt", "불가마 들어가기", "불가마"); kd:SetAttribute("Sauna", "kiln")
P(p3, "ShopCounter", V3(5,6,28), V3(48,b+3,-16), C3(224,138,79), Enum.Material.Wood)
P(p3, "ShopTop", V3(6,0.6,30), V3(48,b+6.3,-16), C3(255,227,194), Enum.Material.Marble)
local shelfColors = {C3(247,214,74),C3(143,211,232),C3(242,104,154),C3(247,235,208),C3(201,139,89),C3(123,211,137)}
P(p3, "Shelf", V3(4,18,36), V3(67,b+9,-16), C3(247,235,221), Enum.Material.Wood)
for row = 0, 3 do for i = 0, 7 do P(p3, "Goods", V3(1.6,2.4,2.6), V3(64.8,b+3+row*4,-30+i*4), shelfColors[(row+i)%6+1], nil, {CanCollide=false}) end end
local shs = P(p3, "ShopSign", V3(0.3,5,22), V3(64.7,b+21,-16), C3(224,138,79)); sign(shs, Enum.NormalId.Left, "매점  식혜 · 계란 · 바나나우유 · 라면 · 빙수", C3(224,138,79), C3(255,255,255))
npc(p3, V3(56,b+3,-16), -90, "shop", "f")
P(p3, "SleepFloor", V3(40,0.2,30), V3(-50,b+0.1,40), C3(46,57,86))
P(p3, "SleepWallA", V3(40,14,2), V3(-50,b+7,25), C3(58,69,102))
P(p3, "SleepWallB", V3(2,14,18), V3(-31,b+7,34), C3(58,69,102))
local sls = P(p3, "SleepSign", V3(14,2.6,0.3), V3(-50,b+11,23.9), C3(58,69,102)); sign(sls, Enum.NormalId.Back, "수면실 · 쉿!", C3(58,69,102), C3(251,226,154))
local matColors = {C3(247,198,208),C3(191,224,242),C3(251,226,154),C3(191,235,221)}
local k = 0
for _, x in ipairs({-62,-50,-38}) do for _, z in ipairs({33,46}) do
	k += 1
	P(p3, "Mat", V3(8,0.4,10), V3(x,b+0.3,z), matColors[k%4+1], Enum.Material.Fabric)
	local seat = Instance.new("Seat"); seat.Name = "SleepMat"; seat.Anchored = true; seat.Size = V3(3,0.4,3); seat.Transparency = 1; seat.CFrame = CFrame.new(x,b+1.4,z) * CFrame.Angles(math.rad(-90),0,0); seat.Parent = p3
	P(p3, "Pillow", V3(4,1,2.4), V3(x,b+1,z-4), C3(255,255,255), Enum.Material.Fabric, {CanCollide=false})
end end
for _, m in ipairs({{-12,30,C3(243,154,74)},{0,30,C3(142,197,240)},{12,30,C3(245,155,181)},{-12,44,C3(247,211,94)},{0,44,C3(143,220,194)},{12,44,C3(183,155,232)}}) do P(p3, "PlazaMat", V3(10,0.3,12), V3(m[1],b+0.15,m[2]), m[3], Enum.Material.Fabric) end
local tv = P(p3, "TV", V3(20,11,1), V3(30,b+9,54), C3(34,48,58)); sign(tv, Enum.NormalId.Back, "냥냥 드라마\n고양이 집사의 하루 · 제8화", C3(76,127,191), C3(255,255,255))
npc(p3, V3(0,b+3,0), 0, "staff3", "m")
npc(p3, V3(0,b+3,38), 0, "visitor", "f"); npc(p3, V3(20,b+3,-30), 45, "visitor", "m")
task.wait()

-- ===== 4F PLAYROOM =====
local p4 = Spa.Floor4.Props; b = 180
local tileC = {C3(255,215,226),C3(215,238,255),C3(255,241,194),C3(217,245,229)}
local tiles = Instance.new("Model"); tiles.Name = "Tiles"
for ix = 0, 13 do for iz = 0, 10 do P(tiles, "Tile", V3(10,0.2,10), V3(-65+ix*10,b+0.1,-50+iz*10), tileC[(ix+iz)%4+1]) end end
tiles.Parent = p4
P(p4, "Tower", V3(16,14,16), V3(-44,b+7,0), C3(247,211,94))
for _, c in ipairs({{-51,-7},{-37,-7},{-51,7},{-37,7}}) do P(p4, "Post", V3(1,10,1), V3(c[1],b+19,c[2]), C3(229,83,75)) end
local roof = Instance.new("WedgePart"); roof.Anchored = true; roof.Size = V3(18,4,9); roof.CFrame = CFrame.new(-44,b+26,-4.5) * CFrame.Angles(0,math.rad(180),0); roof.Color = C3(229,83,75); roof.Parent = p4
local roof2 = roof:Clone(); roof2.CFrame = CFrame.new(-44,b+26,4.5); roof2.Parent = p4
local truss = Instance.new("TrussPart"); truss.Anchored = true; truss.Size = V3(2,14,2); truss.Position = V3(-44,b+7,9); truss.Color = C3(142,108,207); truss.Parent = p4
local a = math.atan2(12, 38); local len = math.sqrt(38*38+12*12)
local mid = CFrame.new(-17, b+8.4, 0) * CFrame.Angles(0,0,-a)
local ramp = P(p4, "SlideRamp", V3(len,0.8,7), Vector3.zero, C3(61,139,253), nil, {CanCollide=false}); ramp.CFrame = mid
local r1 = P(p4, "SlideRail", V3(len,2,0.6), Vector3.zero, C3(36,99,201), nil, {CanCollide=false}); r1.CFrame = mid * CFrame.new(0,1,3.6)
local r2 = P(p4, "SlideRail", V3(len,2,0.6), Vector3.zero, C3(36,99,201), nil, {CanCollide=false}); r2.CFrame = mid * CFrame.new(0,1,-3.6)
local top = P(p4, "SlideStart", V3(4,1,6), V3(-38,b+14.5,0), C3(255,255,255), nil, {Transparency=1, CanCollide=false})
prompt(top, "SlidePrompt", "슝~ 타기", "미끄럼틀")
local ss4 = P(p4, "SlideSign", V3(12,2.6,0.3), V3(-44,b+16,8.2), C3(142,108,207)); sign(ss4, Enum.NormalId.Front, "미끄럼틀", C3(142,108,207), C3(255,255,255))
local pit = C3(242,104,154)
P(p4, "PitWall", V3(34,3,1.5), V3(20,b+1.5,-13), pit); P(p4, "PitWall", V3(34,3,1.5), V3(20,b+1.5,13), pit); P(p4, "PitWall", V3(1.5,3,26), V3(37,b+1.5,0), pit); P(p4, "PitWall", V3(1.5,1.2,26), V3(3,b+0.6,0), pit)
local balls = Instance.new("Model"); balls.Name = "Balls"
local bc = {C3(242,104,154),C3(61,139,253),C3(245,195,52),C3(47,191,155),C3(183,155,232),C3(229,83,75)}
for i = 1, 180 do
	local ball = Instance.new("Part"); ball.Shape = Enum.PartType.Ball; ball.Size = V3(1.8,1.8,1.8); ball.Color = bc[i%6+1]; ball.Material = Enum.Material.SmoothPlastic
	ball.Position = V3(math.random(5,35), b + 1 + (i%3)*1.8, math.random(-11,11)); ball.Anchored = false; ball.Parent = balls
end
balls.Parent = p4
local ps = P(p4, "PitSign", V3(12,2.6,0.3), V3(20,b+5,-13.9), pit); sign(ps, Enum.NormalId.Front, "볼풀", pit, C3(255,255,255))
local tr = P(p4, "Trampoline", V3(1.6,12,12), V3(40,b+0.8,-34), C3(61,139,253), nil, {Shape=Enum.PartType.Cylinder}); tr.CFrame = CFrame.new(40,b+0.8,-34) * CFrame.Angles(0,0,math.rad(90)); tr:SetAttribute("Bounce", 120)
local trs = P(p4, "TrampSign", V3(14,2.6,0.3), V3(40,b+10,-54.6), C3(61,139,253)); sign(trs, Enum.NormalId.Front, "트램펄린", C3(61,139,253), C3(255,255,255))
for _, c in ipairs({{40,26,-34},{40,22,-30},{-44,17,0},{-12,4,30},{12,4,30},{24,4,-36},{-56,4,-24},{56,4,8},{-24,4,-40},{0,4,16}}) do
	local coin = P(p4, "Coin", V3(0.6,4,4), V3(c[1],b+c[2],c[3]), C3(245,195,52), Enum.Material.Neon, {Shape=Enum.PartType.Cylinder, CanCollide=false})
	coin:SetAttribute("CoinValue", 1)
end
npc(p4, V3(48,b+3,20), -60, "teacher", "f")
npc(p4, V3(-12,b+3,32), 0, "visitor", "f"); npc(p4, V3(24,b+3,32), 0, "visitor", "m")
task.wait()

-- ===== 5F VIP LOUNGE =====
local p5 = Spa.Floor5.Props; b = 240
P(p5, "Carpet", V3(60,0.2,50), V3(0,b+0.1,10), C3(122,30,52), Enum.Material.Fabric)
local vp = P(p5, "VIPPool", V3(40,3,26), V3(0,b+1.5,30), C3(242,194,48), Enum.Material.Glass, {Transparency=0.35, CanCollide=false}); vp:SetAttribute("Pool","vip")
for _, r in ipairs({{V3(42,1.6,1.5),V3(0,b+0.8,16.5)},{V3(1.5,1.6,27),V3(-20.8,b+0.8,30)},{V3(1.5,1.6,27),V3(20.8,b+0.8,30)}}) do P(p5,"Rim",r[1],r[2],C3(242,194,48),Enum.Material.Marble,{CanCollide=false}) end
local vs = P(p5, "VIPSign", V3(40,6,0.6), V3(0,b+18,54.6), C3(242,194,48)); sign(vs, Enum.NormalId.Back, "VIP 라운지 · 황금 온탕 (냥전 3배)", C3(40,36,52), C3(242,194,48))
for _, x in ipairs({-40,40}) do local th = Instance.new("Seat"); th.Name = "Throne"; th.Anchored = true; th.Size = V3(5,1,5); th.Position = V3(x,b+2,-20); th.Color = C3(242,194,48); th.Material = Enum.Material.Foil; th.Parent = p5; P(p5,"ThroneBack",V3(5,8,1),V3(x,b+6,-22.5),C3(242,194,48),Enum.Material.Foil) end
npc(p5, V3(0,b+3,-20), 0, "vipstaff", "m")
print("[Nyangjjim] world built")
