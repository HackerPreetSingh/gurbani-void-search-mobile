import 'package:flutter/material.dart';
import '../../domain/models/tracker_models.dart';

class TemplateSelectionGrid extends StatelessWidget {
  final Function(TrackerTemplateType) onTemplateSelected;

  const TemplateSelectionGrid({super.key, required this.onTemplateSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60.0),
      child: Center(
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _buildTile(
              icon: Icons.auto_awesome,
              label: 'Mool Mantar',
              color: Colors.orange,
              onTap: () => onTemplateSelected(TrackerTemplateType.moolMantar),
            ),
            _buildTile(
              icon: Icons.favorite,
              label: 'Simran',
              color: Colors.redAccent,
              onTap: () => onTemplateSelected(TrackerTemplateType.waheguruSimran),
            ),
            _buildTile(
              icon: Icons.menu_book,
              label: 'Bani Count',
              color: Colors.teal,
              onTap: () => onTemplateSelected(TrackerTemplateType.baniCount),
            ),
            _buildTile(
              icon: Icons.library_books,
              label: 'Sehaj Path',
              color: Colors.purple,
              onTap: () => onTemplateSelected(TrackerTemplateType.sehajPath),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 280,
      height: 180,
      child: Card(
        elevation: 0,
        color: color.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withAlpha(50)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
