refund_introduction_book:
    type: book
    title: <&6>Economic Reset Guide
    author: <&c>Aldriex
    signed: true
    text:
    - <&0><&l>Important Notice<n><n><&0><player.name>,<n><n>We've made significant changes to our economy system that affect everyone on the server.<n><n>Please read this guide carefully to understand your options.
    - <&4><&l>What Changed?<n><n><&0>• All NPC shops have been permanently removed<n><n>• The server economy has been reset<n><n>• A new refund system has been implemented to help you recover your items
    - <&2><&l>Your Refund Tokens<n><n><&0>All money you earned from selling items to NPCs has been converted into <&a>Refund Tokens<&0>.<n><n>These tokens can ONLY be used to reclaim items you previously sold.
    - <&9><&l>Your Statistics<n><n><&0>• <&a>Refund Tokens:<&0> <server.flag[refunds.<player.uuid>.balance].if_null[0].proc[format_as_tokens]><n>• <&6>Tokens Needed:<&0> <player.uuid.proc[get_total_sell_cost].proc[format_as_tokens]><n>• <&b>Items Sold:<&0> <server.flag[refunds.<player.uuid>.sold].if_null[<map>].size> types<n>• <&d>Items Bought:<&0> <server.flag[refunds.<player.uuid>.bought].if_null[<map>].size> types<n><n><element[<&b><&l>Click here to open menu].on_click[/refunds]>
    - <&9><&l>The /refunds Command<n><n><&0>Type <element[<&b>/refunds].on_click[/refunds]><&0> to access the refund menu where you can:<n><n>• <&a>Reclaim<&0> items you sold<n>• <&b>Return<&0> items you bought
    - <&6><&l>Reclaiming Items<n><n><&0>Use your refund tokens to buy back items you sold at the exact price you sold them for.<n><n>As you reclaim items, the total tokens you need will decrease - so don't be afraid to reclaim the items you want!
    - <&5><&l>Returning Items<n><n><&0>You can return items you bought from NPCs for the price you paid.<n><n>This will add to your refund tokens.
    - <&c><&l>Important!<n><n><&0>If you return items and fill your required token balance, any extra tokens will be redeemed at 1¢ each.<n><n>This means excess tokens become regular money you can use freely!
    - <&d><&l>Admin Support<n><n><&0>If you have questions or issues with the refund system, please contact an admin.<n><n>We're here to help ensure a smooth transition.
    - <&6><&l>Final Notes<n><n><&0>This system ensures everyone can recover their items fairly.<n><n>The economy reset gives us all a fresh start with better balance.<p><&0>Good luck!<n><&c>- Aldriex

# Task to give the book to players on first login after deployment
give_refund_book:
    type: task
    script:
        - define trace_id <util.random_uuid>

        # Check if player has refund data
        - define has_sold <server.has_flag[refunds.<player.uuid>.sold]>
        - define has_bought <server.has_flag[refunds.<player.uuid>.bought]>
        - define has_balance "<server.flag[refunds.<player.uuid>.balance].if_null[0]> > 0"

        # Only proceed if player has any refund data
        - if !<[has_sold]> && !<[has_bought]> && !<[has_balance]>:
            - ~log "REFUND_BOOK_SKIP: TraceID=<[trace_id]> Player=<player.name>(<player.uuid>) Reason=NO_REFUND_DATA" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log
            - stop

        # Check if player has already received the book
        - if !<server.has_flag[refunds.book_given.<player.uuid>]>:
            - ~log "REFUND_BOOK_GENERATION: TraceID=<[trace_id]> Player=<player.name>(<player.uuid>) HasSold=<[has_sold]> HasBought=<[has_bought]> Balance=$<server.flag[refunds.<player.uuid>.balance].if_null[0].format_number>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

            # Create the book with custom lore
            - define book <item[refund_introduction_book].with[lore=<&7>Generated for: <&e><player.name>|<&7>Date: <&e><util.time_now.format[yyyy-MM-dd]>|<&7>|<&6>This book contains important|<&6>information about your refunds.]>
            # Give the book
            - give <[book]>
            # Mark as given
            - flag server refunds.book_given.<player.uuid>:true

            - ~log "REFUND_BOOK_DELIVERED: TraceID=<[trace_id]> Player=<player.name>(<player.uuid>) GenerationDate=<util.time_now.format[yyyy-MM-dd]> GenerationTime=<util.time_now.format[HH:mm:ss]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

            # Send welcome message with clickable
            - clickable save:open_refunds for:<player> until:5m:
                - run open_refund_menu_for_player def.target_uuid:<player.uuid>
            - narrate "<&6>═══════════════════════════════"
            - narrate "<&e><&l>IMPORTANT ECONOMIC UPDATE!"
            - narrate "<&6>═══════════════════════════════"
            - narrate "<&f>Welcome back, <&e><player.name><&f>!"
            - narrate "<&f>Major changes have been made to the server economy."
            - narrate "<&f>You've been given an <&6>Economic Reset Guide<&f> book."
            - narrate "<&a>Please read it carefully to understand the new refund system."
            - narrate "<&f>"
            - narrate "<&f>Quick Start: <element[<&b><&l>Click here to open your refund menu!].on_click[<entry[open_refunds].command>]>"
            - narrate "<&6>═══════════════════════════════"
        - else:
            - ~log "REFUND_BOOK_SKIP: TraceID=<[trace_id]> Player=<player.name>(<player.uuid>) Reason=ALREADY_RECEIVED" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

# World event to trigger on player join
refund_book_on_join:
    type: world
    enabled: <server.has_flag[refunds.enabled]>
    events:
        on player joins:
            # Small delay to ensure player is fully loaded
            - wait 2s
            - run give_refund_book