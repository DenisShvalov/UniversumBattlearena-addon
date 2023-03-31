ability_timelord_mind = {}

LinkLuaModifier( "modifier_ability_timelord_mind_aura", "heroes/doctor/timelord_mind", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_timelord_mind_aura_stack", "heroes/doctor/timelord_mind", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_timelord_mind_aura_permanent_stack", "heroes/doctor/timelord_mind", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_timelord_mind_aura_enemycheck", "heroes/doctor/timelord_mind", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_particle_hidden", "heroes/doctor/timelord_mind", LUA_MODIFIER_MOTION_NONE )

function ability_timelord_mind:GetIntrinsicModifierName() -- Активации при вкачивании скилла
	return "modifier_ability_timelord_mind_aura"
end


--Модификатор временных стаков 
modifier_ability_timelord_mind_aura_stack = class({})

function modifier_ability_timelord_mind_aura_stack:IsHidden()
	return true
end

function modifier_ability_timelord_mind_aura_stack:IsDebuff()
	return false
end

function modifier_ability_timelord_mind_aura_stack:IsPurgable()
	return false
end

function modifier_ability_timelord_mind_aura_stack:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end

function modifier_ability_timelord_mind_aura_stack:RemoveOnDeath()
	return false
end

function modifier_ability_timelord_mind_aura_stack:OnDestroy()
	if not IsServer() then return end
	self.parent:RemoveStack(self.parent.temp_int)
end

--Модификатор постоянных стаков
modifier_ability_timelord_mind_aura_permanent_stack = {}

function modifier_ability_timelord_mind_aura_permanent_stack:IsHidden()
	return false
end

function modifier_ability_timelord_mind_aura_permanent_stack:IsDebuff()
	return false
end

function modifier_ability_timelord_mind_aura_permanent_stack:IsPurgable()
	return false
end

function modifier_ability_timelord_mind_aura_permanent_stack:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ability_timelord_mind_aura_permanent_stack:RemoveOnDeath()
	return false
end

function modifier_ability_timelord_mind_aura_permanent_stack:OnCreated( kv )
	if not IsServer() then return end
	self:SetStackCount( kv.bonus )
end

function modifier_ability_timelord_mind_aura_permanent_stack:OnRefresh( kv )
	if not IsServer() then return end
	self:SetStackCount( self:GetStackCount() + kv.bonus )
end

function modifier_ability_timelord_mind_aura_permanent_stack:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}

	return funcs
end

function modifier_ability_timelord_mind_aura_permanent_stack:GetModifierBonusStats_Intellect()
	return self:GetStackCount()
end


modifier_ability_timelord_mind_aura_enemycheck = {}

function modifier_ability_timelord_mind_aura_enemycheck:IsHidden()
	return true
end

function modifier_ability_timelord_mind_aura_enemycheck:IsDebuff()
	return true
end

function modifier_ability_timelord_mind_aura_enemycheck:IsStunDebuff()
	return false
end

function modifier_ability_timelord_mind_aura_enemycheck:IsPurgable()
	return true
end

function modifier_ability_timelord_mind_aura_enemycheck:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end


--Аура, ищущая врагов
modifier_ability_timelord_mind_aura = {}

function modifier_ability_timelord_mind_aura:IsHidden()
	return self:GetStackCount()==0
end

function modifier_ability_timelord_mind_aura:IsDebuff()
	return false
end

function modifier_ability_timelord_mind_aura:IsStunDebuff()
	return false
end

function modifier_ability_timelord_mind_aura:IsPurgable()
	return false
end

function modifier_ability_timelord_mind_aura:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ability_timelord_mind_aura:RemoveOnDeath()
	return false
end

function modifier_ability_timelord_mind_aura:DestroyOnExpire()
	return false
end


function modifier_ability_timelord_mind_aura:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.temp_int = self:GetAbility():GetSpecialValueFor( "temp_int" )
	self.bonus = self:GetAbility():GetSpecialValueFor( "perm_int" )
	self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
	self.xp_boost = self:GetAbility():GetSpecialValueFor( "xp_boost" )
		
	if not IsServer() then return end
