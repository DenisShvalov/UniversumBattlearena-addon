local GOLD_INCOME = 2;

_G.nCOUNTDOWNTIMER = 1801; -- Установка таймера на 30 минут

if CMultiverseBattlearenaGameMode == nil then
	_G.CMultiverseBattlearenaGameMode = class({})
end

require( "events" )
require( "utility_functions" )
require( "util/util" )


function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
	
		PrecacheResource( "soundfile", "soundevents/ability_sounds.vsndevts", context )
	
end


function Activate()
-- Создание и инициализация режима
	CMultiverseBattlearenaGameMode():InitGameMode() 
end

function CMultiverseBattlearenaGameMode:InitGameMode()

	print( "Battlearena is loaded." )
	
----------------- Установка внутриклассовых переменных экземпляра ----------------------
	
-- Установка цветов для команд и изменение полоски хп
	self.m_TeamColors = {}
	self.m_TeamColors[DOTA_TEAM_GOODGUYS] = { 61, 210, 150 }	--		Teal
	self.m_TeamColors[DOTA_TEAM_BADGUYS]  = { 243, 201, 9 }		--		Yellow
	self.m_TeamColors[DOTA_TEAM_CUSTOM_1] = { 197, 77, 168 }	--      Pink
	self.m_TeamColors[DOTA_TEAM_CUSTOM_2] = { 255, 108, 0 }		--		Orange
	self.m_TeamColors[DOTA_TEAM_CUSTOM_3] = { 52, 85, 255 }		--		Blue
	self.m_TeamColors[DOTA_TEAM_CUSTOM_4] = { 101, 212, 19 }	--		Green
	self.m_TeamColors[DOTA_TEAM_CUSTOM_5] = { 129, 83, 54 }		--		Brown
	self.m_TeamColors[DOTA_TEAM_CUSTOM_6] = { 27, 192, 216 }	--		Cyan
	self.m_TeamColors[DOTA_TEAM_CUSTOM_7] = { 199, 228, 13 }	--		Olive
	self.m_TeamColors[DOTA_TEAM_CUSTOM_8] = { 140, 42, 244 }	--		Purple
	
	for team = 0, (DOTA_TEAM_COUNT-1) do
		color = self.m_TeamColors[ team ]
		if color then
			SetTeamCustomHealthbarColor( team, color[1], color[2], color[3] )
		end
	end
	
-- Установка сообщения о победителе
	
	self.m_VictoryMessages = {}
	self.m_VictoryMessages[DOTA_TEAM_GOODGUYS] = "#VictoryMessage_GoodGuys"
	self.m_VictoryMessages[DOTA_TEAM_BADGUYS]  = "#VictoryMessage_BadGuys"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_1] = "#VictoryMessage_Custom1"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_2] = "#VictoryMessage_Custom2"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_3] = "#VictoryMessage_Custom3"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_4] = "#VictoryMessage_Custom4"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_5] = "#VictoryMessage_Custom5"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_6] = "#VictoryMessage_Custom6"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_7] = "#VictoryMessage_Custom7"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_8] = "#VictoryMessage_Custom8"
	
	self.m_GatheredShuffledTeams = {}
	self.countdownEnabled = false -- Переменная, отвечающая за включение счетчика до конца игры
	self.isGameTied = true -- Переменная, отвечающая за то, ничья сейчас или нет
	self.leadingTeam = -1 -- Переменная, отвечающая за лидирующую команду
	self.runnerupTeam = -1 -- Команда на втором месте
	self.leadingTeamScore = 0 --Очки лидирующей команды
	self.runnerupTeamScore = 0 --Очки команды на втором месте
	
-- Установка лимита киллов для победы
	
	self.KILLS_TO_WIN_SINGLES = 30 -- соло
	self.KILLS_TO_WIN_DUOS = 35 -- дуо
	self.KILLS_TO_WIN_TRIOS = 40 -- трио
	self.KILLS_TO_WIN_QUADS = 55 -- квадро
	self.KILLS_TO_WIN_QUINTS = 70 -- пента
	
	self.TEAM_KILLS_TO_WIN = self.KILLS_TO_WIN_SINGLES --Базово стоит соло
	self.CLOSE_TO_VICTORY_THRESHOLD = 3 -- Значение приближения к победе
	self:GatherAndRegisterValidTeams() -- Создание правильных команд
	
