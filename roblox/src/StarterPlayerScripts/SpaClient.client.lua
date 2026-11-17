-- Nyangjjim Spaland client UI: HUD, elevator, dialog, sauna minigame, closet, Robux store.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local C = require(RS:WaitForChild("SpaConfig"))
local remotes = RS:WaitForChild("SpaRemotes")
local Action, Notify, GetState = remotes:WaitForChild("Action"), remotes:WaitForChild("Notify"), remotes:WaitForChild("GetState")

local ST = {coins = 0, gender = "", towel = "pink", outfit = "orange", jjim = true, owned = {}, passes = {}}
local INK, WHITE, BLUE, PINK, GOLD, MINT = Color3.fromRGB(34,48,58), Color3.new(1,1,1), Color3.fromRGB(61,139,253), Color3.fromRGB(242,104,154), Color3.fromRGB(245,195,52), Color3.fromRGB(47,191,155)
local FONT = Enum.Font.GothamBold

local gui = Instance.new("ScreenGui"); gui.Name = "SpaUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = player:WaitForChild("PlayerGui")
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 14); c.Parent = o end
local function pad(o, p) local u = Instance.new("UIPadding"); for _, k in ipairs({"PaddingTop","PaddingBottom","PaddingLeft","PaddingRight"}) do u[k] = UDim.new(0, p) end; u.Parent = o end
local function frame(parent, size, pos, color, anchor) local f = Instance.new("Frame"); f.Size = size; f.Position = pos or UDim2.new(); f.BackgroundColor3 = color or WHITE; f.BorderSizePixel = 0; if anchor then f.AnchorPoint = anchor end; f.Parent = parent; corner(f, 18); return f end
local function label(parent, text, size, pos, ts, color) local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = size; t.Position = pos or UDim2.new(); t.Text = text; t.TextColor3 = color or INK; t.Font = FONT; t.TextSize = ts or 18; t.TextWrapped = true; t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = parent; return t end
local function button(parent, text, size, color, tc) local b = Instance.new("TextButton"); b.Size = size; b.BackgroundColor3 = color or Color3.fromRGB(241,244,248); b.TextColor3 = tc or INK; b.Text = text; b.Font = FONT; b.TextSize = 17; b.AutoButtonColor = true; b.BorderSizePixel = 0; b.Parent = parent; corner(b, 12); return b end
local function list(parent, padding, dir) local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, padding or 8); l.FillDirection = dir or Enum.FillDirection.Vertical; l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = parent; return l end
local function grid(parent, cell) local g = Instance.new("UIGridLayout"); g.CellSize = cell; g.CellPadding = UDim2.fromOffset(8, 8); g.SortOrder = Enum.SortOrder.LayoutOrder; g.Parent = parent; return g end

-- HUD
local hud = frame(gui, UDim2.fromOffset(190, 46), UDim2.fromOffset(12, 12), WHITE)
local coinTxt = label(hud, "냥전 0", UDim2.new(1, -16, 1, 0), UDim2.fromOffset(16, 0), 22)
local floorTxt = label(gui, "", UDim2.fromOffset(240, 30), UDim2.fromOffset(14, 62), 16, WHITE); floorTxt.TextStrokeTransparency = 0.4
local bar = Instance.new("Frame"); bar.BackgroundTransparency = 1; bar.Size = UDim2.fromOffset(330, 46); bar.Position = UDim2.new(1, -12, 0, 12); bar.AnchorPoint = Vector2.new(1, 0); bar.Parent = gui
local bl = list(bar, 8, Enum.FillDirection.Horizontal); bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
local bCloset = button(bar, "꾸미기", UDim2.fromOffset(100, 46), BLUE, WHITE)
local bStore = button(bar, "로벅스 상점", UDim2.fromOffset(130, 46), GOLD, Color3.fromRGB(59,42,0))

