# Supabase setup for Health Connect

## 1. Create the database

In the Supabase dashboard, open **SQL Editor**, choose **New query**, paste the complete contents of `supabase/schema.sql`, and press **Run**.

This creates the organisations, memberships, RAF cases, documents and messages tables, the private document bucket, indexes, and Row Level Security policies.

## 2. Find the Flutter connection values

Open **Project Settings → API** (or **Connect** in newer dashboard layouts).

Copy:

- Project URL
- Publishable key (the public client key)

Never put the service-role or secret key inside the Flutter application.

## 3. Run the app with Supabase enabled

From the project directory:

```powershell
flutter pub get
flutter run -d windows --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
```

For Android:

```powershell
flutter run -d emulator-5554 --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
```

Do not commit real keys to source files. The publishable key is designed for client applications, while database protection comes from authentication and RLS.

## 4. Email confirmation during development

By default, Supabase may require confirmation before a new user can sign in. Check **Authentication → Providers → Email**. Keep confirmation enabled for production. During initial local testing, either confirm using the email message or temporarily disable confirmation.

## 5. Current rollout mode

The existing interface continues to use encrypted local demo persistence unless launched with both Dart defines. The Supabase service layer is ready for account, case, messaging and document operations. Roll out with synthetic test data before using personal or health information.

Before production, arrange a POPIA/legal security review, MFA, organisation verification, audit logging, retention/deletion workflows, backups, malware scanning, and a processing agreement.
