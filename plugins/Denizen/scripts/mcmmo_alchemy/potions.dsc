# Haste Potion - Base (3 minutes)
haste_potion:
    type: item
    material: potion
    display name: <&f>Potion of Haste
    mechanisms:
        potion_effects: <list[<map[effect=FAST_DIGGING;amplifier=0;duration=3600t]>]>
        custom_model_data: 0
    recipes:
        1:
            type: brewing
            input: awkward_potion
            ingredient: carrot

# Haste Potion - Extended (8 minutes)
haste_potion_extended:
    type: item
    material: potion
    display name: <&f>Potion of Haste
    lore:
    - <&9>Haste (8:00)
    mechanisms:
        potion_effects: <list[<map[effect=FAST_DIGGING;amplifier=0;duration=9600t]>]>
        custom_model_data: 0
    recipes:
        1:
            type: brewing
            input: haste_potion
            ingredient: redstone

# Haste Potion II (3 minutes)
haste_potion_ii:
    type: item
    material: potion
    display name: <&f>Potion of Haste
    lore:
    - <&9>Haste II (3:00)
    mechanisms:
        potion_effects: <list[<map[effect=FAST_DIGGING;amplifier=1;duration=3600t]>]>
        custom_model_data: 0
    recipes:
        1:
            type: brewing
            input: haste_potion
            ingredient: glowstone_dust

# Splash Haste Potion - Base (2:15)
splash_haste_potion:
    type: item
    material: splash_potion
    display name: <&f>Splash Potion of Haste
    lore:
    - <&9>Haste (3:00)
    - <&7>
    - <&7>When applied:
    - <&9>Haste (2:15)
    mechanisms:
        potion_effects: <list[<map[effect=FAST_DIGGING;amplifier=0;duration=2700t]>]>
        custom_model_data: 0
    recipes:
        1:
            type: brewing
            input: haste_potion
            ingredient: gunpowder

# Splash Haste Potion - Extended (6:00)
splash_haste_potion_extended:
    type: item
    material: splash_potion
    display name: <&f>Splash Potion of Haste
    lore:
    - <&9>Haste (8:00)
    - <&7>
    - <&7>When applied:
    - <&9>Haste (6:00)
    mechanisms:
        potion_effects: <list[<map[effect=FAST_DIGGING;amplifier=0;duration=7200t]>]>
        custom_model_data: 0
    recipes:
        1:
            type: brewing
            input: haste_potion_extended
            ingredient: gunpowder

# Splash Haste Potion II (2:15)
splash_haste_potion_ii:
    type: item
    material: splash_potion
    display name: <&f>Splash Potion of Haste
    lore:
    - <&9>Haste II (3:00)
    - <&7>
    - <&7>When applied:
    - <&9>Haste II (2:15)
    mechanisms:
        potion_effects: <list[<map[effect=FAST_DIGGING;amplifier=1;duration=2700t]>]>
        custom_model_data: 0
    recipes:
        1:
            type: brewing
            input: haste_potion_ii
            ingredient: gunpowder

# Lingering Haste Potion - Base (0:45)
lingering_haste_potion:
    type: item
    material: lingering_potion
    display name: <&f>Lingering Potion of Haste
    lore:
    - <&9>Haste (3:00)
    - <&7>
    - <&7>Creates a cloud of:
    - <&9>Haste (0:45)
    mechanisms:
        potion_effects: <list[<map[effect=FAST_DIGGING;amplifier=0;duration=900t]>]>
        custom_model_data: 0
    recipes:
        1:
            type: brewing
            input: splash_haste_potion
            ingredient: dragon_breath

# Lingering Haste Potion - Extended (2:00)
lingering_haste_potion_extended:
    type: item
    material: lingering_potion
    display name: <&f>Lingering Potion of Haste
    lore:
    - <&9>Haste (8:00)
    - <&7>
    - <&7>Creates a cloud of:
    - <&9>Haste (2:00)
    mechanisms:
        potion_effects: <list[<map[effect=FAST_DIGGING;amplifier=0;duration=2400t]>]>
        custom_model_data: 0
    recipes:
        1:
            type: brewing
            input: splash_haste_potion_extended
            ingredient: dragon_breath

# Lingering Haste Potion II (0:45)
lingering_haste_potion_ii:
    type: item
    material: lingering_potion
    display name: <&f>Lingering Potion of Haste
    lore:
    - <&9>Haste II (3:00)
    - <&7>
    - <&7>Creates a cloud of:
    - <&9>Haste II (0:45)
    mechanisms:
        potion_effects: <list[<map[effect=FAST_DIGGING;amplifier=1;duration=900t]>]>
        custom_model_data: 0
    recipes:
        1:
            type: brewing
            input: splash_haste_potion_ii
            ingredient: dragon_breath
