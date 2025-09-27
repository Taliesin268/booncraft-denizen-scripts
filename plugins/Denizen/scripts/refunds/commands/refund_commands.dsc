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
    definitions: player_uuid
    script:
    - define trace_id <util.random_uuid>

    # Check if balance refund has already been processed for this player
    - if <server.has_flag[refunds.balance_processed.<[player_uuid]>]>:
        - ~log "BALANCE_REFUND_SKIP: TraceID=<[trace_id]> UUID=<[player_uuid]> Reason=ALREADY_PROCESSED" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
        - stop

    - define target <player[<[player_uuid]>].if_null[null]>
    - if !<[target].has_played_before.if_null[false]>:
        - ~log "BALANCE_REFUND_SKIP: TraceID=<[trace_id]> UUID=<[player_uuid]> Reason=PLAYER_NOT_FOUND" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
        - stop

    - define player_name <[target].name>
    - define available_funds <[target].money>

    - if !<server.flag[refunds.<[player_uuid]>.sold].exists>:
        - ~log "BALANCE_REFUND_SKIP: TraceID=<[trace_id]> Player=<[player_name]>(<[player_uuid]>) Reason=NO_SOLD_DATA" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
        - stop

    - define total_sold_items_price <[player_uuid].proc[get_total_sell_cost]>
    - define current_balance <server.flag[refunds.<[player_uuid]>.balance].if_null[0]>
    - define remaining_debt <[total_sold_items_price].sub[<[current_balance]>]>

    - ~log "BALANCE_REFUND_ATTEMPT: TraceID=<[trace_id]> Player=<[player_name]>(<[player_uuid]>) AvailableFunds=$<[available_funds].format_number> RemainingDebt=$<[remaining_debt].format_number> CurrentBalance=$<[current_balance].format_number>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    # If the player has enough money to cover the remaining debt, take it all and clear their debt.
    - if <[available_funds]> >= <[remaining_debt]>:
        - money take quantity:<[remaining_debt]> players:<[target]>
        - flag server refunds.<[player_uuid]>.balance:+:<[remaining_debt]>
        - define new_balance <server.flag[refunds.<[player_uuid]>.balance]>
        - ~log "BALANCE_REFUND_SUCCESS: TraceID=<[trace_id]> Player=<[player_name]>(<[player_uuid]>) Type=FULL_PAYMENT MoneyTaken=$<[remaining_debt].format_number> NewBalance=$<[new_balance].format_number>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
    # If the player doesn't have enough money, take what they have and update their debt accordingly.
    - else:
        - money set quantity:0 players:<[target]>
        - flag server refunds.<[player_uuid]>.balance:+:<[available_funds]>
        - define new_balance <server.flag[refunds.<[player_uuid]>.balance]>
        - ~log "BALANCE_REFUND_SUCCESS: TraceID=<[trace_id]> Player=<[player_name]>(<[player_uuid]>) Type=PARTIAL_PAYMENT MoneyTaken=$<[available_funds].format_number> NewBalance=$<[new_balance].format_number> RemainingDebt=$<[remaining_debt].sub[<[available_funds]>].format_number>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    # Mark this player's balance as processed
    - flag server refunds.balance_processed.<[player_uuid]>:true

