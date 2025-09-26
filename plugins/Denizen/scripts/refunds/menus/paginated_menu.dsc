#Next/previous page items & inventory script
next_page:
  type: item
  material: paper
  display name: <&a>Next Page

previous_page:
  type: item
  material: paper
  display name: <&a>Previous Page

page_information:
    type: item
    material: redstone_torch
    display name: <&6>Page ? of ?
    lore:
    - <&7>Current page information

page_click_listener:
  type: world
  events:
    on player clicks item_flagged:page in inventory:
       - run open_paged_inventory def.items:<context.item.flag[items]> def.page:<context.item.flag[page]> def.inventory:<context.inventory> def.target_uuid:<context.item.flag[target_uuid]> def.return_to:<context.item.flag[return_to]>

open_paged_inventory:
  type: task
  definitions: items|page|inventory|target_uuid|return_to
  script:
  #Page fallback in case no definition is provided
  - define page 1 if:!<[page].exists>
  - define target_uuid <player.uuid> if:!<[target_uuid].exists>

  # Store original inventory name before cloning
  - define inventory_name <[inventory]>
  # Clone inventory
  - define inventory <inventory[<[inventory]>]>

  # Update title for admin mode
  - if <[target_uuid]> != <player.uuid>:
    - define target_name <server.flag[refunds.<[target_uuid]>.player_name].if_null[Unknown]>
    - if <[inventory_name]> == refund_reclaim_menu:
      - adjust <[inventory]> title:<Element[<red><[target_name]><black> Reclaim Sold Items]>
    - else if <[inventory_name]> == refund_return_listing:
      - adjust <[inventory]> title:<Element[<red><[target_name]><black> Return Purchased Items]>

  #This is a list of all items that can end up in the inventory
  - define slots <[inventory].size.sub[18]> if:!<[slots].exists>
  - repeat <[slots]> as:index:
    - take slot:<[index]> quantity:64 from:<[inventory]>

  - if page == 1:
    - define paged_items <[items].sub_lists[<[slots].add[1]>]>
  - else:
    - define paged_items <[items].sub_lists[<[slots]>]>
  - define number_of_pages <[paged_items].size>

  #The items that'll appear on this page
  - define items_on_page <list> if:!<[items].exists>
  - define items_on_page <[paged_items].get[<[page]>]>

  #Sets the items to the inventory
  - give <[items_on_page]> to:<[inventory]>

  #Sets the next/previous page buttons (if there are any)
  - if <[page]> > 1:
    - inventory set d:<[inventory]> slot:<[inventory].size.sub[5]> o:<item[previous_page].with_flag[page:<[page].sub[1]>].with_flag[items:<[items]>].with_flag[target_uuid:<[target_uuid]>].with_flag[return_to:<[return_to]>]>

  - if <[page]> < <[paged_items].size>:
    - inventory set d:<[inventory]> slot:<[inventory].size.sub[3]> o:<item[next_page].with_flag[page:<[page].add[1]>].with_flag[items:<[items]>].with_flag[target_uuid:<[target_uuid]>].with_flag[return_to:<[return_to]>]>

  - inventory set d:<[inventory]> slot:<[inventory].size.sub[4]> o:<item[page_information].with[display_name=<gold>Page <[page]> of <[number_of_pages]>]>

  # Set back button with return_to if provided
  - if <[return_to].exists>:
    - inventory set d:<[inventory]> slot:<[inventory].size.sub[8]> o:<item[back_button].with_flag[return_to:<[return_to]>]>

  # Update balance item for reclaim menu to use targets balance
  - if <[inventory].slot[<[inventory].size>].has_flag[action]> && <[inventory].slot[<[inventory].size>].flag[action]> == balance:
    - run get_refund_balance_item def.target_uuid:<[target_uuid]> save:balance_result
    - inventory set d:<[inventory]> slot:<[inventory].size> o:<entry[balance_result].created_queue.determination>

  # Set target_uuid on confirm button if present
  - if <[inventory].slot[<[inventory].size>].has_flag[action]> && <[inventory].slot[<[inventory].size>].flag[action]> == confirm:
    - inventory adjust d:<[inventory]> slot:<[inventory].size> flag:target_uuid:<[target_uuid]>

  #Opens the inventory
  - inventory open d:<[inventory]>