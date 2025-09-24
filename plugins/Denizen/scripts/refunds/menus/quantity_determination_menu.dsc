quantity_determination_menu:
    type: inventory
    inventory: chest
    title: How many items?
    gui: true
    definitions:
        empty: <item[gray_stained_glass_pane].with[display=<&7>]>
        increment: <item[green_stained_glass_pane].with[display=<&a>Increase Quantity;lore=<&7>Click to increase the quantity by 1.;flag=action:increment;flag=amount:1]>
        increment_16: <item[green_stained_glass_pane].with[display=<&a>Increase Quantity;lore=<&7>Click to increase the quantity by 16.;flag=action:increment;flag=amount:16]>
        increment_32: <item[green_stained_glass_pane].with[display=<&a>Increase Quantity;lore=<&7>Click to increase the quantity by 32.;flag=action:increment;flag=amount:32]>
        decrement: <item[red_stained_glass_pane].with[display=<&a>Decrease Quantity;lore=<&7>Click to decrease the quantity by 1.;flag=action:decrement;flag=amount:1]>
        decrement_16: <item[red_stained_glass_pane].with[display=<&a>Decrease Quantity;lore=<&7>Click to decrease the quantity by 16.;flag=action:decrement;flag=amount:16]>
        decrement_32: <item[red_stained_glass_pane].with[display=<&a>Decrease Quantity;lore=<&7>Click to decrease the quantity by 32.;flag=action:decrement;flag=amount:32]>
        invalid_item: <item[bedrock].with[display=<&c>Invalid Item;lore=<&7>Something went wrong, this item won't work.]>
    slots:
    - [] [] [] [] [] [] [] [] []
    - [decrement_32] [decrement_16] [decrement] [] [invalid_item] [] [increment] [increment_16] [increment_32]
    - [back_button] [] [] [] [swap_to_stacks] [] [] [] []

open_quantity_determination_menu:
    type: task
    definitions: item|unit_price|max_quantity|return_to
    script:
        - define inventory <inventory[quantity_determination_menu]>
        - inventory d:<[inventory]> set slot:14 o:<[item].proc[add_quantity_item_lore].context[<[unit_price]>|<[max_quantity]>]>
        - inventory set d:<[inventory]> slot:19 o:<item[back_button].with_flag[return_to:<[return_to]>]>
        - inventory open d:<[inventory]>

add_quantity_item_lore:
    type: procedure
    definitions: item|unit_price|max_quantity
    script:
        - determine <item[<[item]>].with[display_name=How many <[item].material.name> would you like to reclaim?].with[lore=Price (each): <&a>$<[unit_price]>|<gold>Click the adjacent buttons to change the quantity. (Max <[max_quantity]>);flag=max_quantity:<[max_quantity]>]>

swap_to_stacks:
    type: item
    material: dried_kelp_block
    display name: <&e>Swap to Stacks
    lore:
    - <&7>Click to switch to stack mode.
    - <&7>In stack mode, each click increases or decreases the quantity by 64.

swap_to_items:
    type: item
    material: dried_kelp
    display name: <&e>Swap to Items
    lore:
    - <&7>Click to switch to item mode.
    - <&7>In item mode, each click increases or decreases the quantity by 1.

quantity_determination_menu_handler:
    type: world
    events:
        on player clicks item in quantity_determination_menu:
            - choose <context.item.flag[action]>:
                - case back:
                    - inventory open d:<inventory[<context.item.flag[return_to]>]>

                - case increment:
                    - run change_quantity def.inventory:<context.inventory> def.amount:<context.item.flag[amount]> def.direction:increment

                - case decrement:
                    - run change_quantity def.inventory:<context.inventory> def.amount:<context.item.flag[amount]> def.direction:decrement
        on player clicks swap_to_stacks in quantity_determination_menu:
            - inventory d:<context.inventory> set slot:23 o:swap_to_items
        on player clicks swap_to_items in quantity_determination_menu:
            - inventory d:<context.inventory> set slot:23 o:swap_to_stacks

# TODO make it check for stack mode
change_quantity:
    type: task
    definitions: inventory|amount|direction
    script:
        - define item <[inventory].slot[14]>
        - if <[direction]> == increment:
            - inventory d:<[inventory]> adjust slot:14 quantity:<[item].quantity.add[<[amount]>]>
        - else if <[direction]> == decrement:
            - if <[item].quantity.sub[<[amount]>]> < 1:
                - inventory d:<[inventory]> adjust slot:14 quantity:1
            - else:
                - inventory d:<[inventory]> adjust slot:14 quantity:<[item].quantity.sub[<[amount]>]>
        - define item <[inventory].slot[14]>
        - if <[item].quantity> > <[item].max_stack>:
            - inventory d:<[inventory]> adjust slot:14 quantity:<[item].max_stack>
        - if <[item].quantity> > <[item].flag[max_quantity]>:
            - inventory d:<[inventory]> adjust slot:14 quantity:<[item].flag[max_quantity]>