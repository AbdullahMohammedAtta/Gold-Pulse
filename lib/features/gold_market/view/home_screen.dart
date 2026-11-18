import 'package:material_ui/material_ui.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top Badges ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('● LIVE LBMA SPOT', style: TextStyle(fontSize: 10, color: Color(0xFFFFD700))),
                  ),
                  const Text('⏱ Updated 2m ago', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),

              // --- Global Spot Price Card ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1E24), Color(0xFF25252D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('GOLD SPOT PRICE (OZ / USD)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('XAU/USD', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '\$2,384.50',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(0, 255, 0, 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('+1.42% (+\$33.40 today)', style: TextStyle(fontSize: 11, color: Colors.green)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Low: \$2,351.10', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('Day Range', style: TextStyle(fontSize: 11, color: Color(0xFFFFD700))),
                        Text('High: \$2,392.80', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.7,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Currency Selector Chips ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['USD (\$)', 'EUR (€)', 'GBP (£)', 'AED (د.إ)'].map((currency) {
                  return GestureDetector(
                    onTap: () {
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currency,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // --- Karat Rates Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('⭐ Karat Rates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('● PER GRAM', style: TextStyle(fontSize: 10, color: Color(0xFFFFD700))),
                ],
              ),
              const SizedBox(height: 12),

              // --- Karat Items List ---
              _buildKaratCard('24K', 'Pure Gold', '99.9% Purity • Investment Bullion', '\$76.68', 'Tola: \$894.40', '+ \$1.08 today'),
              _buildKaratCard('22K', '91.6% Purity', 'Sovereign & Eastern Ornaments', '\$70.24', 'Tola: \$819.28', '+ \$0.99 today'),
              _buildKaratCard('21K', 'Most Popular Jewelry', '87.5% Standard • Bridal & Modern', '\$67.10', 'Tola: \$782.60', '+ \$0.94 today'),
              _buildKaratCard('18K', '75.0% Fine', 'European Standard & Gem Settings', '\$57.51', 'Tola: \$670.80', '+ \$0.81 today'),

              const SizedBox(height: 16),

              // --- Weight Calculator Button ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate, color: Color(0xFFFFD700)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Weight Calculator', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('Estimate physical bullion value', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {},
                      child: const Text('Convert', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKaratCard(String karat, String badge, String subtitle, String price, String tola, String change) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(karat, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(badge, style: const TextStyle(fontSize: 9, color: Color(0xFFFFD700))),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(tola, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('/ gram', style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(change, style: const TextStyle(fontSize: 11, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}