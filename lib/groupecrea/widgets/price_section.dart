import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriceSection extends StatelessWidget {
  final double price;
  final Function(double) onPriceChanged;
  final int maxWomen;

  static const double _minPrice = 10.0;
  static const double _maxPrice = 500.0;

  const PriceSection({
    super.key,
    required this.price,
    required this.onPriceChanged,
    required this.maxWomen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.green.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceDisplay(),
          const SizedBox(height: 25),
          _buildSlider(context),
          const SizedBox(height: 20),
          _buildRevenueInfo(),
        ],
      ),
    );
  }

  Widget _buildSlider(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPriceButton(
            icon: Icons.remove,
            onPressed:
                price > _minPrice ? () => onPriceChanged(price - 5) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Text(
              '${price.toInt()}€',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildPriceButton(
            icon: Icons.add,
            onPressed:
                price < _maxPrice ? () => onPriceChanged(price + 5) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.3),
            Colors.green.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color:
                  onPressed == null
                      ? Colors.green.withOpacity(0.3)
                      : Colors.green,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueInfo() {
    final totalRevenue = price * maxWomen;
    final revenuePerWoman = totalRevenue / maxWomen;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildRevenueRow('Revenu total potentiel', totalRevenue),
          const SizedBox(height: 5),
          _buildRevenueRow('Revenu par femme', revenuePerWoman),
        ],
      ),
    );
  }

  Widget _buildRevenueRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
        Text(
          '${amount.toStringAsFixed(0)}€',
          style: GoogleFonts.poppins(
            color: Colors.green,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDisplay() {
    return Column(
      children: [
        Text(
          'Prix d\'entrée',
          style: GoogleFonts.poppins(
            color: Colors.green,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              price.toStringAsFixed(0),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            Text(
              '€',
              style: GoogleFonts.poppins(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
