local data = {};

data.EquipSum = function(table)
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

--Argument(id): Integer representation of a buff id.
--Return: Boolean
--Value: True if the buff id is present on the player, false if not.
data.GetBuffActive = function(id)

end

--Argument(id): Integer representation of skill ID, as listed in dats.
--Return: Integer
--Value: The player's current level in that skill.
data.GetCombatSkill = function(id)

end

--Return: Table with keys as 1-indexed integers representing equipment slot.  (Main = 1, Back = 16)
--Table.Id: The item's Id, or 0 if no item present.
--Table.ExtData: The item's 28 byte additional data field as a 1-indexed array of bytes, or a table with [1] = 0 if no item present.
data.GetEquipmentTable = function()

end

--Return: Zero-indexed integer representing player's current main job (1 = war, 2 = mnk, 22 = run)
data.GetMainJob = function()

end

--Return: Integer representing player's current main job level.
data.GetMainJobLevel = function()

end

--Argument(id): Integer representing a MERIT_TYPE(https://github.com/LandSandBoat/server/blob/base/src/map/merit.h)
--Return: Integer representing the number of merit upgrades the player has in this category.
data.GetMeritCount = function(id)

end

--Argument(job): Zero-indexed integer representing a job (1 = war, 2 = mnk, 22 = run)
--Argument(category): Zero-indexed integer representing category(0-9)
--Return: Integer representing the number of job points the player has in this category.
data.GetJobPoints = function(job, category)

end

--Argument(job): Zero-indexed integer representing a job (1 = war, 2 = mnk, 22 = run)
--Return: Integer representing the total number of spent job points the player has on this job(for gifts)
data.GetJobPointTotal = function(job)

end

--Return: Integer matching the player's current Id.
data.GetPlayerId = function()

end

--Return: Zero-indexed integer representing player's current main job (1 = war, 2 = mnk, 22 = run)
data.GetSubJob = function()

end

--Return: Integer representing player's current main job level.
data.GetSubJobLevel = function()

end

--Return: Integer representing the player's current zone.
data.GetZone = function()

end

return data;