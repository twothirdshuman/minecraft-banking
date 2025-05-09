local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
monitor.clear()
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

--- @param accountName string
local function showBalance(accountName)
    local balance = nil
    parallel.waitForAny(showLoading, function ()
        local res = http.get("https://minecraft-banking.deno.dev/api/getBalance?account="..accountName)

        if res.getResponseCode() ~= 200 then
            local err = res.readAll()
            print("Error occurred:"..err)
            centerText("Error occurred:"..err)
            sleep(10)
            return
        end

        balance = textutils.unserialiseJSON(res.readAll())["balance"]
    end)

    monitor.clear()
    onLineCenter(accountName, 2)
    onLineCenter("balance:", 4)

    local money = "$"..balance
    if balance < 0 then
        money = "-$"..(-balance)
    end

    onLineCenter(money, 5)
    local _, _, _, _ = os.pullEvent("monitor_touch")
end

--- @param title string
--- @return string | nil
local function showAccounts(title)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write(title)

    local accounts = {}
    parallel.waitForAny(showLoading, function ()
        local res = http.get("https://minecraft-banking.deno.dev/api/getAccounts")
        
        if res.getResponseCode() ~= 200 then
            local err = res.readAll()
            print("Error occurred:"..err)
            centerText("Error occurred:"..err)
            sleep(10)
            return
        end
    
        accounts = textutils.unserialiseJSON(res.readAll())
    end)

    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write(title)
    for i=1,#accounts do
        monitor.setCursorPos(1, i + 1)
        monitor.write(accounts[i])
    end

    local _, _, x, y = os.pullEvent("monitor_touch")

    if (y - 1) <= #accounts then
        return accounts[y - 1]
    end
    return nil
end


---@param title string
local function numberInput(title)
    onLineCenter(title, 1)

    -- red - e 
    -- white  - 0
    -- green  - d
    -- black - f


    local emptyLine = function ()
        monitor.blit("               ", "000000000000000", "fffffffffffffff")
    end

    local bgLine = "fdddffdddffdddf"
    local fgLine = "000000000000000"

    local startY = height - (4 * 3)
    monitor.setCursorPos(1, startY)
    emptyLine()
    monitor.setCursorPos(1, startY + 1)
    monitor.blit("  1    2    3  ", fgLine, bgLine) -- width 15
    monitor.setCursorPos(1, startY + 2)
    emptyLine()
    monitor.setCursorPos(1, startY + 3)
    monitor.blit("  4    5    6  ", fgLine, bgLine) -- width 15
    monitor.setCursorPos(1, startY + 4)
    emptyLine()
    monitor.setCursorPos(1, startY + 5)
    monitor.blit("  7    8    9  ", fgLine, bgLine) -- width 15
    monitor.setCursorPos(1, startY + 6)
    emptyLine()
    monitor.setCursorPos(1, startY + 7)
    monitor.blit(" clr   0   sbm ", "00000000000fff0", "feeeffdddff000f") -- width 15

    local _, _, _, _ = os.pullEvent("monitor_touch")
end

local function doTransaction()
    local from = showAccounts("Who are you?")
    local amount = numberInput("Input amount:")
    local to = showAccounts("To whom?")
end

local function main() 
    monitor.setCursorPos(1, 1)
    monitor.write("Check balance", colors.green)
    monitor.setCursorPos(1, 2)
    monitor.write("Do transaction", colors.blue)
    monitor.setCursorPos(1, 3)
    monitor.write("List accounts", colors.red)
    
    local _, _, x, y = os.pullEvent("monitor_touch")
    
    if y == 1 then

        local acc = nil
        monitor.clear()
        acc = showAccounts("Select account:")
        

        while acc == nil do
            monitor.clear()
            centerText("Please select someone.")
            sleep(1)
            acc = showAccounts("Select account:")
        end

        monitor.clear()
        showBalance(acc)
    end
    if y == 2 then
        doTransaction()
    end
    if y == 3 then
        showAccounts("All accounts:")
    end
end

local status, err = pcall(main)

if status == false then
    print("error: "..err)
    monitor.clear()

    centerText("error: "..err)
    local _, _, _, _ = os.pullEvent("monitor_touch")
end