modifier_fountain_aura_effect_lua = class({})

--------------------------------------------------------------------------------

function modifier_fountain_aura_effect_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
	return funcs
end

function modifier_fountain_aura_effect_lua:GetTexture()
	return "rune_regen"
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_effect_lua:GetModifierHealthRegenPercentage( params )
	return 10
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_effect_lua:GetModifierTotalPercentageManaRegen( params )
	return 10
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_effect_lua:GetModifierConstantManaRegen( params )
	return 0
end

--------------------------------------------------------------------------------

