--------------------------------------------------------------
-- Addon Metadata
--------------------------------------------------------------
addon.author   = 'Mugi (Ported to Ashita v4 by Djarum)';
addon.name     = 'Trustee';
addon.version  = '1.2.0';

--------------------------------------------------------------
-- Load Required Libraries
--------------------------------------------------------------
require 'common'
require 'name_map'

local settings = require 'settings'

--Default Settings
local default_settings = T{
	trustList = {}
}

local trustee = T{
	settings = settings.load(default_settings)
}

ashita.events.register('load', 'load_cb', function()
end)

ashita.events.register('unload', 'unload_cb', function()
	settings.save()
end)

--------------------------------------------------------------
-- Command Function:
-- Called whenever a command is entered in the game. Further
-- parsing is required once this function is called. If the
-- command is determined to be for this addon, return true.
-- Otherwise return false.
-- Args: a string representing the entered command.
-- Return: true if the command is handled by this addon.
--------------------------------------------------------------
ashita.events.register('command', 'command_cb', function(e)
	-- Break the incoming player command into individual tokens
	local parameters = e.command:args();
	
	-- Get the number of tokens in the command
	local tokenCount = length(parameters);
	
	-- If the user uses /trustee or /tr then it belongs to us,
	-- so we should process it here. Otherwise we let Ashita
	-- fall through to the next addon.
	if parameters[1] == '/trustee' or parameters[1] == '/tr' then
		
		-- If our command has exactly two tokens, process it here.
		-- Commands with two tokens:
		--   trustee tName
		--   trustee list
		--   trustee save
		--   trustee help
		if tokenCount == 2 then
			-- Handle the case for a list command
			if parameters[2] == 'list' then
				-- Print the current list from the command function
				printCurrentTrustLists('[List]');
				
				-- Finished processing this command
				return true;
			end
		
			-- Handle the case for a save command
			if parameters[2] == 'save' then
				settings.save()				

				-- Print confirmation
				print('[Trustee][Save] The addon settings and Trust list have been saved.');
				
				-- Finished processing this command
				return true;
			end
		
			-- Handle the case for a help command
			if parameters[2] == 'help' then
				-- Display the general help block.
				displayHelp();
				
				-- Finished processing this command
				return true;
			end
			
			-- Handle the case for a tName command. This must be at the end of the
			-- TokenCount(2) if statement to avoid cross-pollenating with other commands.
			summonTrustParty(parameters[2])

			return true
		end
		
		-- If our command has exactly two tokens, process it here.
		-- Commands with two tokens:
		--   trustee remove tName
		--   trustee help commandName
		--   trustee char charName
		if tokenCount == 3 then
			if parameters[2] == 'remove' then
				-- Remove the given trust set from the trust list.
				-- If no trust set exists, say so.
				if trustee.settings.trustList[parameters[3]] == nil then
					print('[Trustee][Remove] There is no trust set named "'.. parameters[3] .. '" in the list.');
				else
					trustee.settings.trustList[parameters[3]] = nil;
					print('[Trustee][Remove] Trust set "' .. parameters[3] .. '" has been removed.');
				end
				
				-- Finished processing this command
				return true;
			end		

			-- Handle the case for an individual help command
			if parameters[2] == 'help' then
				-- Display the individual help information for the given command
				displayIndividualHelp(parameters[3]);
				
				-- Finished processing this command
				return true;
			end	
			
			-- Handle the case for a char command (two-part names)
			if parameters[2] == 'char' then
				-- Print the character shorthand information, if it exists
				printCharacterShorthandNames(parameters[3]);
				
				-- Finished processing this command
				return true;
			end
		end
		
		-- If our command has more than three tokens, process it here.
		-- Commands with more than three tokens:
		--   trustee add SetName ListOfCharNames
		--   trustee add SetName party
		--   trustee char charNamePart1 charNamePart2
		if tokenCount > 3 then
			-- Handle the case for a char command (two-part names)
			if parameters[2] == 'char' then
				-- Print the character shorthand information, if it exists.
				-- The input is a string concatenation of a name split up
				-- by the command:args() function.
				printCharacterShorthandNames(parameters[3] .. ' ' .. parameters[4]);
				return true;
			end
			
			-- Handle the case for an add command 
			if parameters[2] == 'add' then
				-- Data Format: /command add setName CommaSeparatedListOfNames
				-- If the name entered is a Trustee reserved word, cancel and alert the user
				if not nameIsValid(parameters[3]) then
					print('[Trustee][Add] The name "' .. parameters[3] .. '" is reserved. Try again with another name.');
					return true;
				end
				
				-- Extract all the relevant information for easy usage.				
				local setName = parameters[3];
				local setCiphers = nil;
				
				-- If we're doing a party add, we collect the party names
				-- and extract the cipher list from them. If we're doing a
				-- regular add we extract the cipher list from the parameters.
				if parameters[4] == 'party' then
					setCiphers = { };
					
					-- Extract each name from the party list. If it's a cipher, store it in the cipher set.
					for i = 0, AshitaCore:GetMemoryManager():GetParty():GetAlliancePartyMemberCount1() - 1 do
						local cipherName = AshitaCore:GetMemoryManager():GetParty():GetMemberName(i):lower();
						if isCipher(cipherName) then
							table.insert(setCiphers, cipherName);
						end
					end

					-- If we found zero ciphers in the party, we cannot create a set and print an error.
					if length(setCiphers) == 0 then
						print('[Trustee][Add][Party] Cannot create a Trust set. Your party has no Trusts to store.');
						return true;
					end
				else
					-- The list of names can be a single element or multiple, but
					-- the 'getCipherNames' function can handle that.
					setCiphers = getCipherNames(parameters);				
				end

				-- Convert the Cipher short names to the Trust spell names
				for i = 1, length(setCiphers) do
					-- Retrieve the full name from the name map
					local tempCipher = getCipherNameFromShorthand(setCiphers[i])
									
					-- If the name wasn't matched, tell the user and cancel this command.
					if tempCipher == nil then
						print('[Trustee][Add] "' .. setCiphers[i] .. '" does not match any Trust names.' 
							  .. ' Change the name and try your command again.');
						return true;
					end
					
					-- Replace the shorthand name with the full name
					setCiphers[i] = tempCipher;
				end
				
				-- Check for a table entry update vs. a creation
				local tableState = trustee.settings.trustList[setName] == nil and 'created' or 'updated';
				
				-- Add the information to the trust lists table
				trustee.settings.trustList[setName] = setCiphers;
						
				-- Convert the cipher list to a string
				local cipherString = '';
				for i = 1, length(setCiphers) do
					cipherString = cipherString .. setCiphers[i] .. ', ';
				end 
				
				-- Inform the user of the changes
				print('[Trustee][Add] Successfully ' .. tableState .. ' "' .. setName .. '" trust set with: '
					  .. '[' .. cipherString:sub(1, cipherString:len()-2) .. ']');
				
				settings.save()
				-- Finished processing this command
				return true;
			end
		end
		
		-- If no valid command was given after /trustee or /tr, print a message
		print('[Trustee][Command] You entered an invalid or incomplete command "' .. command .. '". Enter "/trustee help" for addon information or try again.');
		
		-- If we are here, the command was for Trustee, but had invalid syntax
		return true;
	end

	-- If we arrive here, then the command is not meant for this addon; let it fall through
	return false;
end)

