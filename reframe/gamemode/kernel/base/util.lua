re._kernel._included = re._kernel._included or {}
re._kernel._includeCache = re._kernel._includeCache or {}
re._kernel.Timers = {}
re._kernel.hooks = {}
re._kernel.stored = {}

local fileFind = file.Find
local includeFunc = include
local addCSLua = AddCSLuaFile
local SERVER = SERVER
local CLIENT = CLIENT
local playerMeta = FindMetaTable('Player')
		
function playerMeta:SetNetVar(key, value)
    local valueType = type(value)

    if valueType == "boolean" then
        self:SetNWBool(key, value)
    elseif valueType == "number" then
        if math.floor(value) == value then
            self:SetNWInt(key, value)
        else
            self:SetNWFloat(key, value)
        end
    elseif valueType == "string" then
        self:SetNWString(key, value)
    elseif valueType == "Vector" then
        self:SetNWVector(key, value)
    elseif valueType == "Angle" then
        self:SetNWAngle(key, value)
    elseif valueType == "Entity" and IsValid(value) then
        self:SetNWEntity(key, value)
    else
        error("SetNetVar: Unsupported type " .. valueType)
    end
end

function playerMeta:SetSharedVar(key, value)
	return self:SetNetVar(key, value)
end

function playerMeta:GetSharedVar(key, default)
    local val = self:GetNWString(key, nil)
    return val or default
end

function re:GetLogTypeColor(logType)
	local logTypes = {
		Color(255, 50, 50, 255),
		Color(255, 150, 0, 255),
		Color(255, 200, 0, 255),
		Color(0, 150, 255, 255),
		Color(0, 255, 125, 255)
	};
	
	return logTypes[logType] or logTypes[5];
end;

function re:GetCoreVersion()
	return self.CoreVersion;
end;

function re:GetBaseFolder()
	local folder = string.gsub(self.BaseFolder, "gamemodes/", "");
	
	if (folder) then
		return folder;
	end;
end;

function re:GetSchemaFolder()
	local folder = string.gsub(self.SchemaFolder, "gamemodes/", "");
	
	if (folder) then
		return folder;
	end;
end;

function re._kernel:UnpackColor(color)
	return color.r, color.g, color.b, color.a
end

local MAGIC_CHARACTERS = "([%(%)%.%%%+%-%*%?%[%^%$])"

function re._kernel:Replace(text, find, replace)
	return ( text:gsub(find:gsub(MAGIC_CHARACTERS, "%%%1"), replace) )
end

function re._kernel:NewMetaTable(base)
	local object = {}
	
	setmetatable(object, base)
	
	base.__index = base
	
	return object
end

hook.RECall = hook.Call

local CurTime = CurTime
local hook = hook


function re._kernel:IsHookCached(name)
    return self.hooks[name] ~= nil
end

function re._kernel:CacheHook(name)
    if not self:IsHookCached(name) then
        self.hooks[name] = {}
        for _, module in pairs(self.modules) do
            local hookFunc = module[name]
            if hookFunc and type(hookFunc) == "function" then
                table.insert(self.hooks[name], hookFunc)
            end
        end
    end
    return self.hooks[name]
end

function re._kernel:CallCachedHook(name, callGamemodeHook, ...)
    local cachedHooks = self:CacheHook(name)
    for _, hookFunc in ipairs(cachedHooks) do
        local value = hookFunc(...)
        if value ~= nil then
            return value
        end
    end

    if callGamemodeHook then
        local gmHook = re[name]
        if gmHook and type(gmHook) == "function" then
            local value = gmHook(re, ...)
            if value ~= nil then
                return value
            end
        end
    end
end

function re._kernel:Call(name, ...)
    return self:CallCachedHook(name, true, ...)
end

function hook.Call(name, gamemode, ...)
	re.Client = LocalPlayer()
	
	if (!gamemode) then
		gamemode = re
	end
	
	local hookCall = hook.RECall
	local value = re._kernel:CallCachedHook(name, nil, ...)
	
	if (value == nil) then
		return hookCall(name, gamemode, ...)
	else
		return value
	end
end


function re._kernel:CallTimerThink(curTime)
	for k, v in pairs(self.Timers) do
		if (!v.paused) then
			if (curTime >= v.nextCall) then
				local success, value = pcall( v.Callback, unpack(v.arguments) )
				
				if (!success) then
					ErrorNoHalt("RE -> the "..tostring(k).." timer has failed to run.")
					ErrorNoHalt(value)
				end
				
				v.nextCall = curTime + v.delay
				v.calls = v.calls + 1
				
				if (v.calls == v.repetitions) then
					self.Timers[k] = nil
				end
			end
		end
	end
end

-- A function to get whether a timer exists.
function re._kernel:TimerExists(name)
	return self.Timers[name]
end

-- A function to start a timer.
function re._kernel:StartTimer(name)
	if (self.Timers[name] and self.Timers[name].paused) then
		self.Timers[name].nextCall = CurTime() + self.Timers[name].timeLeft
		self.Timers[name].paused = nil
	end
end

-- A function to pause a timer.
function re._kernel:PauseTimer(name)
	if (self.Timers[name] and !self.Timers[name].paused) then
		self.Timers[name].timeLeft = self.Timers[name].nextCall - CurTime()
		self.Timers[name].paused = true
	end
end


-- A function to destroy a timer.
function re._kernel:DestroyTimer(name)
	self.Timers[name] = nil
end

