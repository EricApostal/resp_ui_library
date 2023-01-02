local main = {}
--[[ 
Main UI builder :)
]]
print("main program called :)")

function main.start()
    local roact = {}

    -- dodgy ass way to load libraries --
    for _, file in listfiles('repos\\roact', true) do  -- Set the second argument to `true` to include subdirectories
        if not file:match("%.%a+$") then  -- Skip directories
            local chunk = loadfile(file)
            roact[file] = chunk()
        end
    end    
    --------------------------------------
    print("Main function called!")
end

return main