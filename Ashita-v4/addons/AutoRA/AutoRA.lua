--Copyright © 2013, Banggugyangu
--Copyright © 2021, Djarum
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of <addon name> nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

addon.name = 'autora'
addon.author = 'Djarum'
addon.version = '4.0.0'

settings = require 'settings'

local jobs = {
    'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF',
    'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM',
    'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP',
    'DNC', 'SCH', 'GEO', 'RUN'
}

local default_settings = T{
    player_mjob = 'MON',
    language = 1,
    auto = true,

    job_settings = T{
        ['RNG'] = {
            HaltOnTp = false,
            Delay = 1.5,
            Ammo = 'Stone Arrow',
            AmmoBag = 'Stone Quiver',
            WeaponSkill = ''
        },
        ['COR'] = {
            HaltOnTp = false,
            Delay = 1.3,
            Ammo = 'Bronze Bullet',
            AmmoBag = 'Brz. Bull. Pouch',
            WeaponSkill = ''
        },
        ['THF'] = {
            HaltOnTp = false,
            Delay = 1.3,
            Ammo = 'Bronze Bolt',
            AmmoBag = 'B. Bolt Quiver',
            WeaponSkill = ''
        }
    }
}

local autora = T {
    settings = settings.load(default_settings)
}

local ActionCategory = {
    FinishedRangedAttack = 2,
    FinishedWeaponSkill = 3,
    BeginRangedAttack = 12
}

local getItemName = function(slot) 
    local mmInventory = AshitaCore:GetMemoryManager():GetInventory()

    local index = mmInventory:GetEquippedItem(slot).ItemIndex
    if index <= 0 then return nil end

    local bag = math.floor(index / 254)
    local slot = math.floor(index % 254)
    local id = mmInventory:GetItem(bag, slot).Id
    local item = AshitaCore:GetResourceManager():GetItemById(id)

    return item.Name[autora.settings.language] -- Index with current language instead of hardcoding 2 (English)
end

local queueCommand = function(mode, command)
    AshitaCore:GetChatManager():QueueCommand(mode, command)
end

function addToChat(mode, message)
    AshitaCore:GetChatManager():AddChatMessage(mode, false, message)
end

local shoot = function()
    queueCommand(1, '/shoot <t>')
end

local weaponSkill = function()
    s = autora.settings
    queueCommand(1, '/ws "' ..  s.job_settings[s.player_mjob].WeaponSkill .. '" <t>')
end

local equipAmmo = function()
    s = autora.settings
    queueCommand(1, '/equip ammo "' ..  s.job_settings[s.player_mjob].Ammo .. '"')
end

local useAmmoBag = function()
    ashita.tasks.once(0, function()
        s = autora.settings
        queueCommand(1, '/item "' .. s.job_settings[s.player_mjob].AmmoBag .. '" <me>')
        coroutine.sleep(3)
        queueCommand(1, '/equip ammo "' .. s.job_settings[s.player_mjob].Ammo ..'"')
    end)
end

start = function()
    autora.settings.auto = true
    addToChat(17, '*** AutoRA Starting')
    check()
end

stop = function()
    autora.settings.auto = false
    addToChat(17, '*** AutoRA Stopping')
end

check = function()
    if not autora.settings.auto then return end

    player = GetPlayerEntity()

    if not player or not player.TargetIndex then
        stop()
        return
    end

    local tp = AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0)
    s = autora.settings

    if tp >= 1000 then
        if s.job_settings[s.player_mjob].HaltOnTp then
            s.auto = false
            addToChat(17, '*** AutoRA Halting at 1000 TP')
        elseif player.Status == 1 and s.job_settings[s.player_mjob].WeaponSkill ~= '' then 
            ashita.tasks.once(0.1, weaponSkill)
            return
        end
    end

    shoot()
end

