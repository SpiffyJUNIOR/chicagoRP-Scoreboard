AddCSLuaFile()

for _, f in pairs(file.Find("chicagorp_scoreboard/*.lua", "LUA")) do
    if string.Left(f, 3) == "sv_" then
        if SERVER then 
            include("chicagorp_scoreboard/" .. f) 
        end
    elseif string.Left(f, 3) == "cl_" then
        if CLIENT then
            include("chicagorp_scoreboard/" .. f)
        else
            AddCSLuaFile("chicagorp_scoreboard/" .. f)
        end
    elseif string.Left(f, 3) == "sh_" then
        AddCSLuaFile("chicagorp_scoreboard/" .. f)
        include("chicagorp_scoreboard/" .. f)
    else
        print("chicagoRP Scoreboard detected unaccounted for lua file '" .. f .. "' - check prefixes!")
    end
    print("chicagoRP Scoreboard successfully loaded!")
end
