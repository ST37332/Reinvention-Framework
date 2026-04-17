include('base/loader.lua')
if SERVER then
    AddCSLuaFile('base/loader.lua')
end


re._kernel.IncludeDir("libraries")
re.Locale:AutoInit()