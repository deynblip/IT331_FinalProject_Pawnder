# 🐾 Pawnder

**Pawnder** is a community-based Android app built with **Flutter and Dart** that helps people take part in animal rescue and welfare. Users can report stray, injured, sick, or trapped animals, see nearby reports on a map, respond to rescue situations, and find pets available for adoption.

The name combines **"paw"** (animals) and **"finder"** (the act of finding): helping people find animals that need help, and helping those animals be found by rescuers and by families who will give them a home.

> Final project for **IT 331: Application Development and Emerging Technologies**
> College of Informatics and Computing Sciences, Batangas State University – The National Engineering University (Alangilan Campus)

---

## 📑 Table of Contents

- [Problem](#-problem)
- [Objectives](#-objectives)
- [Target Users](#-target-users)
- [Getting Started](#-getting-started)
- [Features](#-features)
- [How It Works](#-how-it-works)
- [Tech Stack](#-tech-stack)
- [Backend Setup (Supabase and Firebase)](#-backend-setup-supabase-and-firebase)
- [Project Structure](#-project-structure)
- [Privacy and Security](#-privacy-and-security)
- [Known Limitations](#-known-limitations)
- [Future Enhancements](#-future-enhancements)
- [Team](#-team)
- [References](#-references)

---

## ❓ Problem

Stray animals are a large concern in the Philippines. A Mars Petcare Pet Homelessness Project report placed the number of stray cats and dogs in the country at **13.11 million** (Interaksyon, 2024). Information about animals in need is still shared mostly through social media posts and separate online communities. This causes:

- **Scattered animal reports** across different platforms
- **Unclear animal locations**, so helpers cannot find the animal
- **No rescue updates**: people don't know if someone is already responding or if the animal was rescued
- **Scattered and unsafe adoption**: listings are hard to find, and scammers or people posing as adopters can take advantage (Philippine Daily Inquirer, 2022; Cebu Daily News, 2025)

Pawnder keeps reports, locations, rescue status, and adoption screening together in one app.

---

## 🎯 Objectives

1. Allow users to report an animal in need with photos, type, urgency level, description, pinned map location, and contact details.
2. Display reported animals on an interactive map and in a Reports Bulletin so users can easily locate nearby cases.
3. Enable users to respond to reports and track each animal's rescue status from **Needs Rescue** to **Rescued**, with a location-based check-in.
4. Provide an Adoption Bulletin where pets can be posted and browsed, supported by administrator review of posts, screening of applications, and a final decision by the original poster.
5. Provide an administrator dashboard for reviewing adoption posts, applications, reported content, and Verified Rescuer applications.

---

## 🧑‍🤝‍🧑 Target Users

| User | Description |
|---|---|
| **Community members** | Report stray animals and help in rescue situations |
| **Pet owners and rescuers** | Post animals for adoption to find them new homes |
| **Potential adopters** | Browse available pets and submit adoption applications |
| **Verified Rescuers** | Members of rescue organizations, verified by the admin, with extra rescue permissions |
| **Administrators** | Review adoption posts, screen applications, review reported content, and approve Verified Rescuers |

---

## 🚀 Getting Started

There are two ways to run Pawnder.

### Option 1: Install the APK (easiest)

For testers and anyone who only wants to use the app. No coding tools are needed.

1. On an Android phone, download the APK: **[Download Pawnder APK](https://drive.google.com/drive/folders/1h2XuqgSnpk5BAWhn8-PzIENGx4df4o5q?usp=sharing)**
2. Open the downloaded file and allow **Install unknown apps** when asked.
3. If Google Play Protect shows a warning, tap **More details → Install anyway**. This appears because the app is not from the Play Store.
4. Open Pawnder and allow **notifications** and **location**.

> If an older Pawnder build is installed and the new one fails to install ("App not installed"), uninstall the old one first.

### Option 2: Run from the source code

For developers who want to run or change the code.

**Requirements**
- Flutter SDK (Dart SDK `^3.13.4`)
- Android Studio with an Android emulator or a physical Android device
- Internet connection (all data is stored online in Supabase)

```bash
git clone https://github.com/deynblip/IT331_FinalProject_Pawnder.git
cd IT331_FinalProject_Pawnder
flutter pub get
flutter run
```

To build your own APK: `flutter build apk --release` (the file is saved in `build/app/outputs/flutter-apk/app-release.apk`).

The app is already connected to the team's Supabase project (`lib/services/supabase_config.dart` holds the project URL and the public key, which are safe to share).

### Accounts

| Role | How to get one |
|---|---|
| Community Member | Sign up in the app as a **Community Member** (an 8-digit code is sent by email) |
| Verified Rescuer | Sign up as a **Professional Rescuer** (or apply later from Profile) with your organization details. Rescue permissions unlock after the admin approves the application. Until then, the account works as a regular user. |
| Admin | Created by the team only. Ask the team for the demo admin login. |

> Admin accounts cannot be created from the app. They are assigned in the Supabase dashboard with `supabase/scripts/make_admin.sql`.

> **Note:** the Android application ID is `com.pawnder.app`.

---

## ✨ Features

### Accounts
- **Sign Up** as a Community Member or a Professional Rescuer, with an **8-digit email verification code**
- **Password rules** for new accounts (at least 8 characters, a letter and a number) with a live checklist
- **Terms & Conditions** must be scrolled to the end before *I Agree* can be tapped
- **Log In**, **Forgot Password** (code by email), **Change Password**, and **auto-login** when the app is reopened
- **Profile photo**, saved online and shown on the Profile and in the side drawer

### Reporting and rescue
- **Report a Stray**: up to **3 photos**, animal type, urgency (*Urgent*, *Needs Help*, *Sighted*), condition and behavior, a *"Has a collar / looks like someone's pet"* checkbox, a pinned location (*Use my location* or *Pin on map*), and the reporter's **name, phone number, and email**
- **Home**: quick *Report a Stray* button, nearby reports from other users that still need help, and safety reminders
- **Map**: color-coded pins of animals that still need help, distance filters (*All*, 5, 10, 20 km), a *My Location* button, and a floating preview card
- **Reports Bulletin** with urgency filters, and **Report Details** with a photo gallery, date and time, distance, *Get Directions* (Google Maps), and **Contact the Reporter** (call or email)
- **Rescued animals** leave the Map and Reports Bulletin and stay in *My Reports* and *My Responses*
- **Rescue response**: *I'm on my way!*, *I've arrived · Check in* (within 200 m), *Cancel*, *Take over*, and *Mark as Rescued*
- **Responder track record and trust levels** (New Helper, Active Helper, Trusted Helper)
- **Verified Rescuer** applications and badge

### Adoption
- **Adoption Bulletin** with Dogs / Cats / All Pets and Rescued Stray / Rehoming filters (rescued strays are listed first)
- **Post a Pet** for adoption, reviewed by the admin before it is published
- **Edit an approved post up to 2 times** without another admin review
- **Adoption Application** with a valid-ID agreement for the in-person meet-up
- The poster makes the **final decision** on applications that the admin forwards

### My Activity (Profile)
- **My Reports** (edit or remove while no one is responding)
- **My Responses**: reports you responded to, with *You are responding*, *Completed*, or *You withdrew*
- **Adoption Applications** (edit or withdraw while pending)
- **My Adoption Posts** (status, edits left, edit, or remove)

### Notifications and settings
- **In-app notifications** (bell with unread count) and **push notifications** on the phone, even when the app is closed
- **Dark mode** for the user side, saved on the phone
- **Report Post / Report Content** for anything inappropriate
- Side drawer: Help & Support, About, Settings, Terms & Conditions, Privacy Policy, Log Out

### Administrators
- **Dashboard** with counts and a side drawer (Change Password, About, Log Out, and an admin photo)
- **Adoption Posts**: approve, or reject with a required reason
- **Applications**: forward to the poster or reject with a reason
- **Reported Content**: dismiss the report or remove the content
- **Rescuers**: approve, reject, or remove the Verified Rescuer badge, with the applicant's track record
- **Registered users** count; users can be restricted from the database

---

## 🔄 How It Works

### Rescue flow
1. A user reports an animal. The report shows as **Needs Rescue** on Home, the Map, and the Reports Bulletin.
2. Another user taps **I'm on my way!** The report becomes **Rescue in Progress**, and the reporter is notified. The reporter cannot respond to their own report.
3. At the location, the responder taps **I've arrived · Check in**. This only works within **200 m** of the pinned location.
4. A checked-in responder, a Verified Rescuer, or the reporter taps **Mark as Rescued**. The report becomes **Rescued** and leaves the Map and the Reports Bulletin.
5. If every responder cancels, the report goes back to **Needs Rescue**. If there are no updates for **24 hours**, a Verified Rescuer can **take over** the report.

### Trust levels
Every responder has a track record. A rescue only counts when the responder checked in at the location.

| Level | Requirement |
|---|---|
| **New Helper** | No completed rescues yet |
| **Active Helper** | 3 or more completed rescues |
| **Trusted Helper** | 10 or more completed rescues and a cancel rate below 30% |

### Verified Rescuers
- Users apply during Sign Up (*Professional Rescuer*) or later from Profile, with their organization, role, contact person and number, and official page.
- The admin checks the application with the organization and approves or rejects it. Permissions only unlock after approval.
- Verified Rescuers can respond to several reports at once, become the **lead responder**, choose outcomes such as *Unable to locate*, take over inactive reports, and get a **"Rescued by [Organization]"** tag on their adoption posts.

### Adoption flow
1. A user posts a pet → **Pending** (not shown in the Adoption Bulletin yet).
2. The admin **approves** it (published) or **rejects** it with a reason. The poster can edit a rejected post and resubmit it.
3. An approved post can be edited **up to 2 times** and stays published.
4. A user applies → the admin **screens** the application and **forwards** it to the poster or rejects it.
5. The poster sees the applicant's contact details and makes the **final decision**. The ID is checked in person, never uploaded.

---

## 🛠 Tech Stack

| Category | Tool / Package |
|---|---|
| Language and framework | Flutter, Dart (SDK `^3.13.4`) |
| Backend | **Supabase**: Auth, Postgres database, Storage, Row Level Security, Edge Functions (`supabase_flutter`) |
| Push notifications | **Firebase Cloud Messaging** (`firebase_core`, `firebase_messaging`) through a Supabase Edge Function |
| Maps | `flutter_map` + `latlong2` (OpenStreetMap tiles), Google Maps for directions |
| Location | `geolocator`, `geocoding`, OpenStreetMap Nominatim through `http` |
| Device features | `image_picker` (camera and gallery), `url_launcher` and `android_intent_plus` (maps, calls, and email) |
| Saved settings | `shared_preferences` (dark mode) |
| Tools | Android Studio, Git and GitHub, Canva (UI design) |

---

## 🗄 Backend Setup (Supabase and Firebase)

This is only needed to run Pawnder on a **new** Supabase project. The team's project is already set up.

### Supabase
1. Create a Supabase project and put its URL and publishable key in `lib/services/supabase_config.dart`.
2. In **SQL Editor**, run the migrations in `supabase/migrations/` **once each, in order**:

   | File | What it adds |
      |---|---|
   | `0001_pawnder_init.sql` | Tables, functions, security rules, and storage buckets |
   | `0002_my_activity.sql` | Edit and remove your own reports |
   | `0003_my_applications.sql` | Edit and withdraw your own applications |
   | `0004_device_tokens.sql` | Phone tokens for push notifications |
   | `0005_device_tokens_service_role.sql` | Access for the push Edge Function |
   | `0006_report_contact_and_post_edits.sql` | Reporter contact details and the edit limit for approved posts |
   | `0007_post_edit_limit_two.sql` | Lowers the edit limit for approved posts to 2 |

3. **Authentication**: turn on *Confirm email*, set the email OTP length to **8**, and set up SMTP (the team uses Gmail SMTP).
4. Create the admin: sign up in the app, then run `supabase/scripts/make_admin.sql` (change the email first).
5. Optional: `supabase/scripts/check_setup.sql` checks the setup, `seed_demo.sql` adds demo reports and pets, and `delete_test_accounts.sql` removes test accounts.

> New database changes go in a **new** migration file (`0007_...sql`). Old migrations are never edited or run again.

### Push notifications (Firebase)
1. Create a Firebase project with an Android app for `com.pawnder.app`, and put `google-services.json` in `android/app/`.
2. Deploy the Edge Function in `supabase/functions/send-push/` as `send-push` (Verify JWT: off).
3. In **Edge Functions → Secrets**, add `FCM_SERVICE_ACCOUNT` (the Firebase service account JSON) and `WEBHOOK_SECRET`.
4. Add a **Database Webhook** on `notifications` (Insert) that sends a POST to the `send-push` function with the header `x-webhook-secret`.

> Never commit the Supabase secret key, the database password, the Gmail App Password, or the Firebase service account key.

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point, theme, and startup
├── models/                   # StrayReport, AdoptionPet, AdoptionApplication, ContentReport, AppNotification, RescuerApplication
├── services/                 # Supabase services: auth, reports, responses, adoption, applications,
│                             # content reports, notifications, rescuers, push
├── screens/                  # User screens (welcome, login, home, map, reports, adopt, profile, forms, ...)
│   ├── admin/                # Admin dashboard, posts, applications, reported content, rescuers
│   └── drawer/               # About, Settings, Help & Support, Terms, Privacy Policy
├── utils/                    # Colors, styles, validators, theme controller, responsive layout
└── widgets/                  # Reusable widgets (cards, photo gallery, profile avatar, field labels, ...)

supabase/
├── migrations/               # Database changes (run once each, in order)
├── functions/send-push/      # Edge Function that sends push notifications
└── scripts/                  # Admin, setup check, demo data, and test account scripts

android/app/google-services.json   # Firebase config for push notifications
```

---

## 🔐 Privacy and Security

- **Row Level Security**: users can only change their own data; admin actions are checked in the database.
- **Adoption contact details** are only visible to the poster, admins, and applicants whose application was forwarded.
- **Report contact details** are visible to logged-in users so the owner of a lost pet can reach the reporter.
- **No IDs are uploaded.** Adopters agree to present a valid ID in person, in line with the **Data Privacy Act of 2012 (RA 10173)**.
- **Nothing important is deleted.** Removed reports, posts, and content are hidden and kept for records. Problem accounts are restricted instead of deleted.
- **Passwords** are handled by Supabase Auth and are never stored by the app.

---

## ⚠️ Known Limitations

- **Submitting a report does not guarantee immediate rescue or assistance.**
- **Stray vs. lost pet:** Pawnder cannot confirm whether an animal is a stray or someone's lost pet. The *"Possibly a lost pet"* tag depends on what the reporter sees.
- **GPS spoofing:** the 200 m check-in can be bypassed with mock-location apps.
- **Updates are not instant:** lists refresh every 10–20 seconds and with pull-to-refresh (not real-time).
- **Dark mode** is for the user side only. The admin side, Login, and Welcome screens stay light.
- **Older reports** made before contact details were added have no *Contact the Reporter* card.
- **Address text** comes from OpenStreetMap (or the phone's geocoder) and may be incomplete in some areas, such as a missing barangay. The pinned location itself is exact.
- **No payments or vet services:** the app does not handle donations, adoption fees, animal delivery, or veterinary and shelter services.
- **Free services:** OpenStreetMap Nominatim allows about 1 request per second; Gmail SMTP limits how many emails can be sent; the free Supabase project pauses after a week without use.
- **Partner organization:** [Strays Worth Saving](https://swsph.org/) is a proposed partner only and has not been contacted.
- **Rescuer verification depends on the admin**, so approval is not instant.
- **Platforms:** built and tested for Android.

---

## 🔮 Future Enhancements

- **Auto-timeout for responders** who do not check in within a set time
- **Photo proof** when marking an animal as rescued
- **Lost & Found** section for lost pets
- **Real-time updates** with Supabase Realtime
- **Nearby alerts** for new urgent reports
- **Optional ID verification** with a *Verified* badge, stored securely and visible only to admins
- **Dark mode** for the admin side

---

## 👥 Team

**Group 2**

- Aniñon, Shanea May B.
- Banaag, Ace Angela P.
- Cura, Dane Mercy J.

**Course Facilitator:** Mr. Maurice Oliver Dela Cruz

---

## 📚 References

- Cebu Daily News. (2025). *"Willing to adopt": Puppies, kittens used as food in reptile facilities.* https://cebudailynews.inquirer.net/624809/willing-to-adopt-puppies-kittens-used-as-food-in-reptile-facilities
- Interaksyon. (2024). *Public urged to provide temporary shelter for stray animals.* https://interaksyon.philstar.com/trends-spotlights/2024/07/23/280154/public-urged-provide-temporary-shelter-stray-animals/
- Philippine Daily Inquirer. (2022). *Saving the homeless: How stray animals struggle to find homes amid pandemic.* https://newsinfo.inquirer.net/1646978/saving-the-homeless-how-stray-animals-struggle-to-find-homes-amid-pandemic
- Strays Worth Saving. https://swsph.org/