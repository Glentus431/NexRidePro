
-- SAFE TAP V8
-- Blocks top navigation and Shop controls

local GuiService = game:GetService("GuiService")

local function isBlocked(obj)
    local current = obj

    while current and current ~= pg do
        local name = current.Name:lower()
        local text = getText(current):lower()
        local combined = name .. " " .. text

        for _, word in ipairs({
            "shop",
            "store",
            "garage",
            "inventory",
            "topbar",
            "navbar",
            "toolbar",
            "header"
        }) do
            if combined:find(word, 1, true) then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

local function tap(obj)
    if not visible(obj) then
        return false
    end

    if isBlocked(obj) then
        setStatus("Blocked navigation button")
        return false
    end

    local pos = obj.AbsolutePosition
    local size = obj.AbsoluteSize

    local x = pos.X + size.X / 2
    local y = pos.Y + size.Y / 2

    -- Avoid the game's upper navigation area.
    -- Adjust this boundary for your screen.
    local SAFE_TOP = 150

    if y < SAFE_TOP then
        setStatus("Blocked top-row tap")
        return false
    end

    local ok = pcall(function()
        VIM:SendMouseButtonEvent(
            x, y, 0, true, game, 0
        )

        task.wait(0.04)

        VIM:SendMouseButtonEvent(
            x, y, 0, false, game, 0
        )
    end)

    if not ok then
        setStatus("Simulated tap unavailable")
    end

    return ok
end