-- toast & bubble
local toastF = frame(gui, UDim2.fromOffset(420, 44), UDim2.new(0.5, 0, 0, 70), INK, Vector2.new(0.5, 0)); toastF.Visible = false
local toastT = label(toastF, "", UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0), 16, WHITE); toastT.TextXAlignment = Enum.TextXAlignment.Center
local tt = 0
local function toast(msg) tt += 1; local my = tt; toastT.Text = msg; toastF.Visible = true; task.delay(2.8, function() if tt == my then toastF.Visible = false end end) end
local function bubble(msg)
	local head = player.Character and player.Character:FindFirstChild("Head"); if not head then return end
	local old = head:FindFirstChild("SpaBubble"); if old then old:Destroy() end
	local bb = Instance.new("BillboardGui"); bb.Name = "SpaBubble"; bb.Size = UDim2.fromOffset(260, 54); bb.StudsOffset = Vector3.new(0, 4.2, 0); bb.AlwaysOnTop = true; bb.Adornee = head; bb.Parent = head
	local f = frame(bb, UDim2.fromScale(1, 1), nil, WHITE); local st = Instance.new("UIStroke"); st.Thickness = 3; st.Color = INK; st.Parent = f
	local t = label(f, msg, UDim2.fromScale(1, 1), nil, 18); t.TextXAlignment = Enum.TextXAlignment.Center
	task.delay(2.6, function() bb:Destroy() end)
end

-- modal helper
local modals = {}
local function modal(name, w, h)
	local m = frame(gui, UDim2.fromOffset(w, h), UDim2.fromScale(0.5, 0.5), WHITE, Vector2.new(0.5, 0.5)); m.Visible = false; m.Name = name; pad(m, 18)
	local sc = Instance.new("UISizeConstraint"); sc.MaxSize = Vector2.new(w, h); sc.Parent = m
	m.Size = UDim2.new(0.92, 0, 0.86, 0); modals[name] = m; return m
end
local function closeModals() for _, m in pairs(modals) do m.Visible = false end end
local function header(m, title, onClose)
	local t = label(m, title, UDim2.new(1, -60, 0, 36), nil, 26); t.Font = Enum.Font.GothamBlack
	local x = button(m, "닫기", UDim2.fromOffset(64, 36)); x.Position = UDim2.new(1, -64, 0, 0)
	x.MouseButton1Click:Connect(function() m.Visible = false; if onClose then onClose() end end)
end
local function body(m) local sf = Instance.new("ScrollingFrame"); sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0; sf.Size = UDim2.new(1, 0, 1, -48); sf.Position = UDim2.fromOffset(0, 48); sf.AutomaticCanvasSize = Enum.AutomaticSize.Y; sf.CanvasSize = UDim2.new(); sf.ScrollBarThickness = 6; sf.Parent = m; return sf end
local function clear(o) for _, c in ipairs(o:GetChildren()) do if not c:IsA("UIListLayout") and not c:IsA("UIGridLayout") and not c:IsA("UIPadding") then c:Destroy() end end end

-- ===== elevator =====
local elev = modal("Elevator", 360, 470); header(elev, "엘리베이터")
local elevBody = body(elev); list(elevBody, 8)
local function openElevator(cur)
	closeModals(); clear(elevBody)
	for i = #C.Floors, 1, -1 do
		local locked = i == 5 and not ST.passes.VIP
		local b = button(elevBody, i .. "F  " .. C.Floors[i] .. (i == cur and "   · 지금 여기" or "") .. (locked and "   · VIP 전용" or ""), UDim2.new(1, -8, 0, 54), i == cur and INK or (locked and Color3.fromRGB(255,240,200) or nil), i == cur and WHITE or nil)
		b.LayoutOrder = #C.Floors - i
		b.MouseButton1Click:Connect(function() elev.Visible = false; if i ~= cur then Action:FireServer("elevator", i) end end)
	end
	elev.Visible = true
end

-- ===== dialog =====
local dlg = frame(gui, UDim2.new(0.94, 0, 0, 200), UDim2.new(0.5, 0, 1, -16), WHITE, Vector2.new(0.5, 1)); dlg.Visible = false; pad(dlg, 16)
local dsc = Instance.new("UISizeConstraint"); dsc.MaxSize = Vector2.new(640, 260); dsc.Parent = dlg
local dName = label(dlg, "", UDim2.new(1, 0, 0, 24), nil, 16, MINT)
local dText = label(dlg, "", UDim2.new(1, 0, 0, 60), UDim2.fromOffset(0, 26), 18)
local dChoices = Instance.new("Frame"); dChoices.BackgroundTransparency = 1; dChoices.Size = UDim2.new(1, 0, 1, -92); dChoices.Position = UDim2.fromOffset(0, 92); dChoices.Parent = dlg
local dGrid = Instance.new("UIGridLayout"); dGrid.CellSize = UDim2.new(0.5, -6, 0, 40); dGrid.CellPadding = UDim2.fromOffset(8, 8); dGrid.Parent = dChoices
local function showNode(node)
	if not node then dlg.Visible = false return end
	dText.Text = node.text; clear(dChoices)
	for i, c in ipairs(node.choices) do local b = button(dChoices, c[1], UDim2.new(), nil); b.LayoutOrder = i; b.TextSize = 15; b.MouseButton1Click:Connect(function() showNode(c[2] and c[2]() or nil) end) end
	dlg.Visible = true
