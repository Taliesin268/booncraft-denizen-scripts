# TODO: handle other ways of moving the items around
alchemically_swap_all_items:
    type: task
    definitions: original_item|new_item
    script:
        # Convert all carrots in inventory to alchemical carrots
        - foreach <player.inventory.find_all_items[<[original_item]>]> as:slot:
            - define quantity <player.inventory.slot[<[slot]>].quantity>
            - inventory set d:<player.inventory> slot:<[slot]> o:<item[<[new_item]>].with[quantity=<[quantity]>]>

mcmmo_alchemy_handlers:
    type: world
    events:
        # Convert carrots to alchemical carrots for Bedrock players when opening brewing stand
        on player opens brewing stand:
            - foreach <proc[get_custom_potions]> as:custom_potion key:key:
                - foreach next if:<player.mcmmo.level[alchemy].if_null[0].is[less].than[<[custom_potion].get[skill_level]>]>
                - run alchemically_swap_all_items def.original_item:<[custom_potion].get[base_ingredient]> def.new_item:<item[<[custom_potion].get[alchemical_ingredient]>].with_flag[brewer:<player.uuid>]>

        # Convert alchemical carrots back to regular carrots when closing brewing stand
        on player closes brewing stand:
            - foreach <proc[get_custom_potions]> as:custom_potion key:key:
                - run alchemically_swap_all_items def.new_item:<[custom_potion].get[base_ingredient]> def.original_item:<[custom_potion].get[alchemical_ingredient]>

        # Handle brewing completion and replace with custom potions
        on brewing stand brews:
            # Get the ingredient item from the brewing stand
            - define ingredient <context.inventory.input>
            # TODO: apply experience to brewer

            # TODO: If no changes (air or invalid potion), then cancel (check if normal potions have "recipes")
            - if !<[ingredient].script.name.exists>:
                - define result <context.result>
                - choose <[ingredient].material.name>:
                    - case redstone:
                        - foreach <context.inventory.list_contents.first[3]> as:base_item:
                            - foreach next if:!<proc[get_custom_potions].keys.contains[<[base_item].script.name>]>
                            # Base item is a custom potion
                            - if !<[base_item].proc[is_extended]> and !<[base_item].proc[is_amplified]>:
                                - define extended_potion <[base_item].proc[extend_potion]>
                                - define result <[result].overwrite[<[extended_potion]>].at[<[loop_index]>]>
                    - case glowstone_dust:
                        - foreach <context.inventory.list_contents.first[3]> as:base_item:
                            - foreach next if:!<proc[get_custom_potions].keys.contains[<[base_item].script.name>]>
                            # Base item is a custom potion
                            - if !<[base_item].proc[is_extended]> and !<[base_item].proc[is_amplified]>:
                                - define amplified_potion <[base_item].proc[amplify_potion]>
                                - define result <[result].overwrite[<[amplified_potion]>].at[<[loop_index]>]>
                    - case gunpowder:
                        - foreach <context.inventory.list_contents.first[3]> as:base_item:
                            - foreach next if:!<proc[get_custom_potions].keys.contains[<[base_item].script.name>]>
                            # Base item is a custom potion
                            - if !<[base_item].proc[is_splash]> and !<[base_item].proc[is_lingering]>:
                                - define splash_potion <[base_item].proc[convert_potion_to_splash]>
                                - define result <[result].overwrite[<[splash_potion]>].at[<[loop_index]>]>
                    - case dragon_breath:
                        - foreach <context.inventory.list_contents.first[3]> as:base_item:
                            - foreach next if:!<proc[get_custom_potions].keys.contains[<[base_item].script.name>]>
                            # Base item is a custom potion
                            - if <[base_item].proc[is_splash]> and !<[base_item].proc[is_lingering]>:
                                - define lingering_potion <[base_item].proc[convert_potion_to_lingering]>
                                - define result <[result].overwrite[<[lingering_potion]>].at[<[loop_index]>]>
                    - default:
                        - stop
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
            - foreach <context.result> as:result_item:
                - if <[result_item].effects_data.first.get[base_type]> != awkward:
                    - define result:->:<[result_item]>
                    - foreach next
                - define result:->:<item[<[potion_name]>]>

            - determine RESULT:<[result]>
        