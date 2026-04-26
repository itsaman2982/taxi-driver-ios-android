import 'package:flutter/material.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

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
          'Promotions & Incentives',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Active Promotions Header
            const Text(
              'Active Promotions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Active Card 1: Weekend Bonus Boost
            _buildActivePromotionCard(
              badge: 'HOT',
              title: 'Weekend Bonus Boost!',
              description: 'Complete 10 trips by Sunday 11:59 PM to earn ₹1,500 bonus',
              timeLeft: 'Ends in 2 days, 14 hours',
              amount: '₹1,500',
              progress: 0.7,
              progressText: '7/10 Trips',
              showFlame: true,
            ),
            const SizedBox(height: 16),

            // Active Card 2: Peak Hour Rush
            _buildActivePromotionCard(
              badge: 'ACTIVE',
              title: 'Peak Hour Rush',
              description: 'Complete 3 trips during peak hours (7-9 PM) for ₹300 bonus',
              timeLeft: 'Today only',
              amount: '₹300',
              progress: 0.33,
              progressText: '1/3 Trips',
              showClock: true,
            ),

            const SizedBox(height: 24),

            // 2. Upcoming Promotions
            const Text(
              'Upcoming Promotions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildUpcomingCard(
              icon: Icons.card_giftcard,
              title: 'Holiday Incentive',
              subtitle: 'Earn 2x bonuses on all trips\nStarts Dec 23 - Dec 26',
              rightSide: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('2x Bonus', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 2),
                  Text('In 5 days', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            _buildUpcomingCard(
              icon: Icons.star,
              title: 'New Year Boost',
              subtitle: '₹5,000 bonus for 50 trips\nStarts Jan 1 - Jan 7',
              rightSide: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹5,000', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('In 12 days', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Earnings Boosters
            const Text(
              'Earnings Boosters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Hotspots Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: Colors.red.withValues(alpha: 0.1),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.location_on, color: Colors.red, size: 20),
                       ),
                       const SizedBox(width: 12),
                       const Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('Current Hotspots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                             Text('High demand areas with surge pricing', style: TextStyle(color: Colors.grey, fontSize: 12)),
                           ],
                         ),
                       ),
                       TextButton(
                         onPressed: (){}, 
                         child: const Text('View Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                       )
                     ],
                   ),
                   const SizedBox(height: 16),
                   _buildHotspotItem('Downtown Mall', '2.5x', Colors.red.withValues(alpha: 0.05), Colors.red),
                   const SizedBox(height: 8),
                   _buildHotspotItem('Airport Terminal', '1.8x', Colors.orange.withValues(alpha: 0.05), Colors.orange),
                   const SizedBox(height: 8),
                   _buildHotspotItem('Business District', '1.5x', Colors.amber.withValues(alpha: 0.05), Colors.amber.shade700),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Consecutive Trips Bonus (Dark Card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sync, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Consecutive Trips Bonus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Complete trips back-to-back for extra earnings', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Streak', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('3 trips', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                   Align(
                     alignment: Alignment.centerLeft,
                     child: Text('Next bonus at 5 consecutive trips: +₹100', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // 4. My Earned Bonuses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Earned Bonuses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(onPressed: (){}, child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                 boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5), // Light Green
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events, color: Color(0xFF10B981), size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text('₹3,250', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 8),
                  Text('Total bonuses earned this month', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text('8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Bonuses Earned', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text('₹406', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Avg per Bonus', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
             const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePromotionCard({
    required String badge,
    required String title,
    required String description,
    required String timeLeft,
    required String amount,
    required double progress,
    required String progressText,
    bool showFlame = false,
    bool showClock = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showFlame) ...[
                const Icon(Icons.local_fire_department, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              if (showClock) ...[
                const Icon(Icons.access_time_filled, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const Text(
                    'Bonus',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Text(timeLeft, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Text('Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              Text(progressText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUpcomingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget rightSide,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
             padding: const EdgeInsets.all(10),
             decoration: const BoxDecoration(
               color: Color(0xFFF8F9FA),
               shape: BoxShape.circle,
             ),
             child: Icon(icon, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
          rightSide,
        ],
      ),
    );
  }

  Widget _buildHotspotItem(String name, String multiplier, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: textColor),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          Text(
            multiplier,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
