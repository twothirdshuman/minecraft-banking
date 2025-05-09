local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
--- @type number, number
local width, height = monitor.getSize()

---@param title string
local function numberInput(title)

end

local function selectAccount()
    
end

monitor.setCursorPos(1, 1)
monitor.write("Check balance", colors.green)
monitor.setCursorPos(1, 3)
monitor.write("Do transaction", colors.blue)
monitor.setCursorPos(1, 5)
monitor.write("Create account", colors.yellow)
monitor.setCursorPos(1, 7)
monitor.write("List accounts", colors.red)

while true do
    print("waiting")
    local _, _, x, y = os.pullEvent("monitor_touch")
    
    break
end