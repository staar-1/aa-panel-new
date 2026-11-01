-- ==========================================================
-- Anime Adventures Monitor - Correção de Leitura de Recursos
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

-- Criar Caixinha Visual
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
title.Text = "📊 AA Monitor - Ativo"
title.TextColor3 = Color3.fromRGB(56, 189, 248)
title.TextSize = 13
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 70)
statusLabel.Position = UDim2.new(0, 10, 0, 30)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Lendo recursos..."
statusLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = frame

local function getPlayerStats()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    
    local gems = 0
    local dices = 0
    local traitRerolls = 0
    local summerGems = 0

    if leaderstats then
        for _, v in ipairs(leaderstats:GetChildren()) do
            local name = v.Name:lower()
            local val = tonumber(v.Value) or 0
            
            -- Imprime no F9 para termos certeza absoluta do nome exato
            print("[AA DEBUG] Item encontrado -> Nome:", v.Name, "| Valor:", val)

            if name:find("gem") and not name:find("summer") and not name:find("pearl") then
                gems = val
            elseif name:find("summer") or name:find("pearl") or name:find("event") then
                summerGems = val
            elseif name:find("dice") or name:find("dados") then
                dices = val
            elseif name:find("reroll") or name:find("trait") then
                traitRerolls = val
            end
        end
    else
        warn("[AA DEBUG] Pasta leaderstats não encontrada!")
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
