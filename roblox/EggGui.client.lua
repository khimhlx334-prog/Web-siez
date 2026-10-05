-- ============================================================
-- 🥚 EGG ISLE · EggGui v2 (LocalScript → StarterPlayerScripts)
-- GUI มือถือ: ฟักไข่ 3 ระดับ · คอลเลกชัน · Rebirth · ป้ายประกาศแอดมิน
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local plr = Players.LocalPlayer

local evHatch = ReplicatedStorage:WaitForChild("Hatch")
local evAnn = ReplicatedStorage:WaitForChild("Announce")

local RARITY_COLOR = {
	["ธรรมดา"] = Color3.fromRGB(160, 160, 160),
	["ไม่ธรรมดา"] = Color3.fromRGB(61, 220, 132),
	["หายาก"] = Color3.fromRGB(64, 156, 255),
	["มหากาพย์"] = Color3.fromRGB(177, 101, 255),
	["ตำนาน"] = Color3.fromRGB(255, 190, 40),
}
local EGG_LIST = {
	{ id = "basic", label = "🥚 ธรรมดา", cost = 100 },
	{ id = "rare", label = "🥚 หายาก", cost = 1500 },
	{ id = "leg", label = "🥚 ตำนาน", cost = 30000 },
}
local PET_NAMES = {
	cat = "แมวส้ม 🐱", dog = "คอร์กี้ 🐶", rab = "กระต่ายขาว 🐰", pan = "แพนด้า 🐼",
	cap = "คาปิบาร่า 🦫", ele = "ช้างชมพู 🐘", lio = "สิงโตทอง 🦁", dra = "มังกรน้ำแข็ง 🐉",
	uni = "ยูนิคอร์นรุ้ง 🦄", gld = "ดราก้อนทอง 🐲", phx = "ฟีนิกซ์จักรวาล 🌟",
}

local gui = Instance.new("ScreenGui"); gui.Name = "EggIsleGui"; gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local function fmt(n)
	local s = tostring(math.floor(n or 0))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
local function btn(name, text, size, pos, color, parent)
	local b = Instance.new("TextButton")
	b.Name = name; b.Size = size; b.Position = pos; b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.BackgroundColor3 = color; b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold; b.TextScaled = true; b.Text = text
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 255, 255); s.Transparency = 0.55; s.Thickness = 2; s.Parent = b
	b.Parent = parent or gui
	return b
end

-- แถบบน: เหรียญ + พาวเวอร์
local top = Instance.new("Frame"); top.Size = UDim2.fromOffset(230, 44)
top.Position = UDim2.new(0.5, 0, 0, 16); top.AnchorPoint = Vector2.new(0.5, 0)
top.BackgroundColor3 = Color3.fromRGB(18, 22, 34); top.BackgroundTransparency = 0.15
local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 12); tc.Parent = top
top.Parent = gui
local topTxt = Instance.new("TextLabel"); topTxt.Size = UDim2.new(1, -10, 1, 0); topTxt.Position = UDim2.fromOffset(5, 0)
topTxt.BackgroundTransparency = 1; topTxt.Font = Enum.Font.GothamBold; topTxt.TextScaled = true
topTxt.TextColor3 = Color3.fromRGB(255, 220, 120); topTxt.Parent = top

-- 📢 ป้ายประกาศจากแอดมิน (เห็นทุกคน)
local ann = Instance.new("TextLabel"); ann.Size = UDim2.new(0.8, 0, 0, 46)
ann.Position = UDim2.new(0.5, 0, 0, 70); ann.AnchorPoint = Vector2.new(0.5, 0)
ann.BackgroundColor3 = Color3.fromRGB(255, 90, 60); ann.BackgroundTransparency = 0.1
ann.Font = Enum.Font.GothamBold; ann.TextScaled = true; ann.TextColor3 = Color3.fromRGB(255, 255, 255)
ann.TextWrapped = true; ann.Visible = false
local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0, 12); ac.Parent = ann
local ast = Instance.new("UIStroke"); ast.Color = Color3.fromRGB(255, 255, 255); ast.Thickness = 2; ast.Parent = ann
ann.Parent = gui
evAnn.OnClientEvent:Connect(function(msg)
	ann.Text = "📢 " .. tostring(msg)
	ann.Visible = true
	task.delay(4.5, function() ann.Visible = false end)
end)

-- ปุ่มหลักล่าง
local hatchBtn = btn("Hatch", "🥚 ฟักไข่", UDim2.fromOffset(120, 60), UDim2.new(0.5, 0, 1, -60), Color3.fromRGB(255, 160, 40))
local collBtn = btn("Coll", "🐾", UDim2.fromOffset(56, 56), UDim2.new(1, -40, 1, -60), Color3.fromRGB(64, 156, 255))

-- แผงคอลเลกชัน (สร้างก่อนเพื่อให้ hatchBtn อ้างอิงได้)
local collPanel = Instance.new("Frame"); collPanel.Size = UDim2.new(0.9, 0, 0.55, 0)
collPanel.Position = UDim2.new(0.5, 0, 0.5, 0); collPanel.AnchorPoint = Vector2.new(0.5, 0.5)
collPanel.BackgroundColor3 = Color3.fromRGB(20, 24, 38); collPanel.Visible = false
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 16); cc.Parent = collPanel
collPanel.Parent = gui