end
local BYE = {"안녕히 계세요", nil}
local LINES = {"양머리 하니까 귀엽지?", "식혜 마시러 갈까?", "불가마는 진짜 뜨거워…", "4층 미끄럼틀 타봤어?", "계란은 이마로 깨는 거야!", "바나나우유 최고!", "VIP 라운지 황금 온탕 가봤어?"}
local TALK = {}
TALK.counter = function() return {text = "어서 오세요, 냥찜 스파랜드입니다! 무엇을 도와드릴까요?", choices = {
	{"찜질복이랑 양머리 주세요", function() Action:FireServer("jjimkit"); return {text = "여기 찜질복이요! 양머리도 예쁘게 말아드렸어요. 색은 꾸미기에서 바꿀 수 있어요.", choices = {{"고마워요!", nil}}} end},
	{"층 안내 해주세요", function() return {text = "1층 로비, 2층 목욕탕(남탕·여탕), 3층 찜질광장·매점·수면실, 4층 놀이방, 5층 VIP 라운지예요. 엘리베이터는 뒤쪽 가운데!", choices = {{"더 물어볼게요", TALK.counter}, BYE}} end},
	{"냥전은 어떻게 벌어요?", function() return {text = "사우나·불가마에서 땀을 빼거나, 온탕에 몸을 담그거나, 4층 놀이방에서 주워요. 매일 접속하면 출석 보너스도 있어요!", choices = {{"더 물어볼게요", TALK.counter}, BYE}} end},
	BYE}} end
TALK.guide = function() return {text = "왼쪽 파란 커튼이 남탕, 오른쪽 분홍 커튼이 여탕이에요. 안에 온탕, 냉탕, 건식 사우나가 있어요. 온탕에 담그고 있으면 냥전이 조금씩 생겨요!", choices = {{"알겠어요!", nil}}} end
TALK.scrub = function() return {text = "손님, 때 좀 밀어드릴까? 냥전 30개면 2분 동안 반짝반짝 빛나!", choices = {{"밀어주세요 (30냥)", function() Action:FireServer("scrub"); return nil end}, {"괜찮아요", nil}}} end
TALK.shop = function()
	local ch = {}
	for _, f in ipairs(C.Foods) do table.insert(ch, {f.name .. " · " .. f.price .. "냥", function() Action:FireServer("food", f.id); return nil end}) end
	table.insert(ch, BYE)
	return {text = "어서 와~ 뭐 줄까? 먹으면 잠깐 빨라진다! 지금 냥전 " .. ST.coins .. "개 있네.", choices = ch}
