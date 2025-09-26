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
        # Give items to player with leftover tracking
        - give <item[<[material]>]> quantity:<[quantity]> ignore_leftovers save:give_result
        - define leftover_items <entry[give_result].leftover_items>
        - define total_leftover <[leftover_items].parse[quantity].sum>
        - define actual_quantity <[quantity].sub[<[total_leftover]>]>
        - define actual_cost <[unit_price].mul[<[actual_quantity]>]>

        # If no items could be given (inventory completely full), stop
        - if <[actual_quantity]> <= 0:
            - narrate "<red>Your inventory is completely full! Please make some space and try again."
            - stop

        # Update player's refund balance
        - flag server refunds.<[target].uuid>.balance:-:<[actual_cost]>

        # Update sold items quantity
        - define new_quantity <[available_quantity].sub[<[actual_quantity]>]>
        - if <[new_quantity]> <= 0:
            # Remove the item entry entirely
            - flag server refunds.<[target].uuid>.sold:<server.flag[refunds.<[target].uuid>.sold].exclude[<[material]>]>
        - else:
            # Update the quantity
            - flag server refunds.<[target].uuid>.sold.<[material]>.quantity:<[new_quantity]>

        # Success message
        - define remaining_balance <server.flag[refunds.<[target].uuid>.balance].if_null[0]>
        - narrate "Successfully reclaimed <green><[actual_quantity].format_number> <gray>x <green><[material]> <gray>for <green>$<[actual_cost].format_number><gray>!"
        - narrate "Remaining refund balance: <gold>$<[remaining_balance].format_number>"

        # If some items didn't fit, inform the player
        - if <[total_leftover]> > 0:
            - narrate "<yellow>Warning: <red><[total_leftover]> <yellow>items couldn't fit in your inventory and were not given."

return_items:
    type: task
    definitions: target|inventory
    script:
        # Default Values
        - define target <player> if:!<[target].exists>

        # Extract and group items from chest inventory (excluding UI elements)
        - define items_list <[inventory].exclude_item[back_button|confirm_button|info_block|empty_slot].list_contents>
        - define items_to_return <map>
        - foreach <[items_list]> as:item:
            - define mat <[item].material.name>
            - define current_qty <[items_to_return].get[<[mat]>].if_null[0]>
            - define items_to_return.<[mat]>:<[current_qty].add[<[item].quantity>]>

        - if <[items_to_return].is_empty>:
            - narrate "<yellow>No items to return! Place items in the chest and try again."
            - stop

        # Validate items against bought data and calculate refund
        - define total_refund 0
        - define items_to_process <map>
        - define invalid_items <list>
        - foreach <[items_to_return]> key:material as:requested_qty:
            - define bought_data <server.flag[refunds.<[target].uuid>.bought.<[material]>].if_null[null]>

            # Skip items not in bought list
            - if <[bought_data]> == null:
                - define invalid_items:->:<[material]>
            - else:
                - define available_qty <[bought_data].get[quantity]>
                - define unit_price <[bought_data].get[unit_price]>
                - define actual_qty <[requested_qty].min[<[available_qty]>]>

                # Info when capping quantity at available amount
                - if <[actual_qty]> < <[requested_qty]>:
                    - define leftover_qty <[requested_qty].sub[<[actual_qty]>]>
                    - narrate "<blue>ℹ <gray>The maximum number of <item[<[material]>].with[quantity=2].formatted> you can return is <[actual_qty]>. Leaving <[leftover_qty]> behind."

                - define items_to_process.<[material]>:<map[quantity=<[actual_qty]>;unit_price=<[unit_price]>]>
                - define total_refund:+:<[actual_qty].mul[<[unit_price]>]>

        # Warn about invalid items
        - if !<[invalid_items].is_empty>:
            - narrate "<red>Cannot return items you didn't buy from server: <[invalid_items].formatted>"

        # Check if anything valid to process
        - if <[items_to_process].is_empty>:
            - narrate "<red>No valid items to return!"
            - stop

        # Check balance capacity and handle overflow
        - define current_balance <server.flag[refunds.<[target].uuid>.balance].if_null[0]>
        - define max_balance <[target].uuid.proc[get_total_sell_cost]>
        - define balance_capacity <[max_balance].sub[<[current_balance]>]>

        # Process refund - balance vs direct money
        - if <[total_refund]> <= <[balance_capacity]>:
            # Add all to balance
            - flag server refunds.<[target].uuid>.balance:+:<[total_refund]>
            - narrate "<green>Added <gold>$<[total_refund].format_number> <green>to your refund balance!"
        - else:
            # Split between balance and direct money
            - define balance_amount <[balance_capacity]>
            - define money_amount <[total_refund].sub[<[balance_capacity]>]>
            - flag server refunds.<[target].uuid>.balance:<[max_balance]>
            - money give quantity:<[money_amount]> players:<[target]>
            - narrate "<green>Refund balance maxed out! Added <gold>$<[balance_amount].format_number> <green>to balance and <gold>$<[money_amount].format_number> <green>to your wallet!"

        # List all successfully returned items
        - narrate "<gray>Items returned:"
        - foreach <[items_to_process]> key:material as:data:
            - define quantity <[data].get[quantity]>
            - define item_display <item[<[material]>].with[quantity=2].formatted>
            - narrate "<gray>- <[quantity]> <[item_display]>"

        # Update bought quantities and clean up zero entries
        - foreach <[items_to_process]> key:material as:data:
            - define current_bought_qty <server.flag[refunds.<[target].uuid>.bought.<[material]>.quantity]>
            - define new_qty <[current_bought_qty].sub[<[data].get[quantity]>]>
            - if <[new_qty]> <= 0:
                # Remove the item entry entirely
                - flag server refunds.<[target].uuid>.bought:<server.flag[refunds.<[target].uuid>.bought].exclude[<[material]>]>
            - else:
                # Update the quantity
                - flag server refunds.<[target].uuid>.bought.<[material]>.quantity:<[new_qty]>

        # Take the processed items from inventory
        - foreach <[items_to_process]> key:material as:data:
            - take item:<[material]> from:<[inventory]> quantity:<[data].get[quantity]>