get_custom_potions:
    type: procedure
    script:
        - definemap potions_list:
            haste_potion:
                skill_level: 100
                base_ingredient: carrot
                alchemical_ingredient: alchemical_carrot
                duration: 3600t
            absorption_potion:
                skill_level: 200
                base_ingredient: quartz
                alchemical_ingredient: alchemical_quartz_dust
                duration: 1800t
            dullness_potion:
                skill_level: 200
                base_ingredient: slime_ball
                alchemical_ingredient: alchemical_sizzling_slimeball
                duration: 3600t
        - determine <[potions_list]>

calculate_potion_duration:
    type: procedure
    definitions: duration|type
    script:
        - choose <[type]>:
            - case extended:
                - determine <[duration].mul[8].div[3].round>
            - case amplified:
                - determine <[duration].div[2].round>

# Haste Potion
haste_potion:
    type: item
    material: potion
    display name: <&f>Potion of Haste
    mechanisms:
        potion_effects: <list[[base_type=mundane]|[effect=haste;duration=3600t;amplifier=0;ambient=false;particles=true;icon=true]]>

absorption_potion:
    type: item
    material: potion
    display name: <&f>Potion of Absorption
    mechanisms:
        potion_effects: <list[[base_type=mundane]|[effect=absorption;duration=1800t;amplifier=0;ambient=false;particles=true;icon=true]]>

dullness_potion:
    type: item
    material: potion
    display name: <&f>Potion of Dullness
    mechanisms:
        potion_effects: <list[[base_type=mundane]|[effect=mining_fatigue;duration=3600t;amplifier=0;ambient=false;particles=true;icon=true]]>

generic_potion:
    type: item
    material: potion
    display name: <&f>Generic Potion
    recipes:
        1:
            type: brewing
            input: *_potion
            ingredient: redstone|glowstone_dust|gunpowder|dragon_breath

is_amplified:
    type: procedure
    definitions: potion
    script:
        - determine <[potion].effects_data.get[2].get[amplifier].if_null[0].is[more].than[0]>

is_splash:
    type: procedure
    definitions: potion
    script:
        - determine <[potion].material.name.equals[splash_potion]>

is_lingering:
    type: procedure
    definitions: potion
    script:
        - determine <[potion].material.name.equals[lingering_potion]>

is_extended:
    type: procedure
    definitions: potion
    script:
        - determine <element[false].as_boolean> if:<[potion].proc[is_amplified]>
        - define base_duration <proc[get_custom_potions].get[<[potion].script.name.if_null[none]>].get[duration].if_null[0]>
        - determine <[potion].effects_data.get[2].get[duration].if_null[0].is[more].than[<duration[<[base_duration]>]>]>

extend_potion:
    type: procedure
    definitions: potion
    script:
        - define base_effects <[potion].effects_data>
        - define base_duration <[base_effects].get[2].get[duration].in_seconds.if_null[0]>
        - define new_duration <[base_duration].proc[calculate_potion_duration].context[extended]>
        - define base_effects <[base_effects].overwrite[<[base_effects].get[2].include[duration=<duration[<[new_duration]>]>]>].at[2]>
        - determine <[potion].with[potion_effects=<[base_effects]>]>

amplify_potion:
    type: procedure
    definitions: potion
    script:
        - define base_effects <[potion].effects_data>
        - define base_amplifier <[base_effects].get[2].get[amplifier].if_null[0]>
        - define base_duration <[base_effects].get[2].get[duration].in_seconds.if_null[0]>
        - define new_duration <[base_duration].proc[calculate_potion_duration].context[amplified]>
        - define base_effects <[base_effects].overwrite[<[base_effects].get[2].include[amplifier=<[base_amplifier].add[1]>].include[duration=<[new_duration]>]>].at[2]>
        - define name_suffix " II"
        - repeat <[base_amplifier]>:
            - define name_suffix "<[name_suffix]>I"
        - determine <[potion].with[potion_effects=<[base_effects]>].with[display_name=<[potion].display><[name_suffix]>]>

convert_potion_to_splash:
    type: procedure
    definitions: potion
    script:
        - determine <[potion].with[material=splash_potion].with[display_name=<&f>Splash <[potion].display>]>

convert_potion_to_lingering:
    type: procedure
    definitions: potion
    script:
        - determine <[potion].with[material=lingering_potion].with[display_name=<&f>Lingering<[potion].display.after[Splash]>]>