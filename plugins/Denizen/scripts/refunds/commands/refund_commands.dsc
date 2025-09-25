import_refund_data:
    type: command
    name: import_refund_data
    description: Imports refund data from an server-side YAML file.
    usage: /import_refund_data
    permission: refunds.import
    script:
    - ~yaml load:player_transaction_history.yml id:player_transaction_history
    - flag server refunds:<yaml[player_transaction_history].read[]>
    - yaml unload player_transaction_history

balance_refunds:
    type: task
    definitions: player_name
    script:
    - define target <server.match_offline_player[<[player_name]>]>
    - define available_funds <[target].money>
    - if !<server.flag[refunds.<[target].uuid>.sold].exists>:
        - stop
    - define total_sold_items_price <[target].uuid.proc[get_total_sell_cost]>
    - define remaining_debt <[total_sold_items_price].sub[<server.flag[refunds.<[target].uuid>.balance].if_null[0]>]>
    # If the player has enough money to cover the remaining debt, take it all and clear their debt.
    - if <[available_funds]> >= <[remaining_debt]>:
        - money take quantity:<[remaining_debt]> players:<[target]>
        - flag server refunds.<[target].uuid>.balance:+:<[remaining_debt]>
    # If the player doesn't have enough money, take what they have and update their debt accordingly.
    - else:
        - money set quantity:0 players:<[target]>
        - flag server refunds.<[target].uuid>.balance:+:<[available_funds]>

get_total_sell_cost:
    type: procedure
    definitions: uuid
    script:
    - define total 0
    - define sold_items <server.flag[refunds.<[uuid]>.sold].if_null[<map>]>
    - foreach <[sold_items].values> as:value:
        - define total:+:<[value].get[unit_price].mul[<[value].get[quantity]>]>
    - determine <[total]>

reclaim_item:
    type: task
    definitions: target|item|quantity
    script:
        # Default Values
        - define quantity 1 if:!<[quantity].exists>
        - define target <player> if:!<[target].exists>

        - define material <[item].material.name>
        - define unit_price <server.flag[refunds.<[target].uuid>.sold.<[material]>.unit_price]>
        - define available_quantity <server.flag[refunds.<[target].uuid>.sold.<[material]>.quantity].if_null[0]>
        - define available_balance <server.flag[refunds.<[target].uuid>.balance].if_null[0]>
        - define item_plural <[item].with[quantity=2].formatted>

        # Check if quantity is valid
        - if <[quantity]> > <[available_quantity]>:
            - clickable for:<player> usages:1 until:2m save:adjust_reclaim_item_quantity:
                - run reclaim_item def.player:<[target]> def.item:<[item]> def.quantity:<[available_quantity]>
            - narrate "<yellow>You tried to reclaim more <[item_plural]> than you have available. You can only reclaim <red><[available_quantity].format_number><yellow>. Click <green><bold><element[here].on_click[<entry[adjust_reclaim_item_quantity].command>]><yellow> to reclaim that many."
            - stop

        # Check if the player can afford it
        - define total_cost <[unit_price].mul[<[quantity]>]>
        - if <[available_balance]> < <[total_cost]>:
            - define highest_quantity_affordable <[available_balance].div_int[<[unit_price]>]>
            # Cancel if they can't afford even one
            - if <[highest_quantity_affordable]> <= 0:
                - narrate "<red>You do not have enough balance to reclaim any <[item_plural]>! You need at least <gold>$<[unit_price].format_number> <red>but you only have <gold>$<[available_balance].format_number><red>."
                - stop
            # Otherwise, offer to reclaim the most they can afford
            - clickable for:<player> usages:1 until:2m save:adjust_reclaim_item_quantity:
                - run reclaim_item def.player:<[target]> def.item:<[item]> def.quantity:<[highest_quantity_affordable]>
            - narrate "<yellow>You do not have enough money to reclaim that many items! You need <gold>$<[total_cost].format_number> <yellow>but you only have <gold>$<[available_balance].format_number><yellow>. You could afford <red><[highest_quantity_affordable].format_number><yellow> of these items. Click <green><bold><element[here].on_click[<entry[adjust_reclaim_item_quantity].command>]><yellow> to reclaim that many."
            - stop
        - narrate "Reclaiming <green><[quantity].format_number> <gray>x <green><[material]> <gray>for <green>$<[unit_price].mul[<[quantity]>].format_number><gray>."