balance_refunds_for_all:
    type: task
    script:
    - define batch_trace_id <util.random_uuid>
    - define initiator <player.name.if_null[CONSOLE]>
    - define initiator_uuid <player.uuid.if_null[CONSOLE]>

    # Get all players with refund data using existing procedure
    - define refund_players <proc[get_refund_players]>
    - if <[refund_players].is_empty>:
        - narrate "<&c>No players with refund data found."
        - ~log "BALANCE_REFUND_BATCH: BatchID=<[batch_trace_id]> Initiator=<[initiator]>(<[initiator_uuid]>) Result=NO_PLAYERS_FOUND" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
        - stop

    - define all_uuids <[refund_players].keys>
    - define processed_count 0
    - define skipped_count 0
    - define total_count <[all_uuids].size>

    - ~log "BALANCE_REFUND_BATCH_START: BatchID=<[batch_trace_id]> Initiator=<[initiator]>(<[initiator_uuid]>) TotalPlayers=<[total_count]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    - narrate "<&6>Starting balance refund processing for <[total_count]> players..."

    # Process each player
    - foreach <[all_uuids]> as:uuid:
        # Check if this player has already been processed
        - if <server.has_flag[refunds.balance_processed.<[uuid]>]>:
            - define skipped_count:+:1
            - foreach next

        # Run balance_refunds for this player
        - run balance_refunds def.player_uuid:<[uuid]>
        - define processed_count:+:1

        # Progress update every 10 players
        - if <[loop_index].mod[10]> == 0:
            - narrate "<&7>Progress: <[loop_index]>/<[total_count]> players processed..."
            - ~log "BALANCE_REFUND_BATCH_PROGRESS: BatchID=<[batch_trace_id]> Progress=<[loop_index]>/<[total_count]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    - ~log "BALANCE_REFUND_BATCH_COMPLETE: BatchID=<[batch_trace_id]> Initiator=<[initiator]>(<[initiator_uuid]>) Processed=<[processed_count]> Skipped=<[skipped_count]> Total=<[total_count]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    - narrate "<&a>Balance refund processing complete!"
    - narrate "<&e>Processed: <&f><[processed_count]> players"
    - narrate "<&e>Skipped (already processed): <&f><[skipped_count]> players"
    - narrate "<&e>Total: <&f><[total_count]> players"

