# Pufferfish Kill Weapon
# A special pufferfish that instantly kills any entity attacked by an op player

pufferfish_of_doom:
    type: item
    material: pufferfish
    display name: <red>Pufferfish of Doom
    lore:
    - <dark_gray>One touch means instant death!
    - <empty>
    - <red>☠ <gray>Wielder must be OP
    - <red>☠ <gray>Instantly kills any entity
    - <empty>
    - <dark_red><italic>With great power comes
    - <dark_red><italic>great responsibility...
    enchantments:
    - vanishing_curse:1
    mechanisms:
        hides: HIDE_ENCHANTS

pufferfish_kill_weapon:
    type: world
    events:
        on player tries to attack entity with:pufferfish_of_doom:
            # Check if the attacking player is op
            - if !<player.is_op>:
                - narrate "<red>✘ You must be an operator to use the Pufferfish of Doom!" targets:<player>
                - stop

            # Get the target entity
            - define target <context.entity>

            # Log the attack
            - ~log "PUFFERFISH_KILL: Player=<player.name> Target=<[target].name.if_null[<[target].entity_type>]> Location=<[target].location.simple>" file:plugins/Denizen/logs/adhoc/pufferfish_kills_<util.time_now.format[yyyy-MM-dd]>.log

            # Play dramatic effects at target location
            - playeffect effect:EXPLOSION_HUGE at:<[target].location> visibility:100
            - playsound sound:ENTITY_WITHER_DEATH <[target].location> volume:2 pitch:0.5
            - playsound sound:ENTITY_PUFFER_FISH_DEATH <[target].location> volume:2 pitch:2

            # If target is a player, use /kill command
            - if <[target].is_player>:
                - define target_name <[target].name>
                - execute as_server "kill <[target_name]>"
                - narrate "<red>☠ <gold><[target_name]> <red>was eliminated by the Pufferfish of Doom!" targets:<server.online_players>
            # If target is any other entity, remove it
            - else:
                - remove <[target]>
                - narrate "<red>☠ <gold><[target].entity_type.replace_text[_].with[ ].to_titlecase> <red>was obliterated by the Pufferfish of Doom!"

            # Give the attacker some feedback
            - actionbar "<dark_red>✦ <red>The Pufferfish of Doom claims another victim! <dark_red>✦" targets:<player>

            # Cancel the normal attack
            - determine cancelled
