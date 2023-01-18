local import = {}

-- turns the imports into a 2D array with paths specified
function index_modules(module_path)
    local files = {}
    local all_modules = listfiles(module_path)

    for i, item in pairs(all_modules) do
      -- Modify the path field to include the full path to the file
  
      local name = item.name
      local path = all_modules .. "/" .. item.name
      local download_url = item.download_url
      local file_data = {
        name = name,
        path = path,
        type = item.type,
        download_url = download_url
      }
      table.insert(files, file_data)
      -- Check if the item is a directory
  
      if item.type == "dir" then
          local subfiles = index_modules(item.url, path)
  
          for subfile_name, subfile_info in pairs(subfiles) do
              -- print( string.format("Subfile name = %s", subfile_name) )
              table.insert(files, subfile_info)
          end
      end
    end
end


function import.test()

	print("Foo!")

end

-- local files = index_modules("repos/resp_ui_lib")
-- for file, name in pairs(files) do
--   print(file, name)
-- end


return import