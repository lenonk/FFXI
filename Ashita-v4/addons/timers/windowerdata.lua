gData = {};

--Quicky function to sum values from a table with item ID as key and a numerical value.
--Shouldn't need to be changed.
gData.EquipSum = function(table)
    local total = 0;
    local equipment = gData.GetEquipmentTable();
    for _,equipPiece in pairs(equipment) do
        local value = table[equipPiece.Id];
        if value ~= nil then
            total = total + value;
        end
    end
    return total;
end

--Should be compatible with windower as long as ExtData is correctly set.
--If you don't like the hideous code, can certainly fill the table with your own extdata lib and omit ExtData from GetEquipmentTable entirely.
gData.ParseAugments = function()
    local result = {};
    result.EnhancingDuration = 0;
    result.EnhancingReceived = 0;
    result.Generic = {};

    local equipment = gData.GetEquipmentTable();
    for _,equipPiece in pairs(equipment) do
        if equipPiece ~= nil and equipPiece.ExtData ~= nil then
            local extData = equipPiece.ExtData;
            local augType = struct.unpack('B', extData, 1);
            if (augType == 2) or (augType == 3) then
                local augFlag = struct.unpack('B', extData, 2);
                if (augFlag % 64) >= 32 then
                    --Delve
                elseif (augFlag == 131) then
                    --Dynamis Augments

                    --Dls. Torques
                    if equipPiece.Id == 25441 or equipPiece.Id == 25442 or equipPiece.Id == 25443 then
                        local rankByte = struct.unpack('B', extData, 7);
                        local rank = ((rankByte % 128) - (rankByte % 4)) / 4;
                        result.EnhancingDuration = result.EnhancingDuration + (rank / 100);
                    end
                    
                    --Ajax
                    if equipPiece.Id == 27639 then
                        local rankByte = struct.unpack('B', extData, 7);
                        local rank = ((rankByte % 128) - (rankByte % 4)) / 4;
                        if (rank > 0) then
                            result.EnhancingReceived = result.EnhancingReceived + ajaxValues[rank];
                        end
                    end

                elseif (augFlag % 16) >= 8 then
                    --Shield
                elseif (augFlag % 256) >= 128 then
                    --Evolith
                else
                    local maxAugments = 5;
                    if (augFlag % 128) >= 64 then --Magian
                        maxAugments = 4;
                    end
                    for i = 1,maxAugments,1 do
                        local augmentBytes = struct.unpack('H', extData, 1 + (2 * i));
                        local augmentId = augmentBytes % 0x800;
                        local augmentValue = (augmentBytes - augmentId) / 0x800;
                        if (augmentId == 0x4E0) then
                            result.EnhancingDuration = result.EnhancingDuration + ((augmentValue + 1) / 100);         
                        elseif result.Generic[augmentId] == nil then
                            result.Generic[augmentId] = { augmentValue };
                        else
                            local augTable = result.Generic[augmentId];
                            augTable[#augTable + 1] = augmentValue;
                        end
                    end
                end
            end
        end
    end

    return result;
end

--Argument(id): Integer representation of a buff id.
--Return: Boolean
--Value: true if the buff id is present on the player, false if not.
gData.GetBuffActive = function(id)

end

--Argument(id): Integer representation of skill ID, as listed in dats.
--Return: Integer
--Value: The player's current level in that skill.
gData.GetCombatSkill = function(id)

end

--Return: Table with keys as 1-indexed integers representing equipment slot.  (Main = 1, Back = 16)
--Table.Id: The item's Id, or 0 if no item present.
--Table.ExtData: The item's 28 byte additional data field as a 1-indexed array of bytes, or a table with [1] = 0 if no item present. (Only used in ParseAugments)
gData.GetEquipmentTable = function()

end

--Return: Integer representing player's current main job (1 = war, 2 = mnk, 22 = run)
gData.GetMainJob = function()

end

--Return: Integer representing player's current main job level.
gData.GetMainJobLevel = function()

end

--Argument(id): Integer representing a MERIT_TYPE(https://github.com/LandSandBoat/server/blob/base/src/map/merit.h)
--Return: Integer representing the number of merit upgrades the player has in this category.
gData.GetMeritCount = function(id)

end

--Argument(job): Zero-indexed integer representing a job (1 = war, 2 = mnk, 22 = run)
--Argument(category): Zero-indexed integer representing category(0-9)
--Return: Integer representing the number of job points the player has in this category.
gData.GetJobPoints = function(job, category)

end

--Argument(job): Zero-indexed integer representing a job (1 = war, 2 = mnk, 22 = run)
--Return: Integer representing the total number of spent job points the player has on this job(for gifts)
gData.GetJobPointTotal = function(job)

end

--Return: Integer matching the player's current Id.
gData.GetPlayerId = function()

end

--Return: Zero-indexed integer representing player's current main job (1 = war, 2 = mnk, 22 = run)
data.GetSubJob = function()

end

--Return: Integer representing player's current main job level.
data.GetSubJobLevel = function()

end

--Return: Integer representing the player's current zone.
gData.GetZone = function()

end