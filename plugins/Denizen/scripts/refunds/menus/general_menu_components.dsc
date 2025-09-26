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
        - <&7>Current Balance: <&a>$<server.flag[refunds.<player.uuid>.balance].if_null[0].format_number>
        - <&7> / <red>$<player.uuid.proc[get_total_sell_cost].if_null[0].format_number> (cost to reclaim all)
        - <&7>This balance is used to
        - <&7>reclaim items you sold.
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