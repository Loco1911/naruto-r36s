-- storymode/catalog.lua
local function log(msg)
    local f = io.open("storymode/debug.log", "a")
    if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. "[CATALOG] " .. msg .. "\n")
        f:close()
    end
end

log("Reading catalog.json")
local catalogStr = main.f_fileRead("storymode/catalog.json")
if not catalogStr or catalogStr == "" then 
    log("ERROR: catalog.json not found or empty")
    return {} 
end

log("Decoding JSON")
local ok, decoded = pcall(function() return json.decode(catalogStr) end)
if not ok then 
    log("ERROR: JSON decode failed: " .. tostring(decoded))
    return {} 
end

log("Catalog loaded successfully, chapters: " .. #decoded)
return decoded
