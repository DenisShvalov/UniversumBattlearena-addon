base_gold_count = 2;
base_xp_count = 8;

function CenterBoost(hero)
	
	local gametime = GameRules:GetGameTime();
	local gold_count = base_gold_count + (gametime / 500);
	local xp_count = base_xp_count + (gametime / 140) ;
	if hero.boost_timer == true then
		hero:ModifyGold(gold_count, true, 0);
		hero:AddExperience(xp_count, 0, false, true);
		
		return 1;
	end
end
   
function CenterBoostOnStartTouch(trigger)
	
	local hero = trigger.activator;
	--if hero:IsRealHero() then
	hero.boost_timer = true
	hero:SetThink("CenterBoost", self)
	--end
end

function CenterBoostOnEndTouch(trigger)
	
	local hero = trigger.activator
	hero.boost_timer = false
	
end
	
