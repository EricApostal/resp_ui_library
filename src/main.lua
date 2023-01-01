--[[ 
Main UI builder :)
]]
print('MAIN FUNCTION RAN REEEE')
local roact = {}
for _, file in listfiles('repos\\roact', true) do  -- Set the second argument to `true` to include subdirectories
    if not file:match("%.%a+$") then  -- Skip directories
        local chunk = loadfile(file)
        roact[file] = chunk()
    end
end


--[[
    That is my hacky way of loading roact locally
    pretty fast tho
]]

for _,v in roact do
    print(v)
end

-- ======================================================== -- 

local LocalPlayer = game:GetService("Players").LocalPlayer

-- Create our virtual tree describing a full-screen text label.
local tree = roact.createElement("ScreenGui", {}, {
	Label = roact.createElement("TextLabel", {
		Text = "Hello, world!",
		Size = UDim2.new(1, 0, 1, 0),
	}),
})

-- Turn our virtual tree into real instances and put them in PlayerGui
roact.mount(tree, LocalPlayer.PlayerGui, "HelloWorld")