local mod = get_mod("recoil_fix")

mod.on_setting_changed = function()
    mod.debug_mode = mod:get("debug_mode")
    mod.recoil_blending_lerp = mod:get("recoil_blending_lerp")
end

mod.on_setting_changed()

mod:io_dofile("recoil_fix/scripts/fixes/player_unit_recoil_ext_fix")
