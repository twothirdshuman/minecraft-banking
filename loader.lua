local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
--- @type number, number
local width, height = monitor.getSize()

local function centerText(text)
    
end

while true do
    local _, _, x, y = os.pullEvent("monitor_touch")
    
end