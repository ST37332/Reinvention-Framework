GM.Name = 'Re:Framework'

DeriveGamemode('sandbox')
re = {
    _kernel = {},
    base = {},
    net = {},
    hash = {},
    basedir = GM.FolderName .. "/gamemode/"
}

re.SchemaFolder = re.Folder
re.BaseFolder = GM.Folder

include(re.basedir..'kernel/boot.lua')
if SERVER then
    AddCSLuaFile(re.basedir..'kernel/boot.lua')
end