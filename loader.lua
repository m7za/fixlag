if _G.M7ZA_LoaderRan then return end
_G.M7ZA_LoaderRan = true

local games = {
    [10449761463] = "https://raw.githubusercontent.com/m7za1/fixlagbym7za/refs/heads/main/tsbg.lua",
    [15269951959] = "https://raw.githubusercontent.com/m7za1/fixlagbym7za/refs/heads/main/lbg.lua"
}

local url = games[game.PlaceId]

if url then
    pcall(function()
        loadstring(game:HttpGet(url))()
    end)
end
