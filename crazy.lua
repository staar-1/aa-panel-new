-- ==========================================================
-- Anime Adventures Monitor - Leitor Direto da Interface (UI)
-- ==========================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local API_ENDPOINT = "http://localhost:3000/api/update"
local SECRET_KEY = "AA_Panel_Secr3t_Key_2026!#$@"
local INTERVALO_SEGUNDOS = 15

local httpRequest = (syn and syn.request) or (http and http.request) or request or http_request

if not httpRequest then
    warn("[ Painel Bot ] Seu executor não suporta requisições HTTP!")
    return
end

-- Criar Caixinha Visual de Status
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AAPanelMonitorUI"
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 110)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "📊 AA Monitor - UI Reader"
title.TextColor3 = Color3.fromRGB(56, 189, 248)
title.TextSize = 13
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 70)
statusLabel.Position = UDim2.new(0, 10, 0, 30)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Lendo interface..."
statusLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = frame

-- Função para limpar e extrair apenas números do texto da UI
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

    if playerGui then
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                local parentName = gui.Parent and gui.Parent.Name:lower() or ""
                local textVal = gui.Text or ""
                
                -- Varredura por contexto nos nomes dos elementos da interface
                if parentName:find("gem") and gems == 0 then
                    gems = extractNumber(textVal)
                elseif (parentName:find("summer") or parentName:find("pearl")) and summerGems == 0 then
                    summerGems = extractNumber(textVal)
                elseif parentName:find("dice") and dices == 0 then
                    dices = extractNumber(textVal)
                elseif (parentName:find("reroll") or parentName:find("trait")) and traitRerolls == 0 then
                    traitRerolls = extractNumber(textVal)
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

    local reqSuccess, _ = pcall(function()
        return httpRequest({
            Url = API_ENDPOINT,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = SECRET_KEY
            },
            Body = payload
        })
    end)

    if reqSuccess then
        statusLabel.Text = string.format("Gems: %d | Rerolls: %d\nDices: %d | Summer: %d\nStatus: 🟢 Enviado!", data.gems, data.traitRerolls, data.dices, data.summerGems)
        statusLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
    else
        statusLabel.Text = "Status: 🔴 Erro de conexão com API"
        statusLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
    end
end

task.spawn(function()
    while true do
        sendDataToDashboard()
        task.wait(INTERVALO_SEGUNDOS)
    end
end)