-- Установка количества команд в зависимости от карты	
	if GetMapName() == "solo_templeriver" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 1 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 1 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 1 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_3, 1 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_4, 1 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_5, 1 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_6, 1 )
	end 
	
-- Установка игровых правил
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 ) -- Постоянный таймер
	GameRules:SetUseUniversalShopMode(true) -- Магазин по всей карте
	GameRules:SetPreGameTime(30) -- Время между пиками игроков и началом игры
	GameRules:SetStrategyTime(10) -- Стратегическое время
	--GameRules:SetPostGameTime(10) -- Время после конца игры
	GameRules:SetShowcaseTime(0) -- Время показа всех игроков
	GameRules:SetHeroSelectionTime(30) -- Время пиков
	GameRules:SetHeroSelectPenaltyTime(0) --Время пинальти
	GameRules:SetHideKillMessageHeaders(true) -- Скрыть надписи об убийствах
	--GameRules:SetCustomGameSetupAutoLaunchDelay(5) -- Автозапуск после того как все игроки подключились
	--GameRules:LockCustomGameSetupTeamAssignment(true) -- Запрет выходить из команд после загрузки всех игроков
	GameRules:GetGameModeEntity():SetRuneEnabled( DOTA_RUNE_DOUBLEDAMAGE , true ) --Включение руны двойного урона
	GameRules:GetGameModeEntity():SetRuneEnabled( DOTA_RUNE_HASTE, true )  --Включение руны ускорения
	GameRules:GetGameModeEntity():SetRuneEnabled( DOTA_RUNE_ILLUSION, true ) --Включение руны иллюзий
	GameRules:GetGameModeEntity():SetRuneEnabled( DOTA_RUNE_INVISIBILITY, false ) --Отключение руны невидимости
	GameRules:GetGameModeEntity():SetRuneEnabled( DOTA_RUNE_REGENERATION, true ) --Включение руны регенерации
	GameRules:GetGameModeEntity():SetRuneEnabled( DOTA_RUNE_ARCANE, true ) --Включение руны волшебства
	GameRules:GetGameModeEntity():SetRuneEnabled( DOTA_RUNE_BOUNTY, true ) --Включение рун богатства
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true ) -- Разрешение на изменение верхней части худа
	GameRules:GetGameModeEntity():SetBountyRuneSpawnInterval(60) -- Настройка интервалов рун богатства
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath(false) -- Отключение потери денег при смерти
	GameRules:GetGameModeEntity():SetGiveFreeTPOnDeath(false) -- Отключение выдачи бесплатного свитка телепорта при смерти
	GameRules:SetGoldPerTick(GOLD_INCOME) -- Золото за тик
	GameRules:GetGameModeEntity():SetFountainPercentageHealthRegen( 0 ) -- Отключение регенерации фонтана
	GameRules:GetGameModeEntity():SetFountainPercentageManaRegen( 0 ) -- Отключение регенерации маны фонтана
	GameRules:GetGameModeEntity():SetFountainConstantManaRegen( 0 ) -- Отключение регенерации маны фонтана
	GameRules:GetGameModeEntity():SetFixedRespawnTime(10); -- Установка начального времени возрождения героев
	GameRules:GetGameModeEntity():SetBuybackEnabled(false); -- Запрет на выкуп
	GameRules:GetGameModeEntity():SetFreeCourierModeEnabled( true ) --
	GameRules:GetGameModeEntity():SetUseTurboCouriers( true ) -- Настройка курьеров как в турбо	
	GameRules:SetTimeOfDay(0.25)
	Convars:SetFloat("dota_time_of_day_rate", 1/480)
	
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CMultiverseBattlearenaGameMode, 'OnGameRulesStateChange' ), self ) --Если произошло событие смены состояние, вызывается функция смены состояния
	ListenToGameEvent( "dota_team_kill_credit", Dynamic_Wrap( CMultiverseBattlearenaGameMode, 'OnTeamKillCredit' ), self ) -- Если произошло событие смерти какого-либо героя, вызывается функция
	
	CMultiverseBattlearenaGameMode:SetUpFountains() -- Функция установки фонтанов
	
	GameRules:SetPostGameLayout( DOTA_POST_GAME_LAYOUT_SINGLE_COLUMN )
	GameRules:SetPostGameColumns( {
		DOTA_POST_GAME_COLUMN_LEVEL,
		DOTA_POST_GAME_COLUMN_ITEMS,
		DOTA_POST_GAME_COLUMN_KILLS,
		DOTA_POST_GAME_COLUMN_DEATHS,
		DOTA_POST_GAME_COLUMN_ASSISTS,
		DOTA_POST_GAME_COLUMN_NET_WORTH,
		DOTA_POST_GAME_COLUMN_DAMAGE,
		DOTA_POST_GAME_COLUMN_HEALING,
	} )
