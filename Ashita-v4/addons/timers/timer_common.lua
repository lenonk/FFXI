function ActionIsLocal(actor)
    local party = AshitaCore:GetMemoryManager():GetParty()

    if not party then return false end

    -- Extract each party member's index and see if their ServerId matches actor
    for i = 0, party:GetAlliancePartyMemberCount1() - 1 do
        local serverId = party:GetMemberServerId(i)
        if serverId and (serverId == actor) then
            return true
        end
    end

    return false
end

function GetTargetIndex(target)
    if not target then return nil end

    local targetIndex = nil
    local packedIndex = bit.band(target, 0x7FF);

    if ((packedIndex < 0x400) and (AshitaCore:GetMemoryManager():GetEntity():GetServerId(packedIndex) == target)) then
        -- Target is a monster
        targetIndex = packedIndex
    else
        for i = 0x400,0x8FF do
            if (AshitaCore:GetMemoryManager():GetEntity():GetServerId(i) == target) then
                targetIndex = i;
                break;
            end
        end
    end

    return targetIndex
end
