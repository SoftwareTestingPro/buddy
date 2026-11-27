# Buddy - Rent a Buddy & Safe Connections Platform

**Buddy** is a fast, responsive, cross-platform Flutter application (Android + Web) inspired by companionship platforms like [buddysearch.in](https://buddysearch.in/). It features an original modern design system (coral & indigo aesthetics), robust authentication architecture, and a free-tier database layer (Supabase PostgreSQL / Firebase Firestore).

---

## 🚀 Key Features

1. **Original Visual Identity & Design System**:
   - Built with Material 3 styling, custom trust badges, rounded modern cards, and a warm coral (`#FF5364`) + deep iris indigo (`#6C5CE7`) palette.
   - Clean card-based layouts for verified buddies with activity tags, ratings, and instant booking hooks.

2. **Core Sub-pages & Modules**:
   - **Explore & Search Hub**: Search buddies by keywords, filter across 12+ Pan-India cities (Delhi NCR, Bengaluru, Mumbai, Pune, Kolkata, Jaipur, etc.), and filter by 8 distinct hangout categories.
   - **Interactive Buddy Earnings Calculator**: Allows users to calculate potential income by adjusting hours/week and desired hourly rate (e.g. ₹15,000 to ₹60,000+/month).
   - **Multi-step Profile Setup & Onboarding**: Name, verified phone number validation, city selection, bio, and a toggle to "Become a Verified Buddy" with hourly rate and preferred activities.
   - **Public Venue Booking Flow**: Schedule date, time, duration (hours), public meeting point (Starbucks, mall, park), special notes, and safety agreement.
   - **My Bookings Manager**: View active, confirmed, and completed sessions with live cost breakdowns.
   - **Transparent Membership Plans**: Free Explorer, Buddy Plus (₹399/mo), and VIP Pass (₹899/3mo).

3. **Security & Free-Tier Database**:
   - **Zero Secrets in Git**: Sensitive credentials stored strictly in `.env` (which is included in `.gitignore`). Template committed as [`.env.example`](.env.example).
   - **Database Security Rules**:
     - Supabase PostgreSQL schema with Row Level Security (RLS) located in [`security/supabase_schema_and_rules.sql`](security/supabase_schema_and_rules.sql).
     - Firebase Cloud Firestore security rules located in [`security/firestore.rules`](security/firestore.rules).
   - **Offline-First & Graceful Fallback**: Works immediately out-of-the-box with a local cached repository so the app can be tested right away without requiring immediate cloud setup.

---

## 🛠️ Project Structure

```
Buddy/
├── .env.example                       # Environment secrets template
├── .env                              # Local secrets (gitignored)
├── pubspec.yaml                      # Dependencies & asset declarations
├── security/
│   ├── supabase_schema_and_rules.sql # Supabase RLS security rules & schema
│   └── firestore.rules               # Firestore security rules
├── lib/
│   ├── main.dart                     # App entry point
│   ├── config/
│   │   └── app_config.dart           # Safe .env loader
│   ├── models/
│   │   ├── user_profile.dart         # User & Buddy profile model
│   │   ├── booking.dart              # Booking schedule model
│   │   └── category_and_plans.dart   # Categories & subscription models
│   ├── services/
│   │   ├── mock_data.dart            # Pan-India cities, categories, buddies
│   │   └── buddy_repository.dart     # Auth, session & booking manager
│   ├── theme/
│   │   └── app_theme.dart            # Coral/Indigo palette & UI theme
│   ├── widgets/
│   │   └── buddy_card.dart           # Responsive Buddy profile card
│   └── screens/
│       ├── home/home_screen.dart     # Main exploration & navigation shell
│       ├── auth/
│       │   ├── google_auth_dialog.dart
│       │   └── profile_setup_screen.dart
│       ├── booking/
│       │   ├── booking_modal.dart
│       │   └── my_bookings_screen.dart
│       ├── calculator/earnings_calculator_screen.dart
│       └── plans/membership_plans_screen.dart
```

---

## 🏃 Running the Application

### 1. Web
```bash
flutter run -d chrome
# Or to build release:
flutter build web --release
```

### 2. Android
```bash
flutter run -d android
# Or to build APK:
flutter build apk --release
```
