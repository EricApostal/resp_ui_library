print("========================================================================") 

local http_service = game:GetService("HttpService")

function generate_index(repository_url: string, folder_name: string)
    local repository_indexes = {}

    -- request file names / downloads from the repository (github API)
    local repository_response = http.request({
        Url = repository_url,
        Method = "GET",
        Headers = {
            ["Authorization"] = ""
        }
    })
    
    if repository_response.StatusCode ~= 200 then
        warn("Status code " .. tostring(repository_response.StatusCode) .. " was thrown when accessing URL \"" .. repository_url)
    end

    -- Converts the "Data" field of the http response to json
    
    local repository_data = http_service:JSONDecode( repository_response.Body )

    -- iterate through the entire response table
    for _, file_data in repository_data do
        if file_data.type == 'file' then
            table.insert(repository_indexes, {
                name = file_data.name,
                download_url = file_data.download_url,
                path = folder_name .. "/" ..file_data.name
            })
        elseif file_data.type == 'dir' then
            local subdirectory_name = file_data.name
            makefolder(folder_name .. "/" .. subdirectory_name .. "/")
            local subdirectory_data = generate_index(repository_url .. "/" .. file_data.name, folder_name)
            for _, subdirectory_file_data in subdirectory_data do
                -- so we can flatten the data, but have a path that extends to the subdir

                local _fdata = subdirectory_file_data
                print(subdirectory_name)
                _fdata.path = folder_name .. "/" .. subdirectory_name .. "/" .. _fdata.name
                
                table.insert(repository_indexes, _fdata)
            end
        end
    end
    return repository_indexes
end

function build_repository(repository_url: string, folder_name: string)
    print("Now building Repository for " .. folder_name)
    makefolder("repos")
    makefolder("repos/" .. folder_name)

    -- Returns a table of an index of the entire repository, including subdirectories
    local repository_index = generate_index(repository_url, folder_name)

    for i,v in repository_index do
        print(i .. "/" ..  #repository_index .. " items downloaded!") -- a bit spammy but works

        local working_directory = 'repos/'
        local path_split = string.split(v.path, '/')
        -- splits the path so we can remove the actual file name, and make a directory
        -- this could have been done by making v.path exist, but I kept having problems so here it will stay
        
        table.remove(path_split, #path_split)
        -- removes the last item of the array, so we can ignore the file name

        for _, segment in ipairs(path_split) do
            -- re-"stringifies" the array, so it can be used as a path.
            working_directory = working_directory .. segment .. "/"
        end

        working_directory = working_directory:sub(1, #working_directory - 1)
        -- Shortens the string by one as the last "/" can't be used in an actual file

        if not isfolder(working_directory) then
            -- just makes the folders for files to go into
            makefolder(working_directory)
            if not isfolder(working_directory) then
                error("No folder was made, you done messed something up -_-")
            end
        end

        -- now we can finally iterate through the table of downloads
        local lua_file_resp = http.request({
            Url = v.download_url,
            Method = "GET",
            Headers = {
                ["Authorization"] = ""
            }
        })

        -- grab the string
        local lua_file_content = lua_file_resp.Body

        -- now we need to actually write the individual file
        writefile("repos/" .. v.path, lua_file_content)
        
    end
end

print("Building roact repository...")
build_repository("https://api.github.com/repos/Roblox/roact/contents/src", "roact")
print("Roact has been downloaded!")