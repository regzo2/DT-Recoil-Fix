return {
	run = function()
		fassert(rawget(_G, "recoil_fix"), "`recoil_fix` encountered an error loading the Darktide Mod Framework.")

		new_mod("recoil_fix", {
			mod_script       = "recoil_fix/scripts/recoil_fix_main",
			mod_data         = "recoil_fix/scripts/recoil_fix_data",
			mod_localization = "recoil_fix/scripts/recoil_fix_localization",
		})
	end,
	packages = {},
}
