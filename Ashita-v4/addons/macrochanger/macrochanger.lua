-- A quick rewrite of the Windower addon for Ashita v3 that swaps your macro pallette on job change.
-- Yes, I'm lazy.

addon.name = 'MacroChanger'
addon.author = 'Derahine, Djarum'
addon.version = '1.0.0.0'

require 'common'

jobs = {
	[1]  = 'WAR',
	[2]  = 'MNK',
	[3]  = 'WHM',
	[4]  = 'BLM',
	[5]  = 'RDM',
	[6]  = 'THF',
	[7]  = 'PLD',
	[8]  = 'DRK',
	[9]  = 'BST',
	[10] = 'BRD',
	[11] = 'RNG',
	[12] = 'SAM',
	[13] = 'NIN',
	[14] = 'DRG',
	[15] = 'SMN',
	[16] = 'BLU',
	[17] = 'COR',
	[18] = 'PUP',
	[19] = 'DNC',
	[20] = 'SCH',
	[21] = 'GEO',
	[22] = 'RUN'
}

macros = {
	THF = {Book = '1', Page = '1'},
	WHM = {Book = '2', Page = '1'},
	RDM = {Book = '3', Page = '1'},
	RUN = {Book = '4', Page = '1'},
	MNK = {Book = '5', Page = '1'},
	SAM = {Book = '6', Page = '1'},
	PLD = {Book = '7', Page = '1'},
	DRK = {Book = '8', Page = '1'},
	BST = {Book = '9', Page = '1'},
	BRD = {Book = '10', Page = '1'},
	RNG = {Book = '11', Page = '1'},
	DRG = {Book = '12', Page = '1'},
	NIN = {Book = '13', Page = '1'},
	WAR = {Book = '14', Page = '1'},
	PUP = {Book = '15', Page = '1'},
	SCH = {Book = '16', Page = '1'},
	COR = {Book = '17', Page = '1'},
	BLU = {Book = '18', Page = '1'},
	DNC = {Book = '19', Page = '1'},
	BLM = {Book = '20', Page = '1'},

	SMN = {Book = '2', Page = '5'},
	GEO = {Book = '16', Page = '5'}
}

config = {
	current_job = ''
}

ashita.events.register('load', 'load_cb', function()
end);

ashita.events.register('unload', 'unload_cb', function()
end);

function send_to_log(msg)
	print('\31\200[\31\05' .. addon.name .. '\31\200]\30\01 ' .. msg);
end

ashita.events.register('packet_in', 'packet_in_cb', function(e)
	if (e.id == 0x1B) then		
		local jobId = e.data:byte(0x08 + 1)
		local job = jobs[jobId]
		if (config.current_job ~= job) then
			config.current_job = job
			local book = ''
			local page = ''
			if job and macros[job] then
				book = macros[job].Book
				page = macros[job].Page			
			
				send_to_log('[\31\05'.. job ..'\30\01] Changing macros to Book: '.. book .. ' and Page: '.. page)
				ashita.tasks.once(1, (function(book, page)
					AshitaCore:GetChatManager():QueueCommand(1, '/macro book ' .. book)
					coroutine.sleep(1.2)
					AshitaCore:GetChatManager():QueueCommand(1, '/macro set ' .. page)
				end):bindn(book, page))

			end
		end	
	end
	return false;
end)