--************************************************************
--*                                                          *
--*      Non-Ashita Built-In Functions After This Point      *
--*                                                          *
--************************************************************

--------------------------------------------------------------
-- printCurrentTrustLists Function: 
-- When called, prints the entire set of trust lists to the
-- chat log. The list could be very long.
-- Returns: Nothing (Not Required)
--------------------------------------------------------------
function printCurrentTrustLists(location)
	print('[Trustee]' .. location .. ' Current Trust Sets are');
	
	-- If there are no current trust lists, print the empty message.
	-- Otherwise print the entries in a numbered list.
	if next(trustee.settings.trustList) == nil then
		print('     No Trust Lists Created\n');
	else
		local count = 1;
		local currentSet = '';
		for k, v in pairs(trustee.settings.trustList) do
			currentSet = '';
			for _, s in pairs(v) do 
				currentSet = currentSet .. s .. ', ';
			end
			currentSet = ((currentSet:len() > 0) and currentSet:sub(1,currentSet:len()-2)) or 'Empty';
			print('     ' .. count .. '. ' .. k .. ' -> [' .. currentSet .. ']');
			count = count + 1;
		end
		print(' ');
	end	
end

--------------------------------------------------------------
-- printCurrentTrustLists Function: 
-- When called, prints the entire set of trust lists to the
-- chat log. The list could be very long.
-- Returns: Nothing (Not Required)
--------------------------------------------------------------
function printCharacterShorthandNames(charName)
	if NameMap[charName] == nil then
		print('[Trustee][Char] There is no Trust named "' .. charName .. '". Check the spelling and try again.');
		return;
	end
	
	print('[Trustee][Char] Trust Shorthand Naming Information:');
	print(' ');
	print('Trust Name: ' .. charName);
	print(' ');
	print('Unique Names: ' .. charName .. ', ' .. NameMap[charName]:concat(', ') );
	print(' ');
	print('These unique names can be used with /tr add in the TrustList to add ' .. charName .. ' to a Trust set.');
	print('For more information on creating Trust sets, use the "/tr help add" command.');
	print(' '); 
