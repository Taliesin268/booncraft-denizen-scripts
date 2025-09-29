#!/usr/bin/env python3
"""
Convert Minecraft inventory JSON files to YAML format for item restoration.
Uses inventoryContents as it contains all items including armor and offhand.
Converts color codes and formatting to Denizen format.
"""

import json
import yaml
import sys
import re
from pathlib import Path

# Minecraft color code to Denizen tag mapping
COLOR_MAP = {
    'black': '<&0>',
    'dark_blue': '<&1>',
    'dark_green': '<&2>',
    'dark_aqua': '<&3>',
    'dark_red': '<&4>',
    'dark_purple': '<&5>',
    'gold': '<&6>',
    'gray': '<&7>',
    'dark_gray': '<&8>',
    'blue': '<&9>',
    'green': '<&a>',
    'aqua': '<&b>',
    'red': '<&c>',
    'light_purple': '<&d>',
    'yellow': '<&e>',
    'white': '<&f>'
}

def convert_inventory_json_to_yaml(json_file_path):
    """Convert a Minecraft inventory JSON file to YAML format."""

    # Read the JSON file
    with open(json_file_path, 'r') as f:
        data = json.load(f)

    # Extract SURVIVAL mode data (main game mode)
    survival_data = data.get('SURVIVAL', {})

    # Create output structure with only inventoryContents
    # (it includes armor slots 36-39 and offhand slot 40)
    output_data = {}

    # Extract inventory contents with adjusted slot numbers (add 1 for Denizen)
    if 'inventoryContents' in survival_data:
        output_data['inventoryContents'] = process_items_with_slot_adjustment(survival_data['inventoryContents'])

    # Create output YAML filename
    yaml_file_path = json_file_path.replace('.json', '.yaml')

    # Write to YAML file
    with open(yaml_file_path, 'w') as f:
        yaml.dump(output_data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

    print(f"Converted {json_file_path} to {yaml_file_path}")
    return yaml_file_path

def process_items_with_slot_adjustment(items_dict):
    """Process a dictionary of items, adjusting slot numbers by +1 for Denizen."""
    processed_items = {}

    for slot, item_data in items_dict.items():
        # Add 1 to slot number for Denizen (0-indexed to 1-indexed)
        new_slot = str(int(slot) + 1)
        processed_items[new_slot] = process_item(item_data)

    return processed_items

def convert_minecraft_text_to_denizen(text_json):
    """Convert Minecraft JSON text format to Denizen color tags."""
    if not isinstance(text_json, (str, dict, list)):
        return str(text_json)

    # If it's a string that looks like JSON, try to parse it
    if isinstance(text_json, str):
        # Handle legacy section sign colors first
        if '§' in text_json:
            # Convert legacy color codes directly
            text_json = text_json.replace('§0', '<&0>')
            text_json = text_json.replace('§1', '<&1>')
            text_json = text_json.replace('§2', '<&2>')
            text_json = text_json.replace('§3', '<&3>')
            text_json = text_json.replace('§4', '<&4>')
            text_json = text_json.replace('§5', '<&5>')
            text_json = text_json.replace('§6', '<&6>')
            text_json = text_json.replace('§7', '<&7>')
            text_json = text_json.replace('§8', '<&8>')
            text_json = text_json.replace('§9', '<&9>')
            text_json = text_json.replace('§a', '<&a>')
            text_json = text_json.replace('§b', '<&b>')
            text_json = text_json.replace('§c', '<&c>')
            text_json = text_json.replace('§d', '<&d>')
            text_json = text_json.replace('§e', '<&e>')
            text_json = text_json.replace('§f', '<&f>')
            text_json = text_json.replace('§l', '<&l>')
            text_json = text_json.replace('§o', '<&o>')
            text_json = text_json.replace('§n', '<&n>')
            text_json = text_json.replace('§m', '<&m>')
            text_json = text_json.replace('§k', '<&k>')
            text_json = text_json.replace('§r', '<&r>')
            return text_json

        if text_json.startswith('{') or text_json.startswith('['):
            try:
                # First try to fix NBT-style JSON to standard JSON
                fixed_json = text_json
                # Replace unquoted keys with quoted keys (but not inside already quoted strings)
                fixed_json = re.sub(r'(?<!")(\b\w+\b)(?=:)', r'"\1"', fixed_json)
                # Replace NBT boolean values
                fixed_json = fixed_json.replace(':1b', ':true').replace(':0b', ':false')
                # Don't replace all :1 and :0 as they could be valid numbers

                text_json = json.loads(fixed_json)
            except (json.JSONDecodeError, Exception):
                # If it's not valid JSON even after fixes, just return as is
                return text_json
        else:
            return text_json

    # Process list of text components (lore)
    if isinstance(text_json, list):
        result = []
        for item in text_json:
            converted = convert_minecraft_text_to_denizen(item)
            if converted:
                result.append(converted)
        return result

    # Process single text component
    if isinstance(text_json, dict):
        output = ""

        # Handle root text first
        if 'text' in text_json and text_json['text']:
            # Apply formatting to root text if it has content
            if text_json.get('bold'):
                output += '<&l>'
            color = text_json.get('color', '')
            if color in COLOR_MAP:
                output += COLOR_MAP[color]
            elif color and color.startswith('#'):
                output += f'<&color[{color}]>'
            output += text_json['text']

        # Handle extra components
        if 'extra' in text_json:
            if isinstance(text_json['extra'], list):
                for extra_item in text_json['extra']:
                    if isinstance(extra_item, dict):
                        extra_output = ""
                        # Apply formatting for this component
                        if extra_item.get('bold'):
                            extra_output += '<&l>'

                        color = extra_item.get('color', '')
                        if color in COLOR_MAP:
                            extra_output += COLOR_MAP[color]
                        elif color and color.startswith('#'):
                            extra_output += f'<&color[{color}]>'

                        # Add the text
                        if 'text' in extra_item:
                            extra_output += extra_item['text']

                        # Recursively handle nested extras
                        if 'extra' in extra_item:
                            extra_output += convert_minecraft_text_to_denizen({'extra': extra_item['extra']})

                        output += extra_output
                    elif isinstance(extra_item, str):
                        output += extra_item
                    else:
                        output += convert_minecraft_text_to_denizen(extra_item)
            elif isinstance(text_json['extra'], str):
                output += text_json['extra']

        return output if output else ""

    return str(text_json)

def process_item(item_data):
    """Process a single item, extracting ID and breaking down components."""
    if not item_data:
        return None

    processed_item = {}

    # Extract the item ID and remove minecraft: prefix
    if 'id' in item_data:
        processed_item['id'] = item_data['id'].replace('minecraft:', '')

    # Extract count if present
    if 'count' in item_data:
        processed_item['count'] = item_data['count']

    # Process components - break them down into individual fields
    if 'components' in item_data:
        processed_item['components'] = {}

        for component_key, component_value in item_data['components'].items():
            # Remove minecraft: prefix from component keys
            clean_key = component_key.replace('minecraft:', '')

            # Special handling for custom_name and lore
            if component_key == 'minecraft:custom_name':
                # Convert custom name to Denizen format
                denizen_name = convert_minecraft_text_to_denizen(component_value)
                if isinstance(denizen_name, str) and denizen_name:
                    processed_item['components'][clean_key] = denizen_name
                else:
                    processed_item['components'][clean_key] = component_value

            elif component_key == 'minecraft:lore':
                # Convert lore to Denizen format
                denizen_lore = convert_minecraft_text_to_denizen(component_value)
                if denizen_lore:
                    processed_item['components'][clean_key] = denizen_lore
                else:
                    processed_item['components'][clean_key] = component_value

            elif component_key == 'minecraft:container':
                # Process shulker box contents
                if isinstance(component_value, str) and component_value.startswith('['):
                    try:
                        container_data = json.loads(component_value)
                        processed_container = []
                        for container_item in container_data:
                            if 'item' in container_item:
                                processed_container_item = {
                                    'slot': container_item.get('slot', 0),
                                    'item': process_item(container_item['item'])
                                }
                                processed_container.append(processed_container_item)
                        processed_item['components'][clean_key] = processed_container
                    except json.JSONDecodeError:
                        processed_item['components'][clean_key] = component_value
                else:
                    processed_item['components'][clean_key] = component_value

            elif component_key == 'minecraft:bundle_contents':
                # Process bundle contents
                if isinstance(component_value, str) and component_value.startswith('['):
                    try:
                        bundle_data = json.loads(component_value)
                        processed_bundle = []
                        for bundle_item in bundle_data:
                            processed_bundle.append(process_item(bundle_item))
                        processed_item['components'][clean_key] = processed_bundle
                    except json.JSONDecodeError:
                        processed_item['components'][clean_key] = component_value
                else:
                    processed_item['components'][clean_key] = component_value

            elif component_key == 'minecraft:trim':
                # Process trim data to extract material and pattern
                if isinstance(component_value, str) and component_value.startswith('{'):
                    try:
                        # Fix NBT-style JSON for trim
                        fixed_trim = component_value
                        fixed_trim = re.sub(r'(?<!")(\b\w+\b)(?=:)', r'"\1"', fixed_trim)
                        parsed_trim = json.loads(fixed_trim)
                        # Remove minecraft: prefix from trim values
                        if 'material' in parsed_trim:
                            parsed_trim['material'] = parsed_trim['material'].replace('minecraft:', '')
                        if 'pattern' in parsed_trim:
                            parsed_trim['pattern'] = parsed_trim['pattern'].replace('minecraft:', '')
                        processed_item['components'][clean_key] = parsed_trim
                    except (json.JSONDecodeError, Exception):
                        processed_item['components'][clean_key] = component_value
                else:
                    processed_item['components'][clean_key] = component_value

            elif isinstance(component_value, str) and (
                component_value.startswith('{') or component_value.startswith('[')
            ):
                # Parse other JSON strings within components
                try:
                    # Try to parse as JSON for better structure
                    parsed_value = json.loads(component_value)
                    # For enchantments and similar nested structures, remove minecraft: prefix
                    if isinstance(parsed_value, dict) and clean_key == 'enchantments':
                        cleaned_enchants = {}
                        for ench_key, ench_val in parsed_value.items():
                            cleaned_enchants[ench_key.replace('minecraft:', '')] = ench_val
                        parsed_value = cleaned_enchants
                    processed_item['components'][clean_key] = parsed_value
                except json.JSONDecodeError:
                    # If parsing fails, keep as string
                    processed_item['components'][clean_key] = component_value
            else:
                processed_item['components'][clean_key] = component_value

    # Include DataVersion if present
    if 'DataVersion' in item_data:
        processed_item['DataVersion'] = item_data['DataVersion']

    # Include schema_version if present
    if 'schema_version' in item_data:
        processed_item['schema_version'] = item_data['schema_version']

    return processed_item

def main():
    """Main function to convert inventory JSON files to YAML."""

    # Define the JSON files to convert
    json_files = [
        'plugins/Denizen/amityes_inventory.json',
        'plugins/Denizen/clowns_inventory.json'
    ]

    # Convert each file
    for json_file in json_files:
        if Path(json_file).exists():
            try:
                convert_inventory_json_to_yaml(json_file)
            except Exception as e:
                print(f"Error converting {json_file}: {e}", file=sys.stderr)
        else:
            print(f"File not found: {json_file}", file=sys.stderr)

if __name__ == "__main__":
    main()