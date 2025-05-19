local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
monitor.clear()
--- @type number, number
local width, height = monitor.getSize()

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

    
local function useState(state)

end

---@param component function
local function mount(component) 

end

return {
    showLoading = showLoading,
    centerText = centerText,
    onLineCenter = onLineCenter
}