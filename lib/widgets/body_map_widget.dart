import 'package:flutter/material.dart';
import '../theme/colors.dart';

class BodyMapWidget extends StatelessWidget {
  final String viewMode; // 'front' or 'back'
  final String? selectedBodyArea;
  final ValueChanged<String> onViewModeChanged;
  final ValueChanged<String> onSelectBodyArea;

  const BodyMapWidget({
    Key? key,
    required this.viewMode,
    required this.selectedBodyArea,
    required this.onViewModeChanged,
    required this.onSelectBodyArea,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C182E) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // View Mode Selector Header (Front View / Back View)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggleButton('front', 'Front View', Icons.check),
                const SizedBox(width: 8),
                _buildViewToggleButton('back', 'Back View', Icons.flip_camera_android),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Interactive Diagram Canvas
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF070F1E) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: viewMode == 'front' ? _buildFrontViewDiagram(isDark) : _buildBackViewDiagram(isDark),
          ),

          const SizedBox(height: 16),
          Text(
            selectedBodyArea != null
                ? 'Selected: $selectedBodyArea'
                : 'Click any body region to filter symptoms',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selectedBodyArea != null ? AppColors.primaryTeal : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(String mode, String label, IconData icon) {
    final bool isActive = viewMode == mode;
    return InkWell(
      onTap: () => onViewModeChanged(mode),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.black : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.black : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FRONT VIEW DIAGRAM LAYOUT
  // ==========================================
  Widget _buildFrontViewDiagram(bool isDark) {
    return Column(
      children: [
        // Row 1: Ears - Head - Eyes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBodyPill('Ears', width: 60, height: 36),
            const SizedBox(width: 8),
            _buildBodyCircle('Head', size: 60),
            const SizedBox(width: 8),
            _buildBodyPill('Eyes', width: 60, height: 36),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: Nose
        _buildBodyPill('Nose', width: 68, height: 32),
        const SizedBox(height: 8),

        // Row 3: Neck
        _buildBodyPill('Neck', width: 68, height: 32),
        const SizedBox(height: 10),

        // Row 4: Left Arm - Chest - Right Arm
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBodyPill('Left Arm', label: 'Arms', width: 50, height: 90),
            const SizedBox(width: 10),
            _buildBodyBox('Chest', width: 110, height: 75),
            const SizedBox(width: 10),
            _buildBodyPill('Right Arm', label: 'Arms', width: 50, height: 90),
          ],
        ),
        const SizedBox(height: 8),

        // Row 5: Left Hand - Abdomen - Right Hand
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBodyPill('Left Hand', label: 'Hands', width: 50, height: 36),
            const SizedBox(width: 10),
            _buildBodyBox('Abdomen', width: 110, height: 80),
            const SizedBox(width: 10),
            _buildBodyPill('Right Hand', label: 'Hands', width: 50, height: 36),
          ],
        ),
        const SizedBox(height: 10),

        // Row 6: Left Leg - Right Leg
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBodyPill('Left Leg', label: 'Legs', width: 60, height: 105),
            const SizedBox(width: 14),
            _buildBodyPill('Right Leg', label: 'Legs', width: 60, height: 105),
          ],
        ),
        const SizedBox(height: 8),

        // Row 7: Left Foot - Right Foot
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBodyPill('Left Foot', label: 'Feet', width: 60, height: 34),
            const SizedBox(width: 14),
            _buildBodyPill('Right Foot', label: 'Feet', width: 60, height: 34),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // BACK VIEW DIAGRAM LAYOUT
  // ==========================================
  Widget _buildBackViewDiagram(bool isDark) {
    return Column(
      children: [
        // Row 1: Head (Back)
        _buildBodyCircle('Head', label: 'Head / Scalp', size: 60),
        const SizedBox(height: 8),

        // Row 2: Neck (Back)
        _buildBodyPill('Neck', label: 'Neck / Spine', width: 90, height: 32),
        const SizedBox(height: 10),

        // Row 3: Left Arm - Upper Back - Right Arm
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBodyPill('Left Arm', label: 'Arms', width: 50, height: 90),
            const SizedBox(width: 10),
            _buildBodyBox('Upper Back', label: 'Upper Back', width: 110, height: 75),
            const SizedBox(width: 10),
            _buildBodyPill('Right Arm', label: 'Arms', width: 50, height: 90),
          ],
        ),
        const SizedBox(height: 8),

        // Row 4: Left Hand - Lower Back - Right Hand
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBodyPill('Left Hand', label: 'Hands', width: 50, height: 36),
            const SizedBox(width: 10),
            _buildBodyBox('Lower Back', label: 'Lower Back', width: 110, height: 80),
            const SizedBox(width: 10),
            _buildBodyPill('Right Hand', label: 'Hands', width: 50, height: 36),
          ],
        ),
        const SizedBox(height: 10),

        // Row 5: Left Leg - Right Leg
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBodyPill('Left Leg', label: 'Legs', width: 60, height: 105),
            const SizedBox(width: 14),
            _buildBodyPill('Right Leg', label: 'Legs', width: 60, height: 105),
          ],
        ),
        const SizedBox(height: 8),

        // Row 6: Left Foot - Right Foot
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBodyPill('Left Foot', label: 'Feet / Heel', width: 60, height: 34),
            const SizedBox(width: 14),
            _buildBodyPill('Right Foot', label: 'Feet / Heel', width: 60, height: 34),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // HELPER BUILDERS FOR BODY REGION SHAPES
  // ==========================================
  Widget _buildBodyCircle(String areaKey, {String? label, required double size}) {
    final bool isSelected = selectedBodyArea == areaKey;
    return GestureDetector(
      onTap: () => onSelectBodyArea(areaKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? AppColors.primaryTeal.withOpacity(0.3)
              : const Color(0xFF1E293B),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.white24,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label ?? areaKey,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyPill(String areaKey, {String? label, required double width, required double height}) {
    final bool isSelected = selectedBodyArea == areaKey;
    return GestureDetector(
      onTap: () => onSelectBodyArea(areaKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? AppColors.primaryTeal.withOpacity(0.3)
              : const Color(0xFF1E293B),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.white24,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label ?? areaKey,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyBox(String areaKey, {String? label, required double width, required double height}) {
    final bool isSelected = selectedBodyArea == areaKey;
    return GestureDetector(
      onTap: () => onSelectBodyArea(areaKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primaryTeal.withOpacity(0.3)
              : const Color(0xFF1E293B),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.white24,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label ?? areaKey,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
