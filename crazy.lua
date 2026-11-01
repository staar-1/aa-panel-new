-- ==========================================================
-- Anime Adventures Account Monitor Script
-- ==========================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configurações do seu Painel / Servidor
local API_ENDPOINT = "http://localhost:3000/api/update"
local SECRET_KEY = "AA_Panel_Secr3t_Key_2026!#$@"
local INTERVALO_SEGUNDOS = 30

-- Função para identificar a função de requisição do executor (compatibilidade)
local httpRequest = (syn and syn.request) or (http and http.request) or request or http_request

if not httpRequest then
    warn("[ Painel Bot ] Seu executor não suporta requisições HTTP!")
    return
end

-- Função para buscar valores dos recursos no Anime Adventures
local function getPlayerStats()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")

    -- 1. Valores do Leaderstats (Padrão)
    local gems = leaderstats and leaderstats:FindFirstChild("Gems") and leaderstats.Gems.Value or 0
    local dices = leaderstats and leaderstats:FindFirstChild("Dices") and leaderstats.Dices.Value or 0
    local traitRerolls = leaderstats and leaderstats:FindFirstChild("TraitRerolls") and leaderstats.TraitRerolls.Value or 0

    -- 2. Tentar buscar Summer Gems / Event Gems na Interface (UI) caso não esteja no leaderstats
    local summerGems = 0
    if leaderstats and leaderstats:FindFirstChild("SummerGems") then
        summerGems = leaderstats.SummerGems.Value
    elseif playerGui and playerGui:FindFirstChild("MainUI") then
        -- Exemplo de fallback buscando direto na UI se o evento utilizar elemento visual
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

-- Função para enviar os dados via POST
local function sendDataToDashboard()
    local data = getPlayerStats()
    local payload = HttpService:JSONEncode(data)

    local success, response = pcall(function()
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

    if success then
        print("[ Painel Bot ] Dados enviados com sucesso para " .. LocalPlayer.Name)
    else
        warn("[ Painel Bot ] Erro ao enviar dados:", response)
    end
end

-- Notificação na tela confirmando que o monitor foi carregado
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Painel Monitor",
        Text = "Script de monitoramento ativado!",
        Duration = 5
    })
end)

-- Loop Infinito executando em Thread separada
task.spawn(function()
    while true do
        sendDataToDashboard()
        task.wait(INTERVALO_SEGUNDOS)
    end
end)