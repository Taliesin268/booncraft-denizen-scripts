# Main menu showing balance and options
refund_main_menu:
    type: inventory
    inventory: chest
    title: Refund Menu
    gui: true
    definitions:
        reclaim: <item[chest].with[display=<&a>Reclaim Sold Items;lore=<&7>Get back items you sold|<&7>using your refund balance.|<&7>|<&e>Click to view items!;flag=action:reclaim]>
        returns: <item[hopper].with[display=<&6>Return Purchased Items;lore=<&7>Return items you bought|<&7>to increase your balance.|<&7>|<&e>Click to view returnable items!;flag=action:returns]>
    slots:
    - [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot]
    - [empty_slot] [] [reclaim] [] [refund_balance] [] [returns] [] [empty_slot]
    - [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot]

refund_main_menu_handler:
    type: world
    events:
        on player clicks item in refund_main_menu:
            - if !<context.item.has_flag[action]>:
                - stop

            - choose <context.item.flag[action]>:
                - case reclaim:
                    - run open_paged_inventory def.items:<player.uuid.proc[get_refund_list]> def.page:1 def.inventory:refund_reclaim_menu

                - case returns:
                    - run open_paged_inventory def.items:<player.uuid.proc[get_refund_list].context[bought]> def.page:1 def.inventory:refund_return_listing

refund_reclaim_menu:
    type: inventory
    inventory: chest
    title: Reclaim Sold Items
    gui: true
    slots:
    # Items display area (first 3 rows - 27 slots)
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    # Separator row
    - [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot]
    # Navigation row - conditional previous/next based on page
    - [back_button] [air] [air] [air] [air] [air] [air] [air] [refund_balance]

refund_return_listing:
    type: inventory
    inventory: chest
    title: Return Purchased Items
    gui: true
    slots:
    # Items display area (first 3 rows - 27 slots)
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    # Separator row
    - [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot] [empty_slot]
    # Navigation row - conditional previous/next based on page
    - [back_button] [air] [air] [air] [air] [air] [air] [air] [confirm_button]

refund_reclaim_menu_handler:
    type: world
    events:
        on player clicks item in refund_reclaim_menu:
            - if !<context.item.has_flag[action]>:
                - stop

            - choose <context.item.flag[action]>:
                - case back:
                    - inventory open d:refund_main_menu

                - case reclaim:
                    - define unit_price <server.flag[refunds.<player.uuid>.sold.<context.item.material.name>.unit_price]>
                    - define max_quantity <server.flag[refunds.<player.uuid>.sold.<context.item.material.name>.quantity]>
                    - run open_quantity_determination_menu def.item:<context.item> def.unit_price:<[unit_price]> def.max_quantity:<[max_quantity]> def.return_to:<context.inventory>

refund_return_listing_handler:
    type: world
    events:
        on player clicks item in refund_return_listing:
            - if !<context.item.has_flag[action]>:
                - stop

            - choose <context.item.flag[action]>:
                - case back:
                    - inventory open d:refund_main_menu

                - case confirm:
                    - inventory open d:refund_return_menu

add_refund_lore:
    type: procedure
    definitions: item|uuid|direction
    script:
    - define direction sold if:!<[direction].exists>
    - define all_items <server.flag[refunds.<[uuid]>.<[direction]>].if_null[<map>]>
    - define base_lore <list[Price (each): <&a>$<[all_items.<[item]>.unit_price]>|Quantity: <&a><[all_items.<[item]>.quantity]>]>
    - if <[direction]> == sold:
        - define base_lore:->:<Element[<gold>Click to reclaim!]>
        - determine <item[<[item]>].with[lore=<[base_lore]>;flag=action:reclaim]>
    - else:
        - determine <item[<[item]>].with[lore=<[base_lore]>]>

get_refund_list:
    type: procedure
    definitions: uuid|direction
    script:
    - define list <list>
    - define direction sold if:!<[direction].exists>
    - define all_items <server.flag[refunds.<[uuid]>.<[direction]>].if_null[<map>]>
    - foreach <[all_items]> as:value key:key:
        - define list:->:<[key].proc[add_refund_lore].context[<[uuid]>|<[direction]>]>
    - determine <[list]>

refund_return_menu:
    type: inventory
    inventory: chest
    title: Return Purchased Items
    definitions:
        confirm: <item[confirm_button].with[display=<&a>Confirm Return;lore=<&7>Click to confirm returning|<&7>the selected items.]>
        info: <item[info_block].with[display=<&e>Information;lore=<&7>Place items you wish to|<&7>return in the slots above.|<&7>|<&7>Your refund balance will be|<&7>increased by the total|<&7>value of the returned items.|<&7>|<&7>Click <green>confirm<&7> to process|<&7>the return.]>
    slots:
        - [] [] [] [] [] [] [] [] []
        - [] [] [] [] [] [] [] [] []
        - [] [] [] [] [] [] [] [] []
        - [back_button] [empty_slot] [empty_slot] [empty_slot] [info] [empty_slot] [empty_slot] [empty_slot] [confirm]

refund_return_menu_handler:
    type: world
    events:
        on player closes refund_return_menu:
            - define items_to_return <context.inventory.exclude_item[back_button|confirm_button|info_block|empty_slot].list_contents>
            - if !<[items_to_return].is_empty>:
                - foreach <[items_to_return]> as:item:
                    - give <[item]>
                - narrate "<yellow>Return cancelled - all items have been returned to your inventory."
        on player clicks confirm_button in refund_return_menu:
            - run return_items def.target:<player> def.inventory:<context.inventory>
        on player clicks back_button in refund_return_menu:
            - run open_paged_inventory def.items:<player.uuid.proc[get_refund_list].context[bought]> def.page:1 def.inventory:refund_return_listing
        on player clicks confirm_button|info_block|empty_slot in refund_return_menu:
            - determine cancelled
        on player drags back_button|confirm_button|info_block|empty_slot in refund_return_menu:
            - determine cancelled