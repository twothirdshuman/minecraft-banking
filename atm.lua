local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
--- @type number, number
local width, height = monitor.getSize()

monitor.setCursorPos(1, 1)
monitor.write("check balance")
monitor.setCursorPos(1, 2)
monitor.write("do transaction")

while true do
    local _, _, x, y = os.pullEvent("monitor_touch")
    print(x, y)
end