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
