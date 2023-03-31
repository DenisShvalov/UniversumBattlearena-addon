--[[ events.lua ]]

---------------------------------------------------------------------------
-- Event: Game state change handler
---------------------------------------------------------------------------
function CMultiverseBattlearenaGameMode:OnGameRulesStateChange() --Функция отвечающая за последовательное изменение правил
	local nNewState = GameRules:State_Get() --Локальная переменная получит текущее состояние игры

	if nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then -- Если сейчас время пиков героев, то запускается функций по распределению команд
		self:AssignTeams() --Функция распределения команд

	elseif nNewState == DOTA_GAMERULES_STATE_PRE_GAME then --Если сейчас преигровая стадия
		local numberOfPlayers = PlayerResource:GetPlayerCount() --Смотрим количество игроков
		if numberOfPlayers > 7 then -- Если больше 7 игроков
			nCOUNTDOWNTIMER = 1801 --Таймер на 30 минут
		elseif numberOfPlayers > 4 and numberOfPlayers <= 7 then -- Если игроков от 5 до 7
			nCOUNTDOWNTIMER = 1501 -- Таймер на 25 минут
		else
			nCOUNTDOWNTIMER = 1201 -- Таймер на 20 минут
		end
		
		if GetMapName() == "solo_templeriver" then -- Если карта solo_templeriver
			self.TEAM_KILLS_TO_WIN = self.KILLS_TO_WIN_SINGLES --Лимит киллов устанавливается для соло
	--[[	elseif GetMapName() == "desert_duo" then
			self.TEAM_KILLS_TO_WIN = self.KILLS_TO_WIN_DUOS
		elseif GetMapName() == "temple_quartet" then
			self.TEAM_KILLS_TO_WIN = self.KILLS_TO_WIN_QUADS
		elseif GetMapName() == "desert_quintet" then
			self.TEAM_KILLS_TO_WIN = self.KILLS_TO_WIN_QUINTS
		else
			self.TEAM_KILLS_TO_WIN = self.KILLS_TO_WIN_TRIOS --]]
		end


		CustomNetTables:SetTableValue( "game_state", "victory_condition", { kills_to_win = self.TEAM_KILLS_TO_WIN } ) -- Создаем сетевую таблицу game_state, с ключом victory_condition, котором присваивается значение kills_to_win равное self.TEAM_KILLS_TO_WIN

		self._fPreGameStartTime = GameRules:GetGameTime() --Присваиваем переменной self._fPreGameStartTime значение времени в игре

	elseif nNewState == DOTA_GAMERULES_STATE_STRATEGY_TIME then -- Если новое состояние - стратегическое время
		for nPlayerID = 0, ( DOTA_MAX_TEAM_PLAYERS - 1 ) do -- Цикл, перебирающий всех игроков в игре
			local hPlayer = PlayerResource:GetPlayer( nPlayerID ) 
			if hPlayer and not PlayerResource:HasSelectedHero( nPlayerID ) then -- Если игрок существует и не выбрал героя
				hPlayer:MakeRandomHeroSelection() --Ему выбирается случайный герой
			end	
		end

	elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then -- Если новое состояние - начатая игра
		
		self.countdownEnabled = true -- Включается таймер
		CustomGameEventManager:Send_ServerToAllClients( "show_timer", {} ) -- Показывает всем игрокам таймер
		--DoEntFire( "center_experience_ring_particles", "Start", "0", 0, self, self  )
		GameRules:GetGameModeEntity():SetAnnouncerDisabled( true ) -- Выключает стандартного анонсера доты
	end
end

--------------------------------------------------------------------------------
-- Event: OnNPCSpawned
--------------------------------------------------------------------------------
--[[function CMultiverseBattlearenaGameMode:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if spawnedUnit:IsRealHero() then
		-- Destroys the last hit effects
		local deathEffects = spawnedUnit:Attribute_GetIntValue( "effectsID", -1 )
		if deathEffects ~= -1 then
			ParticleManager:DestroyParticle( deathEffects, true )
			spawnedUnit:DeleteAttribute( "effectsID" )
		end
		if self.allSpawned == false then
			if GetMapName() == "mines_trio" then
				--print("mines_trio is the map")
				--print("self.allSpawned is " .. tostring(self.allSpawned) )
				local unitTeam = spawnedUnit:GetTeam()
				local particleSpawn = ParticleManager:CreateParticleForTeam( "particles/addons_gameplay/player_deferred_light.vpcf", PATTACH_ABSORIGIN, spawnedUnit, unitTeam )
				ParticleManager:SetParticleControlEnt( particleSpawn, PATTACH_ABSORIGIN, spawnedUnit, PATTACH_ABSORIGIN, "attach_origin", spawnedUnit:GetAbsOrigin(), true )
			end
		end
	end
end--]]

