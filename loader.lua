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

local function waitForStart()
    monitor.clear()
    centerText("Press anywhere to start")
    local _, _, x, y = os.pullEvent("monitor_touch")
end

local function loadAndExecute()
    monitor.clear()
    centerText("Loading...")
    local res = http.get("https://minecraft-banking.deno.dev/atm.lua")
    
    if res.getResponseCode() ~= 200 then
        local err = res.readAll()
        print("Error occurred:"..err)

    end

    local script = res.readAll()
    local func, err = load(script)
    if err ~= nil then
        print("Error occurred: "..err)
        centerText("Error")
        sleep(5)
        return
    end

    if func == nil then
        print("could not load func")
        centerText("could not load func")
        sleep(5)
        return
    end
    func()
end

while true do
    waitForStart()
    loadAndExecute()
end