-- Workspace rules (was workspaces.conf; nwg-displays >= 0.4.3 writes this file)
hl.workspace_rule({ workspace = "1", monitor = "desc:Acer Technologies VG270K L 641300C934202", default = true })
hl.workspace_rule({ workspace = "2", monitor = "desc:Lenovo Group Limited D24-45 UMHP8F7H" })
hl.workspace_rule({ workspace = "3", monitor = "desc:Lenovo Group Limited D24-45 UMHP8F7H", default = true })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1", default = true })
for i = 5, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1" })
end
hl.workspace_rule({ workspace = "special:koreader_dev", gaps_in = 2, gaps_out = 4 })