end

---------------------------------------------------------------------------------------

--Функция отвечающая за установку аур фонтанов
function CMultiverseBattlearenaGameMode:SetUpFountains()

	LinkLuaModifier( "modifier_fountain_aura_lua", LUA_MODIFIER_MOTION_NONE ) -- Функция на добавление нового модификатора из файла modifier_fountain_aura_lua
	LinkLuaModifier( "modifier_fountain_aura_effect_lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier( "modifier_fountain_damage_aura_lua", LUA_MODIFIER_MOTION_NONE ) -- Функция на добавление нового модификатора из файла modifier_fountain_damage_aura_lua
	LinkLuaModifier( "modifier_fountain_damage_aura_effect_lua", LUA_MODIFIER_MOTION_NONE )

	local fountainEntities = Entities:FindAllByClassname( "ent_dota_fountain") -- Поиск всех энтити фонтанов на карте
	for _,fountainEnt in pairs( fountainEntities ) do           -- Цикл, перебирающий каждый найденный фонтан
		fountainEnt:AddNewModifier( fountainEnt, fountainEnt, "modifier_fountain_aura_lua", {} ) -- Установка ауры регенерации
		fountainEnt:RemoveModifierByName("modifier_fountain_aura") --Удаление стандартной ауры у энтити фонтанов
		fountainEnt:AddNewModifier( fountainEnt, fountainEnt, "modifier_fountain_damage_aura_lua", {} ) -- Установка ауры урона фонтана
	end
end

--Функция отвечающая за установку урона башен на базах
--[[function CMultiverseBattlearenaGameMode:SetUpTowers()

	LinkLuaModifier( "modifier_fountain_damage_aura_lua", LUA_MODIFIER_MOTION_NONE ) -- Функция на добавление нового модификатора из файла modifier_fountain_damage_aura_lua
	LinkLuaModifier( "modifier_fountain_damage_aura_effect_lua", LUA_MODIFIER_MOTION_NONE )
	
	local towers = Entities:FindAllByClassname("npc_dota_tower") -- Поиск всех энтити башен на карте
	for _, tower in pairs(towers) do
		tower:AddNewModifier( fountainEnt, fountainEnt, "modifier_fountain_damage_aura_lua", {} ) -- Установка ауры урона фонтана
	end
end--]]

-- Функция отвечающая за изменение времени респавна игроков
function CMultiverseBattlearenaGameMode:SetRespawnTime()
	
	local gametime = GameRules:GetGameTime(); -- локальная переменная времени игры
	
	if gametime >= 600 and gametime < 1200 then
		GameRules:GetGameModeEntity():SetFixedRespawnTime(15); -- Если время от 10 до 20 минуты, то респаун 15 секунд
	elseif gametime > 1200 then
		GameRules:GetGameModeEntity():SetFixedRespawnTime(20); -- Если время от 20 минуты, то респавун 20 секунд
	end
end

--Функция усиления лагерей нейтральных крипов
function CMultiverseBattlearenaGameMode:NeutralCampProgression()

	local gametime = GameRules:GetGameTime();
	if gametime == 298 then
		local camps = Entities:FindAllByClassname("npc_dota_neutral_spawner");
		for _, camp in pairs(camps) do
			camp:SetKeyValue("CampType", "Moderate")
			EntFire(camp, "ApplySettings", "", 0, nil, nil)
		end
	elseif gametime == 598 then
		local camps = Entities:FindAllByClassname("npc_dota_neutral_spawner");
		for _, camp in pairs(camps) do
			camp:SetKeyValue("CampType", "Hard")
			EntFire(camp, "ApplySettings", "", 0, nil, nil)
		end
	elseif gametime == 898 then
		local camps = Entities:FindAllByClassname("npc_dota_neutral_spawner");
		for _, camp in pairs(camps) do
			camp:SetKeyValue("CampType", "Ancient")
			EntFire(camp, "ApplySettings", "", 0, nil, nil)
		end
	end
end

--Функция для определения цвета команды
function CMultiverseBattlearenaGameMode:ColorForTeam(teamID)
	local color = self.m_TeamColors[ teamID ] -- Смотрим цвет команды
	if color == nil then
		color = { 255, 255, 255 } -- Если у команды нет цвета, то присваиваем белый цвет
	end
	return color -- Возвращаем цвет
end

--Функция для присвоения игрокам цвета их команды 
function CMultiverseBattlearenaGameMode:UpdatePlayerColor( nPlayerID )
	if not PlayerResource:HasSelectedHero( nPlayerID ) then -- Проверка, выбрал ли игрок с таким ID героя, если нет, то ничего не возвращает
		return
	end

	local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID ) -- Присвоение локальной переменной hero выбранного игроком с id nPlayerID указателя на энтити героя
	if hero == nil then  -- Проверка на то, есть ли герой или нет
		return
	end

	local teamID = PlayerResource:GetTeam( nPlayerID ) --Присвоение локальной переменной teamID - ID команды игрока с ID nPlayerID
	local color = self:ColorForTeam( teamID ) -- Присвоение переменной color цвета команды с использованием функции ColorForTeam
	PlayerResource:SetCustomPlayerColor( nPlayerID, color[1], color[2], color[3] ) --Устанавливает цвет команды на миникарте, в таблице счета и т.д
