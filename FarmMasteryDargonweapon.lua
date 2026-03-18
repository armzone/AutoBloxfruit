-- ===== CONFIG =====
local WEAPONS = {
    {name = "Dragonheart", weaponType = "Sword", masteryRequired = 500, stats = {"Sword", "Melee", "Defense"}, script = "https://raw.githubusercontent.com/armzone/BananaConfig/refs/heads/main/FarmSwordMastery.lua"},
    {name = "Dragonstorm", weaponType = "Gun",   masteryRequired = 500, stats = {"Gun", "Melee", "Defense"},   script = "https://raw.githubusercontent.com/armzone/BananaConfig/refs/heads/main/FarmGunMastery.lua"}
}
local STAT_REQUIRED_LEVEL = 2800
-- ==================

local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
local craftRemote = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RF/Craft")
local player = game:GetService("Players").LocalPlayer

local function GetInventory()
    local ok, inventory = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if not ok or type(inventory) ~= "table" then return nil end
    return inventory
end

local function craftWeapon(weaponName)
    print("กำลัง Craft: " .. weaponName)
    craftRemote:InvokeServer(unpack({"Craft", weaponName, {}}))
    task.wait(2)
end

local function equipWeapon(weaponName)
    print("กำลัง Equip: " .. weaponName)
    remote:InvokeServer(unpack({[1]="LoadItem",[2]=weaponName}))
    task.wait(1)
end

local function refundStat()
    remote:InvokeServer(unpack({[1]="BlackbeardReward",[2]="Refund",[3]="2"}))
end

local function fixStats(statsToFix)
    while player.Team == nil do task.wait(3) end
    
    local stats = player:WaitForChild("Data"):WaitForChild("Stats")
    local needRefund = false

    -- 1. เช็คก่อนว่ามี Stat ไหนต่ำกว่าเกณฑ์บ้าง
    for _, statName in ipairs(statsToFix) do
        local stat = stats:FindFirstChild(statName)
        if stat and stat:FindFirstChild("Level") then
            if stat.Level.Value < STAT_REQUIRED_LEVEL then
                needRefund = true
                break -- เจอแค่ตัวเดียวที่ต้องแก้ ก็ถือว่าต้อง Refund ทั้งหมด
            end
        end
    end

    -- 2. ถ้าจำเป็นต้อง Refund ให้ทำแค่ครั้งเดียว
    if needRefund then
        print("Stats ไม่ถูกต้อง กำลังทำการ Refund...")
        refundStat()
        task.wait(1) -- รอให้ระบบเกม Update ค่า Stat ที่คืนมาเป็น Point

        -- 3. อัป Stat คืนกลับไปตามรายการที่กำหนด
        for _, statName in ipairs(statsToFix) do
            print("กำลังอัป Stat: " .. statName)
            -- ส่ง Remote อัปแต้ม (ใช้ 9999 ได้ถ้าเกมรองรับการตัดยอดอัตโนมัติ)
            remote:InvokeServer("AddPoint", statName, 9999) 
            task.wait(0.5) 
        end
    else
        print("Stats ถูกต้องอยู่แล้ว")
    end
end

local function runScript(url)
    local fn, err = loadstring(game:HttpGet(url))
    if fn then task.spawn(fn) else warn("loadstring error: " .. tostring(err)) end
end

local function rejoin()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, player)
end

local function findWeapon(inventory, weaponName, weaponType)
    for _, item in pairs(inventory) do
        if type(item) == "table" and item.Name == weaponName and item.Type == weaponType then
            return item
        end
    end
    return nil
end

-- ===== เลือกทีม =====
repeat task.wait() until game:IsLoaded()

local player = game:GetService("Players").LocalPlayer

local function FindMarinesButton()
    local playerGui = player:WaitForChild("PlayerGui")

    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local chooseTeam = gui:FindFirstChild("ChooseTeam", true)
            if chooseTeam then
                local btn = chooseTeam:FindFirstChild("TextButton", true)
                if btn and btn.Parent and btn.Parent.Name == "Frame" then
                    return btn
                end
            end
        end
    end
end

repeat
    task.wait(1)

    local success, err = pcall(function()
        local btn = FindMarinesButton()

        if btn then
            print("เจอปุ่มแล้ว กำลังกด...")

            for _, v in pairs(getconnections(btn.Activated)) do
                v.Function()
            end
        else
            warn("ยังไม่เจอปุ่ม Marines")
        end
    end)

    if not success then
        warn("เลือกทีม error:", err)
    end

until player.Team ~= nil

print("เลือกทีมสำเร็จ:", player.Team.Name)
-- ====================

for _, weaponData in ipairs(WEAPONS) do
    local inventory = GetInventory()
    if not inventory then
        warn("ดึง inventory ไม่สำเร็จ")
        continue
    end

    local item = findWeapon(inventory, weaponData.name, weaponData.weaponType)

    if not item then
        print(weaponData.name .. " ไม่มีใน inventory กำลัง Craft...")
        craftWeapon(weaponData.name)
        inventory = GetInventory()
        item = findWeapon(inventory, weaponData.name, weaponData.weaponType)
    end

    if not item then
        warn("Craft " .. weaponData.name .. " ไม่สำเร็จ")
        continue
    end

    if not item.Equipped then
        equipWeapon(weaponData.name)
    end

    if (item.Mastery or 0) >= weaponData.masteryRequired then
        print(weaponData.name .. " Mastery ครบแล้ว ข้ามไป Task ถัดไป")
        continue
    end

    print(weaponData.name .. " Mastery: " .. (item.Mastery or 0) .. "/" .. weaponData.masteryRequired)
    fixStats(weaponData.stats)
    runScript(weaponData.script)

    while true do
        local inv = GetInventory()
        if inv then
            local current = findWeapon(inv, weaponData.name, weaponData.weaponType)
            if current and (current.Mastery or 0) >= weaponData.masteryRequired then
                print(weaponData.name .. " Mastery ครบแล้ว! Rejoining...")
                break
            end
            print(weaponData.name .. " Mastery: " .. (current and current.Mastery or 0) .. "/" .. weaponData.masteryRequired)
        end
        task.wait(5)
    end

    task.wait(2)
    rejoin()
    return
end

print("All tasks complete!")

while type(_G.Horst_AccountChangeDone) ~= "function" do
    task.wait(1)
end

local ok, err = _G.Horst_AccountChangeDone()
if ok then
    print("Done sent successfully!")
else
    print("Failed to send DONE: " .. tostring(err))
end
