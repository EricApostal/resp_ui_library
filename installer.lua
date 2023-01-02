--[[
Basically just a repository cloner
clones into /repos/file_name

Intentionally modular for you skiddies out there <3
]]
for i = 1,10 do print('\n') end
-- module to just wrap some of the requests, makes my code look nice :D
function send_request(url)
	   local response = http.request({
	   Url = url,
	   Method = "GET",
	   Headers = {
		   ["Authorization"] = ""
	   }
	   })
	   if not response.StatusCode == 200 then
		   warn(string.format("Request returned with code %s!", response.StatusCode))
	   end
	   return response
   end

-- Get the HttpService
local http_service = game:GetService("HttpService")

-- Main function to build the repository
function build_repository(repository_url, folder_name)
	local url = repository_url

	if not string.match(url, "api.github.com") then
		-- so you can just drop any github url in and it works :)

		url = string.gsub(url, "www.github.com/", "api.github.com/repos/")
		url = string.gsub(url, "http://github.com/", "https://api.github.com/repos/")
		url = string.gsub(url, "https://github.com/", "https://api.github.com/repos/")
		url = string.gsub(url, "/tree/master/", "/contents/")

	end

    -- Create the "repos" directory if it does not exist
    makefolder("repos")

    -- Create a subdirectory within the "repos" directory with the specified name
    makefolder(string.format("repos/%s", folder_name))

    -- Generate an index of the repository's files and directories
    local repository_index = generate_index(url, folder_name)

    -- Download all of the files in the repository
    download_files(repository_index, folder_name, url)

    -- Print a message indicating that the repository has been built
    print("Repository built!")
end

function get_base_url(url)
	-- returns user/repo_name so it can be used for other api hits, while still allowing extendable urls
	-- ei: you can still pull from sirtzn/ui_lib/src, and it will pull sirtzn/ui_lib as well

	local api_base_stripped = string.gsub(url, "https://", "")
	local api_base_stripped = string.gsub(api_base_stripped, "http://", "")
	local api_base_stripped = string.gsub(api_base_stripped, "api.github.com/repos/", "")
	local api_base_stripped = string.gsub(api_base_stripped, "www.github.com/", "")
	
	local split_url = string.split(api_base_stripped, '/')

	local _r = string.format("%s/%s", split_url[1], split_url[2])
	return _r
end

