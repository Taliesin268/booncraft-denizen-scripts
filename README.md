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
A comprehensive player refund system allowing players to reclaim items they've sold and return items they've bought during the server economy transition.

**Features:**
- Item reclaim with balance validation
- Item return system for bought items
- Interactive quantity selection (individual items or stacks)
- Inventory management with partial fulfillment
- Clickable error recovery options
- Balance tracking and cost calculations
- Introduction book with personalized statistics
- LuckPerms integration for permission management
- Comprehensive logging with trace IDs

## 🚀 Refund System Deployment Guide

### Prerequisites
- **Required Plugins:**
  - Denizen (latest version)
  - LuckPerms (for permission groups)
  - Essentials or similar economy plugin
- **Data Files:**
  - `player_transaction_history.yml` in Denizen plugin directory

### Phase 1: Initial Setup

1. **Install Scripts**
   ```bash
   # Upload all scripts to the server
   plugins/Denizen/scripts/refunds/
   ├── commands/refund_commands.dsc
   ├── items/refund_introduction_book.dsc
   └── menus/
       ├── general_menu_components.dsc
       ├── paginated_menu.dsc
       ├── quantity_determination_menu.dsc
       └── refund_main_menu.dsc
   ```

2. **Prepare Transaction Data**
   Create `plugins/Denizen/player_transaction_history.yml` with this structure:
   ```yaml
   # UUID of player
   ff85caa5-3d6d-4247-b446-90448e57bc81:
     player_name: Aldriex
     balance: 50000.00  # Their starting refund balance
     sold:
       diamond:
         unit_price: 100
         quantity: 64
       iron_ingot:
         unit_price: 10
         quantity: 256
     bought:
       enchanted_golden_apple:
         unit_price: 5000
         quantity: 5
   ```

3. **Import Data**
   ```
   /import_refund_data
   ```
   This loads all transaction history into server flags.

### Phase 2: Testing with Select Players

1. **Manual Testing Commands**
   ```
   # Test with specific player (as admin)
   /refunds admin PlayerName

   # Give book manually to test player
   /ex run give_refund_book player:PlayerName

   # Process balance for single test player
   /ex run balance_refunds def.player_uuid:<server.match_offline_player[PLAYER_NAME].uuid>
   ```

2. **Grant Admin Permissions to Staff**
   ```
   # Add refunds.admin permission to staff group
   /lp group staff permission set refunds.admin true

   # Or for individual staff members
   /lp user StaffName permission set refunds.admin true
   ```

3. **Monitor Testing**
   ```bash
   # Check logs for any issues
   tail -f plugins/Denizen/logs/refunds/refunds_YYYY-MM-DD.log

   # Verify player data
   /ex narrate <server.flag[refunds.<server.match_offline_player[PLAYER_NAME].uuid>]>
   ```

### Phase 3: Staged Deployment

1. **Setup Permission Groups**
   ```
   # Create the main refunds group
   /ex run setup_refunds_luckperms_group
   ```
   This automatically:
   - Creates `has_refunds` LuckPerms group
   - Adds all players with refund data to the group
   - Logs all actions with trace IDs

2. **Process Balances for All Players**
   ```
   # Convert player money to refund balances
   /ex run balance_refunds_for_all
   ```
   This will:
   - Check each player's current money
   - Calculate their refund debt
   - Adjust balances accordingly
   - Skip already processed players

3. **Enable Book Distribution (Selective)**
   ```
   # Enable automatic book on join
   /ex flag server refunds.enabled:true

   # Reload scripts to apply the change
   /ex reload
   ```
   Players will receive the introduction book when they join.

### Operations & Maintenance

#### Admin Commands
- `/refunds` - Open refund menu (player's own data)
- `/refunds admin <player>` - View any player's refund data (requires `refunds.admin` permission)

#### System Control Flags
```
# Enable book distribution (DO NOT set to false - just remove the flag to disable)
/ex flag server refunds.enabled:true

# Disable book distribution (remove the flag entirely)
/ex flag server refunds.enabled:!

# Check if player received book
/ex narrate <server.has_flag[refunds.book_given.<server.match_offline_player[PLAYER_NAME].uuid>]>

# Check if player's balance was processed
/ex narrate <server.has_flag[refunds.balance_processed.<server.match_offline_player[PLAYER_NAME].uuid>]>

# View player's refund data
/ex narrate <server.flag[refunds.<server.match_offline_player[PLAYER_NAME].uuid>]>

# Reset player's book received flag (to give again)
/ex flag server refunds.book_given.<server.match_offline_player[PLAYER_NAME].uuid>:!
```

#### Troubleshooting

**Player didn't receive book:**
```
# Check if they have refund data
/ex narrate <server.has_flag[refunds.<server.match_offline_player[PLAYER_NAME].uuid>.sold]>

# Manually give book
/ex run give_refund_book player:PlayerName
```

**Balance not updating:**
```
# Check current balance
/ex narrate <server.flag[refunds.<server.match_offline_player[PLAYER_NAME].uuid>.balance]>

# Manually process balance
/ex run balance_refunds def.player_uuid:<server.match_offline_player[PLAYER_NAME].uuid>
```

**Menu not opening:**
```
# Check permissions
/lp user PlayerName permission check refunds.use

# Test direct menu open
/ex run open_refund_menu_for_player def.target_uuid:<server.match_offline_player[PLAYER_NAME].uuid> player:PlayerName
```

#### Log Files
- **Location:** `plugins/Denizen/logs/refunds/refunds_YYYY-MM-DD.log`
- **Log Types:**
  - `RECLAIM_ATTEMPT/SUCCESS/FAILED` - Item reclaim operations
  - `RETURN_ATTEMPT/SUCCESS/FAILED` - Item return operations
  - `BALANCE_REFUND_*` - Balance processing operations
  - `REFUND_BOOK_*` - Book distribution events
  - `ADMIN_ACCESS` - Admin menu access
  - `LUCKPERMS_GROUP_*` - Permission group operations

#### Rollback Procedures
If issues arise:
1. Disable the system: `/ex flag server refunds.enabled:!`
2. Export current state: `/ex narrate <server.flag[refunds]> > refunds_backup.yml`
3. Fix issues in scripts
4. Reload: `/ex reload`
5. Re-import if needed: `/import_refund_data`

**Status:** ✅ Production Ready

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