-- แผงเลือกไข่
local eggPanel = Instance.new("Frame"); eggPanel.Size = UDim2.fromOffset(260, 170)
eggPanel.Position = UDim2.new(0.5, 0, 1, -165); eggPanel.AnchorPoint = Vector2.new(0.5, 0.5)
eggPanel.BackgroundColor3 = Color3.fromRGB(20, 24, 38); eggPanel.Visible = false
local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0, 16); ec.Parent = eggPanel
eggPanel.Parent = gui
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 6); layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.Parent = eggPanel
for _, e in ipairs(EGG_LIST) do
	local b = btn("e_" .. e.id, e.label .. " · " .. fmt(e.cost), UDim2.new(0.9, 0, 0, 46), UDim2.new(0.5, 0, 0, 0), Color3.fromRGB(52, 62, 92), eggPanel)
	b.LayoutOrder = 1
	b.Activated:Connect(function() evHatch:FireServer(e.id) end)
end
hatchBtn.Activated:Connect(function() eggPanel.Visible = not eggPanel.Visible; collPanel.Visible = false end)

local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1, -12, 1, -44); scroll.Position = UDim2.fromOffset(6, 38)
scroll.BackgroundTransparency = 1; scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.ScrollBarThickness = 4; scroll.Parent = collPanel
local cl = Instance.new("UIListLayout"); cl.Padding = UDim.new(0, 5); cl.Parent = scroll
local clTitle = Instance.new("TextLabel"); clTitle.Size = UDim2.new(1, 0, 0, 34); clTitle.Position = UDim2.new(0, 0, 0, 2)
clTitle.BackgroundTransparency = 1; clTitle.Font = Enum.Font.GothamBold; clTitle.TextScaled = true
clTitle.TextColor3 = Color3.fromRGB(255, 255, 255); clTitle.Text = "🐾 คอลเลกชันของฉัน"; clTitle.Parent = collPanel
collBtn.Activated:Connect(function() collPanel.Visible = not collPanel.Visible; eggPanel.Visible = false end)

-- ป้ายผลฟัก (ป๊อปอัพกลางจอ)
local pop = Instance.new("Frame"); pop.Size = UDim2.fromOffset(240, 110)
pop.Position = UDim2.new(0.5, 0, 0.35, 0); pop.AnchorPoint = Vector2.new(0.5, 0.5)
pop.BackgroundColor3 = Color3.fromRGB(16, 20, 32); pop.Visible = false
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 18); pc.Parent = pop
local pst = Instance.new("UIStroke"); pst.Thickness = 3; pst.Parent = pop
pop.Parent = gui
local popTxt = Instance.new("TextLabel"); popTxt.Size = UDim2.new(1, -12, 1, -8); popTxt.Position = UDim2.fromOffset(6, 4)
popTxt.BackgroundTransparency = 1; popTxt.Font = Enum.Font.GothamBold; popTxt.TextScaled = true
popTxt.TextColor3 = Color3.fromRGB(255, 255, 255); popTxt.TextWrapped = true; popTxt.Parent = pop

evHatch.OnClientEvent:Connect(function(res)
	pst.Color = RARITY_COLOR[res.rarity] or Color3.fromRGB(255, 255, 255)
	popTxt.Text = res.emoji .. " " .. res.name .. "\n[" .. res.rarity .. "] พาวเวอร์ " .. res.power
	pop.Visible = true
	task.delay(2.2, function() pop.Visible = false end)
end)

-- อัปเดตข้อความ
local function refresh()
	local ls = plr:FindFirstChild("leaderstats")
	if ls then topTxt.Text = "🪙 " .. fmt(ls.Coins.Value) .. "  ⚡ " .. fmt(plr:GetAttribute("Power") or 0) end
	-- คอลเลกชัน
	local ok, counts = pcall(function() return Http:JSONDecode(plr:GetAttribute("PetsJSON") or "{}") end)
	if ok and type(counts) == "table" then
		scroll:ClearAllChildren(); Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 5)
		local n = 0
		for id, count in pairs(counts) do
			n += 1
			local row = Instance.new("TextLabel"); row.Size = UDim2.new(1, -4, 0, 30)
			row.BackgroundColor3 = Color3.fromRGB(34, 40, 60); row.Font = Enum.Font.GothamBold
			row.TextScaled = true; row.TextColor3 = Color3.fromRGB(255, 255, 255)
			row.Text = " " .. (PET_NAMES[id] or id) .. "  x" .. count
			local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = row
			row.Parent = scroll
		end
		if n == 0 then
			local empty = Instance.new("TextLabel"); empty.Size = UDim2.new(1, 0, 0, 30)
			empty.BackgroundTransparency = 1; empty.TextColor3 = Color3.fromRGB(160, 170, 190)
			empty.Font = Enum.Font.Gotham; empty.TextScaled = true; empty.Text = "ยังไม่มีสัตว์ — ไปฟักไข่เลย!"; empty.Parent = scroll
		end
		scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(1, n) * 35 + 10)
	end
end
task.spawn(function() while true do task.wait(0.5) pcall(refresh) end end)