end

--------------------------------------------------------------
-- getTrustSetString Function: 
-- When called, returns a string representing the trust set 
-- with the name provided.
-- Returns: a string representation of the named trust set.
--------------------------------------------------------------
function getTrustSetString(setName)
	local outputString = '';
	
	-- If the trust set does not exist, simply return "Empty"
	if trustee.settings.trustList[setName] == nil then
		return 'Empty';
	end
	
	-- Add all trust names to the output string
	for _, s in pairs(trustee.settings.trustList[setName]) do
		outputString = outputString .. s .. ', ';			
	end		
	
	-- If there are any trusts in the list, return them. Otherwise return "Empty".
	return (outputString:len() > 0 and outputString:sub(1,outputString:len()-2)) or 'Empty';
end

--------------------------------------------------------------
-- summonTrustParty Function: 
-- When called, attempts to summon the Trust set with the name
-- matching the input parameter. 
-- Returns: Nothing (Not Required)
--------------------------------------------------------------
function summonTrustParty(partyName)
	-- Check if the trustList contains a set with the name provided in partyName
	local trustSet = trustee.settings.trustList[partyName];
	
	-- If the provided set name has no party associated with it, print an error and cancel this summon
	if trustSet == nil then
		print('[Trustee][Command] Trust summon failed. The Trust List does not contain a set named "' .. partyName .. '".');
		return false;
	end
	
	print('[Trustee][Sets] Summoning Trust Set "' .. partyName .. '": [ ' .. getTrustSetString(partyName) .. ' ]');
	ashita.tasks.once(1, (function(trustSet, partyName)
		mmParty = AshitaCore:GetMemoryManager():GetParty()
		cManager = AshitaCore:GetChatManager()

		for x = 1, mmParty:GetAlliancePartyMemberCount1() do
			if isCipher(mmParty:GetMemberName(x - 1)) then
				print('[Trustee][Sets] Releasing existing trusts and waiting 4 seconds...');
				cManager:QueueCommand(1, '/refa all')			
				coroutine.sleep(4)
				break
			end
		end

		for _, v in pairs(trustSet) do
			cManager:QueueCommand(1, string.format('/ma "%s" <me>', v))
			coroutine.sleep(6)
		end
	end):bindn(trustSet, partyName))
	
	return true;
end

--------------------------------------------------------------
-- nameIsValid Function: 
-- When called, checks an incoming name against a set of addon
-- reserved words. If the name is reserved, return false. 
-- Otherwise return true.
-- Returns: true if name is valid, false otherwise
--------------------------------------------------------------
function nameIsValid(name)
	local reserved = { "add", "remove", "list", "help" };
	
	-- Check the incoming name against the above reserved list.
	-- If the incoming name is in the reserved list, return false.
	for _, n in pairs(reserved) do
		if name == n then
			return false;
		end
	end
	
	-- The name is not reserved
	return true;
