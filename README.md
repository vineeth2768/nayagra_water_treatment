# Nayagra Water Treatment Plant CRM & Service Management System

A production-quality, corporate enterprise Web CRM built using **Flutter Web**, **Firebase Authentication**, **Cloud Firestore**, **MVC Architecture**, and **Provider State Management**.

Designed for water treatment plant manufacturers, operations teams, and service providers (RO Plants, Water Softeners, DM Plants, STP, and ETP) to manage clients, equipment installations, automated 6-month periodic maintenance cycles, customer service history, and technician dispatching.

---

## 🌊 Key Features

### 1. Corporate Executive Dashboard
- **6 KPI Summary Cards**: Total Customers, Total Installed Plants, Upcoming Services, Overdue Services (with red visual alerts), Completed Services, and Services Due This Month.
- **Monthly Service Trend Chart**: 6-month historical activity volume visualized with `fl_chart`.
- **Plant Technology Breakdown**: Distribution progress bars across Commercial RO, Industrial RO, Softeners, and Treatment Plants.
- **Overdue Service Alert Banner**: Instant visual warning for plants needing urgent filter replacement or chemical descaling.
- **Quick Action Triggers**: Instant navigation to add customers, reschedule, or complete services.

### 2. Customer Management System (CRUD)
- **Comprehensive Profiles**:
  - Personal Information: Name, Gender, Primary Phone, Alternate Contact, Date of Birth.
  - Installation Details: Site Name, Plant Type, Commissioning Date, First Contact Date.
  - Location: Address, City, State, PIN Code.
  - Additional: Operational notes, Feed water TDS, membrane specs.
- **Search & Filtering**: Real-time search by Customer Name, Phone, Site Name, City, or Plant Type.
- **Sorting**: Newest installed, oldest installed, alphabetical.
- **Pagination**: Configurable page-by-page table view.
- **CSV Data Export**: One-click download of the filtered customer directory.

### 3. Automated 6-Month Service Scheduling Engine
- **Automatic First Service Generation**: When a customer installation is registered, Service #1 is automatically scheduled for **Installation Date + 6 Months**.
- **Accurate Month-End Date Math**: Uses month-end clamping (e.g., Aug 31 + 6 months -> Feb 28, not overflowing into March).
- **Service Completion Workflow**:
  - Records completion date, technician name, multiline service notes, and replaced consumables (filters, antiscalants, valves).
  - Automatically calculates and schedules **Service N + 1** (+6 months from completion date).
  - Updates customer's `lastServiceDate` and `nextServiceDate`.
  - **Immutable Historical Records**: Previous service history is never overwritten.
- **Rescheduling**: Flexible adjustment of upcoming maintenance dates by administrators.

### 4. Dedicated Upcoming & Completed Service Modules
- **Upcoming Services**: Categorized with dynamic badges:
  - 🟢 **Upcoming** (> 30 days away)
  - 🟡 **Due Soon** (<= 30 days away)
  - 🔴 **Overdue** (Past scheduled date, automatically detected)
  - Date range filtering and city filtering.
- **Completed Services**: Permanent audit trail of technician interventions with detailed service report popups and CSV export.

### 5. Customer Profile with Chronological Timeline
- **Tab 1: Overview**: Equipment specs, location, contact, and current service health.
- **Tab 2: Service History Timeline**: Visual timeline tracing the plant lifecycle from commissioning to every subsequent 6-month cycle.
- **Tab 3: Technical Notes**: Feed water parameters, operating guidelines, and notes.

---

## 🏗️ Architecture (MVC + Provider + Repository)

```
lib/
├── core/
│   ├── constants/       # AppColors, AppConstants, AppStrings
│   ├── theme/           # Corporate Water-treatment theme
│   └── utils/           # DateFormatter, CsvExporter, Validators
├── models/
│   ├── customer_model.dart
│   ├── service_model.dart
│   └── user_model.dart
├── repositories/
│   ├── auth_repository.dart
│   ├── customer_repository.dart
│   ├── service_repository.dart
│   └── dashboard_repository.dart
├── controllers/
│   ├── auth_controller.dart
│   ├── customer_controller.dart
│   ├── service_controller.dart
│   └── dashboard_controller.dart
├── providers/
│   ├── auth_provider.dart
│   ├── customer_provider.dart
│   ├── service_provider.dart
│   └── dashboard_provider.dart
├── routes/
│   ├── app_router.dart
│   └── route_names.dart
├── widgets/
│   ├── app_sidebar.dart
│   ├── app_header.dart
│   ├── main_layout.dart
│   ├── dashboard_stat_card.dart
│   ├── customer_data_table.dart
│   ├── service_status_badge.dart
│   ├── complete_service_dialog.dart
│   ├── reschedule_service_dialog.dart
│   └── confirmation_dialog.dart
├── views/
│   ├── auth/            # login_view.dart
│   ├── dashboard/       # dashboard_view.dart
│   ├── customers/       # list, add, edit, details
│   ├── services/        # upcoming, completed, history
│   └── settings/        # settings_view.dart
├── firebase_options.dart
├── app.dart
└── main.dart
```

---

## 🚀 Running the Project Locally

### 1. Prerequisites
- Flutter SDK (v3.13+ or higher)
- Google Chrome

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Tests
```bash
flutter test
```

### 4. Run the Web Application
```bash
flutter run -d chrome
```

### 5. Demo Credentials
If testing without entering custom Firebase keys:
- **Email:** `admin@nayagra.com`
- **Password:** `admin123`
*(Pre-seeded with realistic water treatment plant customer accounts and sample service cycles)*

---

## 🔒 Firebase Configuration & Deployment

### 1. Connect Your Live Firebase Project
Replace the configuration in [`lib/firebase_options.dart`](lib/firebase_options.dart) with your project keys or run:
```bash
flutterfire configure
```

### 2. Cloud Firestore Security Rules
Production security rules are located in [`firestore.rules`](firestore.rules). Deploy with:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### 3. Build & Deploy to Firebase Hosting
```bash
flutter build web --release
firebase deploy --only hosting
```
