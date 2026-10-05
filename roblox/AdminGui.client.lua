-- ============================================================
-- 🛠️ EGG ISLE · AdminGui (LocalScript → StarterPlayerScripts)
-- แผงแอดมินมือถือ — เห็นเฉพาะเจ้าของเกม (เซิร์ฟเวอร์เช็กสิทธิ์ซ้ำทุกครั้ง)
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

-- เช็กฝั่ง client เฉพาะสำหรับ "แสดงปุ่ม" (สิทธิ์จริงเช็กที่เซิร์ฟเวอร์)
local function iAmAdmin()
	return plr.UserId == 0 or (game.CreatorId > 0 and plr.UserId == game.CreatorId)
end
if not iAmAdmin() then return end

local evAdmin = ReplicatedStorage:WaitForChild("Admin")

local gui = Instance.new("ScreenGui"); gui.Name = "AdminGui"; gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p return c end

-- ปุ่มเปิด/ปิดแผง
local tog = Instance.new("TextButton"); tog.Size = UDim2.fromOffset(52, 52)
tog.Position = UDim2.new(1, -36, 0, 70); tog.AnchorPoint = Vector2.new(0.5, 0.5)
tog.BackgroundColor3 = Color3.fromRGB(40, 44, 60); tog.Font = Enum.Font.GothamBold
tog.TextScaled = true; tog.Text = "🛠️"; tog.TextColor3 = Color3.fromRGB(255, 255, 255)
corner(tog, 14)
local tgs = Instance.new("UIStroke"); tgs.Color = Color3.fromRGB(255, 200, 60); tgs.Thickness = 2; tgs.Parent = tog
tog.Parent = gui

-- แผงแอดมิน
local panel = Instance.new("Frame"); panel.Size = UDim2.fromOffset(250, 330)
panel.Position = UDim2.new(1, -135, 0.5, 20); panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(24, 28, 42); panel.BackgroundTransparency = 0.08
panel.Visible = false; corner(panel, 16)
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(255, 200, 60); ps.Thickness = 2; ps.Parent = panel
panel.Parent = gui

local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, 0, 0, 30); title.Position = UDim2.fromOffset(0, 4)
title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255, 200, 60); title.Text = "🛠️ แอดมิน"; title.Parent = panel

local list = Instance.new("ScrollingFrame"); list.Size = UDim2.new(1, -12, 1, -40); list.Position = UDim2.fromOffset(6, 34)
list.BackgroundTransparency = 1; list.ScrollBarThickness = 4; list.CanvasSize = UDim2.new(0, 0, 0, 420)
local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 6); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = list
list.Parent = panel

local function abutton(text, color, fn)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, -4, 0, 40)
	b.BackgroundColor3 = color; b.Font = Enum.Font.GothamBold; b.TextScaled = true
	b.TextColor3 = Color3.fromRGB(255, 255, 255); b.Text = text; corner(b, 10)
	b.Activated:Connect(fn); b.Parent = list
	return b
end
local function afield(ph)
	local t = Instance.new("TextBox"); t.Size = UDim2.new(1, -4, 0, 34)
	t.BackgroundColor3 = Color3.fromRGB(44, 50, 72); t.Font = Enum.Font.Gotham
	t.TextScaled = true; t.PlaceholderText = ph; t.Text = ""
	t.TextColor3 = Color3.fromRGB(255, 255, 255); t.PlaceholderColor3 = Color3.fromRGB(150, 160, 185)
	corner(t, 10); t.Parent = list
	return t
end

abutton("💰 +1,000,000 เหรียญ", Color3.fromRGB(200, 150, 40), function() evAdmin:FireServer("coins", 1000000) end)
abutton("💰 +100,000 เหรียญ", Color3.fromRGB(160, 120, 40), function() evAdmin:FireServer("coins", 100000) end)
abutton("🎁 สุ่มตัวเทพ (มหากาพย์/ตำนาน)", Color3.fromRGB(150, 80, 200), function() evAdmin:FireServer("randomleg") end)
abutton("🐾 แจกครบทุกตัว 11 ชนิด", Color3.fromRGB(60, 130, 200), function() evAdmin:FireServer("allpets") end)
abutton("♻️ รีเซ็ตเซฟของฉัน", Color3.fromRGB(120, 130, 150), function() evAdmin:FireServer("reset") end)

local annBox = afield("พิมพ์ประกาศ...")
abutton("📢 ส่งประกาศทั้งเซิร์ฟเวอร์", Color3.fromRGB(220, 90, 60), function()
	if annBox.Text ~= "" then evAdmin:FireServer("announce", annBox.Text) annBox.Text = "" end
end)

local kickBox = afield("ชื่อผู้เล่นที่จะเตะ...")
abutton("🦵 เตะผู้เล่น", Color3.fromRGB(180, 60, 60), function()
	if kickBox.Text ~= "" then evAdmin:FireServer("kick", kickBox.Text) end
end)

tog.Activated:Connect(function() panel.Visible = not panel.Visible end)
