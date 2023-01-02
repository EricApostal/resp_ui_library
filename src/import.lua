local import = {}

-- turns the imports into a 2D array with paths specified
function import.make_module_table(module_path, module_name) -- module path is just the path to the base ei: repos/roact
    -- Initialize a table to store the index
    local repository_indexes = {}
    local data = listfiles(module_path)
    -- Iterate through the list of files and directories in the repository
    for _, file_data in data do
        -- If the current entry is a file, add it to the index
        if file_data.type == "file" then
            table.insert(repository_indexes, {
                name = file_data.name,
                download_url = file_data.download_url,
                path = string.format("%s/%s", module_name, file_data.name)
            })
        -- If the current entry is a directory, recursively generate an index for it
        elseif file_data.type == "dir" then
            local subdirectory_name = file_data.name
            makefolder(string.format("%s/%s/", module_name, subdirectory_name))
            local subdirectory_data = make_module_table(
                string.format("%s/%s", repository_url, file_data.name), module_name)
            -- Add the files and directories in the subdirectory to the index, with their paths modified to reflect the subdirectory
            for _, subdirectory_file_data in subdirectory_data do
                local _fdata = subdirectory_file_data
                _fdata.path = string.format("%s/%s/%s", folder_name, subdirectory_name, _fdata.name)
                table.insert(repository_indexes, _fdata)
            end
        end
    end
    return repository_indexes
end
    

return import