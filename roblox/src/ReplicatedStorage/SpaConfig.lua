-- Nyangjjim Spaland shared config.
-- MONETIZATION: after publishing, create these in Creator Hub (Monetization > Passes / Developer Products)
-- and paste the numeric IDs into `id`. id = 0 means "not set up yet" and the store shows it as coming soon.
local C = {}

C.GamePasses = {
	{key = "VIP",    id = 2089454868, name = "VIP 회원권",  desc = "5층 VIP 라운지 입장 · 황금 온탕 냥전 3배 · 금색 이름표"},
	{key = "Double", id = 2089904874, name = "냥전 2배",    desc = "사우나·온탕·놀이방에서 버는 냥전이 영원히 2배"},
	{key = "Style",  id = 2088824823, name = "스타일 팩",   desc = "황금·무지개 양머리, 한정 찜질복 색 3종"},
}

C.Products = {
	{key = "c100",  id = 3731117812, coins = 100,  name = "냥전 한 줌"},
	{key = "c550",  id = 3731117861, coins = 550,  name = "냥전 주머니 (+10%)"},
	{key = "c1500", id = 3731117868, coins = 1500, name = "냥전 금고 (+25%)"},
}

C.Floors = {"로비", "목욕탕", "찜질광장", "놀이방", "VIP 라운지"}

C.Foods = {
	{id = "egg",    name = "맥반석 계란", price = 10, say = "계란은 이마로 콩!",      speed = 20, secs = 30},
	{id = "sikhye", name = "식혜",        price = 15, say = "살얼음 식혜 꿀꺽!",      speed = 22, secs = 45},
	{id = "banana", name = "바나나우유",  price = 20, say = "목욕 끝엔 바나나우유!",  speed = 24, secs = 60},
	{id = "ramen",  name = "찜질방 라면", price = 25, say = "후루룩 라면 최고!",      speed = 24, secs = 90},
	{id = "bingsu", name = "팥빙수",      price = 30, say = "시원~한 팥빙수!",        speed = 26, secs = 120},
}

C.Towels = {
	{key = "none",    name = "없음",   color = nil},
	{key = "pink",    name = "딸기",   color = Color3.fromRGB(247,198,208), price = 0},
	{key = "sky",     name = "하늘",   color = Color3.fromRGB(191,224,242), price = 0},
	{key = "mint",    name = "민트",   color = Color3.fromRGB(191,235,221), price = 40},
	{key = "lemon",   name = "레몬",   color = Color3.fromRGB(251,226,154), price = 40},
	{key = "lavender",name = "라벤더", color = Color3.fromRGB(220,203,245), price = 40},
	{key = "gold",    name = "황금",   color = Color3.fromRGB(242,194,48),  pass = "Style"},
	{key = "rainbow", name = "무지개", color = Color3.fromRGB(255,120,200), pass = "Style"},
}

C.Outfits = {
	{key = "orange", name = "주황", color = Color3.fromRGB(243,154,74),  price = 0},
	{key = "pink",   name = "분홍", color = Color3.fromRGB(245,155,181), price = 0},
	{key = "blue",   name = "하늘", color = Color3.fromRGB(142,197,240), price = 0},
	{key = "grey",   name = "회색", color = Color3.fromRGB(169,179,188), price = 0},
	{key = "yellow", name = "노랑", color = Color3.fromRGB(247,211,94),  price = 60},
	{key = "mintc",  name = "민트", color = Color3.fromRGB(143,220,194), price = 60},
	{key = "purple", name = "보라", color = Color3.fromRGB(183,155,232), price = 60},
	{key = "black",  name = "블랙", color = Color3.fromRGB(43,43,51),    pass = "Style"},
	{key = "white",  name = "화이트",color = Color3.fromRGB(244,244,240), pass = "Style"},
	{key = "goldc",  name = "골드", color = Color3.fromRGB(242,194,48),  pass = "Style"},
}

C.Sauna = {
	dry  = {title = "건식 사우나 85°C", speed = 1.0, prize = 6},
	kiln = {title = "불가마 98°C",      speed = 1.4, prize = 8},
}

C.DailyBonus = {20, 25, 30, 40, 50, 60, 100} -- day 1..7 streak

C.NPCs = {
	counter  = {title = "카운터 직원 소라",   skin = Color3.fromRGB(255,227,207), outfit = Color3.fromRGB(61,79,138),  towel = nil},
	guide    = {title = "안내 직원 준",       skin = Color3.fromRGB(247,203,168), outfit = Color3.fromRGB(61,79,138),  towel = nil},
	scrub    = {title = "세신사",             skin = Color3.fromRGB(232,176,138), outfit = Color3.fromRGB(169,179,188), towel = Color3.fromRGB(255,255,255)},
	shop     = {title = "매점 사장님 복희",   skin = Color3.fromRGB(247,203,168), outfit = Color3.fromRGB(229,83,75),  towel = nil},
	staff3   = {title = "찜질방 알바 지우",   skin = Color3.fromRGB(255,227,207), outfit = Color3.fromRGB(61,79,138),  towel = nil},
	teacher  = {title = "놀이방 선생님 다솜", skin = Color3.fromRGB(255,227,207), outfit = Color3.fromRGB(143,220,194), towel = nil},
	vipstaff = {title = "VIP 매니저",         skin = Color3.fromRGB(201,139,98),  outfit = Color3.fromRGB(43,43,51),    towel = nil},
	visitor  = {title = "손님",               random = true},
	soaker   = {title = "손님",               random = true},
}

return C
