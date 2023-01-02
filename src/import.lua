local import = {}

-- turns the imports into a 2D array with paths specified
function index_files(path)
    local files = {}
    local function index_dir(dir)
      for _, file in pairs(listfiles(dir)) do
        local name = file:match("([^/]+)$")
        files[name] = file:sub(#path + 2)
        if isfolder(dir.."/"..name) then
          index_dir(dir.."/"..name)
        end
      end
    end
    index_dir(path)
    return files
end
  
  
  
local files = index_files("repos/resp_ui_lib")
for file, name in pairs(files) do
  print(file, name)
end


return import