setup_refunds_luckperms_group:
    type: task
    script:
    - define trace_id <util.random_uuid>
    - define initiator <player.name.if_null[CONSOLE]>
    - define initiator_uuid <player.uuid.if_null[CONSOLE]>

    # Create the LuckPerms group
    - execute as_server "lp creategroup has_refunds"
    - ~log "LUCKPERMS_GROUP_SETUP: TraceID=<[trace_id]> Initiator=<[initiator]>(<[initiator_uuid]>) Action=CREATE_GROUP GroupName=has_refunds" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    # Get all players with refund data
    - define refund_players <proc[get_refund_players]>
    - if <[refund_players].is_empty>:
        - narrate "<&c>No players with refund data found."
        - ~log "LUCKPERMS_GROUP_SETUP: TraceID=<[trace_id]> Result=NO_PLAYERS_FOUND" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
        - stop

    - define total_count <[refund_players].size>
    - define added_count 0

    - narrate "<&6>Adding <[total_count]> players to has_refunds group..."
    - ~log "LUCKPERMS_GROUP_SETUP_START: TraceID=<[trace_id]> TotalPlayers=<[total_count]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    # Add each player to the group
    - foreach <[refund_players]> key:uuid as:player_name:
        - execute as_server "lp user <[player_name]> parent add has_refunds"
        - define added_count:+:1

        # Progress update every 10 players
        - if <[loop_index].mod[10]> == 0:
            - narrate "<&7>Progress: <[loop_index]>/<[total_count]> players added..."
            - ~log "LUCKPERMS_GROUP_SETUP_PROGRESS: TraceID=<[trace_id]> Progress=<[loop_index]>/<[total_count]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    - ~log "LUCKPERMS_GROUP_SETUP_COMPLETE: TraceID=<[trace_id]> Initiator=<[initiator]>(<[initiator_uuid]>) PlayersAdded=<[added_count]> Total=<[total_count]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    - narrate "<&a>LuckPerms group setup complete!"
    - narrate "<&e>Group created: <&f>has_refunds"
    - narrate "<&e>Players added: <&f><[added_count]>/<[total_count]>"

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
    definitions: target_uuid|item|quantity
    script:
        # Default Values
        - define quantity 1 if:!<[quantity].exists>
        - define target_uuid <player.uuid> if:!<[target_uuid].exists>

        # Generate trace ID for this transaction
        - define trace_id <util.random_uuid>

        - define material <[item].material.name>
        - define unit_price <server.flag[refunds.<[target_uuid]>.sold.<[material]>.unit_price]>
        - define available_quantity <server.flag[refunds.<[target_uuid]>.sold.<[material]>.quantity].if_null[0]>
        - define available_balance <server.flag[refunds.<[target_uuid]>.balance].if_null[0]>
        - define item_plural <[item].with[quantity=2].formatted>

        # Calculate total cost for logging
        - define total_cost <[unit_price].mul[<[quantity]>]>

        # Log attempt
        - ~log "RECLAIM_ATTEMPT: TraceID=<[trace_id]> Player=<player.name>(<player.uuid>) Target=<[target_uuid]> Item=<[material]> Qty=<[quantity]> Cost=$<[total_cost].format_number> Balance=$<[available_balance].format_number>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

        # Check if quantity is valid
        - if <[quantity]> > <[available_quantity]>:
            - ~log "RECLAIM_FAILED: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Reason=INVALID_QUANTITY Requested=<[quantity]> Available=<[available_quantity]>" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
            - clickable for:<player> usages:1 until:2m save:adjust_reclaim_item_quantity:
                - run reclaim_item def.target_uuid:<[target_uuid]> def.item:<[item]> def.quantity:<[available_quantity]>
            - narrate "<yellow>You tried to reclaim more <[item_plural]> than you have available. You can only reclaim <red><[available_quantity].format_number><yellow>. Click <green><bold><element[here].on_click[<entry[adjust_reclaim_item_quantity].command>]><yellow> to reclaim that many."
            - stop

        # Check if the player can afford it
        - if <[available_balance]> < <[total_cost]>:
            - define highest_quantity_affordable <[available_balance].div_int[<[unit_price]>]>
            # Cancel if they can't afford even one
            - if <[highest_quantity_affordable]> <= 0:
                - ~log "RECLAIM_FAILED: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Reason=INSUFFICIENT_BALANCE_ZERO Need=$<[unit_price].format_number> Have=$<[available_balance].format_number>" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
                - narrate "<red>You do not have enough tokens to reclaim any <[item_plural]>! You need at least <gold><[unit_price].proc[format_as_tokens]> tokens <red>but you only have <gold><[available_balance].proc[format_as_tokens]> tokens<red>."
                - stop
            # Otherwise, offer to reclaim the most they can afford
            - ~log "RECLAIM_FAILED: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Reason=INSUFFICIENT_BALANCE Need=$<[total_cost].format_number> Have=$<[available_balance].format_number> CanAfford=<[highest_quantity_affordable]>" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
            - clickable for:<player> usages:1 until:2m save:adjust_reclaim_item_quantity:
                - run reclaim_item def.target_uuid:<[target_uuid]> def.item:<[item]> def.quantity:<[highest_quantity_affordable]>
            - narrate "<yellow>You do not have enough tokens to reclaim that many items! You need <gold><[total_cost].proc[format_as_tokens]> tokens <yellow>but you only have <gold><[available_balance].proc[format_as_tokens]> tokens<yellow>. You could afford <red><[highest_quantity_affordable].format_number><yellow> of these items. Click <green><bold><element[here].on_click[<entry[adjust_reclaim_item_quantity].command>]><yellow> to reclaim that many."
            - stop
        # Give items to current player with leftover tracking
        - give <item[<[material]>]> quantity:<[quantity]> ignore_leftovers save:give_result
        - define leftover_items <entry[give_result].leftover_items>
        - define total_leftover <[leftover_items].parse[quantity].sum>
        - define actual_quantity <[quantity].sub[<[total_leftover]>]>
        - define actual_cost <[unit_price].mul[<[actual_quantity]>]>

        # If no items could be given (inventory completely full), stop
        - if <[actual_quantity]> <= 0:
            - ~log "RECLAIM_FAILED: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Reason=INVENTORY_FULL Item=<[material]> Qty=<[quantity]>" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
            - narrate "<red>Your inventory is completely full! Please make some space and try again."
            - stop

        # Update players refund balance
        - flag server refunds.<[target_uuid]>.balance:-:<[actual_cost]>

        # Update sold items quantity
        - define new_quantity <[available_quantity].sub[<[actual_quantity]>]>
        - if <[new_quantity]> <= 0:
            # Remove the item entry entirely
            - flag server refunds.<[target_uuid]>.sold:<server.flag[refunds.<[target_uuid]>.sold].exclude[<[material]>]>
        - else:
            # Update the quantity
            - flag server refunds.<[target_uuid]>.sold.<[material]>.quantity:<[new_quantity]>

        # Success message
        - define remaining_balance <server.flag[refunds.<[target_uuid]>.balance].if_null[0]>

        # Log success (including leftover info if applicable)
        - if <[total_leftover]> > 0:
            - ~log "RECLAIM_SUCCESS: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Item=<[material]> Qty=<[actual_quantity]>/<[quantity]> Cost=$<[actual_cost].format_number> NewBalance=$<[remaining_balance].format_number> Leftover=<[total_leftover]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
        - else:
            - ~log "RECLAIM_SUCCESS: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Item=<[material]> Qty=<[actual_quantity]> Cost=$<[actual_cost].format_number> NewBalance=$<[remaining_balance].format_number>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

        - narrate "Successfully reclaimed <green><[actual_quantity].format_number> <gray>x <green><[material]> <gray>for <green><[actual_cost].proc[format_as_tokens]> tokens<gray>!"
        - narrate "Remaining refund tokens: <gold><[remaining_balance].proc[format_as_tokens]> tokens"

        # If some items didn't fit, inform the player
        - if <[total_leftover]> > 0:
            - narrate "<yellow>Warning: <red><[total_leftover]> <yellow>items couldn't fit in your inventory and were not given."

