# Implementation Plan - Modern Responsive Hub (v3)

Refine the Dashboard V2 to a more spacious, horizontal layout with enhanced depth and branding consistency.

## Proposed Changes

### [Component Name] Dashboard UI Refinement

#### [MODIFY] [app_hub_v2_view.dart](file:///home/muhamamdhaseebjavaid/AndroidStudioProjects/railway_hrms/lib/promise/rollingstock/screens/app_hub_v2_view.dart)
- **Design Tokens**:
    - Update `backgroundLight` to a warm "Egg White" (`#F2EFE9`).
    - Adjust shadows to be slightly softer and larger for better depth against the new background.
- **Layout Adjustments**:
    - Change grid from 3 columns to **2 columns** on mobile to accommodate the new horizontal card structure.
    - Re-introduce natural vertical and horizontal spacing (16px gaps).
- **Module Card Redesign**:
    - **Horizontal Orientation**: Move the icon to the left and text to the right.
    - **Flexible Text**: Use `Expanded` to hold a `Column` with the Title (1 line) and Subtitle (up to 2 lines).
    - **Visual Cues**: Keep the navigation chevron on the far right.
    - **Balanced Padding**: Increase internal card padding for a premium feel.
- **Overflow Fixes**:
    - Use `Flexible`/`Expanded` strategically within `Row` components.
    - Remove hard-coded height constraints that might conflict with text wrapping.

## Verification Plan

### Manual Verification
- Verify the background color is a warm egg-white.
- Verify module cards show the icon on the left and text on the right.
- Verify the 2-column mobile grid feels balanced and scannable.
- Verify no yellow-striped overflow warnings appear on small screens.
