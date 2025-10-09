alchemically_swap_all_items:
    type: task
    definitions: original_item|new_item|skip_enchanted
    script:
        # Convert all items in inventory to alchemical variants
        - foreach <player.inventory.find_all_items[<[original_item]>]> as:slot:
            - define current_item <player.inventory.slot[<[slot]>]>
            - if <[skip_enchanted].if_null[false]> && <[current_item].is_enchanted>:
                - foreach next
            - define quantity <[current_item].quantity>
            - inventory set d:<player.inventory> slot:<[slot]> o:<item[<[new_item]>].with[quantity=<[quantity]>]>

        # Also swap item on cursor if it matches
        - define cursor_item <player.item_on_cursor>
        - if <[cursor_item].material.name> == <[original_item]>:
            - if <[skip_enchanted].if_null[false]> && <[cursor_item].is_enchanted>:
                - stop
            - define cursor_quantity <[cursor_item].quantity>
            - adjust <player> item_on_cursor:<item[<[new_item]>].with[quantity=<[cursor_quantity]>]>

calculate_brew_time:
    type: procedure
    definitions: skill_level
    script:
    - if <[skill_level]> < 100:
        - determine <duration[20s]>
    - else if <[skill_level]> >= 1000:
        - determine <duration[5s]>
    - else:
        # Linear interpolation: 20 - ((skill - 100) / 900) * 15
        - define progress <[skill_level].sub[100].div[900]>
        - define time_reduction <[progress].mul[15]>
        - define brew_time <element[20].sub[<[time_reduction]>]>
        - determine <duration[<[brew_time]>]>

mcmmo_alchemy_handlers:
    type: world
    events:
        # Convert carrots to alchemical carrots for Bedrock players when opening brewing stand
        on player opens brewing:
            - foreach <proc[get_custom_potions]> as:custom_potion key:key:
                - foreach next if:<player.mcmmo.level[alchemy].if_null[0].is[less].than[<[custom_potion].get[skill_level]>]>
                - define alchemical_ingredient <item[<[custom_potion].get[alchemical_ingredient]>]>
                - if <[alchemical_ingredient].material.max_stack_size> == 1:
                    - adjust <[alchemical_ingredient]> material:<[alchemical_ingredient].material.with[max_stack_size=64]>
                - run alchemically_swap_all_items def.original_item:<[custom_potion].get[base_ingredient]> def.new_item:<[alchemical_ingredient].with_flag[brewer:<player.uuid>]> def.skip_enchanted:<element[true].as_boolean>

        # Convert alchemical carrots back to regular carrots when closing brewing stand
        after player closes brewing:
            - foreach <proc[get_custom_potions]> as:custom_potion key:key:
                - run alchemically_swap_all_items def.new_item:<[custom_potion].get[base_ingredient]> def.original_item:<[custom_potion].get[alchemical_ingredient]>

        on brewing starts:
            - if <context.item> matches alchemical_*:
                - stop if:!<context.item.has_flag[brewer]>
                - define brewer_uuid <context.item.flag[brewer]>
                # set the amount of time it takes to brew appropriately based on their skill level
                - determine BREW_TIME:<player[<[brewer_uuid]>].mcmmo.level[alchemy].if_null[0].proc[calculate_brew_time]>

        # Handle brewing completion and replace with custom potions
        on brewing stand brews:
            # Get the ingredient item from the brewing stand
            - define ingredient <context.inventory.input>

            - if !<[ingredient].script.name.exists>:
                - define result <context.result>
                - define number_of_custom_potions 0
                - choose <[ingredient].material.name>:
                    - case redstone:
                        - foreach <context.inventory.list_contents.first[3]> as:base_item:
                            - foreach next if:!<proc[get_custom_potions].keys.contains[<[base_item].script.name>]>
                            # Base item is a custom potion
                            - if !<[base_item].proc[is_extended]> and !<[base_item].proc[is_amplified]>:
                                - define extended_potion <[base_item].proc[extend_potion]>
                                - define result <[result].overwrite[<[extended_potion]>].at[<[loop_index]>]>
                                - define number_of_custom_potions:++
                    - case glowstone_dust:
                        - foreach <context.inventory.list_contents.first[3]> as:base_item:
                            - foreach next if:!<proc[get_custom_potions].keys.contains[<[base_item].script.name>]>
                            # Base item is a custom potion
                            - if !<[base_item].proc[is_extended]> and !<[base_item].proc[is_amplified]>:
                                - define amplified_potion <[base_item].proc[amplify_potion]>
                                - define result <[result].overwrite[<[amplified_potion]>].at[<[loop_index]>]>
                                - define number_of_custom_potions:++
                    - case gunpowder:
                        - foreach <context.inventory.list_contents.first[3]> as:base_item:
                            - foreach next if:!<proc[get_custom_potions].keys.contains[<[base_item].script.name>]>
                            # Base item is a custom potion
                            - if !<[base_item].proc[is_splash]> and !<[base_item].proc[is_lingering]>:
                                - define splash_potion <[base_item].proc[convert_potion_to_splash]>
                                - define result <[result].overwrite[<[splash_potion]>].at[<[loop_index]>]>
                                - define number_of_custom_potions:++
                    - case dragon_breath:
                        - foreach <context.inventory.list_contents.first[3]> as:base_item:
                            - foreach next if:!<proc[get_custom_potions].keys.contains[<[base_item].script.name>]>
                            # Base item is a custom potion
                            - if <[base_item].proc[is_splash]> and !<[base_item].proc[is_lingering]>:
                                - define lingering_potion <[base_item].proc[convert_potion_to_lingering]>
                                - define result <[result].overwrite[<[lingering_potion]>].at[<[loop_index]>]>
                                - define number_of_custom_potions:++
                    - default:
                        - stop
                - stop if:<[number_of_custom_potions].equals[0]>
                - determine RESULT:<[result]>

            - stop if:!<[ingredient].has_flag[brewer]>

            - foreach <proc[get_custom_potions]> as:custom_potion key:key:
                - if <[ingredient].script.name.if_null[none]> == <[custom_potion].get[alchemical_ingredient]>:
                    - define potion <[custom_potion]>
                    - define potion_name <[key]>
                    - foreach break

            - stop if:!<[potion].exists>

            # Get the brewer and verify Alchemy level
            - define brewer_uuid <[ingredient].flag[brewer]>
            - if <player[<[brewer_uuid]>].mcmmo.level[alchemy].if_null[0]> < <[potion].get[skill_level].if_null[0]>:
                - determine cancelled

            - define result <list>
            - define number_of_custom_potions 0
            - foreach <context.result> as:result_item:
                - if <[result_item].effects_data.first.get[base_type]> != awkward:
                    - define result:->:<[result_item]>
                    - foreach next
                - define result:->:<item[<[potion_name]>]>
                - define number_of_custom_potions:++

            - mcmmo add xp skill:alchemy quantity:<[number_of_custom_potions].mul[30]> player:<player[<[brewer_uuid]>]>

            - determine RESULT:<[result]>


