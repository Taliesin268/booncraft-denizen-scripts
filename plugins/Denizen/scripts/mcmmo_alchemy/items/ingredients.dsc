alchemical_carrot:
    type: item
    material: golden_carrot
    display name: <&6>Alchemical Carrot
    lore:
    - <&7>A specially prepared carrot imbued
    - <&7>with alchemical properties.
    - <&e>
    - <&e>Used to brew Potions of Haste.
    - <&7>Requires Alchemy level 100+
    enchantments:
    - lure:1
    mechanisms:
        hides:
        - ENCHANTS
cancel_eating_alchemical_carrot:
    type: world
    events:
        on player consumes alchemical_carrot:
            - determine cancelled

alchemical_quartz_dust:
    type: item
    material: sugar
    display name: <&6>Nether Quartz Dust
    lore:
    - <&7>A finely ground powder made from
    - <&7>nether quartz.
    - <&e>
    - <&e>Used to brew Potions of Absorption.
    - <&7>Requires Alchemy level 200+
    enchantments:
    - lure:1
    mechanisms:
        hides:
        - ENCHANTS

alchemical_sizzling_slimeball:
    type: item
    material: magma_cream
    display name: <&6>Sizzling Slimeball
    lore:
    - <&7>A slimeball heated to extreme temperatures.
    - <&7>It sizzles to the touch.
    - <&e>
    - <&e>Used to brew Potions of Mining Fatigue.
    - <&7>Requires Alchemy level 200+
    enchantments:
    - lure:1
    mechanisms:
        hides:
        - ENCHANTS

alchemical_crabapple:
    type: item
    material: spider_eye
    display name: <&6>Ugly Crabapple
    lore:
    - <&7>A gnarled, misshapen crabapple with
    - <&7>peculiar alchemical properties.
    - <&e>
    - <&e>Used to brew Potions of Health Boost.
    - <&7>Requires Alchemy level 350+
    enchantments:
    - lure:1
    mechanisms:
        hides:
        - ENCHANTS
cancel_eating_alchemical_crabapple:
    type: world
    events:
        on player consumes alchemical_crabapple:
            - determine cancelled