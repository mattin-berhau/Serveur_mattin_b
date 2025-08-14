local state = {}

local isActive = false
local isMenuOpen = false

---@return boolean
function state.isActive()
    return isActive
end

---@return boolean
function state.isMenuOpen()
    return isMenuOpen
end

function state.setMenuOpen(value)
    isMenuOpen = value
end

---@param value boolean
function state.setActive(value)
    isActive = value
    state.setNuiFocus(value, value)
    if value then
        SendNuiMessage('{"event": "visible", "state": true}')
    end
end

local nuiFocus = false

---@return boolean
function state.isNuiFocused()
    return nuiFocus
end

---@param value boolean
function state.setNuiFocus(value, cursor)
    if value then SetCursorLocation(0.5, 0.5) end

    nuiFocus = value
    SetNuiFocus(value, cursor or false)
    SetNuiFocusKeepInput(value)
end

local isDisabled = false

---@return boolean
function state.isDisabled()
    return isDisabled
end

---@param value boolean
function state.setDisabled(value)
    isDisabled = value
end

return state