return_items:
    type: task
    definitions: target_uuid|inventory
    script:
        # Default Values
        - define target_uuid <player.uuid> if:!<[target_uuid].exists>

        # Generate trace ID for this transaction
        - define trace_id <util.random_uuid>

        # Extract and group items from chest inventory (excluding UI elements)
        - define items_list <[inventory].exclude_item[back_button|confirm_button|info_block|empty_slot].list_contents>
        - define items_to_return <map>
        - foreach <[items_list]> as:item:
            - define mat <[item].material.name>
            - define current_qty <[items_to_return].get[<[mat]>].if_null[0]>
            - define items_to_return.<[mat]>:<[current_qty].add[<[item].quantity>]>

        # Log attempt with quantities
        - define items_log <list>
        - foreach <[items_to_return]> key:material as:quantity:
            - if <[material]> != air:
                - define items_log:->:<[material]>x<[quantity]>
        - ~log "RETURN_ATTEMPT: TraceID=<[trace_id]> Player=<player.name>(<player.uuid>) Target=<[target_uuid]> Items=<[items_log].separated_by[,]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

        - if <[items_to_return].is_empty>:
            - ~log "RETURN_FAILED: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Reason=NO_ITEMS" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
            - narrate "<yellow>No items to return! Place items in the chest and try again."
            - stop

        # Validate items against bought data and calculate refund
        - define total_refund 0
        - define items_to_process <map>
        - define invalid_items <list>
        - foreach <[items_to_return]> key:material as:requested_qty:
            - define bought_data <server.flag[refunds.<[target_uuid]>.bought.<[material]>].if_null[null]>

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
        - if !<[invalid_items].exclude[air].is_empty>:
            - ~log "RETURN_INVALID_ITEMS: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Invalid=<[invalid_items].exclude[air].formatted>" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
            - narrate "<red>Cannot return items you didn't buy from server: <[invalid_items].exclude[air].formatted>"

        # Check if anything valid to process
        - if <[items_to_process].is_empty>:
            - ~log "RETURN_FAILED: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Reason=NO_VALID_ITEMS" type:warning file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
            - narrate "<red>No valid items to return!"
            - stop

        # Check balance capacity and handle overflow
        - define current_balance <server.flag[refunds.<[target_uuid]>.balance].if_null[0]>
        - define max_balance <[target_uuid].proc[get_total_sell_cost]>
        - define balance_capacity <[max_balance].sub[<[current_balance]>]>

        # Build items log with quantities for success message
        - define success_items_log <list>
        - foreach <[items_to_process]> key:material as:data:
            - define success_items_log:->:<[material]>x<[data].get[quantity]>

        # Process refund - balance vs direct money
        - if <[total_refund]> <= <[balance_capacity]>:
            # Add all to balance
            - flag server refunds.<[target_uuid]>.balance:+:<[total_refund]>
            - ~log "RETURN_SUCCESS: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Items=<[success_items_log].separated_by[,]> TotalRefund=$<[total_refund].format_number> ToBalance=$<[total_refund].format_number> NewBalance=$<server.flag[refunds.<[target_uuid]>.balance].format_number>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
            - narrate "<green>Added <gold><[total_refund].proc[format_as_tokens]> tokens <green>to your refund balance!"
        - else:
            # Split between balance and direct money
            - define balance_amount <[balance_capacity]>
            - define money_amount <[total_refund].sub[<[balance_capacity]>]>
            - flag server refunds.<[target_uuid]>.balance:<[max_balance]>
            - money give quantity:<[money_amount]> players:<player[<[target_uuid]>]>
            - ~log "RETURN_SUCCESS: TraceID=<[trace_id]> Player=<player.name> Target=<[target_uuid]> Items=<[success_items_log].separated_by[,]> TotalRefund=$<[total_refund].format_number> ToBalance=$<[balance_amount].format_number> ToWallet=$<[money_amount].format_number> BALANCE_OVERFLOW" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
            - narrate "<green>Refund tokens maxed out! Added <gold><[balance_amount].proc[format_as_tokens]> tokens <green>to balance and <gold>$<[money_amount].format_number> <green>to your wallet!"

        # List all successfully returned items
        - narrate "<gray>Items returned:"
        - foreach <[items_to_process]> key:material as:data:
            - define quantity <[data].get[quantity]>
            - define item_display <item[<[material]>].with[quantity=2].formatted>
            - narrate "<gray>- <[quantity]> <[item_display]>"

        # Update bought quantities and clean up zero entries
        - foreach <[items_to_process]> key:material as:data:
            - define current_bought_qty <server.flag[refunds.<[target_uuid]>.bought.<[material]>.quantity]>
            - define new_qty <[current_bought_qty].sub[<[data].get[quantity]>]>
            - if <[new_qty]> <= 0:
                # Remove the item entry entirely
                - flag server refunds.<[target_uuid]>.bought:<server.flag[refunds.<[target_uuid]>.bought].exclude[<[material]>]>
            - else:
                # Update the quantity
                - flag server refunds.<[target_uuid]>.bought.<[material]>.quantity:<[new_qty]>

        # Take the processed items from inventory
        - foreach <[items_to_process]> key:material as:data:
            - take item:<[material]> from:<[inventory]> quantity:<[data].get[quantity]>