-- A function to create a timer.
function re._kernel:CreateTimer(name, delay, repetitions, Callback, ...)
	self.Timers[name] = {
		calls = 0,
		delay = delay,
		nextCall = CurTime() + delay,
		Callback = Callback,
		arguments = {...},
		repetitions = repetitions
	}
end

--[[
 Includes a Lua file with automatic scope detection (server/client/shared) based on the name prefix.
 @param fileName string The path to the file relative to the current context (or absolute if it starts with @)
 @param realm string? Force the scope to be set to "server", "client", or "shared". If not specified, it is determined based on the name.
 @return any The result of include() (usually the return value of the file)
]]
function re._kernel:Include(fileName, realm)
    if not fileName or fileName == "" then
        error("[RE] No file name specified for inclusion.", 2)
    end

    local cleanName = fileName:gsub("^@gamemode/", ""):gsub("^@", "")

    if re._kernel._included[cleanName] then
        return re._kernel._included[cleanName]
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
            re._kernel._included[cleanName] = result
        end
    elseif realm == "client" then
        if SERVER then
            addCSLua(fileName)
        elseif CLIENT then
            result = includeFunc(fileName)
            re._kernel._included[cleanName] = result
        end
    elseif realm == "shared" then
        if SERVER then
            addCSLua(fileName)
        end
        result = includeFunc(fileName)
        re._kernel._included[cleanName] = result
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
function re._kernel:IncludeDir(directory, bFromLua, bRecursive)
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
        re._kernel:Include(directory .. "/" .. fileName)
    end

    if bRecursive then
        for _, folderName in ipairs(folders) do
            re._kernel:IncludeDir(directory .. "/" .. folderName, bFromLua, true)
        end
    end
end

function re._kernel:ClearIncludeCache()
    re._kernel._included = {}
    re._kernel._includeCache = {}
end

function re._kernel:GetIncludedFiles()
    return table.GetKeys(re._kernel._included)
end

function re._kernel:ReloadFile(fileName, realm)
    re._kernel._included[fileName:gsub("^@gamemodes/", ""):gsub("^@", "")] = nil
    return re._kernel:Include(fileName, realm)
end

function re._kernel:GetShortCRC(value)
	return math.ceil(util.CRC(value) / 100000)
end



local NETWORKED_CLASS_TABLE = {
	[NWTYPE_STRING] = "String",
	[NWTYPE_ENTITY] = "Entity",
	[NWTYPE_VECTOR] = "Vector",
	[NWTYPE_NUMBER] = "Int",
	[NWTYPE_ANGLE] = "Angle",
	[NWTYPE_FLOAT] = "Float",
	[NWTYPE_BOOL] = "Bool"
}

function re._kernel:ConvertNetworkedClass(class)
	return NETWORKED_CLASS_TABLE[class]
end

function re._kernel:GetDefaultClassValue(class)
	local convertTable = {
		["String"] = "",
		["Entity"] = NULL,
		["Vector"] = Vector(0, 0, 0),
		["Int"] = 0,
		["Angle"] = Angle(0, 0, 0),
		["Float"] = 0.0,
		["Bool"] = false
	}
	
	return convertTable[class]
end

if SERVER then
    function re._kernel:StartDataStream(player, name, data)
		if (type(player) != "table") then
			if (!player) then
				player = _player.GetAll();
			else
				player = {player};
			end;
		end;
		
		local encodedData = rec.decode(data);
		local splitTable = self:SplitString(encodedData, 128);
		local players = RecipientFilter();
		
		for k, v in pairs(player) do
			if (type(v) == "Player") then
				players:AddPlayer(v);
			elseif (type(k) == "Player") then
				players:AddPlayer(k);
			end;
		end;
		
		if (#splitTable > 0) then
			umsg.Start("aura_dsStart", players);
				umsg.String(name);
				umsg.String( splitTable[1] );
				umsg.Short(#splitTable);
			umsg.End();
			
			if (#splitTable > 1) then
				for k, v in ipairs(splitTable) do
					if (k > 1) then
						umsg.Start("aura_dsData", players);
							umsg.String(v);
							umsg.Short(k);
						umsg.End();
					end;
				end;
			end;
		end;
	end;
    
	function re._kernel:ServerLog(text)
		ServerLog(text.."\n")
		
		if ( game.IsDedicated() ) then
			print(text)
		end
	end

	function re._kernel:PrintLog(logType, text)
		local recipientFilter = RecipientFilter()
		
		for k, v in ipairs( player.GetAll() ) do
			if (v:GetInfoNum("aura_showlog", 0) == 1) then
				if ( self.player:IsAdmin(v) ) then
					recipientFilter:AddPlayer(v)
				end
			end
		end
		
		umsg.Start("aura_Log", recipientFilter)
			umsg.Short(logType or 5)
			umsg.String(text)
		umsg.End()
		
		if ( AURA_CONVAR_LOG:GetInt() == 1 and game.IsDedicated() ) then
			self:ServerLog(text)
		end
	end
else
    function re._kernel:StartDataStream(name, data)
		local encodedData = rec.decode(data);
		local splitTable = self:SplitString(string.gsub(string.gsub(encodedData, "\\", "\\\\"), "\n", "\\n"), 128);
		
		if (#splitTable > 0) then
			RunConsoleCommand( "aura_dsStart", name, tostring(#splitTable) );
			
			for k, v in ipairs(splitTable) do
				RunConsoleCommand( "aura_dsData", v, tostring(k) );
			end;
		end;
	end;
end