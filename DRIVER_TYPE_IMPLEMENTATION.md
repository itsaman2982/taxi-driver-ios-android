# Driver App Changes for Commission vs Salary-Based Drivers

## Overview
The backend now supports two types of drivers:
1. **Commission-Based**: Earns per ride, wallet is credited/debited based on rides
2. **Salary-Based**: Receives fixed salary, NO wallet transactions for rides

## Required Changes in Driver App

### 1. Driver Provider (`driver_provider.dart`)
**Add getter for driver type:**
```dart
String get driverType => _driver?['driverType'] ?? 'commission';
bool get isCommissionBased => driverType == 'commission';
bool get isSalaryBased => driverType == 'salary';
```

### 2. Earnings Screen (`earnings_screen.dart`)
**Hide/Show based on driver type:**

#### For Salary-Based Drivers:
- **HIDE**: Main earnings card (lines 139-202)
- **HIDE**: "View Payouts" button (lines 248-286)
- **SHOW**: Message explaining they are on salary
- **KEEP**: Trip history (for tracking purposes only)

#### Changes needed:
```dart
// At the top of build method, add:
final driverProvider = Provider.of<DriverProvider>(context);
final isSalaryBased = driverProvider.isSalaryBased;

// Wrap earnings card in conditional:
if (!isSalaryBased) ...[
  // Main Earnings Card (lines 139-202)
  // View Payouts Button (lines 248-286)
] else ...[
  // Salary Driver Message
  Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon(Icons.info_outline, size: 48, color: Colors.blue),
        SizedBox(height: 16),
        Text(
          'Salary-Based Driver',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'You receive a fixed monthly salary. Trip earnings are not credited to your wallet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    ),
  ),
]
```

### 3. Payout Settings Screen (`payout_settings_screen.dart`)
**Completely disable for salary-based drivers:**

#### Option A: Redirect with message
```dart
@override
Widget build(BuildContext context) {
  final driverProvider = Provider.of<DriverProvider>(context);
  
  if (driverProvider.isSalaryBased) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payout Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 24),
              Text(
                'Payouts Not Available',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'You are on a salary-based payment plan. Payouts and withdrawals are not applicable to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              SizedBox(height: 24),
              Text(
                'Contact admin for salary-related queries',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Original payout settings UI for commission-based drivers
  return Scaffold(...);
}
```

#### Option B: Hide the navigation option entirely
In the profile/settings screen, conditionally show payout settings:
```dart
if (driverProvider.isCommissionBased) ...[
  ListTile(
    leading: Icon(Icons.account_balance_wallet),
    title: Text('Payout Settings'),
    onTap: () => Navigator.push(...),
  ),
]
```

### 4. Home Screen / Navigation
**Update wallet/earnings display:**

```dart
// In home screen or wherever wallet balance is shown
Consumer<DriverProvider>(
  builder: (context, driver, _) {
    if (driver.isSalaryBased) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Salary-Based Driver',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }
    
    // Show wallet balance for commission-based drivers
    return Consumer<EarningsProvider>(
      builder: (context, earnings, _) => Text('₹${earnings.totalEarnings}'),
    );
  },
)
```

### 5. Trip Completion Flow
**No changes needed** - Backend handles this automatically:
- Commission drivers: Wallet credited/debited
- Salary drivers: Ride just completes, no wallet changes

### 6. Profile Screen
**Display driver type (optional):**
```dart
ListTile(
  leading: Icon(Icons.work_outline),
  title: Text('Payment Plan'),
  subtitle: Text(
    driverProvider.isSalaryBased ? 'Salary-Based' : 'Commission-Based',
  ),
  trailing: Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: driverProvider.isSalaryBased ? Colors.blue.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      driverProvider.isSalaryBased ? 'SALARY' : 'COMMISSION',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: driverProvider.isSalaryBased ? Colors.blue : Colors.green,
      ),
    ),
  ),
)
```

## Summary of UI Changes

| Screen | Commission Driver | Salary Driver |
|--------|------------------|---------------|
| **Earnings Screen** | Full earnings display + payouts | Trip history only + info message |
| **Payout Settings** | Full access | Blocked with message |
| **Home/Wallet** | Show wallet balance | Show "Salary-Based" badge |
| **Trip Completion** | Shows earnings credited | Shows "Trip Completed" only |
| **Profile** | Shows "Commission-Based" | Shows "Salary-Based" |

## Backend API Changes (Already Implemented)
✅ User model has `driverType` field
✅ Ride completion skips wallet for salary drivers
✅ Admin can set driver type
✅ Payout withdrawal checks wallet balance

## Testing Checklist
- [ ] Commission driver can see earnings and withdraw
- [ ] Salary driver cannot access payout settings
- [ ] Salary driver sees appropriate messages
- [ ] Trip completion works for both types
- [ ] Admin can change driver type
- [ ] Driver type persists after logout/login