function get_folder(full_path)
	-- strips the name of the item off, so I can accurately index the folder
	print( string.format("full_path = %s", full_path))
    local working_directory = "repos/"
    local path_split = string.split(full_path, '/')
    table.remove(path_split, #path_split)

    -- Iterate through the segments of the directory path and create each directory if it does not exist
    for _, segment in ipairs(path_split) do
        working_directory = string.format("%s%s/", working_directory, segment)
    end

    -- Remove the trailing slash from the directory path
    working_directory = working_directory:sub(1, #working_directory - 1)
	working_directory = string.gsub(working_directory, "//", "/")
	return working_directory
end

function needs_update(local_repository_base, repository_url, repository_index)
	-- checks if it needs to be installed or updated
	local last_update_path = string.format("%s/last_update.txt", "repos/" .. local_repository_base)
	if not isfile( last_update_path ) then
		print( string.format("(%s) Can't find last update, assuming first download", local_repository_base ))
		return true
	end

	for i,file in ipairs(repository_index) do
		if not isfile("repos/" .. file.path) then
			return true
		end
	end

	if get_last_commit_time(repository_url) == readfile(last_update_path) then
		-- does not need to update (same version)
		return false
	else
		-- does need to update (different version)
		return true
	end
end

function get_last_commit_time(repository_url)

	local last_commit_url = "https://api.github.com/repos/" .. get_base_url(repository_url) .. "/branches/master"
	local last_commit_str = send_request( last_commit_url ).Body
	
	local last_commit_time = http_service:JSONDecode(last_commit_str).commit.commit.committer.date

	if last_commit_time == nil then
		print( string.format("Error getting last commit time from url %s", repository_url ))
	end

	return last_commit_time
end
-- Function to download all of the files in the repository
function download_files(repository_index, local_repository_base, repository_url)
    -- Iterate through the list of files in the repository

	if not needs_update(local_repository_base, repository_url, repository_index) then
		-- print("Repo is already up to date!")
		return true
	end

    for i, file_data in ipairs(repository_index) do
        -- Print a message indicating the progress of the download
        print(string.format("%d/%d items downloaded!", i, #repository_index))

        -- Create the directory structure for the file if it does not exist
        create_directory(file_data.path)

        -- Download the file
        download_file(file_data)
    end

	-- Create file indicating the last repository update
	local last_commit_time = get_last_commit_time(repository_url)

	local path_to_write = string.format("repos/%s/last_update.txt", local_repository_base)
	writefile(path_to_write, last_commit_time)
end

-- Function to create the directory structure for a file if it does not exist
function create_directory(file_path)

	-- retrieves the folder name, removing the file
	-- ei: repos/roact/hello.lua -> repos/roact
	local working_directory = get_folder(file_path)
	local split_dir = string.split(working_directory, "/")
	local active_dir = ''

	for index, dir in split_dir do
		active_dir = active_dir .. "/" .. dir
		-- Create the directory if it does not exist
		if not isfolder(active_dir) then
			makefolder(active_dir)

			-- If the directory still does not exist after being created, throw an error
			if not isfolder(active_dir) then
				error(string.format("No folder was made, you done messed something up -_-\nFolder was intended to be at %s", working_directory))
			end
		end
	end
end

-- Function to download a file
function download_file(file_data)
    -- Make a request to the download URL of the file

	local response = send_request(file_data.download_url)
    -- Get the content of the file
    local file_content = response.Body

    -- Write the file to the repository directory
	print( string.format("Writing to directory: %s", string.format("repos/%s", file_data.path)) )
    writefile(string.format("repos/%s", file_data.path), file_content)
end

-- Function to generate an index of the repository's files and directories
function generate_index(repository_url, folder_name)
    -- Initialize a table to store the index
    local repository_indexes = {}

    -- Make a request to the repository URL
    local response = send_request(repository_url)

    -- If the request is not successful, print a warning message
    if response.StatusCode ~= 200 then
        warn(string.format("Status code %d was thrown when accessing URL %s",
            response.StatusCode, repository_url))
    end

    -- Decode the JSON response from the request
    local data = http_service:JSONDecode(response.Body)

    -- Iterate through the list of files and directories in the repository
    for _, file_data in data do

        -- If the current entry is a file, add it to the index
        if file_data.type == "file" then
            table.insert(repository_indexes, {
                name = file_data.name,
                download_url = file_data.download_url,
                path = string.format("%s/%s", folder_name, file_data.name)
            })
        -- If the current entry is a directory, recursively generate an index for it
        elseif file_data.type == "dir" then
            local subdirectory_name = file_data.name
            makefolder(string.format("%s/%s/", folder_name, subdirectory_name))
            local subdirectory_data = generate_index(
                string.format("%s/%s", repository_url, file_data.name), folder_name)
            -- Add the files and directories in the subdirectory to the index, with their paths modified to reflect the subdirectory
            for _, subdirectory_file_data in subdirectory_data do
                local _fdata = subdirectory_file_data
                _fdata.path = string.format("%s/%s/%s", folder_name, subdirectory_name, _fdata.name)
                table.insert(repository_indexes, _fdata)
            end
        end
    end
	-- print( string.format("NEW PATH: %s", path) )

	-- converts the relative paths into absolute paths
	-- a bit hacky, but works for descening infinite directories
	for i,v in repository_indexes do
		local file_info = v

		local path = string.gsub(file_info.download_url, "https://raw.githubusercontent.com/", "https://api.github.com/repos/")
		local path = string.gsub(path, string.gsub(repository_url, "contents", "master"), "")
		local path = string.gsub(path, "//", "/")
		local path = folder_name .. "/" .. path
		file_info.path = path

	end

    return repository_indexes
end

print("Building roact repository...")
-- build_repository("https://github.com/Roblox/roact/tree/master/src", "roact")
print("Roact has been downloaded!")
print("Building main script hub...")
build_repository("https://github.com/SirTZN/resp_ui_library/tree/master/src", "resp_ui_lib")
print("Script hub has been downloaded!\nRunning script!")

print(string.format("is main.lua a file? %s", tostring(isfile("repos/resp_ui_lib/main.lua"))))
dofile("repos/resp_ui_lib/main.lua")