local reload = function()
    local bag_count = nil;
    local ammo = false;
    local s = autora.settings

    local inventory = AshitaCore:GetMemoryManager():GetInventory()
    local max = inventory:GetContainerCountMax(0) -- 0 should be players inventory

    for i = 0, max do
        local item = inventory:GetContainerItem(0, i)
        if item.Id > 0 then
            local item_name = AshitaCore:GetResourceManager():GetItemById(item.Id).Name[s.language]:lower()

            if item_name == s.job_settings[s.player_mjob].AmmoBag:lower() then
                bag_count = item.Count
            elseif item_name == s.job_settings[s.player_mjob].Ammo:lower() then
                ammo = true
            end
        end
    end

    if ammo == true then
        ashita.tasks.once(s.job_settings[player_mjob].Delay:num(), equipAmmo)
        local message = '*** AutoRA: equipped ' .. s.job_settings[s.player_mjob].Ammo .. ' from inventory.'
        addToChat(17, message)
        ashita.tasks.once(s.job_settings[s.player_mjob].Delay + 0.5, check)
    elseif bag_count > 0 then
        ashita.tasks.once(s.job_settings[s.player_mjob].Delay:num(), useAmmoBag)
        local message = '*** AutoRA: Used ' .. s.job_settings[s.player_mjob].AmmoBag .. '. You have ' .. bag_count - 1 .. ' left.'
        addToChat(17, message)
        ashita.tasks.once(s.job_settings[s.player_mjob].Delay + 3.5, check)
    else
        addToChat(17, '*** AutoRA: Uh oh!  Looks like you\'re out of ammo!')
        stop()
    end
end

local haltOnTp = function()
    local s = autora.settings
    s.job_settings[s.player_mjob].HaltOnTp = not s.job_settings[s.player_mjob].HaltOnTp

    if s.job_settings[s.player_mjob].HaltOnTp then
        addToChat(17, 'AutoRA will halt upon reaching 1000 TP')
    else
        addToChat(17, 'AutoRA will no longer halt upon reaching 1000 TP')
    end
end

ashita.events.register('text_in', 'text_in_cb', function(e)
    local s = autora.settings

    if not s.auto then return false end
    if e.message == nil or e.message == '' then return false end

    local player = GetPlayerEntity()

    if not player or not player.TargetIndex then
        stop()
        return false
    end
   
    if string.find(e.message, 'You do not have an appropriate ranged weapon equipped.') then
        reload()
        return false
    end

    if string.find(e.message, player.Name .. ' is no longer asleep.') then
        shoot()
        return false
    end

    if string.find(e.message, 'No experience points gained.')
        or string.find(e.message, 'You move and interrupt your aim.')
        or string.find(e.message, player.Name .. ' is paralyzed.')
        or string.find(e.message, ' too far away.')
        or string.find(e.message, 'Unable to see the ')
        or string.find(e.message, 'You cannot see ') then
        stop()
        return false
    end

    -- There is a bug in the code below, but I feel that it's a rare enough case that it's
    -- not worth doing the research necessary to fix it.
    -- If multiple mobs are being fought by your party, and one is defeated by a member of your
    -- party, but that one isn't the one you're fighting, AutoRA will stop.
    -- I could check to see if the name of mob the player is targetting is different from the 
    -- name of the mob that was defeated, but that wouldn't sove the case for two mobs of the 
    -- same name.
    if string.find(e.message, 'defeats ') then
        for i = 1, AshitaCore:GetMemoryManager():GetParty():GetAlliancePartyMemberCount1(), 1 do
            if string.find(e.message, AshitaCore:GetMemoryManager():GetParty():GetMemberName(i - 1)) then
                stop()
                return false
            end
        end
    end

    return false
end)

ashita.events.register('packet_in', 'packet_in_cb', function(e)
    local s = autora.settings

    if not s.auto then return false end

    if e.id == 0x0028 then -- Action packet
        local actor = struct.unpack('I', e.data, 6);
        local category = ashita.bits.unpack_be(e.data:totable(), 82, 4);
        
        --if (actor ~= AshitaCore:GetDataManager():GetParty():GetMemberServerId(0)) then return false end
        if actor ~= GetPlayerEntity().ServerId then return false end

        if category == ActionCategory.FinishedWeaponSkill then
            ashita.tasks.once(s.job_settings[s.player_mjob].Delay * 3, check)
        elseif category == ActionCategory.FinishedRangedAttack then
            local equip = AshitaCore:GetMemoryManager():GetInventory():GetEquippedItem(3) -- 3 == EquipmentSlots.Ammo in v3
            if equip  == nil or equip.Index <= 0 then
                reload()
            else
                ashita.tasks.once(s.job_settings[s.player_mjob].Delay:num(), check)
            end
        end
    elseif e.id == 0x1B then -- Job Change
        local newjobid = e.data:byte(0x08 + 1)

        if newjobid > #jobs then return false end

        if s.player_mjob == jobs[newjobid] then return false end

        s.player_mjob = jobs[newjobid]

        addToChat(17, '*** AutoRA Job Selection: ' .. s.player_mjob)

        if not s.job_settings[s.player_mjob] then 
            addToChat(17, ' No current settings for: ' .. s.player_mjob)
            return false
        end

        hotp = s.job_settings[s.player_mjob].HaltOnTp and 'True' or 'False'

        addToChat(17, ' Halt on TP: ' .. hotp)
        addToChat(17, ' Delay: ' .. s.job_settings[s.player_mjob].Delay)
        addToChat(17, ' Ammo: ' .. s.job_settings[s.player_mjob].Ammo)
        addToChat(17, ' Ammo bag: ' .. s.job_settings[s.player_mjob].AmmoBag)
        addToChat(17, ' Weaponskill: ' .. s.job_settings[s.player_mjob].WeaponSkill)
    end

    return false
end)

