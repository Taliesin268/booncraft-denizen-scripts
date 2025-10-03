get_custom_potions:
    type: procedure
    script:
        - define potions_list <list>
        - define potions_list:->:<map[potion=haste_potion;skill_level=100]>
        - definemap potions_list:
            haste_potion:
                skill_level: 100
                base_ingredient: carrot
                alchemical_ingredient: alchemical_carrot
                duration: 3600t
        - determine <[potions_list]>

calculate_potion_duration:
    type: procedure
    definitions: duration|type
    script:
        - choose <[type]>:
            - case extended:
                - determine <[duration].mul[1.5].round>
            - case amplified:
                - determine <[duration].div[2].round>
            - case splash:
                - determine <[duration].mul[3].div[4].round>
            - case lingering:
                - determine <[duration].div[4].round>

# Haste Potion
haste_potion:
    type: item
    material: potion
    display name: <&f>Potion of Haste
    mechanisms:
        potion_effects: <list[[base_type=mundane]|[effect=haste;duration=3600t]]>