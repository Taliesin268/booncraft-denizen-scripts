refund_clerk_assignment:
    type: assignment
    actions:
        on assignment:
            - trigger name:proximity state:true radius:5
            - trigger name:click state:true
    interact scripts:
        - refund_clerk_interact

refund_clerk_interact:
    type: interact
    steps:
        1:
            proximity trigger:
                entry:
                    script:
                    # Only greet if system is enabled OR player is admin
                    - if <server.has_flag[refunds.enabled]> || <player.has_permission[refunds.admin]>:
                        # Only greet players with refund data
                        - if <server.has_flag[refunds.<player.uuid>.sold]> || <server.has_flag[refunds.<player.uuid>.bought]>:
                            # Check if we've already greeted recently (avoid spam)
                            - if !<player.has_flag[refund_npc_greeted]>:
                                - narrate "<&e>[Refund Clerk] <&f>Hello <player.name>! Click me to access your refunds."
                                - flag player refund_npc_greeted expire:5m

            click trigger:
                script:
                # Check if system is enabled OR player is admin
                - if !<server.has_flag[refunds.enabled]> && !<player.has_permission[refunds.admin]>:
                    - narrate "<&e>[Refund Clerk] <&c>Sorry <player.name>, this isn't ready yet!"
                    - stop

                # Check if player has refund data
                - if !<server.has_flag[refunds.<player.uuid>.sold]> && !<server.has_flag[refunds.<player.uuid>.bought]>:
                    - narrate "<&e>[Refund Clerk] <&c>Sorry, you have nothing to return!"
                    - stop

                # Show main menu
                - run refund_clerk_show_menu

refund_clerk_show_menu:
    type: task
    script:
        - narrate "<&6>══════════════════════════"
        - narrate "<&e><&l>REFUND CLERK"
        - narrate "<&6>══════════════════════════"
        - narrate "<&f>How may I assist you today?"
        - narrate ""

        # Regular player options
        - clickable save:view_refunds for:<player> until:30s:
            - run open_refund_menu_for_player def.target_uuid:<player.uuid>
        - narrate "<element[<&a>[View My Refunds]].on_click[<entry[view_refunds].command>]> <&7>- Access your refund menu"

        - clickable save:check_balance for:<player> until:30s:
            - run refund_clerk_show_balance
        - narrate "<element[<&b>[Check Balance]].on_click[<entry[check_balance].command>]> <&7>- View your current balance"

        - clickable save:get_help for:<player> until:30s:
            - run refund_clerk_show_help
        - narrate "<element[<&e>[Help]].on_click[<entry[get_help].command>]> <&7>- Learn about the refund system"

        # Admin option (only show if player has permission)
        - if <player.has_permission[refunds.admin]>:
            - clickable save:admin_view for:<player> until:30s:
                - run refund_clerk_admin_menu
            - narrate "<element[<&c>[Admin View]].on_click[<entry[admin_view].command>]> <&7>- View any player's refunds"

        - narrate "<&6>══════════════════════════"

refund_clerk_show_balance:
    type: task
    script:
        - define balance <server.flag[refunds.<player.uuid>.balance].if_null[0]>
        - define total_cost <player.uuid.proc[get_total_sell_cost].if_null[0]>

        - narrate "<&6>══════════════════════════"
        - narrate "<&e><&l>YOUR BALANCE"
        - narrate "<&6>══════════════════════════"
        - narrate "<&f>Current Balance: <&a>$<[balance].format_number[#,##0.00]>"
        - narrate "<&f>Total Cost to Reclaim All: <&c>$<[total_cost].format_number[#,##0.00]>"
        - narrate ""
        - clickable save:open_menu for:<player> until:30s:
            - run open_refund_menu_for_player def.target_uuid:<player.uuid>
        - narrate "<element[<&b>[Open Refund Menu]].on_click[<entry[open_menu].command>]> <&7>to manage your items"
        - narrate "<&6>══════════════════════════"