end

function modifier_ability_timelord_mind_aura:OnRefresh( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.temp_int = self:GetAbility():GetSpecialValueFor( "temp_int" )
	self.bonus = self:GetAbility():GetSpecialValueFor( "perm_int" )
	self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
	self.xp_boost = self:GetAbility():GetSpecialValueFor( "xp_boost" )
	
	
	
	if not IsServer() then return end
end

function modifier_ability_timelord_mind_aura:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

function modifier_ability_timelord_mind_aura:OnDeath( params )
	if not IsServer() then return end
	local parent = self:GetParent()
		
	if parent:PassivesDisabled() then return end
	if params.unit:IsIllusion() then return end
	
	if not params.unit:FindModifierByNameAndCaster( "modifier_ability_timelord_mind_aura_enemycheck", parent ) then return end
	
	local bonus 
	local hero = params.unit:IsHero()
		
	if hero then
		bonus = self.bonus
	end

	parent:AddNewModifier(
		parent,
		self:GetAbility(),
		"modifier_ability_timelord_mind_aura_permanent_stack",
		{ bonus = bonus }
	)
	
end

function modifier_ability_timelord_mind_aura:OnAbilityExecuted( params )
	if not IsServer() then return end
	local parent = self:GetParent()
	
	if parent:PassivesDisabled() then return end
	if params.unit:IsIllusion() then return end
	
	if not params.unit:FindModifierByNameAndCaster( "modifier_ability_timelord_mind_aura_enemycheck", parent ) then return end
	
	local hero = params.unit:IsHero()
	local bonus = self.temp_int
	local duration = self.duration
	
	if hero then
		self:SetStackCount( self:GetStackCount() + bonus )
	end
	
	
	parent:AddExperience(self.xp_boost, 0, false, true)
	
	local particle = "particles/econ/items/outworld_devourer/od_shards_exile_gold/od_shards_exile_prison_top_orb_gold.vpcf"
	ApplyParticleEffectOnUnit(parent, particle, 0.8)
	EmitSoundOn( "MultiverseArena.TimelordMind", self:GetCaster())
	
	local modifier = parent:AddNewModifier(
		parent,
		self:GetAbility(),
		"modifier_ability_timelord_mind_aura_stack",
		{ duration = duration }
	)
	modifier.parent = self
	modifier.bonus = bonus

	self:SetDuration( self.duration, true )

end


function modifier_ability_timelord_mind_aura:GetModifierBonusStats_Intellect()
	return self:GetStackCount()
end


function modifier_ability_timelord_mind_aura:RemoveStack( value )
	if (self:GetStackCount() - value) >= 0 then
		self:SetStackCount( self:GetStackCount() - value )
	end
end

function modifier_ability_timelord_mind_aura:IsAura()  --Аура, если не отключили пассивки
	return (not self:GetCaster():PassivesDisabled())
end

function modifier_ability_timelord_mind_aura:GetModifierAura()
	return "modifier_ability_timelord_mind_aura_enemycheck"
end

function modifier_ability_timelord_mind_aura:GetAuraRadius() -- Радиус ауры
	return self.radius
end

function modifier_ability_timelord_mind_aura:GetAuraDuration()
	return 0.4
end

function modifier_ability_timelord_mind_aura:GetAuraSearchTeam()  -- Искать врагов
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_timelord_mind_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_ability_timelord_mind_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_ability_timelord_mind_aura:IsAuraActiveOnDeath()
	return false
end

modifier_particle_hidden = {}

function modifier_particle_hidden:IsHidden()
	return true
end

function modifier_particle_hidden:IsDebuff()
	return false
end

function modifier_particle_hidden:IsStunDebuff()
	return false
end

function modifier_particle_hidden:IsPurgable()
	return true
end

function modifier_particle_hidden:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end

function ApplyParticleEffectOnUnit(unit, particleName, duration)
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)

    local particleModifier = unit:AddNewModifier(unit, nil, "modifier_particle_hidden", {duration = duration})
    particleModifier:AddParticle(particle, false, false, 1, false, false)
end




