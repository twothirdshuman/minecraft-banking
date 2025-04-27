local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
--- @type number, number
local width, height = monitor.getSize()

monitor.setCursorPos(1, 1)
monitor.blit("Check balance", colors.green)
monitor.setCursorPos(1, 3)
monitor.write("Do transaction", colors.blue)

while true do
    local _, _, x, y = os.pullEvent("monitor_touch")
    
end