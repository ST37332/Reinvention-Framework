include('base/util.lua')
if SERVER then
    AddCSLuaFile('base/util.lua')
end


re._kernel.IncludeDir("libraries")
re._kernel.Include("base/cl_draws.lua")
re.Locale:AutoInit()