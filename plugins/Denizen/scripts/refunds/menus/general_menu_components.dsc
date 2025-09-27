back_button:
    type: item
    material: barrier
    display name: <&c>Back to previous menu
    lore:
        - <&7>Click to return to the previous menu.
    flags:
        action: back

refund_balance:
    type: item
    material: sunflower
    display name: <gold>Refund Balance
    lore:
        - <&7>Current Balance: <&a><server.flag[refunds.<player.uuid>.balance].if_null[0].proc[format_as_tokens]> tokens
        - <&7>
        - <list[<&7>If you get <&c><player.uuid.proc[get_total_sell_cost].if_null[0].sub[<server.flag[refunds.<player.uuid>.balance].if_null[0]>].proc[format_as_tokens]> more tokens<&7>,|<&7>any extra tokens will be redeemed|<&7>at 1¢ each.].if[<server.flag[refunds.<player.uuid>.balance].if_null[0].is_less_than[<player.uuid.proc[get_total_sell_cost].if_null[0]>]>].if_null[<list[<&7>Any further returns will add|<&7>1¢ per token to your balance.]>]>
        - <&7>
        - <&7>These tokens are used to
        - <&7>reclaim items you sold.
        - <&7>
        - <&b>Click to add tokens to your balance!
        - <&7>Max contribution: <&e><player.uuid.proc[get_total_sell_cost].if_null[0].sub[<server.flag[refunds.<player.uuid>.balance].if_null[0]>].max[0].proc[format_as_tokens]> tokens
    flags:
        action: balance

confirm_button:
    type: item
    material: emerald
    display name: <&a>Confirm
    lore:
        - <&7>Click to confirm
    flags:
        action: confirm

info_block:
    type: item
    material: spruce_sign
    display name: <&e>Information

empty_slot:
    type: item
    material: gray_stained_glass_pane
    display name: <&7>

get_refund_balance_item:
    type: task
    definitions: target_uuid
    script:
        # Default to current player if no UUID provided
        - define target_uuid <player.uuid> if:!<[target_uuid].exists>

        # Get balance data for the target UUID
        - define current_balance <server.flag[refunds.<[target_uuid]>.balance].if_null[0]>
        - define total_cost <[target_uuid].proc[get_total_sell_cost].if_null[0]>
        - define max_contribution <[total_cost].sub[<[current_balance]>].max[0]>

        # Create conditional message based on whether threshold is reached
        - if <[current_balance].is_less_than[<[total_cost]>]>:
            - define threshold_message <list[<&7>If you get <&c><[total_cost].sub[<[current_balance]>].proc[format_as_tokens]> more tokens<&7>,|<&7>any extra tokens will be redeemed|<&7>at 1¢ each.]>
        - else:
            - define threshold_message <list[<&7>Any further returns will add|<&7>1¢ per token to your balance.]>

        # Create the balance item with same format as static component
        - define balance_item <item[sunflower].with[display=<gold>Refund Balance;lore=<&7>Current Balance: <&a><[current_balance].proc[format_as_tokens]> tokens|<&7>|<[threshold_message].separated_by[|]>|<&7>|<&7>These tokens are used to|<&7>reclaim items you sold.|<&7>|<&b>Click to add tokens to your balance!|<&7>Max contribution: <&e><[max_contribution].proc[format_as_tokens]> tokens;flag=action:balance;flag=target_uuid:<[target_uuid]>]>

        - determine <[balance_item]>