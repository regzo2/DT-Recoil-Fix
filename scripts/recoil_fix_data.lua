local mod = get_mod("recoil_fix")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id      = "debug_mode",
                type            = "checkbox",
                default_value   = false,
            },
            {
                setting_id      = "recoil_move_lerp",
                type            = "numeric",
                default_value   = 1.5,
                range           = {0.1, 3},
                decimals_number = 1
            },
            {
                setting_id      = "recoil_reset_lerp",
                type            = "numeric",
                default_value   = 0.5,
                range           = {0.1, 3},
                decimals_number = 1
            },
        },
    },
}