end

--------------------------------------------------------------
-- getCipherNames Function: 
-- When called, extracts the names of the desired ciphers from
-- the list of parameters. This function can break the Cipher
-- names out of any properly formatted list of names provided
-- by the user.
-- Return: a properly formatted table of Cipher names.
--------------------------------------------------------------
function getCipherNames(list)
	-- Data Format: /command add setName CommaSeparatedListOfNames
	-- Since we receive all parameters, we know the list of
	-- names has to start at index 4.
	local names = '';
	local outNames = { };
	
	-- Compress all the names into a single string
	for i = 4, length(list) do
		names = names .. list[i];
	end
	
	-- Replace all the commas with spaces
	names = names:gsub(',', ' ');
	
	-- Split the string into lowercase tokens using space delimiters.
	-- Note this will remove all the "blank" cipher names provided 
	-- by the user, where the input included ",,".
	for i in names:gmatch("%S+") do
		table.insert(outNames,i:lower());
	end
		
	-- Return a table of Cipher names in proper format
	return outNames;
end

--------------------------------------------------------------
-- getCipherNameFromShorthand Function: 
-- When called, replaces all the short hand cipher names to
-- their exact trust spell names.
-- Return: a list of trust spell names.
--------------------------------------------------------------
function getCipherNameFromShorthand(cipher)
	-- Check every shorthand name of every cipher.
	-- If the shorthand name is found in a cipher's full name,
	-- return the full name.
	for k, v in pairs(NameMap) do
		for i, s in pairs(v) do
			if s == cipher then
				return k;
			end
		end
	end
	
	-- If no name could be matched, return nil
	return nil;
end

--------------------------------------------------------------
-- isCipher Function: 
-- When called, checks to ensure the input cipher is in the
-- cipher list.
-- Return: true if the cipher exists, otherwise false.
--------------------------------------------------------------
function isCipher(cipher)
	-- Check every shorthand name of every cipher.
	-- If the shorthand name is found in a cipher's full name,
	-- return true.
	for k, v in pairs(NameMap) do
		for _, s in pairs(v) do
			if s:lower() == cipher:lower() then
				return true;
			end
		end
	end
	
	-- If no name could be matched, return nil
	return false;
end

--------------------------------------------------------------
-- displayHelp Function: 
-- When called, prints the generic help block to the screen.
-- Return: Nothing (Not Required)
--------------------------------------------------------------
function displayHelp()
	print(' ');
	print('[Trustee][Help] The Trustee addon uses /trustee or /tr for commands.');
	print('The addon functionality can be accessed using the following commands:');
	print('/trustee add SetName TrustList');
	print('     This command creates a Trust set named SetName which summons the Trusts in the TrustList.');
	print('/trustee add SetName party');
	print('     This command creates a Trust set named SetName which contains all the Trusts currently in your party.');
	print('/trustee remove SetName');
	print('     Removes the Trust set named SetName.');
	print('/trustee save');
	print('     Save the current settings and Trust list to a file.');	
	print('/trustee SetName');
	print('     Summon the Trust set named SetName. This process takes approximately 6 seconds per Trust in the set (max. 30).');
	print('/trustee list');
	print('     List all the currently stored Trust sets.');
	print('/trustee help add/remove/setname/list');
	print('     Show more information related to the command you enter.');
	print('/trustee char TrustName');
	print('     Show information on the available shorthand names for the Trust character name entered.');
	print('/trustee help');
	print('     Show this help screen.');
	print(' ');
end

