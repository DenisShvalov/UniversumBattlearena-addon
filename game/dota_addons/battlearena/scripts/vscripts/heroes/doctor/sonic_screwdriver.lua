LinkLuaModifier( "modifier_ability_sonic_screwdriver", "heroes/doctor/sonic_screwdriver", LUA_MODIFIER_MOTION_NONE )

ability_sonic_screwdriver = {}

function ability_sonic_screwdriver:OnSpellStart()
	local caster = self:GetCaster() --Кастер заклинания
	local target = self:GetCursorTarget() --Цель заклинания находится на месте курсора
	local duration = self:GetSpecialValueFor("duration") --Длительность дебаффа из файла способности
	local damageForIntellect = self:GetSpecialValueFor("int_damage") --Урон скилла от интеллекта из файла способности
	local baseDamage = self:GetSpecialValueFor("base_damage") -- Базовый урон
	
	target:AddNewModifier(  --Добавление модификатора для безмолвия
		caster,
		self,
		"modifier_ability_sonic_screwdriver",
		{duration = duration}
	)
	
	-- Нормализация вектора для определения местоположения героя относительно врага. Нужно для таких скиллов, типа спины бристлбека
	local direction = target:GetOrigin()-self:GetCaster():GetOrigin() 
	direction.z = 0
	direction = direction:Normalized()
	
	--[[local effect_cast = ParticleManager:CreateParticle( --Создание партикла эффекта
		"particles/units/heroes/hero_silencer/silencer_last_word_status_cast.vpcf",
		PATTACH_ABSORIGIN_FOLLOW, --Следование эффекта за целью
		target,
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlForward( effect_cast, 1, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )]]--

	EmitSoundOn( "MultiverseArena.SonicScrewdriver", self:GetCaster() ) -- Проигрывание звука
	
	local damageTable = {
		victim = target,
		attacker = caster,
		damage = baseDamage + damageForIntellect * caster:GetIntellect(),
		damage_type = self:GetAbilityDamageType(),
		ability = self
	}
	
	ApplyDamage(damageTable)
end

modifier_ability_sonic_screwdriver = {}

function modifier_ability_sonic_screwdriver:GetEffectName()
	return "particles/econ/events/fall_2021/agh_aura_fall_2021_spark.vpcf" -- Эффект дебаффа
end

function modifier_ability_sonic_screwdriver:IsHidden() -- Эффект не спрятан
	return false
end

function modifier_ability_sonic_screwdriver:IsDebuff() -- Эффект - дебафф
	return true
end

function modifier_ability_sonic_screwdriver:IsStunDebuff() -- Эффект - не стан
	return false
end

function modifier_ability_sonic_screwdriver:IsPurgable() -- Эффект можно развеять
	return true
end

function modifier_ability_sonic_screwdriver:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_sonic_screwdriver:CheckState()
	return { [MODIFIER_STATE_MUTED] = true }
end