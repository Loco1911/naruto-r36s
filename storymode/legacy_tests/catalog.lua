local catalogStr = main.f_fileRead("data/storymode/catalog.json")
if catalogStr == "" then
    return {}
end
local ok, decoded = pcall(function() return json.decode(catalogStr) end)
if not ok then return {} end
return decoded
