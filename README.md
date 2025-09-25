# Booncraft Server Scripts

This repository contains all Denizen Script (.dsc) files for the Booncraft Minecraft server. These scripts provide custom functionality and features for server players.

## 🏗️ Project Structure

```
plugins/Denizen/scripts/
├── refunds/                    # Player refund system [IN DEVELOPMENT]
│   ├── commands/
│   │   └── refund_commands.dsc    # Core refund logic and item reclaim
│   └── menus/
│       ├── refund_main_menu.dsc           # Main refund interface
│       ├── quantity_determination_menu.dsc # Item quantity selection
│       ├── paginated_menu.dsc             # Pagination system
│       └── general_menu_components.dsc    # Reusable UI components
└── [future projects]/
```

## 📝 Script Development

### Requirements
- Minecraft server with Denizen Plugin installed
- VS Code with Denizen Script extension (recommended)

### Development Workflow
Scripts are hot-reloaded automatically when saved to the server. For manual reload:
```
/ex reload
```

Check for script errors:
```
/ex debug
```

## 📦 Current Projects

### Refund System
A comprehensive player refund system allowing players to reclaim items they've sold using their refund balance.

**Features:**
- Item reclaim with balance validation
- Interactive quantity selection (individual items or stacks)
- Inventory management with partial fulfillment
- Clickable error recovery options
- Balance tracking and cost calculations

**Commands:**
- `/import_refund_data` - Load refund data from YAML file

**Status:** ✅ Core functionality complete

## 🔧 Development

### For Contributors
- See [CLAUDE.md](./CLAUDE.md) for detailed development guidance
- All scripts use Denizen Script language (.dsc files)
- Follow existing patterns for menu systems and data management
- Test changes with `/ex reload` and `/ex debug`

### Adding New Projects
1. Create new directory under `plugins/Denizen/scripts/`
2. Follow established patterns from the refund system
3. Update this README with project description
4. Document any new patterns in CLAUDE.md

## 🎯 Planned Features
- Additional player economy features
- Custom game mechanics
- Server management tools
- Player interaction systems

---

**Server:** Booncraft | **Engine:** Paper 1.21.8 | **Scripting:** Denizen Script