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

def convert_minecraft_text_to_denizen_structured(text_json):
    """Convert Minecraft JSON text format to structured format for Denizen.
    Returns a dict with 'text' and optional 'color' and 'bold' fields."""
    if not isinstance(text_json, (str, dict, list)):
        return str(text_json)

    # If it's a string that looks like JSON, try to parse it
    if isinstance(text_json, str):
        # Handle legacy section sign colors first
        if '§' in text_json:
            result = {'text': '', 'format': []}
            # Parse out color codes
            import re
            parts = re.split(r'(§[0-9a-flmnokr])', text_json)
            current_text = ''
            for part in parts:
                if part.startswith('§'):
                    code = part[1]
                    if code == 'l':
                        result['bold'] = True
                    elif code in '0123456789abcdef':
                        color_map = {
                            '0': 'black', '1': 'dark_blue', '2': 'dark_green', '3': 'dark_aqua',
                            '4': 'dark_red', '5': 'dark_purple', '6': 'gold', '7': 'gray',
                            '8': 'dark_gray', '9': 'blue', 'a': 'green', 'b': 'aqua',
                            'c': 'red', 'd': 'light_purple', 'e': 'yellow', 'f': 'white'
                        }
                        result['color'] = color_map.get(code, 'white')
                else:
                    current_text += part
            result['text'] = current_text
            return result

        if text_json.startswith('{') or text_json.startswith('['):
            try:
                # First try to fix NBT-style JSON to standard JSON
                fixed_json = text_json

                # Step 1: Replace NBT boolean values first
                fixed_json = fixed_json.replace('1b', 'true').replace('0b', 'false')

                # Step 2: Quote unquoted keys more carefully
                # This pattern looks for word characters followed by colon
                # but avoids already quoted keys
                parts = []
                in_string = False
                i = 0
                while i < len(fixed_json):
                    if fixed_json[i] == '"' and (i == 0 or fixed_json[i-1] != '\\'):
                        in_string = not in_string
                        parts.append(fixed_json[i])
                    elif not in_string and fixed_json[i].isalpha():
                        # Found potential unquoted key
                        j = i
                        while j < len(fixed_json) and (fixed_json[j].isalnum() or fixed_json[j] == '_'):
                            j += 1
                        if j < len(fixed_json) and fixed_json[j] == ':':
                            # This is an unquoted key
                            parts.append('"' + fixed_json[i:j] + '"')
                            i = j - 1
                        else:
                            parts.append(fixed_json[i])
                    else:
                        parts.append(fixed_json[i])
                    i += 1

                fixed_json = ''.join(parts)

                text_json = json.loads(fixed_json)
            except (json.JSONDecodeError, Exception) as e:
                # If it's not valid JSON even after fixes, just return as is
                return text_json
        else:
            return text_json

    # Process list of text components (lore)
    if isinstance(text_json, list):
        result = []
        for item in text_json:
            converted = convert_minecraft_text_to_denizen_structured(item)
            if converted:
                result.append(converted)
        return result

    # Process single text component
    if isinstance(text_json, dict):
        result = {'text': '', 'format': []}

        # Extract formatting from first component with text
        main_component = text_json
        if 'extra' in text_json and isinstance(text_json['extra'], list) and len(text_json['extra']) > 0:
            # Use the first extra component as main if root has no text
            if not text_json.get('text'):
                main_component = text_json['extra'][0] if isinstance(text_json['extra'][0], dict) else text_json

        # Get formatting - check main component or first extra component
        if main_component.get('bold') or (main_component.get('bold') == 1):
            result['bold'] = True
        if main_component.get('italic') or (main_component.get('italic') == 1):
            result['italic'] = True
        if main_component.get('color'):
            result['color'] = main_component['color']

        # Collect all text
        all_text = []

        # Add root text
        if text_json.get('text'):
            all_text.append(text_json['text'])

        # Add extra text
        if 'extra' in text_json and isinstance(text_json['extra'], list):
            for extra in text_json['extra']:
                if isinstance(extra, dict) and 'text' in extra:
                    all_text.append(extra['text'])
                elif isinstance(extra, str):
                    all_text.append(extra)

        result['text'] = ''.join(all_text)

        # Clean up empty format array and ensure we have valid output
        if 'format' in result and not result['format']:
            del result['format']

        # Only return if we have actual text
        if result['text']:
            return result
        else:
            # Return original if we couldn't extract text
            return str(text_json)

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
                # Convert custom name to structured format for Denizen
                structured_name = convert_minecraft_text_to_denizen_structured(component_value)
                if isinstance(structured_name, dict):
                    processed_item['components'][clean_key] = structured_name
                elif structured_name:
                    processed_item['components'][clean_key] = structured_name
                else:
                    processed_item['components'][clean_key] = component_value
                # Debug output
                if not isinstance(structured_name, dict):
                    print(f"Warning: custom_name not converted to dict: {component_value[:60]}...")

            elif component_key == 'minecraft:lore':
                # Convert lore to structured format
                structured_lore = convert_minecraft_text_to_denizen_structured(component_value)
                if structured_lore:
                    processed_item['components'][clean_key] = structured_lore
                else:
                    processed_item['components'][clean_key] = component_value

            elif component_key == 'minecraft:container':
                # Process shulker box contents - expand to proper YAML structure
                if isinstance(component_value, str) and component_value.startswith('['):
                    try:
                        # Parse container items individually for better error handling
                        def parse_container_items(container_str):
                            """Parse container items one by one"""
                            # Remove outer brackets if present
                            container_str = container_str.strip()
                            if container_str.startswith('['):
                                container_str = container_str[1:]
                            if container_str.endswith(']'):
                                container_str = container_str[:-1]

                            # Split into individual item entries
                            items = []
                            depth = 0
                            current_item = ''
                            in_string = False
                            item_started = False

                            for i, char in enumerate(container_str):
                                if char == '"' and (i == 0 or container_str[i-1] != '\\'):
                                    in_string = not in_string

                                if not in_string:
                                    if char == '{':
                                        if depth == 0:
                                            item_started = True
                                        depth += 1
                                    elif char == '}':
                                        depth -= 1
                                        if depth == 0 and item_started:
                                            # End of an item
                                            current_item += char
                                            items.append(current_item.strip())
                                            current_item = ''
                                            item_started = False
                                            continue

                                if item_started:
                                    current_item += char

                            return items

                        # More aggressive NBT to JSON conversion
                        def fix_nbt_json(text):
                            """Convert NBT-style JSON to standard JSON"""
                            # Replace NBT numeric suffixes (f, L, b, etc.)
                            text = re.sub(r':(-?\d+(?:\.\d+)?)[fFdDlLbBsS](?=[,}\]])', r':\1', text)

                            # Replace NBT booleans - only when followed by 'b'
                            text = re.sub(r':1b(?=[,}\]])', r':true', text)
                            text = re.sub(r':0b(?=[,}\]])', r':false', text)
                            text = text.replace(',1b,', ',true,').replace(',0b,', ',false,')
                            text = text.replace(',1b}', ',true}').replace(',0b}', ',false}')
                            text = text.replace(',1b]', ',true]').replace(',0b]', ',false]')

                            # Replace byte arrays [B;...] with regular arrays
                            text = re.sub(r'\[B;([^\]]+)\]', r'[\1]', text)

                            # Remove minecraft: prefixes
                            text = text.replace('"minecraft:', '"')

                            # Special handling for lore arrays which often have issues
                            # Simplify complex lore structures by removing them if they cause problems
                            if '"lore":' in text:
                                # Try to extract and simplify lore
                                lore_start = text.find('"lore":')
                                if lore_start != -1:
                                    # Find the matching closing bracket for the lore array
                                    bracket_count = 0
                                    in_string = False
                                    lore_end = lore_start + 7  # Start after '"lore":['

                                    for i in range(lore_start + 7, len(text)):
                                        if text[i] == '"' and (i == 0 or text[i-1] != '\\'):
                                            in_string = not in_string
                                        if not in_string:
                                            if text[i] == '[':
                                                bracket_count += 1
                                            elif text[i] == ']':
                                                bracket_count -= 1
                                                if bracket_count == 0:
                                                    lore_end = i + 1
                                                    break

                                    # For now, replace complex lore with empty array to avoid parsing issues
                                    # We can enhance this later to preserve lore if needed
                                    text = text[:lore_start] + '"lore":[]' + text[lore_end:]

                            # Fix unquoted keys - multiple passes for nested structures
                            for _ in range(10):  # Multiple passes to handle deeply nested structures
                                prev = text
                                # Fix unquoted keys after { or , but not in arrays
                                text = re.sub(r'([{,]\s*)([a-zA-Z_][a-zA-Z0-9_-]*)\s*:', r'\1"\2":', text)
                                if prev == text:
                                    break  # No more changes

                            return text

                        # Try to parse the entire container first
                        fixed_container = fix_nbt_json(component_value)

                        # Try to parse the fixed JSON
                        container_data = json.loads(fixed_container)
                        processed_container = {}

                        for container_item in container_data:
                            if 'item' in container_item:
                                slot = container_item.get('slot', 0)
                                # Recursively process the item (this will handle all nested components)
                                processed_item_data = process_item(container_item['item'])
                                if processed_item_data:
                                    # Store by slot number as key for easier access in Denizen
                                    processed_container[str(slot)] = processed_item_data

                        # Store as a proper nested structure, not a JSON string
                        processed_item['components'][clean_key] = processed_container
                        print(f"Successfully parsed container for {processed_item.get('id', 'unknown')} with {len(processed_container)} items")
                    except (json.JSONDecodeError, Exception) as e:
                        print(f"Warning: Could not parse container as whole: {str(e)[:100]}")
                        print("Attempting to parse items individually...")

                        # Try parsing items individually
                        try:
                            processed_container = {}
                            items_str = parse_container_items(component_value)
                            successful = 0
                            failed = 0

                            for item_str in items_str:
                                try:
                                    fixed_item = fix_nbt_json(item_str)
                                    item_data = json.loads(fixed_item)

                                    if 'item' in item_data:
                                        slot = item_data.get('slot', 0)
                                        processed_item_data = process_item(item_data['item'])
                                        if processed_item_data:
                                            processed_container[str(slot)] = processed_item_data
                                            successful += 1
                                except Exception as item_err:
                                    failed += 1
                                    # Try without lore if it has lore
                                    if '"lore":' in item_str:
                                        try:
                                            # Remove lore and try again
                                            item_no_lore = re.sub(r',"lore":\[.*?\]', '', item_str)
                                            fixed_item = fix_nbt_json(item_no_lore)
                                            item_data = json.loads(fixed_item)

                                            if 'item' in item_data:
                                                slot = item_data.get('slot', 0)
                                                processed_item_data = process_item(item_data['item'])
                                                if processed_item_data:
                                                    processed_container[str(slot)] = processed_item_data
                                                    successful += 1
                                                    failed -= 1
                                        except:
                                            pass  # Item truly failed

                            if successful > 0:
                                processed_item['components'][clean_key] = processed_container
                                print(f"Partially parsed container for {processed_item.get('id', 'unknown')}: {successful} items successful, {failed} failed")
                            else:
                                # No items could be parsed - keep as string
                                processed_item['components'][clean_key] = component_value
                                print(f"Could not parse any items in container for {processed_item.get('id', 'unknown')}")
                        except Exception as e2:
                            # Final fallback - keep as string
                            print(f"Failed to parse container items individually: {str(e2)[:100]}")
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