get_refund_players:
    type: procedure
    script:
        - define player_map <map>
        - define all_refund_data <server.flag[refunds].if_null[<map>]>
        - foreach <[all_refund_data]> key:uuid as:player_data:
            - if <[player_data].has_key[player_name]>:
                - define player_map.<[uuid]>:<[player_data].get[player_name]>
        - determine <[player_map]>

open_refund_menu_for_player:
    type: task
    definitions: target_uuid
    script:
        - define target_uuid <player.uuid> if:!<[target_uuid].exists>
        - define inventory <inventory[refund_main_menu]>

        # Update title for admin mode
        - if <[target_uuid]> != <player.uuid>:
            - define target_name <server.flag[refunds.<[target_uuid]>.player_name].if_null[Unknown]>
            - adjust <[inventory]> title:<Element[<red><[target_name]><black> Refund Menu]>
        # Set target_uuid flag on reclaim and returns items
        - inventory adjust d:<[inventory]> slot:12 flag:target_uuid:<[target_uuid]>
        - inventory adjust d:<[inventory]> slot:16 flag:target_uuid:<[target_uuid]>
        # Update refund balance display for the target UUID
        - run get_refund_balance_item def.target_uuid:<[target_uuid]> save:balance_result
        - inventory set d:<[inventory]> slot:14 o:<entry[balance_result].created_queue.determination>
        - inventory open d:<[inventory]>

