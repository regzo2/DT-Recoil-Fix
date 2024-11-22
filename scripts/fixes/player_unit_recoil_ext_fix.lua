local mod = get_mod("recoil_fix")

local WeaponMovementState = require("scripts/extension_systems/weapon/utilities/weapon_movement_state")

local prev_recoil_influence
local lerp_t = 0 -- Initialize to 0 for interpolation to work properly
local delta_t = 0

function update_recoil_settings(c_self, delta_time)
	delta_t = delta_time
    local movement_state_component = c_self._movement_state_component
    local weapon_movement_state = WeaponMovementState.translate_movement_state_component(movement_state_component)
    local recoil_template = c_self._weapon_extension:recoil_template()
    local new_recoil_settings = recoil_template[weapon_movement_state]

    if not prev_recoil_influence then
        prev_recoil_influence = new_recoil_settings.new_influence_percent
    end

    if prev_recoil_influence ~= new_recoil_settings.new_influence_percent then
        if lerp_t < 1 then
            lerp_t = math.min(lerp_t + delta_time * mod.recoil_move_lerp, 1)
            local blended_influence = math.lerp(prev_recoil_influence, new_recoil_settings.new_influence_percent, lerp_t)

            local updated_recoil_settings = table.shallow_copy(new_recoil_settings)
            updated_recoil_settings.new_influence_percent = blended_influence

            if lerp_t == 1 then
                prev_recoil_influence = new_recoil_settings.new_influence_percent
            end

            return updated_recoil_settings
        end
    else
        lerp_t = 0
    end

    prev_recoil_influence = new_recoil_settings.new_influence_percent
    return new_recoil_settings
end

local dbg_recoil = nil

mod:hook("PlayerUnitWeaponRecoilExtension", "fixed_update",  function (func, c_self, unit, dt, t)
	local recoil_component = c_self._recoil_component
	local recoil_control_component = c_self._recoil_control_component
	local weapon_tweak_templates_component = c_self._weapon_tweak_templates_component
	local recoil_template_name = weapon_tweak_templates_component.recoil_template_name

	if recoil_template_name == "none" then
		return
	end

	dbg_recoil = recoil_settings

	local recoil_settings = update_recoil_settings(c_self, dt)

	if recoil_control_component.recoiling then
		local decay_done = c_self:_update_unsteadiness(dt, t, recoil_component, recoil_control_component, recoil_settings)

		if decay_done then
			c_self:_snap_camera()
			c_self:_reset()
		end

		c_self:_update_offset(recoil_component, recoil_control_component, recoil_settings, t)
	end
end)

local lerp_t_o = 0

_old_update_offset = function (c_self, recoil_component, recoil_control_component, recoil_settings, t)
	local unsteadiness = recoil_component.unsteadiness
	local old_pitch_offset = recoil_component.pitch_offset
	local old_yaw_offset = recoil_component.yaw_offset
	local target_pitch = recoil_control_component.target_pitch
	local target_yaw = recoil_control_component.target_yaw
	local rise_end_time = recoil_control_component.rise_end_time
	local influence = dbg_recoil and dbg_recoil.new_influence_percent or 1

	if t > rise_end_time + 0.1 then
		local fp_rotation = c_self._first_person_component.rotation
		local current_pitch = Quaternion.pitch(fp_rotation)
		local starting_pitch = Quaternion.pitch(recoil_control_component.starting_rotation)
		local pitch_diff = starting_pitch - current_pitch

		if pitch_diff > 0 then
			influence = 0
		end
	end

	local influence_inv = 1 - influence
	local final_pitch_offset = (old_pitch_offset * influence_inv + target_pitch * influence) * unsteadiness
	local final_yaw_offset = (old_yaw_offset * influence_inv + target_yaw * influence) * unsteadiness

	if t <= rise_end_time then
		local new_yaw_offset = target_yaw * influence * unsteadiness

		final_yaw_offset = old_yaw_offset * influence_inv + new_yaw_offset
	end

	return final_pitch_offset, final_yaw_offset
end

mod:hook("PlayerUnitWeaponRecoilExtension", "_update_offset", function(func, c_self, recoil_component, recoil_control_component, recoil_settings, t, ...)
	local unsteadiness = recoil_component.unsteadiness
	local old_pitch_offset = recoil_component.pitch_offset
	local old_yaw_offset = recoil_component.yaw_offset
	local target_pitch = recoil_control_component.target_pitch
	local target_yaw = recoil_control_component.target_yaw
	local rise_end_time = recoil_control_component.rise_end_time
	local influence = recoil_settings.new_influence_percent

	if t > rise_end_time + 0.1 then
		local fp_rotation = c_self._first_person_component.rotation
		local current_pitch = Quaternion.pitch(fp_rotation)
		local starting_pitch = Quaternion.pitch(recoil_control_component.starting_rotation)
		local pitch_diff = starting_pitch - current_pitch

		if pitch_diff > 0 then
			lerp_t_o = math.min(lerp_t + delta_t * mod.recoil_reset_lerp, 1)
			influence = math.lerp(recoil_settings.new_influence_percent, 0, lerp_t_o)
		else
			lerp_t_o = 0
		end
	end

	local influence_inv = 1 - influence
	local final_pitch_offset = (old_pitch_offset * influence_inv + target_pitch * influence) * unsteadiness
	local final_yaw_offset = (old_yaw_offset * influence_inv + target_yaw * influence) * unsteadiness

	if t <= rise_end_time then
		local new_yaw_offset = target_yaw * influence * unsteadiness

		final_yaw_offset = old_yaw_offset * influence_inv + new_yaw_offset
	end

	final_pitch_offset_o, final_yaw_offset_0 = _old_update_offset(c_self, recoil_component, recoil_control_component, recoil_settings, t)

	local pitch_discr = final_pitch_offset_o and math.abs((final_pitch_offset_o - final_pitch_offset)) > 0.001 and tostring(math.abs((final_pitch_offset_o - final_pitch_offset))) or "< 0.001"
	local yaw_discr = final_yaw_offset_o and math.abs((final_yaw_offset_o - final_yaw_offset)) > 0.001 and tostring(math.abs((final_yaw_offset_o - final_yaw_offset))) or "< 0.001"

	mod:echo("discrepency: \npitch: " .. pitch_discr .. " \nyaw: " .. yaw_discr)

	recoil_component.pitch_offset = final_pitch_offset
	recoil_component.yaw_offset = final_yaw_offset
end)