# Refunds Backup System
# Commands to save and load refunds data to/from YAML files

save_refunds_command:
    type: command
    name: save_refunds
    description: Saves the current refunds data to a YAML file
    usage: /save_refunds [filename]
    permission: refunds.backup
    script:
    - define filename <context.args.get[1].if_null[refunds_backup_<util.time_now.format[yyyy-MM-dd_HH-mm-ss]>]>

    # Ensure filename has .yml extension
    - if !<[filename].ends_with[.yml]>:
        - define filename <[filename]>.yml

    # Create or load the YAML file
    - yaml create id:refunds_save

    # Get the refunds data from server flags
    - define refunds_data <server.flag[refunds].if_null[<map>]>

    - if <[refunds_data].is_empty>:
        - narrate "<red>No refunds data found to save!"
        - yaml unload id:refunds_save
        - stop

    # Set metadata
    - yaml id:refunds_save set metadata.saved_by:<player.name>
    - yaml id:refunds_save set metadata.saved_at:<util.time_now.format[yyyy-MM-dd HH:mm:ss]>
    - yaml id:refunds_save set metadata.server:<server.motd>
    - yaml id:refunds_save set metadata.total_players:<[refunds_data].size>

    # Save the refunds data
    - yaml id:refunds_save set refunds:<[refunds_data]>

    # Count statistics
    - define total_balance 0
    - define total_items 0
    - foreach <[refunds_data]> key:uuid as:player_data:
        - define total_balance:+:<[player_data].get[balance].if_null[0]>
        - if <[player_data].contains[sold]>:
            - define total_items:+:<[player_data].get[sold].size>

    - yaml id:refunds_save set metadata.total_balance:<[total_balance]>
    - yaml id:refunds_save set metadata.total_items:<[total_items]>

    # Save to file
    - ~yaml savefile:refunds/<[filename]> id:refunds_save

    # Unload from memory
    - yaml unload id:refunds_save

    # Log the backup
    - ~log "REFUNDS_BACKUP_SAVED: Admin=<player.name> File=<[filename]> Players=<[refunds_data].size> TotalBalance=<[total_balance]> TotalItems=<[total_items]>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    - narrate "<green>✓ Refunds data saved to: plugins/Denizen/refunds/<[filename]>"
    - narrate "<gray>  - Players: <white><[refunds_data].size>"
    - narrate "<gray>  - Total Balance: <white>$<[total_balance].format_number[#,##0.00]>"
    - narrate "<gray>  - Total Items: <white><[total_items]>"

load_refunds_command:
    type: command
    name: load_refunds
    description: Loads refunds data from a YAML file (WARNING: Overwrites current data!)
    usage: /load_refunds <&lt>filename<&gt>
    permission: refunds.backup
    script:
    - if <context.args.size> < 1:
        - narrate "<red>Usage: /load_refunds <&lt>filename<&gt>"
        - narrate "<yellow>Available backups:"
        - run list_refund_backups
        - stop

    - define filename <context.args.get[1]>

    # Ensure filename has .yml extension
    - if !<[filename].ends_with[.yml]>:
        - define filename <[filename]>.yml

    # Load the YAML file
    - ~yaml load:refunds/<[filename]> id:refunds_load

    - if !<yaml.list.contains[refunds_load]>:
        - narrate "<red>Failed to load file: plugins/Denizen/refunds/<[filename]>"
        - stop

    # Get metadata
    - define metadata <yaml[refunds_load].read[metadata].if_null[<map>]>
    - define saved_by <[metadata].get[saved_by].if_null[Unknown]>
    - define saved_at <[metadata].get[saved_at].if_null[Unknown]>

    # Show confirmation
    - narrate "<yellow>═══════════════════════════════════════"
    - narrate "<gold>About to load refunds backup:"
    - narrate "<gray>  File: <white><[filename]>"
    - narrate "<gray>  Saved by: <white><[saved_by]>"
    - narrate "<gray>  Saved at: <white><[saved_at]>"
    - narrate "<gray>  Players: <white><[metadata].get[total_players].if_null[0]>"
    - narrate "<gray>  Total Balance: <white>$<[metadata].get[total_balance].if_null[0].format_number[#,##0.00]>"
    - narrate "<red><bold>WARNING: This will OVERWRITE all current refunds data!"
    - narrate "<yellow>═══════════════════════════════════════"
    - narrate "<yellow>Type <white>/confirm_load_refunds <yellow>within 30 seconds to proceed"

    # Store the data temporarily for confirmation
    - flag player pending_refunds_load:<yaml[refunds_load].read[refunds]> expire:30s
    - flag player pending_refunds_file:<[filename]> expire:30s

    # Unload the YAML (we'll reload it if confirmed)
    - yaml unload id:refunds_load

