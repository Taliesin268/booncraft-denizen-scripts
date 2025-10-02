mcmmo_alchemy_handlers:
    type: world
    events:
        # Convert carrots to alchemical carrots for Bedrock players when opening brewing stand
        on player opens brewing stand:
            - narrate "<gray>Checking for Alchemical Carrots..."
            # Check if player has Alchemy 100+ and is Bedrock player
            - if <player.mcmmo.level[alchemy]> < 100:
                - stop
            - if !<player.name.starts_with[.]>:
                - narrate "<red>✘ You must be a Bedrock player to use Alchemical Carrots!"
                # - stop

            # Convert all carrots in inventory to alchemical carrots
            - foreach <player.inventory.list_contents.filter_tag[<[filter_value].material.name.equals[carrot]>]> as:carrot_stack:
                - narrate "<green>✔ Found <&e><[carrot_stack].quantity> <&a>carrot(s), converting to Alchemical Carrots..."
                - define quantity <[carrot_stack].quantity>
                - define slot <player.inventory.find[<[carrot_stack]>]>
                - inventory set d:<player.inventory> slot:<[slot]> o:<item[alchemical_carrot].with[quantity=<[quantity]>]>

        # Convert alchemical carrots back to regular carrots when closing brewing stand
        on player closes brewing stand:
            - foreach <player.inventory.list_contents.filter_tag[<[filter_value].script.name.if_null[none].equals[alchemical_carrot]>]> as:alchemical_stack:
                - define quantity <[alchemical_stack].quantity>
                - define slot <player.inventory.find[<[alchemical_stack]>]>
                - inventory set d:<player.inventory> slot:<[slot]> o:<item[carrot].with[quantity=<[quantity]>]>

        # Flag items placed in the ingredient slot with the player who placed them
        on player clicks item in brewing stand:
            - if <context.slot_type> == FUEL:
                - flag <context.item> brewer:<player.uuid>

        # Handle brewing completion and replace with custom potions
        on brewing stand brews:
            # Get the ingredient item from the brewing stand
            - define ingredient <context.location.inventory.slot[5]>

            # Check if ingredient has brewer flag
            - if !<[ingredient].has_flag[brewer]>:
                - stop

            # Get the brewer and verify Alchemy level
            - define brewer_uuid <[ingredient].flag[brewer]>
            - if <player[<[brewer_uuid]>].mcmmo.level[alchemy]> < 100:
                - stop

            # Check if ingredient is carrot or alchemical carrot
            - if <[ingredient].material.name> != carrot && <[ingredient].script.name.if_null[none]> != alchemical_carrot:
                - stop

            # Process each bottle slot (1, 2, 3)
            - foreach <list[1|2|3]> as:slot:
                - define current_potion <context.location.inventory.slot[<[slot]>]>

                # Skip empty slots
                - if <[current_potion].material.name> == air:
                    - foreach next

                # Determine the result based on current potion and ingredient
                - define result_potion null

                # Check what's currently in the slot and what we're adding
                - choose <[current_potion].material.name>:
                    # Awkward Potion + Carrot = Haste Potion
                    - case potion:
                        - if <[current_potion].has_flag[potion_type]> && <[current_potion].flag[potion_type]> == awkward:
                            - define result_potion <item[haste_potion]>
                        # Check for redstone on haste potion (extended)
                        - else if <[ingredient].material.name> == redstone:
                            - if <[current_potion].script.name.if_null[none]> == haste_potion:
                                - define result_potion <item[haste_potion_extended]>
                        # Check for glowstone on haste potion (level II)
                        - else if <[ingredient].material.name> == glowstone_dust:
                            - if <[current_potion].script.name.if_null[none]> == haste_potion:
                                - define result_potion <item[haste_potion_ii]>
                        # Check for gunpowder to make splash
                        - else if <[ingredient].material.name> == gunpowder:
                            - if <[current_potion].script.name.if_null[none]> == haste_potion:
                                - define result_potion <item[splash_haste_potion]>
                            - else if <[current_potion].script.name.if_null[none]> == haste_potion_extended:
                                - define result_potion <item[splash_haste_potion_extended]>
                            - else if <[current_potion].script.name.if_null[none]> == haste_potion_ii:
                                - define result_potion <item[splash_haste_potion_ii]>

                    # Splash potions + dragon's breath = lingering
                    - case splash_potion:
                        - if <[ingredient].material.name> == dragon_breath:
                            - if <[current_potion].script.name.if_null[none]> == splash_haste_potion:
                                - define result_potion <item[lingering_haste_potion]>
                            - else if <[current_potion].script.name.if_null[none]> == splash_haste_potion_extended:
                                - define result_potion <item[lingering_haste_potion_extended]>
                            - else if <[current_potion].script.name.if_null[none]> == splash_haste_potion_ii:
                                - define result_potion <item[lingering_haste_potion_ii]>

                # If we determined a result, replace the potion
                - if <[result_potion]> != null:
                    - wait 1t
                    - inventory set d:<context.location.inventory> slot:<[slot]> o:<[result_potion]>
