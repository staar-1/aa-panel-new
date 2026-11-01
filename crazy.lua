-- ==========================================================
-- Anime Adventures Monitor - Captura de Moedas + Portais
-- ==========================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local API_ENDPOINT = "http://localhost:3000/api/update"
local SECRET_KEY = "AA_Panel_Secr3t_Key_2026!#$@"
local INTERVALO_SEGUNDOS = 15

local httpRequest = (syn and syn.request) or (http and http.request) or request or http_request

if not httpRequest then return end

-- Criar Caixinha Visual de Status
local screenGui = CoreGui:FindFirstChild("AAPanelMonitorUI") or Instance.new("ScreenGui")
screenGui.Name = "AAPanelMonitorUI"
screenGui.Parent = CoreGui

local frame = screenGui:FindFirstChild("Frame") or Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 130)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
frame.BorderSizePixel = 0
frame.Parent = screenGui

if not frame:FindFirstChild("UICorner") then
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
end

local title = frame:FindFirstChild("Title") or Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "📊 AA Monitor - Full Stats"
title.TextColor3 = Color3.fromRGB(56, 189, 248)
title.TextSize = 13
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

local statusLabel = frame:FindFirstChild("StatusLabel") or Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 90)
statusLabel.Position = UDim2.new(0, 10, 0, 30)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = frame

local function extractNumber(text)
    if not text then return 0 end
    local cleanText = text:gsub("[^%d]", "")
    return tonumber(cleanText) or 0
end

local function getPlayerStats()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local gems = 0
    local dices = 0
    local traitRerolls = 0
    local summerGems = 0
    local skyPortals = 0

    if playerGui then
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                local parentName = gui.Parent and gui.Parent.Name:lower() or ""
                local fullName = gui:GetFullName():lower()
                local textVal = gui.Text or ""
                local textLower = textVal:lower()

                -- 1. Gems
                if (parentName:find("gem") or fullName:find("gem")) and gems == 0 and not parentName:find("summer") then
                    gems = extractNumber(textVal)
                
                -- 2. Summer Gems / Pearls
                elseif (parentName:find("summer") or parentName:find("pearl") or fullName:find("summer")) and summerGems == 0 then
                    summerGems = extractNumber(textVal)
                
                -- 3. Dices
                elseif (parentName:find("dice") or fullName:find("dice")) and dices == 0 then
                    dices = extractNumber(textVal)
                
                -- 4. Star Remnant (Trait Rerolls)
                elseif (parentName:find("star remnant") or fullName:find("star remnant") or textLower:find("star remnant")) and traitRerolls == 0 then
                    local parent = gui.Parent
                    if parent then
                        for _, sibling in ipairs(parent:GetChildren()) do
                            if sibling:IsA("TextLabel") and (sibling.Text:find("Qt") or sibling.Text:find("%d+")) then
                                local num = extractNumber(sibling.Text)
                                if num > 0 then
                                    traitRerolls = num
                                    break
                                end
                            end
                        end
                    end
                    if traitRerolls == 0 then
                        traitRerolls = extractNumber(textVal)
                    end

                -- 5. Sky Portals
                elseif (textLower:find("sky portal") or parentName:find("sky portal") or fullName:find("skyportal")) then
                    local parent = gui.Parent
                    if parent then
                        for _, sibling in ipairs(parent:GetChildren()) do
                            if sibling:IsA("TextLabel") and (sibling.Text:find("%[%d+") or sibling.Text:find("Qt")) then
                                local num = extractNumber(sibling.Text)
                                if num > 0 then
                                    skyPortals = skyPortals + num
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return {
        username = LocalPlayer.Name,
        userId = LocalPlayer.UserId,
        gems = gems,
        dices = dices,
        traitRerolls = traitRerolls,
        summerGems = summerGems,
        skyPortals = skyPortals,
        jobId = game.JobId,
        placeId = game.PlaceId,
        timestamp = os.time()
    }
end

local function sendDataToDashboard()
    local data = getPlayerStats()
    local success, payload = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if not success then return end

    pcall(function()
        httpRequest({
            Url = API_ENDPOINT,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = SECRET_KEY
            },
            Body = payload
        })
    end)

    statusLabel.Text = string.format("Gems: %d | Remnant: %d\nSummer: %d | Sky Portals: %d\nStatus: 🟢 Sincronizado!", data.gems, data.traitRerolls, data.summerGems, data.skyPortals)
end

task.spawn(function()
    while true do
        sendDataToDashboard()
        task.wait(INTERVALO_SEGUNDOS)
    end
end)