end

--Сбор и регистрации правильных команд
function CMultiverseBattlearenaGameMode:GatherAndRegisterValidTeams()

	local foundTeams = {} --Локальная таблица найденных команд
	for _, playerStart in pairs( Entities:FindAllByClassname( "info_player_start_dota" ) ) do --Цикл в котором проходят по каждому месту спавна игроков
		foundTeams[  playerStart:GetTeam() ] = true --Если нашли команду, то ее ID в таблице foundteams ставят true, иначе false
	end

	local numTeams = TableCount(foundTeams) --Ищут количество команд найдя длину таблицы
	local foundTeamsList = {} --Локальный список найденных таблиц
	for t, _ in pairs( foundTeams ) do --Для каждого ID команды в таблице
		table.insert( foundTeamsList, t ) -- В список найденных команд вставляют ID команды
	end

	if numTeams == 0 then --Если длина таблицы команд равна 0, то есть команд нет
		table.insert( foundTeamsList, DOTA_TEAM_GOODGUYS ) -- Выставляют стандартные команды из доты и ставят две команды
		table.insert( foundTeamsList, DOTA_TEAM_BADGUYS )
		numTeams = 2
	end

	local maxPlayersPerValidTeam = math.floor( 10 / numTeams ) -- Переменная которая с читает количество игроков на правильную команду

	self.m_GatheredShuffledTeams = ShuffledList( foundTeamsList ) --Переменной дают перемешанный список команд

	for team = 0, (DOTA_TEAM_COUNT-1) do -- Цикл перебирающий все команды
		local maxPlayers = 0 -- Локальная переменная максимального количества игроков в команде = 0
		if ( nil ~= TableFindKey( foundTeamsList, team ) ) then --Если эта команда находится в таблице
			maxPlayers = maxPlayersPerValidTeam -- устанавливается максимальное количество игроков
		end
		
		GameRules:SetCustomGameTeamMaxPlayers( team, maxPlayers ) -- для команды устанавливается максимальное количество игроков
	end
