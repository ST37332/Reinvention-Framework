re.FACTION = re.FACTION or {}
re.FACTION.List = {}      
re.FACTION.DefaultID = nil

function re.FACTION:Register(tbl)
  if not istable(tbl) then
    ErrorNoHalt("[FACTION] Attempt to register a non-table!\n")
    return
  end
  if not tbl.uniqueID or type(tbl.uniqueID) ~= "string" then
    ErrorNoHalt("[FACTION] Faction without a unique ID, skipped.\n")
    return
  end
  if self.List[tbl.uniqueID] then
    ErrorNoHalt("[FACTION] Faction with ID '" .. tbl.uniqueID .. "' already exists. Skipped.\n")
    return
  end

  tbl.name        = tbl.name or "Unknown"
  tbl.description = tbl.description or ""
  tbl.color       = tbl.color or Color(255,255,255)
  tbl.model       = tbl.model or "models/player/kleiner.mdl"
  tbl.default     = tbl.default or false

  if tbl.default then
    if self.DefaultID and self.DefaultID ~= tbl.uniqueID then
      ErrorNoHalt(string.format(
        "[FACTION] Error: default! Already have '%s', now '%s'. The first one is left as standard.\n",
        self.DefaultID, tbl.uniqueID
      ))
      tbl.default = false
    else
      self.DefaultID = tbl.uniqueID
    end
  end
  
  team.SetUp(tbl.uniqueID, tbl.name, tbl.color, tbl.default)

  self.List[tbl.uniqueID] = tbl
end

function re.FACTION:Get(id)
  return self.List[id]
end

function re.FACTION:GetAll()
  local out = {}
  for id, fac in pairs(self.List) do
    out[id] = {
      uniqueID    = id,
      name        = fac.name,
      description = fac.description,
      color       = fac.color,
      model       = fac.model,
      default     = fac.default
    }
  end
  return out
end
