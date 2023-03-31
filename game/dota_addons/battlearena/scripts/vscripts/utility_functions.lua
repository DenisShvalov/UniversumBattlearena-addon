--[[ utility_functions.lua ]]

---------------------------------------------------------------------------
-- Handle messages
---------------------------------------------------------------------------
function BroadcastMessage( sMessage, fDuration )
    local centerMessage = {
        message = sMessage,
        duration = fDuration
    }
    FireGameEvent( "show_center_message", centerMessage )
end

function PrintTable( t, indent )
    --print( "PrintTable( t, indent ): " )

    if type(t) ~= "table" then return end
    
    if indent == nil then
        indent = "   "
    end

    for k,v in pairs( t ) do
        if type( v ) == "table" then
            if ( v ~= t ) then
                print( indent .. tostring( k ) .. ":\n" .. indent .. "{" )
                PrintTable( v, indent .. "  " )
                print( indent .. "}" )
            end
        else
        print( indent .. tostring( k ) .. ":" .. tostring(v) )
        end
    end
end

function PickRandomShuffle( reference_list, bucket )
    if ( #reference_list == 0 ) then
        return nil
    end
    
    if ( #bucket == 0 ) then
        -- ran out of options, refill the bucket from the reference
        for k, v in pairs(reference_list) do
            bucket[k] = v
        end
    end

    -- pick a value from the bucket and remove it
    local pick_index = RandomInt( 1, #bucket )
    local result = bucket[ pick_index ]
    table.remove( bucket, pick_index )
    return result
end

-- Создание копии
function shallowcopy(orig)
    local orig_type = type(orig) -- Локальной переменной передается тип оригиниала
    local copy -- Создается локальная переменная копия
    if orig_type == 'table' then -- Если тип оригинала - таблица тогда
        copy = {} -- Копия становится пустой таблицей
        for orig_key, orig_value in pairs(orig) do --Передаются значения ключей и значений из оригинала в копию
            copy[orig_key] = orig_value
        end
    else --Если тип данных не таблица
        copy = orig --Копия просто берет данные оригинала
    end
    return copy
end

--Функция для перемешивания списка
function ShuffledList( orig_list )
	local list = shallowcopy( orig_list ) --Создается локальный список копирующий список-аргумент
	local result = {} -- Локальная пустая таблица результата
	local count = #list --Передается количество элементов списка
	for i = 1, count do --Цикл перебирающий все позиции списка
		local pick = RandomInt( 1, #list ) --Выбирают случайное число от 1 до длины списка
		result[ #result + 1 ] = list[ pick ] -- Ставит последним элементом таблицы результата, элемент списка list под индексом pick
		table.remove( list, pick ) -- Удаляет из таблицы элемент с индексом pick
	end
	return result -- Возвращает перемешанный список
end

--Функция для рассчета размера таблицы
function TableCount( t ) 
	local n = 0 --Локальная переменная n = 0
	for _ in pairs( t ) do -- Цикл в котором перебирают каждое значение из таблицы t
		n = n + 1 -- n++
	end
	return n -- возвращает длину таблицы
end

function TableFindKey( table, val )
	if table == nil then
		print( "nil" )
		return nil
	end

	for k, v in pairs( table ) do
		if v == val then
			return k
		end
	end
	return nil
end

function CountdownTimer()
    nCOUNTDOWNTIMER = nCOUNTDOWNTIMER - 1 --Уменьшение таймера на секунду (???)
    local t = nCOUNTDOWNTIMER 
    local minutes = math.floor(t / 60) -- Рассчет оставшихся минут
    local seconds = t - (minutes * 60) -- Рассчет отсавшихся секунд, не считая минуты
    local m10 = math.floor(minutes / 10) -- Рассчет десятков минут
    local m01 = minutes - (m10 * 10) --Рассчет единиц минут
    local s10 = math.floor(seconds / 10) -- Рассчет десятков секунд
    local s01 = seconds - (s10 * 10) -- Рассчет единиц секунд
    local broadcast_gametimer = 
        {
            timer_minute_10 = m10,
            timer_minute_01 = m01,
            timer_second_10 = s10,
            timer_second_01 = s01,
        }
    CustomGameEventManager:Send_ServerToAllClients( "countdown", broadcast_gametimer ) --Сервер отправляет всем игрокам событие countdown (отсчет времени) и информацией broadcast_gametimer(оставшееся время) Используется в панораме
    if t <= 120 then
        CustomGameEventManager:Send_ServerToAllClients( "time_remaining", broadcast_gametimer ) --Если времени меньше или равно 120 секунд, идет обратный отсчет оставшегося времени
    end
end

function SetTimer( cmdName, time )
    print( "Set the timer to: " .. time )
    nCOUNTDOWNTIMER = time
end