end

--Функция обновления таблицы счеты и поиска лидера
function CMultiverseBattlearenaGameMode:UpdateScoreboard()
	local sortedTeams = {} -- Локальная таблица отсортированных команд
	for _, team in pairs( self.m_GatheredShuffledTeams ) do -- Цикл перебирает все зарегистрированные правильные команды
		table.insert( sortedTeams, { teamID = team, teamScore = GetTeamHeroKills( team ) } ) -- В таблицу сортированных команд заносится ключ TeamID и айди команды как значение, ключ teamScore и значение киллов команды
	end

	table.sort( sortedTeams, function(a,b) return ( a.teamScore > b.teamScore ) end ) --Сортируется таблицу команд

	for _, t in pairs( sortedTeams ) do -- Цикл перебирающие все сортированные команды
		local clr = self:ColorForTeam( t.teamID ) -- локальной переменной clr при помощи функции ищется цвет команды

		local score =  --Создается локальная таблица с ID команд и Очками команд
		{
			team_id = t.teamID,
			team_score = t.teamScore
		}
	--	FireGameEvent( "score_board", score ) -- Воспроизводится событие score_board с таблицей score
	end
	
	local leader = sortedTeams[1].teamID -- Локальный переменной лидер дают значение айди первой команды в таблице команд (т.к таблица сортированна, у него больше всех очков)
	
	self.leadingTeam = leader --переменной лидирующей команды становится лидер
	self.runnerupTeam = sortedTeams[2].teamID -- второе место
	self.leadingTeamScore = sortedTeams[1].teamScore -- количество очков лидера
	self.runnerupTeamScore = sortedTeams[2].teamScore -- количество очков второго места
	if sortedTeams[1].teamScore == sortedTeams[2].teamScore then -- Если количество очков первого и второго места равны, то ничья, иначе не ничья
		self.isGameTied = true
	else
		self.isGameTied = false
	end
	
end


--Функция по распределению команд
function CMultiverseBattlearenaGameMode:AssignTeams()

	local vecTeamValid = {} --Локальная переменная с пустой таблицей для подходящих команд
	local vecTeamNeededPlayers = {} -- Локальная переменная с пустой таблицей для команд где нужны игроки
	for nTeam = 0, (DOTA_TEAM_COUNT-1) do --Цикл, просматривающий все возможные команды, nTeam получает ID команды
		local nMax = GameRules:GetCustomGameTeamMaxPlayers( nTeam ) -- Смотрит сколько слотов в команде с nTeam ID
		if nMax > 0 then
			vecTeamNeededPlayers[ nTeam ] = nMax -- Если слотов больше 0, то в таблице команде с ID nTeam придают значение свободных слотов nMax
			vecTeamValid[ nTeam ] = true --В таблице подходящих команд, команда с ID nTeam становится подходящей
		else
			vecTeamValid[ nTeam ] = false --Если слотов меньше 0, то команда неподходящая
		end
	end

	local hPlayers = {} --создает пустую локальную таблицу hPlayers для нераспределенных игроков
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do  --Цикл просматривает ID всех игроков в игре
		if PlayerResource:IsValidPlayerID( nPlayerID ) then -- Проверяет есть ли игрок с таким идентификатором в игре
			local nTeam = PlayerResource:GetTeam( nPlayerID ) -- Локальная переменная nTeam с ID команды игрока
			if vecTeamValid[ nTeam ] == false then -- Если игрок находится в неподходящей команде
				nTeam = PlayerResource:GetCustomTeamAssignment( nPlayerID ) -- то nTeam получает id команды, которую выбрал пользователь
			end
			
			if vecTeamValid[ nTeam ] then  -- Если команда подходящая
				vecTeamNeededPlayers[ nTeam ] = vecTeamNeededPlayers[ nTeam ] - 1 -- Уменьшаем количество доступных слотов в команде на 1
			else
				table.insert( hPlayers, nPlayerID ) -- иначе вставляем в таблицу hPlayers, id игрока
			end
		end
	end


	for _,nPlayerID in pairs( hPlayers ) do -- Цикл для всех нераспределенных игроков в таблице hPlayers
		local nTeamNumber = -1 -- Локальная переменная для команды с наибольшним количеством свобоодных слотов
		local nHighest = 0 -- Локальная переменная максимума свободных слотов
		for nTeam = 0, (DOTA_TEAM_COUNT-1) do --Цикл просматривающий все команды
			if vecTeamValid[ nTeam ] then -- Если команда подходящая
				local nVal = vecTeamNeededPlayers[ nTeam ] -- то мы смотрим, сколько свободных слотов осталось
				if nVal > nHighest then -- Если свободных слотов больше всех
					nHighest = nVal -- Тогда максимум равен количеству свободных слотов команды
					nTeamNumber = nTeam -- Команда становится командой с наибольшим количеством свободных слотов
				end
			end
		end
		
		if nTeamNumber > 0 then --Если ID команды больше 0
			PlayerResource:SetCustomTeamAssignment( nPlayerID, nTeamNumber ) --Нераспределенного игрока помешают в эту команду
			vecTeamNeededPlayers[ nTeamNumber ] = vecTeamNeededPlayers[ nTeamNumber ] - 1 --Уменьшают на 1 количество слотов в команде
		end
	end
		
