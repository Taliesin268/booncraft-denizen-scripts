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
            # Check if player has Alchemy 100+ and is Bedrock player
            - if <player.mcmmo.level[alchemy]> < 100:
                - stop
            
            - foreach <proc[get_custom_potions]> as:custom_potion key:key:
                - foreach next if:<player.mcmmo.level[alchemy].is[less].than[<[custom_potions].get[base_ingredient]>]>
                - run alchemically_swap_all_items def.original_item:<[custom_potion].get[base_ingredient]> def.new_item:<[custom_potion].get[alchemical_ingredient]>

        # Convert alchemical carrots back to regular carrots when closing brewing stand
        on player closes brewing stand:
            - foreach <proc[get_custom_potions]> as:custom_potion key:key:
                - run alchemically_swap_all_items def.new_item:<[custom_potion].get[base_ingredient]> def.original_item:<[custom_potion].get[alchemical_ingredient]>

        # Flag items placed in the ingredient slot with the player who placed them
        after player clicks item in inventory:
            - if <context.inventory.inventory_type> != BREWING:
                - stop
            - if <context.slot_type> == FUEL:
                - inventory flag slot:<context.slot> d:<context.inventory> brewer:<player.uuid>

        # Handle brewing completion and replace with custom potions
        on brewing stand brews:
            # Get the ingredient item from the brewing stand
            - define ingredient <context.inventory.input>

            # Check if ingredient is carrot or alchemical carrot
            - if <[ingredient].script.name.if_null[none]> != alchemical_carrot:
                - stop

            # Check if ingredient has brewer flag
            - determine cancelled if:!<[ingredient].has_flag[brewer]>

            # Get the brewer and verify Alchemy level
            - define brewer_uuid <[ingredient].flag[brewer]>
            - if <player[<[brewer_uuid]>].mcmmo.level[alchemy]> < 100:
                - determine cancelled

            - define result <list>
            - foreach <context.result> as:result_item:
                - if <[result_item].effects_data.first.get[base_type]> != awkward:
                    - define result:->:<[result_item]>
                    - foreach next
                - define result:->:<item[haste_potion]>

            - determine RESULT:<[result]>