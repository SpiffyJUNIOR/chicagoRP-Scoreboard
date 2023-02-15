util.AddNetworkString("chicagoRP_scoreboard_GUI")

local enabled = GetConVar("sv_chicagoRP_scoreboard_enable")

concommand.Add("chicagoRP_scoreboard", function(ply)
    if !IsValid(ply) then return end

    net.Start("chicagoRP_scoreboard_GUI")
    net.WriteBool(true)
    net.Send(ply)
end)








