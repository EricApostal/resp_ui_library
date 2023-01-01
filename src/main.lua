--[[ 
Main UI builder :)
]]

local roact = {}
for _, file in listfiles('repos\\roact', true) do  -- Set the second argument to `true` to include subdirectories
    if not file:match("%.%a+$") then  -- Skip directories
        local chunk = loadfile(file)
        roact[file] = chunk()
    end
end

function main()
    print("main lua file called!")
end