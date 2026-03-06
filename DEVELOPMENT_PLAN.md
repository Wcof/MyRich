# MyRich Development Plan - Implementation Tasks

## Current Status
- ✅ Database schema and initialization working
- ✅ Provider structure in place
- ❌ UI screens showing placeholder content only
- ❌ No actual data visualization
- ❌ Asset management features incomplete

## Key Principle
**使用现成的成熟库，坚决抵制从零开始编写可视化组件**
- Use Syncfusion Flutter Charts for all charting needs
- Use Material Design components for UI
- Leverage existing provider pattern for state management

## Dependencies to Add
```yaml
syncfusion_flutter_charts: ^25.1.35  # Professional charting library
```

---

## Phase 1: Fix Blank Page & Dashboard Implementation (CRITICAL)

### Task 1.1: Implement Dashboard Screen UI
**File**: `lib/screens/dashboard_screen.dart`
- Replace placeholder welcome message with actual dashboard layout
- Display total assets value (sum of all assets)
- Show asset distribution by type (pie chart using Syncfusion SfCircularChart)
- Show asset trend over time (line chart using Syncfusion SfCartesianChart)
- Add quick action buttons (Add Asset, View Details)

**Implementation Details**:
- Use `SfCircularChart` for asset distribution pie chart
- Use `SfCartesianChart` with line series for trend chart
- Calculate total assets from AssetProvider
- Format currency values with intl package

### Task 1.2: Create Dashboard Widgets (Using Syncfusion)
**New Files**:
- `lib/widgets/total_assets_card.dart` - Display total assets with trend (simple Card + Text)
- `lib/widgets/asset_distribution_chart.dart` - Pie chart using SfCircularChart
- `lib/widgets/asset_trend_chart.dart` - Line chart using SfCartesianChart
- `lib/widgets/quick_actions_bar.dart` - Action buttons (Row of ElevatedButtons)

**Key Point**: These widgets are thin wrappers around Syncfusion components, NOT custom implementations

### Task 1.3: Implement Asset Type Provider
**File**: `lib/providers/asset_type_provider.dart`
- Ensure `loadAssetTypes()` fetches from database
- Add method to get asset type by ID
- Add method to get asset type color/icon

---

## Phase 2: Asset List & Management (HIGH PRIORITY)

### Task 2.1: Implement Asset List Screen
**File**: `lib/screens/asset_list_screen.dart`
- Display list of all assets using ListView.builder
- Show: asset name, type, value, date
- Add filter by asset type (DropdownButton)
- Add search functionality (TextField)
- Add floating action button to add new asset
- Implement swipe-to-delete using Dismissible widget

### Task 2.2: Create Asset Detail Screen
**File**: `lib/screens/asset_detail_screen.dart`
- Display asset details
- Show asset records/history (ListView)
- Edit asset information button
- Delete asset option

### Task 2.3: Create Add/Edit Asset Dialog
**New File**: `lib/widgets/asset_form_dialog.dart`
- Form with fields: name, type, value, date
- Use TextFormField for inputs
- Use DropdownButton for type selection
- Validation for required fields
- Save to database via provider

---

## Phase 3: Asset Records & History (MEDIUM PRIORITY)

### Task 3.1: Implement Asset Record Provider
**File**: `lib/providers/asset_record_provider.dart`
- Implement `loadRecords()` to fetch asset value history
- Add method to create new record
- Add method to get records by asset ID

### Task 3.2: Create Asset Records Screen
**New File**: `lib/screens/asset_records_screen.dart`
- Display historical records for an asset using ListView
- Show value changes over time
- Add new record button

---

## Phase 4: Data Persistence & Repositories (MEDIUM PRIORITY)

### Task 4.1: Verify Repository Implementations
**Files**:
- `lib/repositories/asset_repository.dart`
- `lib/repositories/asset_type_repository.dart`
- `lib/repositories/asset_record_repository.dart`

Ensure all CRUD operations are implemented:
- `getAll()` - fetch all records
- `getById(id)` - fetch single record
- `insert(model)` - create new record
- `update(model)` - update existing record
- `delete(id)` - delete record

### Task 4.2: Verify Model Classes
**Files**:
- `lib/models/asset.dart`
- `lib/models/asset_type.dart`
- `lib/models/asset_record.dart`

Ensure models have:
- Proper field definitions
- `fromMap()` constructor for database deserialization
- `toMap()` method for database serialization

---

## Phase 5: Error Handling & Polish (LOW PRIORITY)

### Task 5.1: Add Error Handling
- Wrap database operations in try-catch
- Display user-friendly error messages
- Add retry mechanisms for failed operations

### Task 5.2: Add Loading States
- Show loading indicators during data fetch
- Disable buttons during operations
- Add skeleton loaders for better UX

### Task 5.3: Add Validation
- Validate asset values (positive numbers)
- Validate dates (not in future)
- Validate required fields

---

## Implementation Priority
1. **Critical**: Dashboard UI + data display (Phase 1)
2. **High**: Asset list + management (Phase 2)
3. **Medium**: Asset records (Phase 3)
4. **Medium**: Repository verification (Phase 4)
5. **Low**: Polish & error handling (Phase 5)

---

## Testing Checklist
- [ ] App launches without blank page
- [ ] Dashboard displays total assets value
- [ ] Pie chart renders correctly with asset distribution
- [ ] Line chart renders correctly with asset trend
- [ ] Can add new asset via dialog
- [ ] Can view asset list with all assets
- [ ] Can filter assets by type
- [ ] Can search assets
- [ ] Can edit/delete assets
- [ ] Asset records display correctly
- [ ] No database errors in console
- [ ] No Syncfusion license warnings

---

## Notes
- All charting is handled by Syncfusion - no custom chart implementations
- Use Material Design components for UI consistency
- Leverage provider pattern for state management
- Keep widgets focused on UI presentation, not business logic
