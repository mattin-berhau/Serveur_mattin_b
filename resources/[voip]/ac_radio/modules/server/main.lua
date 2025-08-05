local Config = require 'config'
local Utils = require 'modules.server.utils'

lib.versionCheck('acscripts/ac_radio')

SetConvarReplicated('radio:disconnectWithoutRadio', tostring(Config.disconnectWithoutRadio))
SetConvarReplicated('radio_noRadioDisconnect', tostring(Config.disconnectWithoutRadio)) -- backwards compatibility

SetTimeout(0, function()
    if Utils.hasExport('ox_core.GetPlayer') then
        require 'modules.server.framework.ox'
    elseif Utils.hasExport('es_extended.getSharedObject') then
        require 'modules.server.framework.esx'
    elseif Utils.hasExport('qb-core.GetCoreObject') then
        require 'modules.server.framework.qb'
    end
end)