refunds_command:
    type: command
    name: refunds
    description: Open the refund menu to manage your balance and items
    usage: /refunds [admin <&lt>player<&gt>]
    permission: refunds.use
    tab completions:
        1: admin
        2: <context.args.first.equals[admin].if_true[<proc[get_refund_players].values>].if_false[]>
    script:
        # Handle empty args - open main menu for self
        - if <context.args.is_empty>:
            - run open_refund_menu_for_player def.target_uuid:<player.uuid>
            - stop

        # Handle admin command
        - if <context.args.first> == admin:
            # Check admin permission
            - if !<player.has_permission[refunds.admin]>:
                - narrate "<red>You don't have permission to use admin commands!"
                - stop

            - if <context.args.size> != 2:
                - narrate "<red>Usage: /refunds admin <player>"
                - stop

            - define target_name <context.args.get[2]>
            - define refund_players <proc[get_refund_players]>
            - define target_uuid <[refund_players].filter_tag[<[filter_value].equals[<[target_name]>]>].keys.first.if_null[null]>
            - if <[target_uuid]> == null:
                - narrate "<red>Player '<[target_name]>' not found in refund system!"
                - stop

            # Log admin access with trace ID
            - define trace_id <util.random_uuid>
            - ~log "ADMIN_ACCESS: TraceID=<[trace_id]> Admin=<player.name>(<player.uuid>) Target=<[target_name]>(<[target_uuid]>) Action=OPEN_REFUND_MENU" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

            # Open refund menu for the target player
            - run open_refund_menu_for_player def.target_uuid:<[target_uuid]>
            - narrate "<green>Opened refund menu for <[target_name]>"

        - else:
            - narrate "<red>Usage: /refunds [admin <&lt>player<&gt>]"

