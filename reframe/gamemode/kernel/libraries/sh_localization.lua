local Locale = Locale or {}

Locale.localizations = Locale.localizations or {}
Locale.current = Locale.current or "en"

Locale.cache = Locale.cache or {}

Locale.folder = Locale.folder or "localization"

function Locale:Load(locale)
    locale = locale or self.current

    if self.cache[locale] then
        return self.cache[locale]
    end

    local path = self.folder .. "/" .. locale .. ".yml"
    if not file.Exists(path, "GAME") then
        path = self.folder .. "/" .. locale .. ".yaml"
        if not file.Exists(path, "GAME") then
            ErrorNoHalt("[Locale] Localization file not found: " .. locale .. "\n"..path)
            return {}
        end
    end

    local content = file.Read(path, "GAME")
    if not content then
        return {}
    end

    local ok, data = pcall(re.yaml.Eval, content)
    if not ok then
        ErrorNoHalt("[Locale] Failed to parse " .. locale .. ": " .. tostring(data) .. "\n")
        return {}
    end

    self.localizations[locale] = data
    self.cache[locale] = data
    return data
end

function Locale:LoadAll()
    local files, _ = file.Find(self.folder .. "/*.yml", "GAME")
    local yaml_files, _ = file.Find(self.folder .. "/*.yaml", "GAME")

    for _, fname in ipairs(files) do
        local locale = fname:match("^(.*)%.yml$")
        self:Load(locale)
    end
    for _, fname in ipairs(yaml_files) do
        local locale = fname:match("^(.*)%.yaml$")
        self:Load(locale)
    end
end

function Locale:SetLocalization(locale)
    if not self.localizations[locale] then
        self:Load(locale)
    end
    self.current = locale
    hook.Run("LocaleChanged", locale)
end

function Locale:GetLocalization()
    return self.current
end

function Locale:Get(key, replacements)
    local locale = self.current
    local data = self.localizations[locale] or self:Load(locale)
    if not data then
        return key
    end

    local value = data
    for part in key:gmatch("[^%.]+") do
        if type(value) == "table" then
            value = value[part]
        else
            value = nil
            break
        end
    end

    if value == nil then
        return key
    end

    if type(value) == "string" and replacements and type(replacements) == "table" then
        value = value:gsub("{([%w_]+)}", function(var)
            return tostring(replacements[var] or "")
        end)
    end

    return value
end

function Locale:Translate(key, ...)
    return self:Get(key, ...)
end

function Locale:GetTable(locale)
    locale = locale or self.current
    return self.localizations[locale] or self:Load(locale)
end

function Locale:DetectLocalization()
    local cl_locale = GetConVar("gmod_language"):GetString():lower()
    local map = {
        ["en"] = "en",
        ["ru"] = "ru",
        ["fr"] = "fr",
        ["de"] = "de",
    }
    local detected = map[cl_locale] or "en"
    return detected
end

function Locale:AutoInit()
    self:LoadAll()
    local locale = self:DetectLocalization()
    self:SetLocalization(locale)
end

cvars.AddChangeCallback("gmod_language", function(_, _, new)
    local locale = new:lower():match("^(%a%a)")
    if locale and re.Locale.localizations[locale] then
        re.Locale:SetLocalization(locale)
    end
end)

_G.L = function(key, replacements)
    return re.Locale:Get(key, replacements)
end


re.Locale = Locale