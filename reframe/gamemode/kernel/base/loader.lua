local kernel = kernel or {} 

kernel._included = kernel._included or {}
kernel._includeCache = kernel._includeCache or {}

local fileFind = file.Find
local includeFunc = include
local addCSLua = AddCSLuaFile
local SERVER = SERVER
local CLIENT = CLIENT

--[[
 Includes a Lua file with automatic scope detection (server/client/shared) based on the name prefix.
 @param fileName string The path to the file relative to the current context (or absolute if it starts with @)
 @param realm string? Force the scope to be set to "server", "client", or "shared". If not specified, it is determined based on the name.
 @return any The result of include() (usually the return value of the file)
]]
function kernel.Include(fileName, realm)
    if not fileName or fileName == "" then
        error("[RE] No file name specified for inclusion.", 2)
    end

    local cleanName = fileName:gsub("^@gamemode/", ""):gsub("^@", "")

    if kernel._included[cleanName] then
        return kernel._included[cleanName]
    end

    if not realm then
        if cleanName:find("sv_") then
            realm = "server"
        elseif cleanName:find("cl_") then
            realm = "client"
        elseif cleanName:find("sh_") or cleanName:find("shared%.lua$") then
            realm = "shared"
        else
            realm = "shared"
        end
    end

    local result

    if realm == "server" then
        if SERVER then
            result = includeFunc(fileName)
            kernel._included[cleanName] = result
        end
    elseif realm == "client" then
        if SERVER then
            addCSLua(fileName)
        elseif CLIENT then
            result = includeFunc(fileName)
            kernel._included[cleanName] = result
        end
    elseif realm == "shared" then
        if SERVER then
            addCSLua(fileName)
        end
        result = includeFunc(fileName)
        kernel._included[cleanName] = result
    else
        error("[RE] Invalid realm '" .. tostring(realm) .. "' for file: " .. fileName, 2)
    end

    return result
end

--[[
 Includes all Lua files from the specified directory (not recursively).
 @param directory string The path to the folder relative to the base directory (see baseDir)
 @param bFromLua bool If true, the search is performed from the Lua root (gamemode/ folder). Otherwise, from the schema/gamemod folder.
 @param bRecursive bool If true, subfolders are recursively traversed (optional).
]]
function kernel.IncludeDir(directory, bFromLua, bRecursive)
    if not directory or directory == "" then
        error("[RE] No directory specified for inclusion.", 2)
    end

    local baseDir
    if bFromLua then
        baseDir = ""
    else
        //if Schema and Schema.folder and Schema.loading then
        //    baseDir = Schema.folder .. "/schema/"
        //else
            baseDir = "reframe/gamemode/"
        //end
    end

    local fullPath = baseDir .. directory
    fullPath = fullPath:gsub("//+", "/")

    local files, folders = fileFind(fullPath .. "/*.lua", "LUA")

    for _, fileName in ipairs(files) do
        kernel.Include(directory .. "/" .. fileName)
    end

    if bRecursive then
        for _, folderName in ipairs(folders) do
            kernel.IncludeDir(directory .. "/" .. folderName, bFromLua, true)
        end
    end
end

function kernel.ClearIncludeCache()
    kernel._included = {}
    kernel._includeCache = {}
end

function kernel.GetIncludedFiles()
    return table.GetKeys(kernel._included)
end

function kernel.ReloadFile(fileName, realm)
    kernel._included[fileName:gsub("^@gamemodes/", ""):gsub("^@", "")] = nil
    return kernel.Include(fileName, realm)
end
re._kernel = kernel