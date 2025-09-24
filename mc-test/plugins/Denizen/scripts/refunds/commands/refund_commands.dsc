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
    - define sold_items <server.flag[refunds.<[target].uuid>.sold]>
    - if !<[sold_items]>:
        - stop
    - define total_sold_items_price 0
    - foreach <[sold_items].values> as:value:
        - define total_sold_items_price:+:<[value].get[unit_price].mul[<[value].get[quantity]>]>
    - define remaining_debt <[total_sold_items_price].sub[<server.flag[refunds.<[target].uuid>.balance].if_null[0]>]>
    # If the player has enough money to cover the remaining debt, take it all and clear their debt.
    - if <[available_funds]> >= <[remaining_debt]>:
        - money take quantity:<[remaining_debt]> players:<[target]>
        - flag server refunds.<[target].uuid>.balance:+:<[remaining_debt]>
    # If the player doesn't have enough money, take what they have and update their debt accordingly.
    - else:
        - money set quantity:0 players:<[target]>
        - flag server refunds.<[target].uuid>.balance:+:<[available_funds]>