end

--Функция завершения игры
function CMultiverseBattlearenaGameMode:EndGame( victoryTeam )
		
	local tTeamScores = {} -- Создает пустую таблицу счета команд
	for team = DOTA_TEAM_FIRST, (DOTA_TEAM_COUNT-1) do --Цикл, просматривающий все команды
		tTeamScores[team] = GetTeamHeroKills(team) -- В таблицу с ключом ID команды пишется задается значение счета команды
	end
	
	GameRules:SetPostGameTeamScores( tTeamScores ) --Устанавливает счет команд после игры
	GameRules:SetGameWinner( victoryTeam ) --Устанавливает победителя игры
end

--Функция-таймер, выполняющая команды раз в тик
function CMultiverseBattlearenaGameMode:OnThink()

	self:UpdateScoreboard()
	if GameRules:IsGamePaused() == true then --Если игра находится на паузе, то таймер останавливается
        return 1
    end
	
    for nPlayerID = 0, (DOTA_MAX_TEAM_PLAYERS-1) do --Цикл проходящий через всех игроков по ID. DOTA_MAX_TEAM_PLAYERS - Сумма всех людей во всех командах
		self:UpdatePlayerColor( nPlayerID ) -- Использует функцию для присвоения игроку цвета его команды
	end
	
	if self.countdownEnabled == true then --Если игра началась и отсчет пошел
		CountdownTimer() -- Начинает идти таймер
		if nCOUNTDOWNTIMER == 30 then -- Если таймер равен 30 секунд
			CustomGameEventManager:Send_ServerToAllClients( "timer_alert", {} ) --Отправляется сообщение таймер алерт
		end
		
		if nCOUNTDOWNTIMER <= 0 then -- Если таймер достиг 0
			if self.isGameTied == false then -- Если сейчас не ничья
				GameRules:SetCustomVictoryMessage( self.m_VictoryMessages[self.leadingTeam] ) -- Выводит сообщение о победе команды
				CMultiverseBattlearenaGameMode:EndGame( self.leadingTeam ) -- Запускается функцию завершения игры
				self.countdownEnabled = false
			else
				self.TEAM_KILLS_TO_WIN = self.leadingTeamScore + 1
				local broadcast_killcount = 
				{
					killcount = self.TEAM_KILLS_TO_WIN
				}
				CustomGameEventManager:Send_ServerToAllClients( "overtime_alert", broadcast_killcount )
			end
       	end
	end
	
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then --Проверка на то, если игра находится в прогрессе	
		CMultiverseBattlearenaGameMode:SetRespawnTime() --Выполнение функции установливающее время спавна
	--	CMultiverseBattlearenaGameMode:NeutralCampProgression() -- Выполнение функции обновления лагерей крипов
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then --Если игра закончилась, таймер останавливается
		return nil
	end
	
	return 1
end