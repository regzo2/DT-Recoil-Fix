local mod = get_mod("recoil_fix")

local WeaponMovementState = require("scripts/extension_systems/weapon/utilities/weapon_movement_state")

function lerp_tables(table_a, table_b, t) -- i'm too lazy so it's recursive
    local result = {}
    for key, value_a in pairs(table_a) do
        local value_b = table_b and table_b[key]

        if type(value_a) == "number" and type(value_b) == "number" then
            result[key] = value_a + (value_b - value_a) * t
        elseif type(value_a) == "table" and type(value_b) == "table" then
            result[key] = lerp_tables(value_a, value_b, t)
        else
            result[key] = value_a
        end
    end
    return result
end

local current_state = nil
local previous_state = nil
local recoil_settings_lerp = nil
local lerp_t = 0

function update_recoil_settings(c_self, delta_time)
	local movement_state_component = c_self._movement_state_component
	local weapon_movement_state = WeaponMovementState.translate_movement_state_component(movement_state_component)
    local recoil_template = c_self._weapon_extension:recoil_template()
    local new_recoil_settings = recoil_template[weapon_movement_state]

    if weapon_movement_state ~= current_state then
        previous_state = current_state
        current_state = weapon_movement_state
        lerp_t = 0
    end

    if previous_state and recoil_settings_lerp and lerp_t < 1 then
		if mod.debug_mode then 
			mod:echo("Recoil blend progress: " .. lerp_t) 
		end
        lerp_t = math.min(lerp_t + delta_time * mod.recoil_blending_lerp, 1)
        local previous_settings = recoil_template[previous_state]
        recoil_settings_lerp = lerp_tables(previous_settings, new_recoil_settings, lerp_t)
    else
        recoil_settings_lerp = new_recoil_settings
    end

    return recoil_settings_lerp
end

mod:hook("PlayerUnitWeaponRecoilExtension", "fixed_update",  function (func, c_self, unit, dt, t)
	local recoil_component = c_self._recoil_component
	local recoil_control_component = c_self._recoil_control_component
	local weapon_tweak_templates_component = c_self._weapon_tweak_templates_component
	local recoil_template_name = weapon_tweak_templates_component.recoil_template_name

	if recoil_template_name == "none" then
		return
	end

	local recoil_settings = update_recoil_settings(c_self, dt)

	dbg_recoil = recoil_settings

	if recoil_control_component.recoiling then
		local decay_done = c_self:_update_unsteadiness(dt, t, recoil_component, recoil_control_component, recoil_settings)

		if decay_done then
			c_self:_snap_camera()
			c_self:_reset()
		end

		c_self:_update_offset(recoil_component, recoil_control_component, recoil_settings, t)
	end
end)

mod:hook("PlayerUnitWeaponRecoilExtension", "_update_unsteadiness", function(func, c_self, dt, t, recoil_component, recoil_control_component, recoil_settings, ...)
	local unsteadiness = recoil_component.unsteadiness
	local rise_end_time = recoil_control_component.rise_end_time
	local decay_grace = recoil_settings.decay_grace or 0
	local stat_buffs = c_self._buff_extension:stat_buffs()
	local recoil_modifier = stat_buffs.recoil_modifier or 1
	local num_shots = recoil_control_component.num_shots

	if t <= rise_end_time then
		--mod:echo("rise end time: " .. rise_end_time .. " t: " .. t)
		local rise_index = math.min(num_shots, recoil_settings.num_rises)
		local rise_percent = recoil_settings.rise[rise_index]
		local unsteadiness_increase = rise_percent / recoil_settings.rise_duration * dt

		unsteadiness = math.min(unsteadiness + unsteadiness_increase * recoil_modifier, 1)
	else
		local shooting = recoil_control_component.shooting
		local shooting_grace_decay = t <= (rise_end_time + decay_grace)
		local decay_percent = (shooting or shooting_grace_decay) and recoil_settings.decay.shooting or recoil_settings.decay.idle
		local unsteadiness_decay = decay_percent * dt

		unsteadiness = math.max(0, unsteadiness - unsteadiness_decay * (1 / recoil_modifier))

		--if num_shots > 1 and unsteadiness < 0.75 then
			--local override_shot_count = math.min(num_shots, math.floor(math.max(unsteadiness, 0) * 5))

			--c_self._recoil_control_component.num_shots = override_shot_count
		--end
	end

	unsteadiness = math.min(unsteadiness, 1)

	if unsteadiness < 0.0001 then
		return true
	end

	recoil_component.unsteadiness = unsteadiness 
end)

mod:hook("PlayerUnitWeaponRecoilExtension", "_update_offset", function(func, c_self, recoil_component, recoil_control_component, recoil_settings, t, ...)
	local unsteadiness = recoil_component.unsteadiness
	local old_pitch_offset = recoil_component.pitch_offset
	local old_yaw_offset = recoil_component.yaw_offset
	local target_pitch = recoil_control_component.target_pitch
	local target_yaw = recoil_control_component.target_yaw
	local rise_end_time = recoil_control_component.rise_end_time
	local influence = recoil_settings.new_influence_percent

	local influence_inv = 1 - influence
	local final_pitch_offset = math.abs((old_pitch_offset * influence_inv + target_pitch * influence) * unsteadiness)
	local final_yaw_offset = (old_yaw_offset * influence_inv + target_yaw * influence) * unsteadiness

	recoil_component.pitch_offset = final_pitch_offset
	recoil_component.yaw_offset = final_yaw_offset
end)