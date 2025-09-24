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