---------------------------------------------------------
-- dota_on_hero_finish_spawn
-- * heroindex
-- * hero  		(string)
---------------------------------------------------------

function CMultiverseBattlearenaGameMode:OnHeroFinishSpawn( event )
	local hPlayerHero = EntIndexToHScript( event.heroindex )
	if hPlayerHero ~= nil and hPlayerHero:IsRealHero() then
		local hTP = hPlayerHero:FindItemInInventory( "item_tpscroll" )
		if hTP ~= nil then
			UTIL_Remove( hTP )
		end
	end
end

--------------------------------------------------------------------------------
-- Event: BountyRunePickupFilter
--------------------------------------------------------------------------------
function CMultiverseBattlearenaGameMode:BountyRunePickupFilter( filterTable )
      filterTable["xp_bounty"] = 2*filterTable["xp_bounty"]
      filterTable["gold_bounty"] = 2*filterTable["gold_bounty"]
      return true
end

---------------------------------------------------------------------------
-- Event: OnTeamKillCredit, see if anyone won
---------------------------------------------------------------------------
function CMultiverseBattlearenaGameMode:OnTeamKillCredit( event ) -- Функция возникающая при смерти героя и ищущая победителя

	local nKillerID = event.killer_userid -- Локальная переменная, которая получает ID убийцы героя
	local nTeamID = event.teamnumber -- ID команды, убившей героя
	local nTeamKills = event.herokills -- Количество убийств команды
	local nKillsRemaining = self.TEAM_KILLS_TO_WIN - nTeamKills -- Количество оставшихся киллов до победы
	
	local broadcast_kill_event =  -- Таблица переменных для бродкаста
	{
		killer_id = event.killer_userid,
		team_id = event.teamnumber,
		team_kills = nTeamKills,
		kills_remaining = nKillsRemaining,
		victory = 0,
		close_to_victory = 0,
		very_close_to_victory = 0,
	} 

	if nKillsRemaining <= 0 then -- Если осталось 0 или меньше киллов
		local tTeamScores = {} -- Пустая локальная таблица очков команд
		for team = DOTA_TEAM_FIRST, (DOTA_TEAM_COUNT-1) do -- Цикл, перебирающий все команды
			tTeamScores[team] = GetTeamHeroKills(team) -- В таблицу с ключом ID команды присваивается значение очков команды
		end
		GameRules:SetPostGameTeamScores( tTeamScores ) -- Устанавливается количеством очков после игры

		GameRules:SetCustomVictoryMessage( self.m_VictoryMessages[nTeamID] ) -- Показывается окно победы
		GameRules:SetGameWinner( nTeamID ) -- Устанавливается победитель
		broadcast_kill_event.victory = 1 -- значению победы в таблице broadcast_kill_event ставится 1
	elseif nKillsRemaining == 1 then -- Если осталось одно очко до победы
		EmitGlobalSound( "ui.npe_objective_complete" ) -- Проигрывается глоабльный звук
		broadcast_kill_event.very_close_to_victory = 1 -- Значению очень близко к победе в таблице broadcast_kill_event ставится 1
	elseif nKillsRemaining <= self.CLOSE_TO_VICTORY_THRESHOLD then -- Если количество нужных убийств меньше или равно количеству близкого к победе
		EmitGlobalSound( "ui.npe_objective_given" ) -- Проигрывается звук
		broadcast_kill_event.close_to_victory = 1 -- Значению близко к победе присваивается 1
	end

	CustomGameEventManager:Send_ServerToAllClients( "kill_event", broadcast_kill_event ) -- Проигырвается уведомление игрокам об убийстве
end