ashita.events.register('command', 'command_cb', function(e)
	local command = e.command:args()
    local s = autora.settings

	if not command then return false end

    if command[1] ~= '/ara' and command[1] ~= '/autora' then return false end

    command[2] = command[2] and command[2]:lower() or 'help'

    if #command < 3 and T{'delay', 'ammo', 'ammo_bag', 'ws'}:hasval(command[2]) then
        command[2] = 'help'
    elseif #command >= 4 then
        for i = 4, #command, 1 do
            command[3] = command[3] .. ' ' .. command[i]
        end
    end

    if command[2] == 'start' then
        start()
    elseif command[2] == 'toggle' then
        if s.auto then stop() else start() end
    elseif command[2] == 'stop' then stop() 
    elseif command[2] == 'shoot' then shoot()
    elseif command[2] == 'haltontp' then haltOnTp()
    elseif command[2] == 'delay' then
        s.job_settings[s.player_mjob].Delay = command[3]:num()
        addToChat(17, '*** AutoRA: Now using ' .. s.job_settings[s.player_mjob].Delay .. ' as delay')
        settings.save()
    elseif command[2] == 'ammo' then
        s.job_settings[s.player_mjob].Ammo = command[3]
        addToChat(17, '*** AutoRA: Now using ' .. s.job_settings[s.player_mjob].Ammo .. ' as ammunition')
        settings.save()
    elseif command[2] == 'ammo_bag' then
        s.job_settings[s.player_mjob].AmmoBag = command[3]
        addToChat(17, '*** AutoRA: Now using ' .. s.job_settings[s.player_mjob].AmmoBag .. ' as ammunition bag')
        settings.save()
    elseif command[2] == 'ws' then
        s.job_settings[s.player_mjob].WeaponSkill = command[3]
        addToChat(17, '*** AutoRA: Now using ' .. s.job_settings[s.player_mjob].WeaponSkill .. ' as weapon skill')
        settings.save()
    elseif command[2] == 'help' then
        addToChat(17, 'AutoRA Plus v' .. addon.version .. 'commands:')
        addToChat(17, '//ara [options]')
        addToChat(17, '    start          - Starts auto attack with ranged weapon')
        addToChat(17, '    stop           - Stops auto attack with ranged weapon')
        addToChat(17, '    toggle         - Toggles auto attack with ranged weapon')
        addToChat(17, '    haltontp       - Toggles automatic halt upon reaching 1000 TP')
        addToChat(17, '    ammo <type>    - Sets the ammo to equip in ammo slot')
        addToChat(17, '    ammo_bag <bag> - Sets the type of tool bag to break')
        addToChat(17, '    delay <secs>   - Sets the delay betwen shots')
        addToChat(17, '    ws <skill>     - Sets the preferred weapon skill')
        addToChat(17, '    help           - Displays this help text')
        addToChat(17, ' ')
        addToChat(17, 'Use Alt+D or /ara toggle to toggle auto attack.')
    end

    return true
end)

ashita.events.register('load', 'load_cb', function()
    local player = AshitaCore:GetMemoryManager():GetPlayer()

    autora.settings.auto = false
    autora.settings.player_mjob = jobs[player:GetMainJob()] or 'MON'

    queueCommand(1, '/bind !d /ara toggle')

    --autora.settings.language = AshitaCore:GetConfigurationManager():GetInt32("boot_config", "language", 2)
    --autora.settings.language = AshitaCore:GetConfigurationManager():GetInt32("boot", "ashita.language", "ashita", 2)

end)

ashita.events.register('unload', 'unload_cb', function()
    settings.save()
end)