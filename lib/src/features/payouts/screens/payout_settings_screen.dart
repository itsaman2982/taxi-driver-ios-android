import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/providers/earnings_provider.dart';
import 'package:taxi_driver/src/features/payouts/screens/add_bank_account_screen.dart';

class PayoutSettingsScreen extends StatefulWidget {
  const PayoutSettingsScreen({super.key});

  @override
  State<PayoutSettingsScreen> createState() => _PayoutSettingsScreenState();
}

class _PayoutSettingsScreenState extends State<PayoutSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final earnings = Provider.of<EarningsProvider>(context, listen: false);
      earnings.fetchEarnings();
      earnings.fetchTransactions();
      earnings.fetchPayoutConfig();
      earnings.fetchPayoutMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payout Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<EarningsProvider>(
        builder: (context, earnings, _) {
          // Check driver type from earnings provider's driver data
          final driverData = earnings.earningsData;
          final driverType = driverData['driverType'] ?? 'commission';
          final isSalaryBased = driverType == 'salary';
          
          // Show blocked message for salary-based drivers
          if (isSalaryBased) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Payouts Not Available',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You are on a salary-based payment plan. Payouts and withdrawals are not applicable to your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Text(
                            'Contact admin for salary-related queries',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Original payout settings UI for commission-based drivers
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Linked Bank Account Section
                _buildLinkedAccountSection(earnings.payoutMethods),
                const SizedBox(height: 24),

                // 2. Add New Account Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddBankAccountScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add New Bank Account',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Payout Schedule Section
                _buildPayoutScheduleSection(earnings.payoutConfig),
                const SizedBox(height: 24),

                // 4. Recent Payouts Section
                _buildRecentPayoutsSection(earnings.transactions),
                const SizedBox(height: 24),

                // 5. Instant Payout Card
                _buildInstantPayoutCard(earnings.totalEarnings, earnings.payoutConfig, earnings.payoutMethods),
                const SizedBox(height: 16),

                // 6. Security Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                       const Icon(Icons.security, size: 24),
                       const SizedBox(width: 12),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text(
                             'Bank-level Security',
                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                           ),
                           Text(
                             'Your financial data is encrypted and secure',
                             style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                           ),
                         ],
                       )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // 7. Footer
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.help_outline, size: 18, color: Colors.grey),
                    label: Text(
                      'Payout Help & FAQ',
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLinkedAccountSection(List<dynamic> methods) {
    if (methods.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No payout methods linked')),
      );
    }

    final primary = methods.first;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Linked Payout Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.shield_outlined, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          // Bank Card
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.black,
               borderRadius: BorderRadius.circular(12),
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(primary['label'] ?? 'Account', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     const Icon(Icons.account_balance, color: Colors.white70, size: 20),
                   ],
                 ),
                 const SizedBox(height: 20),
                 Text(primary['type']?.toUpperCase() ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 4),
                 Text(primary['details']?['upi_id'] ?? primary['details']?['account_number'] ?? '****', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                 const SizedBox(height: 16),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Primary Method', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                     Row(
                       children: [
                         Icon(Icons.check_circle, size: 14, color: primary['verified'] == true ? Colors.green : Colors.white),
                         const SizedBox(width: 4),
                          Text(primary['verified'] == true ? 'Verified' : 'Unverified', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                       ],
                     )
                   ],
                 )
               ],
             ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.black54),
              label: const Text('Change Method', style: TextStyle(color: Colors.black87)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecentPayoutsSection(List<dynamic> transactions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Payouts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No recent payouts found', style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            ...transactions.take(3).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPayoutItem(
                date: t['createdAt']?.toString().split('T')[0] ?? '',
                amount: '₹${t['amount']}',
                status: t['status']?.toUpperCase() ?? 'COMPLETED',
                account: 'Bank Account',
                color: t['status'] == 'failed' ? Colors.red : Colors.green,
                icon: t['status'] == 'failed' ? Icons.error : Icons.check,
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildInstantPayoutCard(double balance, Map<String, dynamic> config, List<dynamic> methods) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Instant Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.bolt, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Get your earnings instantly with a small fee',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Text('Available Balance', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
               Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
               const Spacer(),
               ElevatedButton(
                 onPressed: () async {
                   if (methods.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a payout method first')));
                     return;
                   }
                   if (balance < (config['min_withdrawal_limit'] ?? 100)) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minimum balance ₹${config['min_withdrawal_limit'] ?? 100} required')));
                      return;
                   }
                   final messenger = ScaffoldMessenger.of(context);
                   final earningsProvider = Provider.of<EarningsProvider>(context, listen: false);
                   final success = await earningsProvider.requestWithdrawal(balance, methods.first['_id']);
                   if (success) {
                     messenger.showSnackBar(const SnackBar(content: Text('Payout request submitted successfully')));
                     earningsProvider.fetchTransactions();
                   }
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.white,
                   foregroundColor: Colors.black,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0)
                 ),
                 child: const Text('Cash Out Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
               ),
            ],
          ),
          const SizedBox(height: 12),
          Text('*${config['commission_rate'] ?? 2}% fee applies for instant transfers', style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
  Widget _buildPayoutScheduleSection(Map<String, dynamic> config) {
    final automation = config['payout_automation'] ?? 'manual';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payout Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _buildScheduleItem(Icons.calendar_today, 'Payout Type', automation == 'auto' ? 'Automatic weekly payouts enabled' : 'Manual withdrawal only'),
          const SizedBox(height: 20),
          _buildScheduleItem(Icons.access_time, 'Processing Time', 'Funds arrive within 1-2 business days'),
          const SizedBox(height: 20),
          _buildScheduleItem(Icons.currency_rupee, 'Minimum Threshold', '₹${config['min_withdrawal_limit'] ?? 100} minimum for payout processing'),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPayoutItem({
    required String date,
    required String amount,
    required String status,
    required String account,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 2),
            Text(date, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
             const SizedBox(height: 2),
            Text(account, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        )
      ],
    );
  }
}