---------------------------------------------------------------------------
-- Event: OnEntityKilled
---------------------------------------------------------------------------
--[[function CMultiverseBattlearenaGameMode:OnEntityKilled( event )
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	local killedTeam = killedUnit:GetTeam()
	local hero = EntIndexToHScript( event.entindex_attacker )
	local heroTeam = hero:GetTeam()
	local extraTime = 0
	if killedUnit:IsRealHero() then
		self.allSpawned = true
		--print("Hero has been killed")
		--Add extra time if killed by Necro Ult
		if hero:IsRealHero() == true then
			if event.entindex_inflictor ~= nil then
				local inflictor_index = event.entindex_inflictor
				if inflictor_index ~= nil then
					local ability = EntIndexToHScript( event.entindex_inflictor )
					if ability ~= nil then
						if ability:GetAbilityName() ~= nil then
							if ability:GetAbilityName() == "necrolyte_reapers_scythe" then
								print("Killed by Necro Ult")
								extraTime = 20
							end
						end
					end
				end
			end
		end
		if hero:IsRealHero() and heroTeam ~= killedTeam then
			--print("Granting killer xp")
			if killedUnit:GetTeam() == self.leadingTeam and self.isGameTied == false then
				local memberID = hero:GetPlayerID()
				PlayerResource:ModifyGold( memberID, 500, true, 0 )
				hero:AddExperience( 100, 0, false, false )
				local name = hero:GetClassname()
				local victim = killedUnit:GetClassname()
				local kill_alert =
					{
						hero_id = hero:GetClassname()
					}
				CustomGameEventManager:Send_ServerToAllClients( "kill_alert", kill_alert )
			else
				hero:AddExperience( 50, 0, false, false )
			end
		end
		--Granting XP to all heroes who assisted
		local allHeroes = HeroList:GetAllHeroes()
		for _,attacker in pairs( allHeroes ) do
			--print(killedUnit:GetNumAttackers())
			for i = 0, killedUnit:GetNumAttackers() - 1 do
				if attacker == killedUnit:GetAttacker( i ) then
					--print("Granting assist xp")
					attacker:AddExperience( 25, 0, false, false )
				end
			end
		end
		if killedUnit:GetRespawnTime() > 10 then
			--print("Hero has long respawn time")
			if killedUnit:IsReincarnating() == true then
				--print("Set time for Wraith King respawn disabled")
				return nil
			else
				CMultiverseBattlearenaGameMode:SetRespawnTime( killedTeam, killedUnit, extraTime )
			end
		else
			CMultiverseBattlearenaGameMode:SetRespawnTime( killedTeam, killedUnit, extraTime )
		end
	end
end--]

--[[function CMultiverseBattlearenaGameMode:SetRespawnTime( killedTeam, killedUnit, extraTime )
	--print("Setting time for respawn")
	if killedTeam == self.leadingTeam and self.isGameTied == false then
		killedUnit:SetTimeUntilRespawn( 20 + extraTime )
	else
		killedUnit:SetTimeUntilRespawn( 10 + extraTime )
	end
end--]]


--------------------------------------------------------------------------------
-- Event: OnItemPickUp
--------------------------------------------------------------------------------
--[[function CMultiverseBattlearenaGameMode:OnItemPickUp( event )
	local item = EntIndexToHScript( event.ItemEntityIndex )
	local owner = EntIndexToHScript( event.HeroEntityIndex )
	r = 300
	--r = RandomInt(200, 400)
	if event.itemname == "item_bag_of_gold" then
		--print("Bag of gold picked up")
		PlayerResource:ModifyGold( owner:GetPlayerID(), r, true, 0 )
		SendOverheadEventMessage( owner, OVERHEAD_ALERT_GOLD, owner, r, nil )
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	elseif event.itemname == "item_treasure_chest" then
		print( "Special Item Picked Up" )

		if item.GetAbilityName ~= nil then
			--print( "Item is named: - " .. item:GetAbilityName() )
		end

		local hContainer = item:GetContainer()

		for k,v in pairs ( self.itemSpawnLocationsInUse ) do
			if v.hDrop == hContainer then
				--print( '^^^DROP CONTAINER!' )
				if v.hItemDestinationRevealer then
					v.hItemDestinationRevealer:RemoveSelf()
					ParticleManager:DestroyParticle( v.nItemDestinationParticles, false )
					DoEntFire( v.world_effects_name, "Stop", "0", 0, self, self )
				end
				
				table.insert( self.itemSpawnLocations, v )
				table.remove( self.itemSpawnLocationsInUse, k )
				break
			end
		end
		
		CMultiverseBattlearenaGameMode:SpecialItemAdd( event )
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	end
end--]]


--------------------------------------------------------------------------------
-- Event: OnNpcGoalReached
--------------------------------------------------------------------------------
--[[function CMultiverseBattlearenaGameMode:OnNpcGoalReached( event )
	local npc = EntIndexToHScript( event.npc_entindex )
	if npc:GetUnitName() == "npc_dota_treasure_courier" then
		CMultiverseBattlearenaGameMode:TreasureDrop( npc )
	end
end--]]
