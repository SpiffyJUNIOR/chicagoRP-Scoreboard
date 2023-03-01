local HideHUD = false
local OpenMotherFrame = nil
local OpenDropDown = nil
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

local function GetTextWidth(text, font)
    surface.SetFont(font)

    local width = select(1, surface.GetTextSize(text))

    return width
end

local function GetTextHeight(text, font)
    surface.SetFont(font)

    local height = select(2, surface.GetTextSize(text))

    return height
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

local function InvalidatePanel(panel)
    if IsValid(panel) then
        panel:InvalidateLayout()
    end
end

local function FancyClose(dropdownpanel)
    if !IsValid(dropdownpanel) then return end

    dropdownpanel:SizeTo(0, 0, 1, 0, -1)

    timer.Simple(1, function()
        if IsValid(dropdownpanel) then
            dropdownpanel:Close()
        end
    end)
end

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

    function motherFrame:OnMousePressed(mouseCode)
        if !IsValid(OpenDropDown) then return end

        local mouseX, mouseY = input.GetCursorPos()
        local panelX, panelY = OpenDropDown:GetPos()
        local panelW, panelH = OpenDropDown:GetSize()
        local endX, endY = panelX + panelW, panelY + panelH

        if endX < mouseX or mouseX > panelX or endY < mouseY or mouseY > panelY then
            FancyClose(OpenDropDown)
        end

        -- if !OpenDropDown:IsHovered() then -- alt method
        --     FancyClose(OpenDropDown)
        -- end
    end

    function motherFrame:PerformLayout(w, h)
        if IsValid(OpenDropDown) and !IsValid(OpenDropDown.ply) then
            FancyClose(OpenDropDown)
        end

        local players = player.GetAll()
        local playerOptions = chicagoRP_Scoreboard.playerOptions

        for i = 1, #players do
            local ply = players[i]
            if !IsValid(ply) then continue end

            local plyButton = motherFrame:Add("DButton")
            plyButton:Dock(LEFT)
            plyButton:SetSize(145, 36)

            local plyname = ply:getDarkRPVar("rpname") or ply:GetName()
            local job = ply:getDarkRPVar("job")
            local ping = ply:Ping()
            local pingcolor = PingCheck(ping)
            local teamcolor = team.GetColor(ply:Team())

            local parentW, parentH = plyButton:GetSize()
            local jobWidth = GetTextWidth(job, "Default")
            local jobstring = markup.Parse("<font=Default><colour=[[color_white]]>'['</colour><colour=[[teamcolor]]>[[job]]</colour><colour=[[color_white]]>']'</colour></font>")

            function plyButton:Paint(w, h)
                ping = ply:Ping()
                pingcolor = PingCheck(ping)

                local pingstring = tostring(ping) .. "ms"

                draw.DrawText(plyname, "Default", 34, 2, color_white, TEXT_ALIGN_LEFT)
                jobstring:Draw(44, 2)
                draw.DrawText(pingstring, "Default", parentW - 34, 2, pingcolor, TEXT_ALIGN_RIGHT)
            end

            local pfpImage = vgui.Create("AvatarImage", plyButton)
            pfpImage:SetSize(32, 32)
            pfpImage:SetPos(4, 2)
            pfpImage:SetPlayer(ply, 32)

            local optionCount = #playerOptions

            function plyButton:DoClick()
                FancyClose(OpenDropDown)

                local dropdownBox = vgui.Create("DPanel", parent)
                local mouseX, mouseY = input.GetCursorPos()
                dropdownBox:SetSize(0, 0)
                dropdownBox:SetPos(mouseX, mouseY)
                dropdownBox:NoClipping(true)

                dropdownBox.ply = ply

                local dropdownW, dropdownH = 100, (optionCount * 30) + 10

                dropdownBox:SizeTo(dropdownW, dropdownH, 1, 0, -1)

                function dropdownBox:Paint(w, h)
                    surface.SetDrawColor(70, 70, 70, 220)
                    surface.DrawRect(0, 0, w, h)

                    return false
                end

                for i = 1, optionCount do
                    local option = playerOptions[i]
                    local optionButton = dropdownBox:Add("DButton")
                    optionButton:SetPos(5, (i * 30) - 30 + 5)
                    optionButton:SetSize(90, 30)
                    optionButton:SetText(option.title)

                    function optionButton:DoClick()
                        if IsValid(dropdownBox.ply) then
                            option.actionFunc(dropdownBox.ply)
                        end

                        FancyClose(OpenDropDown)
                    end
                end

                OpenDropDown = dropdownBox
            end
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
    InvalidatePanel(OpenMotherFrame)
end)

hook.Add("player_disconnect", "chicagoRP_scoreboard_invalidateGUI", function(_)
    InvalidatePanel(OpenMotherFrame)
end)

hook.Add("PlayerButtonDown", "chicagoRP_vehicleradio_ButtonPressCheck", function(ply, button) -- SWAG MESSIAH............
    if button == KEY_T and IsFirstTimePredicted() and IsValid(OpenMotherFrame) then
        local inputenabled = OpenMotherFrame:IsMouseInputEnabled()

        if inputenabled then
            OpenMotherFrame:SetMouseInputEnabled(true)
        else
            OpenMotherFrame:SetMouseInputEnabled(false)
        end
    end
end)

print("chicagoRP Scoreboard GUI loaded!")