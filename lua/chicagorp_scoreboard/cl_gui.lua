local HideHUD = false
local OpenMotherFrame = nil
local client = LocalPlayer()
local Dynamic = 0

local pingcolor_green = Color(30, 240, 50, 220)
local pingcolor_yellow = Color(235, 235, 25, 220)
local pingcolor_orange = Color(240, 1253, 20, 220)
local pingcolor_red = Color(255, 40, 0, 220)
local pingcolor_darkred = Color(145, 25, 0, 220)
local reddebug = Color(200, 10, 10, 150)
local blurMat = Material("pp/blurscreen")

local enabled = GetConVar("cl_chicagoRP_NPCShop_enable")

local function BlurScreen(panel)
    if (!IsValid(panel) or !panel:IsVisible()) then return end
    local layers, density, alpha = 1, 1, 100
    local scrW, scrH = ScrW(), ScrH()
    local FrameRate, Num, Dark = 1 / RealFrameTime(), 5, 150

    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetMaterial(blurMat)

    for i = 1, Num do
        blurMat:SetFloat("$blur", (i / layers) * density * Dynamic)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(0, 0, scrW, scrH)
    end

    surface.SetDrawColor(0, 0, 0, Dark * Dynamic)
    surface.DrawRect(0, 0, scrW, scrH)
    Dynamic = math.Clamp(Dynamic + (1 / FrameRate) * 7, 0, 1)
end

local function PingCheck(ping)
    if ping <= 50 then
        return pingcolor_green
    elseif ping <= 100 then
        return pingcolor_yellow
    elseif ping <= 150 then
        return pingcolor_orange
    elseif ping <= 200 then
        return pingcolor_red
    elseif ping <= 300 then
        return pingcolor_darkred
    end
end

hook.Add("HUDShouldDraw", "chicagoRP_NPCShop_HideHUD", function()
    if HideHUD == true then
        return false
    end
end)

local function OpenScoreboard()
    local ply = LocalPlayer()
    if IsValid(OpenMotherFrame) then OpenMotherFrame:Close() return end
    if !IsValid(ply) then return end
    if !enabled:GetBool() then return end

    local openbool = net.ReadBool()

    if openbool == false then return end

    local screenwidth = ScrW()
    local screenheight = ScrH()
    local motherFrame = vgui.Create("DFrame")
    motherFrame:SetSize(300, 0)

    local frameW, frameH = motherFrame:GetSize()

    motherFrame:SetPos((screenwidth / 2) - frameW, 0)
    motherFrame:SetVisible(true)
    motherFrame:SetDraggable(false)
    motherFrame:ShowCloseButton(false)
    motherFrame:ParentToHUD()

    HideHUD = true
    motherFrame.lblTitle = nil

    chicagoRP.PanelFadeIn(motherFrame, 0.15)

    function motherFrame:OnClose()
        if IsValid(self) then
            chicagoRP.PanelFadeOut(motherFrame, 0.15)
        end

        HideHUD = false
    end

    function motherFrame:Paint(w, h)
        BlurScreen(panel)

        surface.SetDrawColor(0, 0, 0, 50)
        surface.DrawRect(0, 0, w, h)
    end

    function motherFrame:PerformLayout(w, h)
        local players = player.GetAll()

        for k, ply in ipairs(players) do
            if !IsValid(ply) then continue end

            local plyButton = motherFrame:Add("DButton")
            plyButton:Dock(LEFT)
            plyButton:SetSize(145, 36)

            local parentW, parentH = plyButton:GetSize()

            local plyname = ply:GetName()
            local ping = ply:Ping()
            local pingcolor = PingCheck(ping)

            function plyButton:Paint(w, h)
                ping = ply:Ping()
                pingcolor = PingCheck(ping)

                local pingstring = tostring(ping) .. "ms"

                draw.DrawText(plyname, "Default", 34, 2, color_white, TEXT_ALIGN_LEFT)
                draw.DrawText(pingstring, "Default", parentW - 34, 2, pingcolor, TEXT_ALIGN_RIGHT)
            end

            local pfpImage = vgui.Create("AvatarImage", plyButton)
            pfpImage:SetSize(32, 32)
            pfpImage:SetPos(4, 2)
            pfpImage:SetPlayer(ply, 32)
        end
    end

    OpenMotherFrame = motherFrame
end)

local function CloseScoreboard()
    if IsValid(OpenMotherFrame) then
        chicagoRP.PanelFadeOut(OpenMotherFrame, 0.15)
    end

    timer.Simple(0.15, function()
        if IsValid(OpenMotherFrame) then
            OpenMotherFrame:Close()
        end
    end)
end

hook.Add("ScoreboardShow", "Scoreboard_Open", function()
    OpenScoreboard()
end)

hook.Add("ScoreboardHide", "Scoreboard_Close", function()
    CloseScoreboard()
end)

gameevent.Listen("player_connect_client")
gameevent.Listen("player_disconnect")

hook.Add("player_connect_client", "chicagoRP_scoreboard_invalidateGUI", function(_)
    if IsValid(OpenMotherFrame) then
        OpenMotherFrame:InvalidateLayout()
    end
end)

hook.Add("player_disconnect", "chicagoRP_scoreboard_invalidateGUI", function(_)
    if IsValid(OpenMotherFrame) then
        OpenMotherFrame:InvalidateLayout()
    end
end)

print("chicagoRP Scoreboard GUI loaded!")

-- to-do:
-- player options (open profile, mention, copy steamid, message player, report player)
-- toggle mouse input