--------------------------------------------------------------
-- displayIndividualHelp Function: 
-- When called, prints the help block specific to the command.
-- Return: Nothing (Not Required)
--------------------------------------------------------------
function displayIndividualHelp(commandName)
	-- Create a single empty line at the top of a help screen
	print(' ');
	
	-- Choose the correct command to display help for
	if commandName == 'add' then
		print('[Trustee][Help] Add Trust Set Command:');
		print(' ');
		print('Syntax: /trustee add SetName TrustList');
		print('Syntax: /trustee add SetName party');
		print('This command creates a new Trust set which may be summoned later using /tr SetName.');
		print('SetName can be any character string and uniquely identifies the registered set. If SetName is');
		print('     already a set name, it will be overwritten. Note that SetNames are case sensitive.');
		print('TrustList is a comma-separated list of Trust names which will be included in the set named SetName.');
		print('     Name capitalization does not matter. Any spaces included in the TrustList will be removed. For');
		print('     a list of shorthand names available for a given Trust (to include in a TrustList), please use');
		print('     the command /trustee char TrustName, where TrustName is the Trust\'s full name from the in-game');
		print('     Trust menu.');
		print('The following examples all create differently named sets with the exact same Trust characters:');
		print('     /trustee add set1 Apururu (UC), Semih Lafihna, Trion');
		print('     /tr add set2 apururu,semih, Trion');
		print('     /tr add set3 Apururu,semih,trion');
		print('     /tr add set4 aPuRuRu,Semih Lafihna, TRION');
		print('Rather than including a list of Trusts, you may use the "party" keyword. This will create a Trust set');
		print('containing the Trusts which are currently present in your party. Note that this is incompatible with');
		print('alternate versions of Trusts (such as Lion vs. Lion II) because the game does not differentiate those');
		print('Trusts once they\'re in your party. For example, after summoning Lion II, her name will appear as Lion in');
		print('the party list and thus Trustee will only save their default name (Lion, not Lion II) in the Trust set.');
	elseif commandName == 'remove' then
		print('[Trustee][Help] Remove Trust Set Command:');
		print(' ');
		print('Syntax: /trustee remove SetName');
		print('SetName can be any character string and uniquely identifies the registered set. If SetName references');
		print('     a set in the trust set database, the associated Trust set will be removed. Otherwise this command');
		print('     will do nothing except show an alert message. Note that SetNames are case sensitive.');
	elseif commandName == 'setname' then
		print('[Trustee][Help] Summon Trust Set Command:');
		print(' ');
		print('Syntax: /trustee SetName');
		print('This command summons the Trust set uniquely identified by the SetName value. If the SetName value');
		print('     is not found in the Trust set database, no Trust set will be summoned. Note that SetNames');
		print('     are case sensitive.');
		print('The summoning process uses regular macro-style wait commands to ensure proper Trust cast timing.');
		print('The length of time required to summon a Trust set is based on size and takes the following times:');
		print('     1 Trust  = 10 seconds');
		print('     2 Trusts = 16 seconds');
		print('     3 Trusts = 22 seconds');
		print('     4 Trusts = 28 seconds');
		print('     5 Trusts = 34 seconds');
	elseif commandName == 'list' then
		print('[Trustee][Help] List Trust Sets Command:');
		print(' ');
		print('Syntax: /trustee list');
		print('This command shows all stored Trust sets in a numbered list in the format of SetName -> TrustList.');
	elseif commandName == 'char' then
		print('[Trustee][Help] Trust Character Shorthand Names Command:');
		print(' ');
		print('Syntax: /trustee char TrustName');
		print('This command will show the possible shorthand names for the Trust character\'s name entered. When');
		print('     entering names into the TrustList in a /tr add command, you may use a Trust\'s full name or');
		print('     one of the available shorthand names provided by this command.');
	else
		print('[Trustee][Help] No help information available for "' .. commandName .. '".');
	end
	
	-- Create a single empty line at the bottom of a help screen
	print(' ');
end

--------------------------------------------------------------
-- length Function: 
-- When called, returns the number of elements in a list/table.
-- Alternative to the '#' operator, which has the potential to
-- be incredibly inconsistent.
-- Return: an integer representing the length of the input.
--------------------------------------------------------------
function length(list)
	local count = 0;
	
	for _ in pairs(list) do 
		count = count + 1;
	end
	
	return count;
end