end
TALK.staff3 = function() return {text = LINES[math.random(#LINES)] == "" and "" or ({"불가마는 금방 뜨거워져요. 초록 구간에서 나오면 냥전 8개!", "수면실 매트에 누우면 꿀잠 잘 수 있어요.", "4층 미끄럼틀 강추! 볼풀로 풍덩!", "VIP 회원은 5층 황금 온탕에서 냥전 3배래요."})[math.random(4)], choices = {{"다른 팁도요", TALK.staff3}, {"고마워요!", nil}}} end
TALK.teacher = function() return {text = "놀이방에 온 걸 환영해! 탑 위에서 미끄럼틀을 타고, 트램펄린으로 높이 뛰어서 하늘의 냥전도 잡아 봐!", choices = {{"신난다!", nil}}} end
TALK.vipstaff = function() return {text = "VIP 라운지에 오신 걸 환영합니다. 황금 온탕은 냥전이 3배로 쌓여요. 편히 쉬세요.", choices = {{"좋아요!", nil}}} end
TALK.visitor = function() return {text = LINES[math.random(#LINES)], choices = {{"그렇구나!", nil}, {"옷 예쁘다!", function() return {text = "고마워! 너 양머리도 진짜 귀엽다.", choices = {{"헤헤", nil}}} end}}} end
TALK.soaker = TALK.visitor

-- ===== sauna minigame =====
local sau = modal("Sauna", 380, 520); local sauTitle
do sauTitle = label(sau, "사우나", UDim2.new(1, 0, 0, 36), nil, 26); sauTitle.Font = Enum.Font.GothamBlack end
local sauSub = label(sau, "버튼을 꾹 누르고 버티다가 초록 구간에서 떼세요", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 38), 14, Color3.fromRGB(102,118,138))
local gauge = frame(sau, UDim2.fromOffset(56, 260), UDim2.new(0.5, -110, 0, 90), Color3.fromRGB(240,240,240)); gauge.ClipsDescendants = true
local band = Instance.new("Frame"); band.BorderSizePixel = 0; band.BackgroundColor3 = Color3.fromRGB(123,211,137); band.Size = UDim2.new(1, 0, 0.11, 0); band.Parent = gauge
local fill = Instance.new("Frame"); fill.BorderSizePixel = 0; fill.BackgroundColor3 = Color3.fromRGB(233,87,63); fill.BackgroundTransparency = 0.15; fill.AnchorPoint = Vector2.new(0, 1); fill.Position = UDim2.fromScale(0, 1); fill.Size = UDim2.fromScale(1, 0); fill.Parent = gauge
local secT = label(sau, "0.0초", UDim2.fromOffset(150, 40), UDim2.new(0.5, -30, 0, 140), 30)
local prizeT = label(sau, "", UDim2.fromOffset(170, 60), UDim2.new(0.5, -30, 0, 190), 16, Color3.fromRGB(102,118,138))
local resT = label(sau, "준비됐나요?", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 360), 20); resT.TextXAlignment = Enum.TextXAlignment.Center
local hold = button(sau, "꾹 눌러서 버티기", UDim2.new(1, 0, 0, 56), GOLD, Color3.fromRGB(59,42,0)); hold.Position = UDim2.fromOffset(0, 396); hold.TextSize = 20
local exitB = button(sau, "사우나에서 나가기", UDim2.new(1, 0, 0, 40)); exitB.Position = UDim2.fromOffset(0, 460)
local sv, srun, slo, shi, scfg, st0, slock = 0, false, 0, 0, nil, 0, false
local function newBand() slo = math.random(55, 82); shi = slo + 11; band.Position = UDim2.fromScale(0, 1 - shi / 100); band.Size = UDim2.fromScale(1, (shi - slo) / 100) end
local function sEnd()
	if not srun then return end; srun = false
	local outcome
	if sv >= 100 then outcome = "burn" elseif sv >= slo and sv <= shi then outcome = "perfect" elseif sv > shi or sv >= slo - 12 then outcome = "near" else outcome = "early" end
	Action:FireServer("sauna", outcome); slock = true
	task.delay(1.3, function() slock = false; sv = 0; fill.Size = UDim2.fromScale(1, 0); newBand() end)
end
local function sStart() if srun or slock or not sau.Visible then return end; srun = true; sv = 0; st0 = os.clock(); resT.Text = "후끈후끈…" end
hold.MouseButton1Down:Connect(sStart); hold.MouseButton1Up:Connect(sEnd); hold.MouseLeave:Connect(sEnd)
UIS.InputBegan:Connect(function(i, gp) if sau.Visible and i.KeyCode == Enum.KeyCode.Space then sStart() end end)
UIS.InputEnded:Connect(function(i) if sau.Visible and i.KeyCode == Enum.KeyCode.Space then sEnd() end end)
RunService.RenderStepped:Connect(function(dt)
	if not srun then return end
	sv += dt * 1000 * (0.012 + sv * 0.0004) * (scfg and scfg.speed or 1)
	fill.Size = UDim2.fromScale(1, math.min(1, sv / 100)); secT.Text = string.format("%.1f초", os.clock() - st0)
	if sv >= 100 then sv = 100; sEnd() end
end)
local function closeSauna() srun = false; sau.Visible = false; Action:FireServer("saunaClose"); bubble("개운하다~") end
exitB.MouseButton1Click:Connect(closeSauna)
local function openSauna(kind)
	closeModals(); scfg = C.Sauna[kind]; sauTitle.Text = scfg.title; prizeT.Text = "초록 구간 성공 시\n냥전 +" .. scfg.prize .. (ST.passes.Double and " (2배!)" or "")
	sv = 0; fill.Size = UDim2.fromScale(1, 0); newBand(); resT.Text = "준비됐나요?"; secT.Text = "0.0초"; sau.Visible = true
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.WalkSpeed = 0 end
end
sau:GetPropertyChangedSignal("Visible"):Connect(function() if not sau.Visible then local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.WalkSpeed = 16 end end end)

-- ===== closet =====
local closet = modal("Closet", 440, 560); header(closet, "내 캐릭터 꾸미기")
local cBody = body(closet); list(cBody, 10)
local function section(title, order) local t = label(cBody, title, UDim2.new(1, -8, 0, 22), nil, 14, Color3.fromRGB(102,118,138)); t.LayoutOrder = order; local g = Instance.new("Frame"); g.BackgroundTransparency = 1; g.Size = UDim2.new(1, -8, 0, 0); g.AutomaticSize = Enum.AutomaticSize.Y; g.LayoutOrder = order + 1; g.Parent = cBody; grid(g, UDim2.fromOffset(122, 44)); return g end
local function renderCloset()
	clear(cBody)
	local g1 = section("성별 (입장할 목욕탕이 정해져요)", 1)
	for _, gd in ipairs({{"남자 · 남탕", "m", BLUE}, {"여자 · 여탕", "f", PINK}}) do
		local sel = ST.gender == gd[2]; local b = button(g1, gd[1], UDim2.new(), sel and gd[3] or nil, sel and WHITE or nil)
		b.MouseButton1Click:Connect(function() Action:FireServer("gender", gd[2]) end)
	end
	local g2 = section("양머리 수건", 3)
	for _, t in ipairs(C.Towels) do
		local tag = t.pass and " · 팩" or ((t.price or 0) > 0 and not ST.owned["towel:" .. t.key] and (" · " .. t.price .. "냥") or "")
		local sel = ST.towel == t.key; local b = button(g2, t.name .. tag, UDim2.new(), t.color or nil, INK); b.TextSize = 14
		if sel then local s2 = Instance.new("UIStroke"); s2.Thickness = 3; s2.Color = BLUE; s2.Parent = b end
		b.MouseButton1Click:Connect(function() Action:FireServer("towel", t.key) end)
	end
	local g3 = section("찜질복 색", 5)
	for _, o in ipairs(C.Outfits) do
		local tag = o.pass and " · 팩" or ((o.price or 0) > 0 and not ST.owned["outfit:" .. o.key] and (" · " .. o.price .. "냥") or "")
		local sel = ST.jjim and ST.outfit == o.key; local light = (o.color.R + o.color.G + o.color.B) > 1.6
		local b = button(g3, o.name .. tag, UDim2.new(), o.color, light and INK or WHITE); b.TextSize = 14
		if sel then local s2 = Instance.new("UIStroke"); s2.Thickness = 3; s2.Color = BLUE; s2.Parent = b end
		b.MouseButton1Click:Connect(function() Action:FireServer("outfit", o.key) end)
	end
	local g4 = section("옷", 7)
	local b1 = button(g4, ST.jjim and "찜질복 벗기" or "찜질복 입기", UDim2.new()); b1.MouseButton1Click:Connect(function() Action:FireServer("jjim", not ST.jjim) end)
	local note = label(cBody, "눈·속눈썹·헤어 꾸미기는 다음 업데이트에서 추가돼요.", UDim2.new(1, -8, 0, 40), nil, 13, Color3.fromRGB(102,118,138)); note.LayoutOrder = 9
end

-- ===== robux store =====
local storeM = modal("Store", 460, 580); header(storeM, "로벅스 상점")
local sBody = body(storeM); list(sBody, 10)
local priceCache = {}
local function robuxPrice(id, infoType)
	if id == 0 then return nil end
	if priceCache[id] then return priceCache[id] end
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, infoType) end)
	if ok and info and info.PriceInRobux then priceCache[id] = info.PriceInRobux; return info.PriceInRobux end
end
local function storeRow(title, desc, price, ready, onBuy, order, owned)
	local r = frame(sBody, UDim2.new(1, -8, 0, 84), nil, Color3.fromRGB(246,248,251)); r.LayoutOrder = order; pad(r, 12)
	label(r, title, UDim2.new(1, -130, 0, 24), nil, 18)
	label(r, desc, UDim2.new(1, -130, 0, 36), UDim2.fromOffset(0, 26), 13, Color3.fromRGB(102,118,138))
	local b = button(r, owned and "보유중" or (ready and ((price and ("R$ " .. price)) or "구매") or "준비 중"), UDim2.fromOffset(116, 44), owned and Color3.fromRGB(220,226,232) or (ready and GOLD or Color3.fromRGB(230,230,230)), Color3.fromRGB(59,42,0))
	b.Position = UDim2.new(1, -116, 0.5, -22)
	if ready and not owned then b.MouseButton1Click:Connect(onBuy) end
end
local function renderStore()
	clear(sBody)
	local h1 = label(sBody, "회원권 (한 번 사면 영구)", UDim2.new(1, -8, 0, 22), nil, 14, Color3.fromRGB(102,118,138)); h1.LayoutOrder = 0
	for i, p in ipairs(C.GamePasses) do
		storeRow(p.name, p.desc, robuxPrice(p.id, Enum.InfoType.GamePass), p.id > 0, function() MarketplaceService:PromptGamePassPurchase(player, p.id) end, i, ST.passes[p.key])
	end
	local h2 = label(sBody, "냥전 충전", UDim2.new(1, -8, 0, 22), nil, 14, Color3.fromRGB(102,118,138)); h2.LayoutOrder = 10
	for i, p in ipairs(C.Products) do
		storeRow(p.name, "냥전 " .. p.coins .. "개", robuxPrice(p.id, Enum.InfoType.Product), p.id > 0, function() MarketplaceService:PromptProductPurchase(player, p.id) end, 10 + i, false)
	end
end

bCloset.MouseButton1Click:Connect(function() local v = not closet.Visible; closeModals(); if v then renderCloset(); closet.Visible = true end end)
bStore.MouseButton1Click:Connect(function() local v = not storeM.Visible; closeModals(); if v then storeM.Visible = true; task.spawn(renderStore) end end)

-- daily bonus
local daily = modal("Daily", 360, 260)
local dTitle = label(daily, "출석 보너스", UDim2.new(1, 0, 0, 36), nil, 26); dTitle.Font = Enum.Font.GothamBlack
local dMsg = label(daily, "", UDim2.new(1, 0, 0, 110), UDim2.fromOffset(0, 44), 18)
local dOk = button(daily, "받았어요!", UDim2.new(1, 0, 0, 48), BLUE, WHITE); dOk.Position = UDim2.new(0, 0, 1, -48)
dOk.MouseButton1Click:Connect(function() daily.Visible = false end)

-- floor label
RunService.Heartbeat:Connect(function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	local i = math.clamp(math.floor((hrp.Position.Y + 20) / 60) + 1, 1, #C.Floors)
	floorTxt.Text = i .. "F  " .. C.Floors[i]
end)

local function applyState(s) if not s then return end; ST = s; coinTxt.Text = "냥전 " .. s.coins; if closet.Visible then renderCloset() end end
Notify.OnClientEvent:Connect(function(kind, a, b)
	if kind == "state" then applyState(a)
	elseif kind == "toast" then toast(a)
	elseif kind == "bubble" then bubble(a)
	elseif kind == "elevator" then openElevator(a)
	elseif kind == "sauna" then openSauna(a)
	elseif kind == "saunaResult" then resT.Text = (a == "perfect" and "딱 좋게 땀 뺐다! " or a == "near" and "아깝다! " or a == "burn" and "앗 뜨거! 어질어질… " or "벌써 나가요? ") .. "냥전 +" .. b
	elseif kind == "talk" then closeModals(); dName.Text = b; showNode(TALK[a] and TALK[a]() or TALK.visitor())
	elseif kind == "needpass" then
		local p; for _, x in ipairs(C.GamePasses) do if x.key == a then p = x end end
		toast((p and p.name or "회원권") .. "이 필요해요. 로벅스 상점에서 확인하세요!")
		closeModals(); storeM.Visible = true; task.spawn(renderStore)
	elseif kind == "daily" then dMsg.Text = a .. "일 연속 출석!\n냥전 +" .. b .. "\n7일 연속이면 100냥전!"; daily.Visible = true
	elseif kind == "firsttime" then toast("반가워요! 먼저 성별을 골라 주세요."); closeModals(); renderCloset(); closet.Visible = true
	end
end)
task.spawn(function() applyState(GetState:InvokeServer()) end)
