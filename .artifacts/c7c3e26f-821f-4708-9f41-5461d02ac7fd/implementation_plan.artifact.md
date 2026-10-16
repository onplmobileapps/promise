# Signal & Telecom Inspection Implementation Plan

Implement a new "Signal & Telecom Inspection" feature based on the provided 19-page BRD. This feature will mirror the design, theme, and user flow of the existing Footplate inspection while incorporating the specific requirements for S&T.

## User Review Required

> [!IMPORTANT]
> The BRD contains a large number of fields across 19 pages. The implementation will use a multi-step stepper (Wizard) similar to `einspection_screen.dart` to keep the UI manageable.

## Proposed Changes

### Footplate Dashboard
#### [MODIFY] [footplate_dashboard_screen.dart](file:///Users/muhammadhaseeb/StudioProjects/railway_hrms/lib/features/footplate/dashboard/footplate_dashboard_screen.dart)
- Update the "Start Signal Inspection" button to navigate to the new `SignalInspectionScreen` instead of showing a Toast.

### Signal Inspection Component
#### [NEW] [signal_inspection_screen.dart](file:///Users/muhammadhaseeb/StudioProjects/railway_hrms/lib/features/footplate/dashboard/signal_inspection_screen.dart)
- Create a new stateful widget that implements a multi-step form.
- **Section 1: General Info & Asset Details** (BRD Pages 4, 9, 17)
    - Implement the "Accordion" style asset detail header (Division, Section, Station).
    - Add Station Master/Assistant Station Master fields (Uniform, Conversant, IYD, Rules).
- **Section 2: Station Equipment** (BRD Pages 10, 11)
    - Indication Panel & EBI Screen details.
    - Block Instruments (Neil's Token, Tyer's, etc.) with conditional "Available" logic.
    - Magneto Telephone.
- **Section 3: Power & Battery Systems** (BRD Pages 6, 12, 13)
    - Equipment Room / Relay Room details.
    - Detailed voltage tracking for 12V, 14.2V, 24V, and 60V chargers and batteries.
- **Section 4: Field Assets (Points & Signals)** (BRD Pages 13, 14, 17)
    - Point inspection (Electrical/Mechanical) for specific point numbers (e.g., 112A).
    - Signal visibility and focus check.
    - Track Circuit (Feed End Volt, Relay Terminal Volt).
- **Section 5: Communication & Auxiliary** (BRD Pages 15, 16, 18)
    - VHF, Zong/Ufone GSM, Microwave.
    - DG Set & Tower light monitoring.
    - Painting program and Quarterly failure summary table.

### Shared Widgets
#### [NEW] [signal_inspection_widgets.dart](file:///Users/muhammadhaseeb/StudioProjects/railway_hrms/lib/features/footplate/widgets/signal_inspection_widgets.dart)
- Create reusable components for S&T forms:
    - `VoltageInput`: Text field with range validation and 2-decimal restriction.
    - `SatisfactoryRadio`: Standardized radio group for Satisfactory/Unsatisfactory/Poor.
    - `AssetAccordion`: The toggleable header for fixed information.

## Verification Plan

### Manual Verification
- Tap "Start Signal Inspection" on the dashboard.
- Verify the "Asset Details" accordion expands and collapses.
- Test conditional visibility: Ensure "Block Instrument" sub-fields only show if "Available" is selected.
- Validate voltage ranges (e.g., 12V Charger must be between 13.0 and 15.0).
- Check the "Summary" page to ensure all sections are captured before submission.
