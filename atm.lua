local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
--- @type number, number
local width, height = monitor.getSize()

--- @param text string
---@param line number
local function onLineCenter(text, line)
    local halfLength = string.len(text)
    monitor.setCursorPos(math.floor(width / 2) - math.floor(string.len(text) / 2) + 1, line)

    monitor.write(text)
end

--- @param text string
local function centerText(text)
    local y = math.floor(height / 2)
    local strLength = string.len(text)

    local lines = math.ceil(strLength / width)
    
    for i=1,lines do
        onLineCenter(string.sub(text, (i - 1) * width, math.min(strLength, i * width)), y + i - 1)
    end
end

local function showLoading() 
    local text = "Loading."
    while true do
        centerText(text)
        text = text.."."
        sleep(0.25)
    end
end

---@param title string
local function numberInput(title)

end

local function selectAccount()
    
end

--- @param title string
local function showAccounts(title) 
    monitor.setCursorPos(1, 1)
    monitor.write(title)

    local accounts = {}
    parallel.waitForAny(showLoading, function ()
        local res = http.get("https://minecraft-banking.deno.dev/atm.lua")
        
        if res.getResponseCode() ~= 200 then
            local err = res.readAll()
            print("Error occurred:"..err)
            centerText("Error occurred:"..err)
            return
        end
    
        accounts = textutils.unserialiseJSON(res.readAll())
    end)

    for i=1,#accounts do
        monitor.setCursorPos(1, i + 1)
        monitor.write(accounts[i])
    end

    local _, _, x, y = os.pullEvent("monitor_touch")
end

monitor.setCursorPos(1, 1)
monitor.write("Check balance", colors.green)
monitor.setCursorPos(1, 2)
monitor.write("Do transaction", colors.blue)
monitor.setCursorPos(1, 3)
monitor.write("Create account", colors.yellow)
monitor.setCursorPos(1, 4)
monitor.write("List accounts", colors.red)




local _, _, x, y = os.pullEvent("monitor_touch")
    
if y == 4 then
    showAccounts("All accounts:")
end


