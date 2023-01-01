--[[
    Grabs and builds the script + depends automatically
    intentionally modular for you skiddies out there :)
]]

function build_repository(base_repo: string, folder_name: string, extra_path: string, is_recursive: boolean) 
	--[[
		- Recursively iterates through github repo
		- It has some strange params, but generally it's not too bad
		- I may make a function that generates an array of all information, then a second one 
			to actually download that info, so I could make an accurate progress bar.
	--]]
	if not is_recursive then is_recursive = false end -- weird lua stuff idk

	local folder_path = 'repos\\' .. folder_name
	local last_update_path = folder_path .. "\\last_update.txt"

	makefolder("repos")
	makefolder(folder_path)

	if not is_recursive then 
		url = base_repo .. "contents/" .. (extra_path or '')
	else 
		url = base_repo
	end

	local needs_update_resp = game:GetService("HttpService"):JSONDecode(http.request({
		Url = base_repo .. "branches/master",
		Method = "GET"
		}).Body )

	local needs_update = false
	if isfile(folder_path .. "\\last_update.txt") and not is_recursive then
		if readfile(last_update_path) ~= needs_update_resp.commit.commit.author.date then
			print("Repository needs to be updated, one moment!")
			needs_update = true
		else
			print("Dependency up to date!")
		end
	end

	local a = http.request({
	Url = url,
	Method = "GET"
	})

	local response = a.Body
	local json_body = game:GetService("HttpService"):JSONDecode(response)

	for _, v in json_body do
			if (table.find(listfiles(folder_path), folder_path .. "\\" .. v.name) == nil) or needs_update then
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
					build_repository(v.url, folder_name .. '\\' .. v.name, nil, true)
				end
				
			else
				-- print("Found " .. folder_path .. "\\" .. v.name)
			end
	end
	if not is_recursive then
		writefile(last_update_path, needs_update_resp.commit.commit.author.date)
	end
end

print("Checking dependencies...")
build_repository("https://api.github.com/repos/Roblox/roact/", "roact", "src?ref=master")
print("Installed, running script now...")