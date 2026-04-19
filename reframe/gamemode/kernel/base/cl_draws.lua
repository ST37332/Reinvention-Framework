function re:OverrideMainFont(font)
	if (font) then
		if (!self.PreviousMainFont) then
			self.PreviousMainFont = self._kernel:GetFont("main_text");
		end;
		
		self._kernel:SetFont("main_text", font);
	elseif (self.PreviousMainFont) then
		self._kernel:SetFont("main_text", self.PreviousMainFont)
	end;
end;

function re:GetScreenCenter()
	return ScrW() / 2, (ScrH() / 2) + 32;
end;

function re:GetCachedTextSize(font, text)
	if (!self.CachedTextSizes) then
		self.CachedTextSizes = {};
	end;
	
	if ( !self.CachedTextSizes[font] ) then
		self.CachedTextSizes[font] = {};
	end;
	
	if ( !self.CachedTextSizes[font][text] ) then
		surface.SetFont(font);
		
		self.CachedTextSizes[font][text] = { surface.GetTextSize(text) };
	end;
	
	return unpack( self.CachedTextSizes[font][text] );
end;

function openAura:CalculateAlphaFromDistance(maximum, start, finish)
	if (type(start) == "Player") then
		start = start:GetShootPos();
	elseif (type(start) == "Entity") then
		start = start:GetPos();
	end;
	
	if (type(finish) == "Player") then
		finish = finish:GetShootPos();
	elseif (type(finish) == "Entity") then
		finish = finish:GetPos();
	end;
	
	return math.Clamp(255 - ( (255 / maximum) * ( start:Distance(finish) ) ), 0, 255);
end;

-- A function to draw some simple text.
function re:DrawSimpleText(text, x, y, color, alignX, alignY, shadowless, shadowDepth)
	local mainTextFont = self._kernel:GetFont("main_text");
	local realX = math.Round(x);
	local realY = math.Round(y);
	
	if (!shadowless) then
		local outlineColor = Color( 25, 25, 25, math.min(225, color.a) );
		local depth = shadowDepth or 1;
		
		draw.SimpleText(text, mainTextFont, realX + -depth, realY + -depth, outlineColor, alignX, alignY);
		draw.SimpleText(text, mainTextFont, realX + -depth, realY + depth, outlineColor, alignX, alignY);
		draw.SimpleText(text, mainTextFont, realX + depth, realY + -depth, outlineColor, alignX, alignY);
		draw.SimpleText(text, mainTextFont, realX + depth, realY + depth, outlineColor, alignX, alignY);
	end;
	
	local width, height = draw.SimpleText(text, mainTextFont, realX, realY, color, alignX, alignY);
	
	if (width and height) then
		if (height == 0) then
			height = draw.GetFontHeight(mainTextFont);
		end;
		
		return realY + height + 2;
	else
		return realY;
	end;
end;

function re:DrawInfo(text, x, y, color, alpha, alignLeft, Callback, shadowDepth)
	local mainTextFont = self._kernel:GetFont("main_text");
	local width, height = self:GetCachedTextSize(mainTextFont, text);
	
	if (width and height) then
		if (!alignLeft) then
			x = x - (width / 2);
		end;
		
		if (Callback) then
			x, y = Callback(x, y, width, height);
		end;
	
		return self:DrawSimpleText(text, x, y, Color(color.r, color.g, color.b, alpha or color.a), nil, nil, nil, shadowDepth);
	end;
end;

