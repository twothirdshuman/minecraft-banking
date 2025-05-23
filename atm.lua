local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
monitor.clear()
--- @type number, number
local width, height = monitor.getSize()

local function urlEncode(str)
    local encode = string.gsub(str, " ", "%%20")
    return encode
end

--- @param text string
---@param line number
local function onLineCenter(text, line)
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
        local res, _, aaa = http.get("https://minecraft-banking.deno.dev/api/getBalance?account="..urlEncode(accountName))

        if res == nil then
            print(_)
            local err = aaa.readAll()
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
---@return number
local function numberInput(title)
    monitor.clear()
    onLineCenter(title, 1)

    local emptyLine = function ()
        monitor.blit("               ", "000000000000000", "fffffffffffffff")
    end

    local bgLine = "fdddffdddffdddf"
    local fgLine = "000000000000000"

    local startY = 2
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

    local val = ""
    while true do
        onLineCenter(val, 2)
        local _, _, x, y = os.pullEvent("monitor_touch")
        --     3  8  13 (+5)
        -- 3 - 1, 2, 3
        -- 5 - 4, 5, 6
        -- 7 - 7, 8, 9
        -- 9 - clr, 0, sbm

        local num = math.floor((x + 4) / 5 + math.floor((y - 3) / 2) * 3)

        print(num)

        if num == 10 then
            val = ""
            onLineCenter("               ", 2)
        elseif num == 11 then
            val = val.."0"
        elseif num == 12 then
            if val == "" then
                for i=1,10 do
                    monitor.setCursorPos(1, 2)
                    monitor.blit("  Input number ", "000000000000000", "eeeeeeeeeeeeeee") 
                    sleep(0.1)
                    monitor.setCursorPos(1, 2)
                    monitor.blit("  Input number ", "000000000000000", "fffffffffffffff") 
                    sleep(0.1)
                end
                onLineCenter("               ", 2)
            else
                break
            end
        else
            val = val..num
        end
    end

    local ret = tonumber(val)
    if ret == nil then
        error("impossible")
    end
    return ret
end

---@param from string
---@param to string
---@param amount number
local function makeTransaction(from, to, amount)
    monitor.clear()
    local response = {}
    local fail = false
    parallel.waitForAny(showLoading, function ()
        local res, _, failRes = http.post("https://minecraft-banking.deno.dev/api/makeTransaction", textutils.serializeJSON({
            fromAccountName = from,
            toAccountName = to,
            amount = amount,
            pin = ""
        }))
        
        if failRes ~= nil then
            if failRes.getResponseCode() ~= 200 then
                local err = failRes.readAll()
                print("Error occurred: "..err)
                centerText("Error occurred: "..err)
                fail = true
                return
            end
        end

        response = textutils.unserializeJSON(res.readAll())
    end)

    if fail then
        sleep(10)
        return
    end

    monitor.setCursorPos(1,1)
    monitor.write("Payment done")
    monitor.setCursorPos(1,2)
    monitor.write("amount: $"..response["amount"])
    monitor.setCursorPos(1,3)
    monitor.write("from: "..response["fromAccountName"])
    monitor.setCursorPos(1,4)
    monitor.write("to: "..response["toAccountName"])
    monitor.setCursorPos(1,5)

    monitor.write("id: "..string.sub(response["ulid"], 1, 11))
    monitor.setCursorPos(1,6)
    monitor.write(string.sub(response["ulid"], 12, #response["ulid"]))

    local _, _, _, _ = os.pullEvent("monitor_touch")
end

local function doTransaction()
    local from = showAccounts("Who are you?")
    if from == nil then
        return
    end
    local amount = numberInput("Input amount:")
    local to = showAccounts("To whom?")
    if to == nil then
        return
    end

    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Send $"..amount)
    monitor.setCursorPos(1, 2)
    monitor.write("from: "..from)
    monitor.setCursorPos(1, 3)
    monitor.write("to: "..to)
    onLineCenter("Are you sure?", 5)

    monitor.setCursorPos(1, 7)
    monitor.blit(" YES        NO ", "000000000000000", "fdddffffffffeef")

    local _, _, x, y = os.pullEvent("monitor_touch")
    while not (y == 7 and ((x == 2 or x == 3 or x == 4 ) or (x == 13 or x == 14))) do
        _, _, x, y = os.pullEvent("monitor_touch")
    end

    if (x == 2 or x == 3 or x == 4 ) then
        makeTransaction(from, to, amount)
    else 
        monitor.clear()
        centerText("payment stopped")
        sleep(5)
        return
    end
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