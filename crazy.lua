-- ==========================================================
-- Anime Adventures Account Monitor Script + UI In-Game
-- ==========================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Configurações do seu Painel / Servidor
local API_ENDPOINT = "http://localhost:3000/api/update"
local SECRET_KEY = "AA_Panel_Secr3t_Key_2026!#$@"
local INTERVALO_SEGUNDOS = 15

local httpRequest = (syn and syn.request) or (http and http.request) or request or http_request

if not httpRequest then
    warn("[ Painel Bot ] Seu executor não suporta requisições HTTP!")
    return
end

-- ==========================================================
-- CRIAR INTERVISUALIZAÇÃO (UI) DENTRO DO JOGO
-- ==========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AAPanelMonitorUI"
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 90)
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
title.Text = "📊 AA Monitor Status"
title.TextColor3 = Color3.fromRGB(56, 189, 248)
title.TextSize = 14
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 45)
statusLabel.Position = UDim2.new(0, 10, 0, 35)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Iniciando monitoramento..."
statusLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = frame

-- ==========================================================
-- FUNÇÃO DE COLETA E ENVIO
-- ==========================================================
local function getPlayerStats()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")

    local gems = leaderstats and leaderstats:FindFirstChild("Gems") and leaderstats.Gems.Value or 0
    local dices = leaderstats and leaderstats:FindFirstChild("Dices") and leaderstats.Dices.Value or 0
    local traitRerolls = leaderstats and leaderstats:FindFirstChild("TraitRerolls") and leaderstats.TraitRerolls.Value or 0

    local summerGems = 0
    if leaderstats and leaderstats:FindFirstChild("SummerGems") then
        summerGems = leaderstats.SummerGems.Value
    elseif playerGui and playerGui:FindFirstChild("MainUI") then
        local summerCurrencyLabel = playerGui.MainUI:FindFirstChild("SummerCurrency", true)
        if summerCurrencyLabel and summerCurrencyLabel:IsA("TextLabel") then
            summerGems = tonumber((summerCurrencyLabel.Text:gsub("%D+", ""))) or 0
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

    if not success then
        statusLabel.Text = "Status: Erro ao codificar JSON"
        statusLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
        return
    end

    local reqSuccess, response = pcall(function()
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
        statusLabel.Text = "Status: 🟢 Enviado com sucesso!\nGems: " .. data.gems
        statusLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
    else
        statusLabel.Text = "Status: 🔴 Erro de conexão com API"
        statusLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
    end
end

-- Executar em loop
task.spawn(function()
    while true do
        sendDataToDashboard()
        task.wait(INTERVALO_SEGUNDOS)
    end
end)
