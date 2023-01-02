--[[
    Grabs and builds the script + depends automatically
    intentionally modular for you skiddies out there :)
]]

--[[
this script already needs a rewrite:
	- separate function for indexing into subdirectories ->
		returns table w/paths, then iterates those paths and downlaods in a 
		much more simple script.

	

]]

function build_repository(base_repo: string, folder_name: string, extra_path: string, is_recursive: boolean) 
	--[[
		- Recursively iterates through github repo
		- It has some strange params, but generally it's not too bad
		- I may make a function that generates an array of all information, then a second one 
			to actually download that info, so I could make an accurate progress bar.
	--]]
	if not is_recursive then is_recursive = false end -- nil and false work very strangely in lua...

	local folder_path = 'repos\\' .. folder_name
	local last_update_path = folder_path .. "\\last_update.txt"

	makefolder("repos")
	makefolder(folder_path)

	--[[
		- It's important to note that "is_recursive" is only true when descendend into subdirectories
		- It's generally better to iterate this way so I don't have to maintain 2 functions that
		essentially do the same thing
	]]

	if not is_recursive then
		print("Installing " .. folder_name .. "...")
		url = base_repo .. "contents/" .. (extra_path or '')
	else 
		url = base_repo
	end

	local needs_update_resp = game:GetService("HttpService"):JSONDecode(http.request({
		Url = base_repo .. "branches/master",
		Method = "GET"
		}).Body )

	local needs_update = false
	if isfile(folder_path .. "\\last_update.txt") then
		if readfile(last_update_path) ~= needs_update_resp.commit.commit.committer.date then
			print("Repository " .. folder_name .. " needs to be updated, one moment!")
			delfolder(folder_path)
			needs_update = true
		else
			print("Dependency up to date!")
			print(readfile(last_update_path))
			print(needs_update_resp.commit.commit.author.date)
		end
	end

	local a = http.request({
	Url = url,
	Method = "GET"
	})

	local response = a.Body
	local json_body = game:GetService("HttpService"):JSONDecode(response)
	for _, v in json_body do
		if v.name == nil then warn(v) end
			if needs_update or (table.find(listfiles(folder_path), folder_path .. "\\" .. v.name) == nil) then
				if v.type == 'file' then
					local content = http.request({
					Url = v.download_url,
					Method = "GET"
					}).Body
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
		print(needs_update_resp)
		writefile(last_update_path, needs_update_resp.commit.commit.author.date)
		print("Installed " .. folder_name .. "!")
	end
end

print("Checking dependencies...")
build_repository("https://api.github.com/repos/Roblox/roact/", "roact", "src?ref=master")
build_repository("https://api.github.com/repos/SirTZN/resp_ui_library/", "resp_ui_lib")
print("Installed, running script now...")
local main_script = loadfile('repos\\resp_ui_lib\\src\\main.lua')
print(main_script)