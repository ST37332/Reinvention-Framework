re.option = {}
re.option.keys = {}
re.option.sounds = {}

-- A function to set a schema key.
function re.option:SetKey(key, value)
	self.keys[key] = value
end

-- A function to get a schema key.
function re.option:GetKey(key, lowerValue)
	local value = self.keys[key]
	
	if (lowerValue and type(value) == "string") then
		return string.lower(value)
	else
		return value
	end
end

-- A function to set a schema sound.
function re._kernel:SetSound(name, sound)
	self.sounds[name] = sound
end

-- A function to get a schema sound.
function re._kernel:GetSound(name)
	return self.sounds[name]
end

-- A function to play a schema sound.
function re._kernel:PlaySound(name)
	local sound = self:GetSound(name)
	
	if (sound) then
		if (CLIENT) then
			surface.PlaySound(sound)
		else
			re.player:PlaySound(nil, sound)
		end
	end
end

re.option:SetKey( "default_date", {month = 1, year = 2010, day = 1} )
re.option:SetKey( "default_time", {minute = 0, hour = 0, day = 1} )
re.option:SetKey( "default_days", {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"} )
re.option:SetKey("description_business", "Order items for your business.")
re.option:SetKey("description_inventory", "Manage the items in your inventory.")
re.option:SetKey("description_directory", "A directory of various topics and information.")
re.option:SetKey("description_admin", "Access a variety of server-side options.")
re.option:SetKey("description_attributes", "Check the status of your attributes.")
re.option:SetKey("model_shipment", "models/items/item_item_crate.mdl")
re.option:SetKey("model_cash", "models/props_c17/briefcase001a.mdl")
re.option:SetKey("format_singular_cash", "$%a")
re.option:SetKey("format_cash", "$%a")
re.option:SetKey("name_attributes", "Attributes")
re.option:SetKey("name_attribute", "Attribute")
re.option:SetKey("name_re", "RE: Frame")
re.option:SetKey("name_directory", "Directory")
re.option:SetKey("name_inventory", "Inventory")
re.option:SetKey("name_business", "Business")
re.option:SetKey("name_destroy", "Destroy")
re.option:SetKey("schema_logo", "")
re.option:SetKey("intro_image", "")
re.option:SetKey("menu_music", "music/hl2_song32.mp3")
re.option:SetKey("name_cash", "Cash")
re.option:SetKey("name_drop", "Drop")
re.option:SetKey("top_bars", false)
re.option:SetKey("name_use", "Use")
re.option:SetKey("gradient", "gui/gradient_up")

re._kernel:SetSound("click_release", "ui/buttonclickrelease.wav")
re._kernel:SetSound("rollover", "ui/buttonrollover.wav")
re._kernel:SetSound("click", "ui/buttonclick.wav")

if (CLIENT) then
	re._kernel.fonts = {}
	re._kernel.colors = {}

	-- A function to set a schema color.
	function re._kernel:SetColor(name, color)
		self.colors[name] = color
	end

	-- A function to get a schema color.
	function re._kernel:GetColor(name)
		return self.colors[name]
	end

	-- A function to set a schema font.
	function re._kernel:SetFont(name, font)
		self.fonts[name] = font
	end

	-- A function to get a schema font.
	function re._kernel:GetFont(name)
		return self.fonts[name]
	end

	re._kernel:SetColor( "positive_hint", Color(100, 175, 100, 255) )
	re._kernel:SetColor( "negative_hint", Color(175, 100, 100, 255) )
	re._kernel:SetColor( "information", Color(100, 50, 50, 255) )
	re._kernel:SetColor( "background", Color(0, 0, 0, 125) )
	re._kernel:SetColor( "target_id", Color(50, 75, 100, 255) )
	re._kernel:SetColor( "white", Color(255, 255, 255, 255) )

	re._kernel:SetFont("schema_description", "re_MainText")
	re._kernel:SetFont("player_info_text", "re_MainText")
	re._kernel:SetFont("intro_text_small", "re_IntroTextSmall")
	re._kernel:SetFont("intro_text_tiny", "re_IntroTextTiny")
	re._kernel:SetFont("menu_text_small", "re_MenuTextSmall")
	re._kernel:SetFont("menu_text_huge", "re_MenuTextHuge")
	re._kernel:SetFont("intro_text_big", "re_IntroTextBig")
	re._kernel:SetFont("menu_text_tiny", "re_MenuTextTiny")
	re._kernel:SetFont("date_time_text", "re_MenuTextSmall")
	re._kernel:SetFont("cinematic_text", "re_CinematicText")
	re._kernel:SetFont("target_id_text", "re_MainText")
	re._kernel:SetFont("auto_bar_text", "re_MainText")
	re._kernel:SetFont("menu_text_big", "re_MenuTextBig")
	re._kernel:SetFont("chat_box_text", "re_MainText")
	re._kernel:SetFont("large_3d_2d", "re_Large3D2D")
	re._kernel:SetFont("hints_text", "re_IntroTextTiny")
	re._kernel:SetFont("main_text", "re_MainText")
	re._kernel:SetFont("bar_text", "re_MainText")
else
	--[[
		Backwards compatability, you shouldn't use this
		function for anything new.
	--]]
	function re._kernel:GetColor(name)
		return name
	end
end