include("sh_init.lua")

function ENT:HUDPaintTargetID(x, y, alpha)
	local colorTargetID = openAura.option:GetColor("target_id")
	local colorWhite = openAura.option:GetColor("white")
	local index = self:GetDTInt("index")
	
	if (index != 0) then
		local itemTable = openAura.item:Get(index)
		
		if (itemTable) then
			local color = itemTable.color or colorTargetID
			
			if (itemTable.OnHUDPaintTargetID and itemTable:OnHUDPaintTargetID(self, x, y, alpha) == false) then
				return
			end
			
			y = openAura:DrawInfo(itemTable.name, x, y, color, alpha)
			
			if (itemTable.weightText) then
				y = openAura:DrawInfo(itemTable.weightText, x, y, colorWhite, alpha)
			else
				y = openAura:DrawInfo(itemTable.weight.."kg", x, y, colorWhite, alpha)
			end
		end
	end
end

function ENT:Think()
	local itemTable = self.itemTable
	
	if (itemTable) then
		if (itemTable.OnEntityThink) then
			local nextThink = itemTable:OnEntityThink(self)
			
			if (type(nextThink) == "number") then
				self:NextThink(CurTime() + nextThink)
			end
		end
		
		openAura.plugin:Call("OpenAuraItemEntityThink", itemTable, self)
	end
end

function ENT:Draw()
	local drawModel = true
	local index = self:GetDTInt("index")
	
	if (index != 0) then
		local itemTable = openAura.item:Get(index)
		
		if (itemTable) then
			if (itemTable.OnDrawModel and itemTable:OnDrawModel(self) == false) then
				drawModel = false
			end
			
			if (openAura.plugin:Call("OpenAuraItemEntityDraw", itemTable, self) == false) then
				drawModel = false
			end
		end
	end
	
	if (drawModel) then
		self:DrawModel()
	end
end