refund_clerk_show_help:
    type: task
    script:
        - narrate "<&6>══════════════════════════"
        - narrate "<&e><&l>REFUND SYSTEM HELP"
        - narrate "<&6>══════════════════════════"
        - narrate "<&f>The refund system allows you to:"
        - narrate "<&7>• <&f>Reclaim items you sold to the server"
        - narrate "<&7>• <&f>Return items you bought from the server"
        - narrate "<&7>• <&f>Manage your refund balance"
        - narrate ""
        - narrate "<&f>Your refund balance can only be used"
        - narrate "<&f>to reclaim items you previously sold."
        - narrate ""

        # Guidebook option with cooldown
        - if <player.has_flag[refund_book_cooldown]>:
            - narrate "<&c>Guidebook available in: <&e><player.flag_expiration[refund_book_cooldown].from_now.formatted>"
        - else:
            - clickable save:get_guidebook for:<player> until:30s:
                - run refund_clerk_give_guidebook
            - narrate "<element[<&a>[Get Guidebook]].on_click[<entry[get_guidebook].command>]> <&7>- Receive the introduction book"

        - narrate "<&6>══════════════════════════"

refund_clerk_give_guidebook:
    type: task
    script:
        # Check cooldown
        - if <player.has_flag[refund_book_cooldown]>:
            - narrate "<&c>You must wait <player.flag_expiration[refund_book_cooldown].from_now.formatted> before getting another guidebook."
            - stop

        # Set cooldown
        - flag player refund_book_cooldown expire:5m

        # Create and give the book
        - define book <item[refund_introduction_book].with[lore=<&7>Generated for: <&e><player.name>|<&7>Date: <&e><util.time_now.format[yyyy-MM-dd]>|<&7>|<&6>This book contains important|<&6>information about your refunds.]>
        - give <[book]>

        - narrate "<&a>Here's your refund guidebook! It contains all the information you need."

refund_clerk_admin_menu:
    type: task
    definitions: page
    script:
        # Default to page 1
        - define page 1 if:!<[page].exists>
        - define page <[page].if_null[1]>

        - narrate "<&6>══════════════════════════"
        - narrate "<&c><&l>ADMIN: SELECT PLAYER <&7>(Page <[page]>)"
        - narrate "<&6>══════════════════════════"

        # Get all players with refund data
        - define refund_players <proc[get_refund_players]>
        - if <[refund_players].is_empty>:
            - narrate "<&c>No players with refund data found."
            - narrate "<&6>══════════════════════════"
            - stop

        - narrate "<&f>Click a player to view their refunds:"
        - narrate ""

        # Calculate pagination
        - define items_per_page 10
        - define start_index <[page].sub[1].mul[<[items_per_page]>].add[1]>
        - define end_index <[start_index].add[<[items_per_page]>].sub[1]>
        - define total_players <[refund_players].size>

        # Show players for current page
        - define count 0
        - define shown 0
        - foreach <[refund_players]> key:uuid as:player_name:
            - define count:+:1

            # Skip until we reach the start index
            - if <[count]> < <[start_index]>:
                - foreach next

            # Stop after showing items_per_page players
            - if <[shown]> >= <[items_per_page]>:
                - foreach stop

            - define shown:+:1

            # Create clickable for each player
            - clickable save:admin_view_<[uuid]> for:<player> until:60s:
                - run open_refund_menu_for_player def.target_uuid:<[uuid]>
                - narrate "<&a>Opened refund menu for <&e><[player_name]>"

            # Get basic stats for display
            - define balance <server.flag[refunds.<[uuid]>.balance].if_null[0]>
            - narrate "<element[<&e><[player_name]>].on_click[<entry[admin_view_<[uuid]>].command>]> <&7>- Balance: $<[balance].format_number[#,##0.00]>"

        - narrate ""

        # Show "Show more" if there are more pages
        - if <[end_index]> < <[total_players]>:
            - define next_page <[page].add[1]>
            - clickable save:show_more for:<player> until:60s:
                - run refund_clerk_admin_menu def.page:<[next_page]>
            - narrate "<element[<&b>[Show more...]].on_click[<entry[show_more].command>]> <&7>(<[total_players].sub[<[end_index]>]> more players)"

        # Show "Previous" if not on first page
        - if <[page]> > 1:
            - define prev_page <[page].sub[1]>
            - clickable save:show_previous for:<player> until:60s:
                - run refund_clerk_admin_menu def.page:<[prev_page]>
            - narrate "<element[<&b>[Previous page]].on_click[<entry[show_previous].command>]>"

        - narrate "<&6>══════════════════════════"