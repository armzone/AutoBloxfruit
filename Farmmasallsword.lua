local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CommF_ = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
local player = game:GetService("Players").LocalPlayer

local STAT_REQUIRED_LEVEL = 2800 -- ค่า Stat ขั้นต่ำที่ต้องการ

-- ฟังก์ชัน Equip ดาบ
local function equipSword(weaponName)
    CommF_:InvokeServer(unpack({"LoadItem", weaponName}))
    print("Equipped: " .. tostring(weaponName))
end

-- ฟังก์ชันดึง Inventory
local function getInventory()
    return CommF_:InvokeServer("getInventory")
end

-- ฟังก์ชันหาค่า MasteryRequirements สูงสุด
local function getMaxRequirement(requirements)
    local maxReq = 0
    for _, reqValue in pairs(requirements) do
        if type(reqValue) == "number" and reqValue > maxReq then
            maxReq = reqValue
        end
    end
    return maxReq
end

-- ฟังก์ชัน Refund Stat
local function refundStat()
    CommF_:InvokeServer(unpack({[1]="BlackbeardReward",[2]="Refund",[3]="2"}))
end

-- ฟังก์ชันเช็คและแก้ไข Stats ให้เป็น Sword
local function fixStats()
    while player.Team == nil do task.wait(3) end

    local statsToFix = {"Sword", "Melee", "Defense"} -- Stat ที่ต้องการสำหรับ Sword
    local stats = player:WaitForChild("Data"):WaitForChild("Stats")
    local needRefund = false

    -- เช็คว่ามี Stat ไหนต่ำกว่าเกณฑ์บ้าง
    for _, statName in ipairs(statsToFix) do
        local stat = stats:FindFirstChild(statName)
        if stat and stat:FindFirstChild("Level") then
            if stat.Level.Value < STAT_REQUIRED_LEVEL then
                needRefund = true
                print(statName .. " ต่ำกว่าเกณฑ์: " .. stat.Level.Value .. "/" .. STAT_REQUIRED_LEVEL)
                break
            end
        end
    end

    -- ถ้าจำเป็นต้อง Refund
    if needRefund then
        print("Stats ไม่ถูกต้อง กำลัง Refund...")
        refundStat()
        task.wait(1)

        -- อัป Stat คืนกลับ
        for _, statName in ipairs(statsToFix) do
            print("กำลังอัป Stat: " .. statName)
            CommF_:InvokeServer("AddPoint", statName, 9999)
            task.wait(0.5)
        end
        print("Fix Stats เสร็จสิ้น")
    else
        print("Stats ถูกต้องอยู่แล้ว")
    end
end

-- ฟังก์ชันเช็คว่าดาบทุกอันครบหรือยัง
local function allSwordsDone()
    local inventory = getInventory()
    for _, weapon in pairs(inventory) do
        if type(weapon) == "table" and weapon.Type == "Sword" then
            local mastery = weapon.Mastery or 0
            local maxReq = getMaxRequirement(weapon.MasteryRequirements or {})
            if mastery < maxReq then
                return false
            end
        end
    end
    return true
end

-- ฟังก์ชันหาดาบที่ยังไม่ครบ
local function getNextUnfinishedSword()
    local inventory = getInventory()
    for _, weapon in pairs(inventory) do
        if type(weapon) == "table" and weapon.Type == "Sword" then
            local mastery = weapon.Mastery or 0
            local maxReq = getMaxRequirement(weapon.MasteryRequirements or {})
            if mastery < maxReq then
                return weapon, mastery, maxReq
            end
        end
    end
    return nil
end

-- ฟังก์ชันอัปเดต Description
local function updateDescription(swordName, currentMastery, maxReq)
    local json_data = {
        SwordName = swordName,
        Mastery = currentMastery,
        Required = maxReq
    }
    local encoded = HttpService:JSONEncode(json_data)
    local message = "⚔️ Sword : " .. swordName .. " Mastery : " .. currentMastery .. "/" .. maxReq
    _G.Horst_SetDescription(message, encoded)
end

-- Main Loop
print("Starting Mastery Checker...")
fixStats() -- เช็ค Stat ก่อนเริ่มเลย

while not allSwordsDone() do
    local sword, mastery, maxReq = getNextUnfinishedSword()

    if sword then
        equipSword(sword.Name)
        updateDescription(sword.Name, mastery, maxReq)

        repeat
            task.wait(5)
            local inventory = getInventory()
            for _, weapon in pairs(inventory) do
                if type(weapon) == "table" and weapon.Name == sword.Name then
                    local currentMastery = weapon.Mastery or 0
                    local currentMaxReq = getMaxRequirement(weapon.MasteryRequirements or {})

                    updateDescription(sword.Name, currentMastery, currentMaxReq)
                    print("Waiting... " .. sword.Name .. " Mastery: " .. currentMastery .. " / " .. currentMaxReq)

                    if currentMastery >= currentMaxReq then
                        print(sword.Name .. " Complete!")
                        sword = nil
                    end
                end
            end
        until sword == nil
    end

    task.wait(1)
end

-- ทุกดาบครบแล้ว
print("All swords Complete!")
_G.Horst_SetDescription("⚔️ All Swords Mastery Complete!")

local ok, err = _G.Horst_AccountChangeDone()
if ok then
    print("Done sent successfully!")
else
    print("Failed to send Done: " .. tostring(err))
end
