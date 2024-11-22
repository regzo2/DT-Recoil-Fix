return {
    mod_name = {
        en = "Recoil Fix",
    },
    mod_description = {
        en = "Fixes movement state transitions that cause jerky gun aiming while shooting.",
    },
    debug_mode = {
        en = "Debug"
    },
    recoil_move_lerp = {
        en = "Recoil Movement Speed"
    },
    recoil_move_lerp_description = {
        en = "Speed at which recoil states blend together when changing movement states (between standing still, moving, and crouch standing still and crouch moving). "..
             "Higher is faster and snappier, lower is slower and smoother."..
             "\n\n[Recommend]: 1.5"
    },
    recoil_reset_lerp = {
        en = "Recoil Reset Speed"
    },
    recoil_reset_lerp_description = {
        en = "Speed at which recoil resets after 0.1 seconds and looking around. "..
             "Higher is faster and snappier, lower is slower and smoother."..
             "\n\n[Recommend]: 0.5"
    },
}