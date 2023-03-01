chicagoRP_Scoreboard = {}

chicagoRP_Scoreboard.playerOptions = {
    {
        title = "Steam Profile",
        actionFunc = function(ply)
            ply:ShowProfile()
        end
    },
    {
        title = "Copy SteamID",
        actionFunc = function(ply)
            SetClipboardText(ply:SteamID64())
        end
    }
}

function chicagoRP_Scoreboard.AddPlayerOption(tbl)
    if !istable(tbl) or table.IsEmpty(tbl) then return end

    table.Add(chicagoRP_Scoreboard.playerOptions, tbl)
end