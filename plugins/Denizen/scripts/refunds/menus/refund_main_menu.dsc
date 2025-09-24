# Main menu showing balance and options
refund_main_menu:
    type: inventory
    inventory: chest
    title: Refund Menu
    gui: true
    definitions:
        empty: <item[gray_stained_glass_pane].with[display=<&7>]>
        balance: <item[sunflower].with[display=<&e>Refund Balance;lore=<&7>Current Balance: <&a>$<server.flag[refunds.<player.uuid>.balance].if_null[0].format_number>|<&7>|<&7>This balance is used to|<&7>reclaim items you sold.]>
        reclaim: <item[chest].with[display=<&a>Reclaim Sold Items;lore=<&7>Get back items you sold|<&7>using your refund balance.|<&7>|<&e>Click to view items!;flag=action:reclaim]>
        returns: <item[hopper].with[display=<&6>Return Purchased Items;lore=<&7>Return items you bought|<&7>to increase your balance.|<&7>|<&e>Click to view returnable items!;flag=action:returns]>
    slots:
    - [empty] [empty] [empty] [empty] [empty] [empty] [empty] [empty] [empty]
    - [empty] [] [reclaim] [] [balance] [] [returns] [] [empty]
    - [empty] [empty] [empty] [empty] [empty] [empty] [empty] [empty] [empty]

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
                    - run open_paged_inventory def.items:<player.uuid.proc[get_refund_list].context[bought]> def.page:1 def.inventory:refund_reclaim_menu

refund_reclaim_menu:
    type: inventory
    inventory: chest
    title: Reclaim Sold Items
    gui: true
    definitions:
        empty: <item[gray_stained_glass_pane].with[display=<&7>]>
    slots:
    # Items display area (first 3 rows - 27 slots)
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    - [] [] [] [] [] [] [] [] []
    # Separator row
    - [empty] [empty] [empty] [empty] [empty] [empty] [empty] [empty] [empty]
    # Navigation row - conditional previous/next based on page
    - [back_button] [air] [air] [air] [air] [air] [air] [air] [air]

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

add_refund_lore:
    type: procedure
    definitions: item|uuid|direction
    script:
    - define direction sold if:!<[direction].exists>
    - define all_items <server.flag[refunds.<[uuid]>.<[direction]>].if_null[<map>]>
    - determine <item[<[item]>].with[lore=Price (each): <&a>$<[all_items.<[item]>.unit_price]>|Quantity: <&a><[all_items.<[item]>.quantity]>|<gold>Click to reclaim!;flag=action:reclaim]>

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