confirm_load_refunds_command:
    type: command
    name: confirm_load_refunds
    description: Confirms loading of refunds data
    usage: /confirm_load_refunds
    permission: refunds.backup
    script:
    - if !<player.has_flag[pending_refunds_load]>:
        - narrate "<red>No pending refunds load to confirm!"
        - stop

    - define refunds_data <player.flag[pending_refunds_load]>
    - define filename <player.flag[pending_refunds_file]>

    # Create a backup of current data first
    - narrate "<yellow>Creating backup of current data..."
    - run save_refunds_command def.1:auto_backup_before_load

    # Clear current refunds data and load new data
    - flag server refunds:<[refunds_data]>

    # Clear the pending flags
    - flag player pending_refunds_load:!
    - flag player pending_refunds_file:!

    # Log the load
    - ~log "REFUNDS_BACKUP_LOADED: Admin=<player.name> File=<[filename]> Players=<[refunds_data].size>" file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log

    - narrate "<green>✓ Refunds data loaded successfully from: <[filename]>"
    - narrate "<gray>Use <white>/save_refunds <gray>to create a new backup"

list_refund_backups:
    type: task
    script:
    - define files <util.list_files[plugins/Denizen/refunds].filter[ends_with[.yml]].if_null[<list>]>

    - if <[files].is_empty>:
        - narrate "<gray>No backup files found in plugins/Denizen/refunds/"
        - stop

    - narrate "<gray>Found <white><[files].size> <gray>backup files:"
    - foreach <[files].sort_by_value[parse[after_last[/]]]> as:file:
        - define filename <[file].after_last[/]>
        - narrate "<gray>  - <white><[filename]>"

list_refunds_command:
    type: command
    name: list_refund_backups
    description: Lists all available refund backup files
    usage: /list_refund_backups
    permission: refunds.backup
    script:
    - narrate "<yellow>Available refund backups:"
    - run list_refund_backups

export_refunds_summary_command:
    type: command
    name: export_refunds_summary
    description: Exports a summary of all refunds data to a readable YAML file
    usage: /export_refunds_summary
    permission: refunds.backup
    script:
    - define filename refunds_summary_<util.time_now.format[yyyy-MM-dd_HH-mm-ss]>.yml

    - yaml create id:refunds_summary

    # Add header information
    - yaml id:refunds_summary set export_info.generated_by:<player.name>
    - yaml id:refunds_summary set export_info.generated_at:<util.time_now.format[yyyy-MM-dd HH:mm:ss]>
    - yaml id:refunds_summary set export_info.server:<server.motd>

    - define refunds_data <server.flag[refunds].if_null[<map>]>
    - define player_count 0
    - define total_balance 0
    - define total_items_sold 0

    # Process each player
    - foreach <[refunds_data]> key:uuid as:player_data:
        - define player_count:++
        - define player_name <server.match_offline_player[<[uuid]>].name.if_null[Unknown]>

        # Store player summary
        - yaml id:refunds_summary set players.<[uuid]>.name:<[player_name]>
        - yaml id:refunds_summary set players.<[uuid]>.balance:<[player_data].get[balance].if_null[0]>

        - define total_balance:+:<[player_data].get[balance].if_null[0]>

        # Count and summarize items
        - if <[player_data].contains[sold]>:
            - define item_count 0
            - define item_value 0
            - foreach <[player_data].get[sold]> key:material as:item_data:
                - define quantity <[item_data].get[quantity].if_null[0]>
                - define unit_price <[item_data].get[unit_price].if_null[0]>
                - define item_total <[quantity].mul[<[unit_price]>]>
                - define item_count:+:<[quantity]>
                - define item_value:+:<[item_total]>
                - define total_items_sold:+:<[quantity]>

                # Store item details
                - yaml id:refunds_summary set players.<[uuid]>.items.<[material]>.quantity:<[quantity]>
                - yaml id:refunds_summary set players.<[uuid]>.items.<[material]>.unit_price:<[unit_price]>
                - yaml id:refunds_summary set players.<[uuid]>.items.<[material]>.total_value:<[item_total]>

            - yaml id:refunds_summary set players.<[uuid]>.total_items:<[item_count]>
            - yaml id:refunds_summary set players.<[uuid]>.total_item_value:<[item_value]>

    # Add summary statistics
    - yaml id:refunds_summary set summary.total_players:<[player_count]>
    - yaml id:refunds_summary set summary.total_balance:<[total_balance]>
    - yaml id:refunds_summary set summary.total_items_sold:<[total_items_sold]>
    - yaml id:refunds_summary set summary.average_balance:<[total_balance].div[<[player_count].max[1]>]>

    # Save the file
    - ~yaml savefile:refunds/<[filename]> id:refunds_summary
    - yaml unload id:refunds_summary

    - narrate "<green>✓ Refunds summary exported to: plugins/Denizen/refunds/<[filename]>"
    - narrate "<gray>  - Players: <white><[player_count]>"
    - narrate "<gray>  - Total Balance: <white>$<[total_balance].format_number[#,##0.00]>"
    - narrate "<gray>  - Total Items: <white><[total_items_sold]>"