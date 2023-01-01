--[[
    Grabs and builds the script + depends automatically
    intentionally modular for you skiddies out there :)
]]

function build_repository(url, folder_name) 
	--[[
	This takes a repository URL, then recursively builds it in the workspace folder
	I need a manifest file that can tell me versions and stuff, so I can handle all that
	Since I am iterating through the source though, that's a bit more dificult (I would have to grab commit dates and such)
	--]]
	
	local folder_path = 'repos\\' .. folder_name -- in case I want to modify the default directory
	
	makefolder("repos")
	makefolder(folder_path)

	local a = http.request({
	Url = url,
	Method = "GET"
	})

	local response = a.Body
	local json_body = game:GetService("HttpService"):JSONDecode(response)

	for _, v in json_body do
			
			if table.find(listfiles(folder_path), folder_path .. "\\" .. v.name) == nil then
				-- print( folder_path .. "\\" .. v.name .. " not in the dir " .. folder_path .. "(" .. #listfiles(folder_path) .. " items)" )
				-- print("Downloading " .. folder_path .. "\\" .. v.name)
				if v.type == 'file' then
					local content = http.request({
					Url = v.download_url,
					Method = "GET"
					}).Body
					
					-- print('Writing To: '.. folder_path .. '\\' .. v.name)
					writefile(folder_path .. '\\' .. v.name, content)
				elseif v.type == 'dir' then
					makefolder(folder_path .. '\\' .. v.name)
					build_repository(v.url, folder_name .. '\\' .. v.name)
				end
				
			else
				-- print("Found " .. folder_path .. "\\" .. v.name)
			end
	end

	-- print('Repository Built')
end

print("downloading depends")
build_repository("https://api.github.com/repos/Roblox/roact/contents/src?ref=master", "roact")
print("downloading main script")
build_repository("https://api.github.com/repos/Roblox/roact/contents/src?ref=master", "resps_ui_lib")