# Token conversion helper procedures
format_as_tokens:
    type: procedure
    definitions: dollar_amount
    script:
    # Convert dollars to tokens (multiply by 100) and format as integer
    - define tokens <[dollar_amount].mul[100].round>
    - determine <[tokens].format_number[#,##0]>

dollars_to_tokens_raw:
    type: procedure
    definitions: dollar_amount
    script:
    # Convert dollars to tokens without formatting (for calculations)
    - determine <[dollar_amount].mul[100].round>

tokens_to_dollars:
    type: procedure
    definitions: token_amount
    script:
    # Convert tokens back to dollars (divide by 100)
    - determine <[token_amount].div[100]>

# Token contribution system
contribute_to_balance:
    type: task
    definitions: target_uuid
    script:
        # Default to current player if no UUID provided
        - define target_uuid <player.uuid> if:!<[target_uuid].exists>

        # Calculate contribution cap
        - define current_balance <server.flag[refunds.<[target_uuid]>.balance].if_null[0]>
        - define total_cost <[target_uuid].proc[get_total_sell_cost].if_null[0]>
        - define max_contribution <[total_cost].sub[<[current_balance]>]>

        # Check if they already have enough tokens
        - if <[max_contribution]> <= 0:
            - narrate "<green>You already have enough tokens to reclaim all your items!"
            - stop

        # Check if player has any money
        - if <player.money> <= 0:
            - narrate "<red>You don't have any money to buy tokens with!"
            - stop

        # Set flag to mark player as awaiting input
        - flag player awaiting_contribution expire:30s
        - flag player contribution_target_uuid:<[target_uuid]>
        # Store max contribution in TOKENS for easier comparison
        - flag player contribution_max:<[max_contribution].proc[dollars_to_tokens_raw]>

        # Calculate how much they can actually afford
        - define affordable_tokens <player.money.proc[dollars_to_tokens_raw]>
        - define actual_max <[max_contribution].min[<[affordable_tokens]>]>

        # Prompt player
        - narrate "<&6>══════════════════════════"
        - narrate "<&e><&l>BUY REFUND TOKENS"
        - narrate "<&6>══════════════════════════"
        - narrate "<&f>How many tokens would you like to buy?"
        - narrate "<&7>Rate: <&a>100 tokens = $1.00"
        - narrate "<&7>Your money: <&a>$<player.money.format_number[#,##0.00]>"
        - narrate "<&7>Max you can buy: <&e><[actual_max].proc[format_as_tokens]> tokens"
        - narrate ""
        - narrate "<&b>Type the number of tokens in chat..."
        - narrate "<&7>(You have 30 seconds)"
        - narrate "<&6>══════════════════════════"

        # Schedule timeout message
        - wait 30s
        - if <player.has_flag[awaiting_contribution]>:
            - flag player awaiting_contribution:!
            - flag player contribution_target_uuid:!
            - flag player contribution_max:!
            - narrate "<&c>Token purchase timed out. Open the menu again if you want to buy tokens."

# Chat monitor for token contributions
contribution_chat_monitor:
    type: world
    events:
        on player chats flagged:awaiting_contribution:
            # Get stored data
            - define target_uuid <player.flag[contribution_target_uuid]>
            - define max_contribution <player.flag[contribution_max]>

            # Parse the input
            - define input <context.message.strip_color>

            # Check if it's a valid number
            - if !<[input].is_decimal>:
                - narrate "<&c>That's not a valid number! Please type a number."
                - determine cancelled

            # Convert to number and validate
            - define requested_tokens <[input].round_down>

            # Check if positive
            - if <[requested_tokens]> <= 0:
                - narrate "<&c>Please enter a positive number of tokens!"
                - determine cancelled

            # Calculate cost in dollars
            - define cost <[requested_tokens].proc[tokens_to_dollars]>

            # Check if player has enough money
            - if <[cost]> > <player.money>:
                - narrate "<&c>You don't have enough money! <[requested_tokens]> tokens costs $<[cost].format_number[#,##0.00]> but you only have $<player.money.format_number[#,##0.00]>"
                - determine cancelled

            # Check if it exceeds the contribution cap (max_contribution is already in tokens)
            - if <[requested_tokens]> > <[max_contribution]>:
                - narrate "<&c>You can't buy that many tokens! Maximum: <[max_contribution].format_number[#,##0]> tokens"
                - determine cancelled

            # Process the contribution
            - money take quantity:<[cost]> players:<player>
            - flag server refunds.<[target_uuid]>.balance:+:<[cost]>

            # Clear the flags
            - flag player awaiting_contribution:!
            - flag player contribution_target_uuid:!
            - flag player contribution_max:!

            # Confirm success
            - define new_balance <server.flag[refunds.<[target_uuid]>.balance]>
            - narrate "<&a>Successfully purchased <[requested_tokens]> tokens for $<[cost].format_number[#,##0.00]>!"
            - narrate "<&f>New token balance: <&e><[new_balance].proc[format_as_tokens]> tokens"

            # Cancel the chat message
            - determine cancelled