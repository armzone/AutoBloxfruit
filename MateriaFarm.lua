repeat task.wait() until game:IsLoaded()

local Tasks = {
    {name = "Scrap Metal", amount = 47, script = {
        "https://raw.githubusercontent.com/armzone/BananaConfig/refs/heads/main/ScrapMetal.lua"
    }},
    {name = "Blaze Ember", amount = 60, script = {
        "https://raw.githubusercontent.com/armzone/BananaConfig/refs/heads/main/BlazeEmber.lua"
    }},
    {name = "Dragon Scale", amount = 8, script = {
        "https://raw.githubusercontent.com/armzone/BananaConfig/refs/heads/main/DragonScal.lua"
    }}
}

local function GetItemCount(itemName)
    local ok, inventory = pcall(function()
        return game:GetService("ReplicatedStorage")
            .Remotes["CommF_"]
            :InvokeServer("getInventory")
    end)
    if not ok or type(inventory) ~= "table" then
        warn("GetItemCount failed for: " .. itemName)
        return 0
    end
    local count = 0
    for _, v in pairs(inventory) do
        if v.Name == itemName then
            count += (v.Count or 0)
        end
    end
    return count
end

local function Rejoin()
    local TeleportService = game:GetService("TeleportService")
    local plr = game:GetService("Players").LocalPlayer
    TeleportService:Teleport(game.PlaceId, plr)
end

for _, taskData in ipairs(Tasks) do
    local current = GetItemCount(taskData.name)

    if current >= taskData.amount then
        print(taskData.name .. " krob laew kham pai")
    else
        print("Loading farm: " .. taskData.name)
        for _, url in ipairs(taskData.script) do
            local fn, err = loadstring(game:HttpGet(url))
            if fn then
                task.spawn(fn)
            else
                warn("loadstring error: " .. tostring(err))
            end
        end

        while true do
            local cur = GetItemCount(taskData.name)
            print(taskData.name .. " : " .. cur .. "/" .. taskData.amount)
            if cur >= taskData.amount then break end
            task.wait(5)
        end

        print(taskData.name .. " krob laew! Rejoining...")
        task.wait(2)
        Rejoin()
        return
    end
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
