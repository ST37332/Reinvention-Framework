GM.Name = 'Re:Framework'

DeriveGamemode('sandbox')
re = {
    _kernel = {},
    base = {},
    net = {},
    hash = {},
    basedir = GM.FolderName .. "/gamemode/"
}

include(re.basedir..'kernel/boot.lua')
if SERVER then
    AddCSLuaFile(re.basedir..'kernel/boot.lua')
end