offer_alchemy_book:
    type: task
    script:
        # Rate limit to prevent message spam (5 minutes per player)
        - ratelimit <player> 5m

        # Create clickable for downloading the guide book
        - clickable for:<player> until:5m usages:1 save:download_book:
            - give alchemy_guide_book to:<player.inventory>
            - flag player alchemy_book_offered
            - narrate "<&a>Guide book added to your inventory!"

        # Create clickable for dismissing the notification
        - clickable for:<player> until:5m usages:1 save:dismiss:
            - flag player alchemy_book_offered
            - narrate "<&7>You can always get the guide book by asking a staff member."

        # Send notification message with clickables
        - narrate "<&6><&l>Bedrock Alchemy System"
        - narrate "<&7>You've unlocked Alchemy level 100! Booncraft uses a custom alchemy system for Bedrock compatibility."
        - narrate "<&7>"
        - narrate "<&a><element[⬇ Download Guide Book].on_click[<entry[download_book].command>]> <&8>| <&c><element[Don't remind me again].on_click[<entry[dismiss].command>]>"

alchemy_book_distribution:
    type: world
    events:
        # Notify players when they reach level 100+ in Alchemy
        on mcmmo player levels up alchemy flagged:!alchemy_book_offered:
            - wait 1s
            - if <context.new_level> >= 100 && !<player.has_flag[alchemy_book_offered]>:
                - run offer_alchemy_book

        # Notify existing players with Alchemy >= 100 when they join
        on player joins flagged:!alchemy_book_offered:
            - wait 4s
            - if <player.mcmmo.level[alchemy].if_null[0]> >= 100 && !<player.has_flag[alchemy_book_offered]>:
                - run offer_alchemy_book