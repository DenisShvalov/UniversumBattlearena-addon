modifier_fountain_damage_aura_effect_lua = class({})

--------------------------------------------------------------------------------

function modifier_fountain_damage_aura_effect_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
	return funcs
end

function modifier_fountain_damage_aura_effect_lua:GetTexture()
	return "necrolyte_heartstopper_aura"
end

--------------------------------------------------------------------------------

function modifier_fountain_damage_aura_effect_lua:GetModifierConstantHealthRegen( params )
	return -400
end

--------------------------------------------------------------------------------

function modifier_fountain_damage_aura_effect_lua:OnCreated()
    if IsServer() then
        self.damage_per_sec = self:GetParent():GetMaxHealth() / 25
        self:StartIntervalThink(0.2)
    end
end

function modifier_fountain_damage_aura_effect_lua:OnIntervalThink()
    if IsServer() then
        local damage_table = {
            victim = self:GetParent(),
            attacker = self:GetCaster(),
            damage = self.damage_per_sec,
            damage_type = DAMAGE_TYPE_PURE,
            ability = self:GetAbility()
        }

        ApplyDamage(damage_table)
    end
end

function modifier_fountain_damage_aura_effect_lua:GetModifierTotalPercentageManaRegen( params )
	return -20
end

--------------------------------------------------------------------------------