function re:HUDDrawTargetID()
	local targetIDTextFont = self._kernel:GetFont("target_id_text");
	local traceEntity = NULL;
	local colorWhite = self._kernel:GetColor("white");
	
	self:OverrideMainFont(targetIDTextFont);
	
	if ( IsValid(self.Client) and self.Client:Alive() and !IsValid(self.EntityMenu) ) then
		local fadeDistance = 196;
		local curTime = UnPredictedCurTime();
		local trace = self.player:GetRealTrace(self.Client);
		
		if ( IsValid(trace.Entity) and !trace.Entity:IsEffectActive(EF_NODRAW) ) then
			if (!self.TargetIDData or self.TargetIDData.entity != trace.Entity) then
				self.TargetIDData = {
					showTime = curTime + 0.5,
					entity = trace.Entity
				};
			end;
			
			if (self.TargetIDData) then
				self.TargetIDData.trace = trace;
			end;
			
			if ( !IsValid(traceEntity) ) then
				traceEntity = trace.Entity;
			end;
			
			if (curTime >= self.TargetIDData.showTime) then
				if (!self.TargetIDData.fadeTime) then
					self.TargetIDData.fadeTime = curTime + 1;
				end;
				
				local class = trace.Entity:GetClass();
				local entity = self.entity:GetPlayer(trace.Entity);
				
				if (entity) then
					fadeDistance = self._kernel:Call("GetTargetPlayerFadeDistance", entity);
				end;
				
				local alpha = math.Clamp(self:CalculateAlphaFromDistance(fadeDistance, self.Client, trace.HitPos) * 1.5, 0, 255);
				
				if (alpha > 0) then
					alpha = math.min(alpha, math.Clamp(1 - ( (self.TargetIDData.fadeTime - curTime) / 3 ), 0, 1) * 255);
				end;
				
				self.TargetIDData.fadeDistance = fadeDistance;
				self.TargetIDData.player = entity;
				self.TargetIDData.alpha = alpha;
				self.TargetIDData.class = class;
				
				if (entity and self.Client != entity) then
					if ( self.plugin:Call("ShouldDrawPlayerTargetID", entity) ) then
						if ( !self.player:IsNoClipping(entity) ) then
							if (self.Client:GetShootPos():Distance(trace.HitPos) <= fadeDistance) then
								if (self.nextCheckRecognises and self.nextCheckRecognises[2] != entity) then
									self.Client:SetSharedVar("targetRecognises", true);
								end;
								
								local flashAlpha = nil;
								local toScreen = ( trace.HitPos + Vector(0, 0, 16) ):ToScreen();
								local x, y = toScreen.x, toScreen.y;
								
								if ( !self.player:DoesTargetRecognise() ) then
									flashAlpha = math.Clamp(math.sin(curTime * 2) * alpha, 0, 255);
								end;
								
								if ( self.player:DoesRecognise(entity, RECOGNISE_PARTIAL) ) then
									local text = string.Explode( "\n", self.plugin:Call("GetTargetPlayerName", entity) );
									local newY;
									
									for k, v in ipairs(text) do
										newY = self:DrawInfo(v, x, y, _team.GetColor( entity:Team() ), alpha);
										
										if (flashAlpha) then
											self:DrawInfo(v, x, y, colorWhite, flashAlpha);
										end;
										
										if (newY) then
											y = newY;
										end;
									end;
								else
									local unrecognisedName, usedPhysDesc = self.player:GetUnrecognisedName(entity);
									local wrappedTable = {unrecognisedName};
									local teamColor = _team.GetColor( entity:Team() );
									local result = self.plugin:Call("PlayerCanShowUnrecognised", entity, x, y, unrecognisedName, teamColor, alpha, flashAlpha);
									local newY;
									
									if (type(result) == "string") then
										wrappedTable = {};
										
										self:WrapText(result, targetIDTextFont, math.max(ScrW() / 9, 384), wrappedTable);
									elseif (usedPhysDesc) then
										wrappedTable = {};
										
										self:WrapText(unrecognisedName, targetIDTextFont, math.max(ScrW() / 9, 384), wrappedTable);
									end;
									
									if (result == true or type(result) == "string") then
										for k, v in ipairs(wrappedTable) do
											newY = self:DrawInfo(v, x, y, teamColor, alpha);
												
											if (flashAlpha) then
												self:DrawInfo(v, x, y, colorWhite, flashAlpha);
											end;
											
											if (newY) then
												y = newY;
											end;
										end;
									elseif ( tonumber(result) ) then
										y = result;
									end;
								end;
								
								self.TargetPlayerText.text = {};
								
								self.plugin:Call("GetTargetPlayerText", entity, self.TargetPlayerText);
								self.plugin:Call("DestroyTargetPlayerText", entity, self.TargetPlayerText);
								
								y = self.plugin:Call("DrawTargetPlayerStatus", entity, alpha, x, y) or y;
								
								for k, v in pairs(self.TargetPlayerText.text) do
									y = self:DrawInfo(v.text, x, y, v.color or colorWhite, alpha);
								end;
								
								if (!self.nextCheckRecognises or curTime >= self.nextCheckRecognises[1]
								or self.nextCheckRecognises[2] != entity) then
									self:StartDataStream("GetTargetRecognises", entity);
									
									self.nextCheckRecognises = {curTime + 2, entity};
								end;
							end;
						end;
					end;
				elseif ( self.generator:Get(class) ) then
					if (self.Client:GetShootPos():Distance(trace.HitPos) <= fadeDistance) then
						local generator = self.generator:Get(class);
						local toScreen = ( trace.HitPos + Vector(0, 0, 16) ):ToScreen();
						local owner = self.entity:GetOwner(trace.Entity);
						local power = trace.Entity:GetPower();
						local x, y = toScreen.x, toScreen.y;
						
						y = self:DrawInfo(generator.name, x, y, Color(150, 150, 100, 255), alpha);
						y = self:DrawBar( x - 80, y, 160, 16, self.ProgressBarColor, generator.powerPlural, power, generator.power, power < (generator.power / 5) );
					end;
				elseif ( trace.Entity:IsWeapon() ) then
					if (self.Client:GetShootPos():Distance(trace.HitPos) <= fadeDistance) then
						local active = nil;
						for k, v in ipairs( _player.GetAll() ) do
							if (v:GetActiveWeapon() == trace.Entity) then
								active = true;
							end;
						end;
						
						if (!active) then
							local toScreen = ( trace.HitPos + Vector(0, 0, 16) ):ToScreen();
							local x, y = toScreen.x, toScreen.y;
							
							y = self:DrawInfo("An unknown weapon", x, y, Color(200, 100, 50, 255), alpha);
							y = self:DrawInfo("Press use to equip.", x, y, colorWhite, alpha);
						end;
					end;
				elseif (trace.Entity.HUDPaintTargetID) then
					local toScreen = ( trace.HitPos + Vector(0, 0, 16) ):ToScreen();
					local x, y = toScreen.x, toScreen.y;
					
					trace.Entity:HUDPaintTargetID(x, y, alpha);
				else
					local toScreen = ( trace.HitPos + Vector(0, 0, 16) ):ToScreen();
					local x, y = toScreen.x, toScreen.y;
					
					hook.Call( "HUDPaintEntityTargetID", re, trace.Entity, {
						alpha = alpha,
						x = x,
						y = y
					} );
				end;
			end;
		end;
	end;
	
	self:OverrideMainFont(false);
	
	if ( !IsValid(traceEntity) ) then
		if (self.TargetIDData) then
			self.TargetIDData = nil;
		end;
	end;
end;