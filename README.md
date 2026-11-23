# 🐾 Pawnder

**Pawnder** is a community-based Android app built with **Flutter and Dart** that helps people take part in animal rescue and welfare. Users can report stray, injured, sick, or trapped animals, see nearby reports on a map, respond to rescue situations, and find pets available for adoption.

The name combines **"paw"** (animals) and **"finder"** (the act of finding): helping people find animals that need help, and helping those animals be found by rescuers and by families who will give them a home.

> Final project for **IT 331: Application Development and Emerging Technologies**
> College of Informatics and Computing Sciences, Batangas State University – The National Engineering University (Alangilan Campus)

---

## 📑 Table of Contents

- [Team](#-team)
- [Problem](#-problem)
- [Objectives](#-objectives)
- [Target Users](#-target-users)
- [Current Features](#-current-features)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Changes in This Version](#-changes-in-this-version)
- [Next Step: Supabase Backend](#-next-step-supabase-backend)
- [Future Enhancements](#-future-enhancements)
- [Known Limitations](#-known-limitations)
- [References](#-references)

---

## 👥 Team

**Group 2**

- Aniñon, Shanea May B.
- Banaag, Ace Angela P.
- Cura, Dane Mercy J.

**Course Facilitator:** Mr. Maurice Oliver Dela Cruz

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

1. Allow users to report an animal in need with a photo, type, urgency level, description, and pinned map location.
2. Display reported animals on an interactive map and in a Reports Bulletin so users can easily locate nearby cases.
3. Enable users to respond to reports and track each animal's rescue status from **Needs Rescue** to **Rescued**.
4. Provide an Adoption Bulletin where pets can be posted and browsed, supported by administrator screening of applications and a final decision by the original poster.
5. Provide an administrator dashboard for reviewing adoption posts and reported content, and monitoring platform activity.

---

## 🧑‍🤝‍🧑 Target Users

| User | Description |
|---|---|
| **Community members** | Report stray animals and help in rescue situations |
| **Pet owners and rescuers** | Post animals for adoption to find them new homes |
| **Potential adopters** | Browse available pets and submit adoption applications |
| **Verified Rescuers** *(planned)* | Members of rescue organizations, vets, or LGU animal welfare offices who are verified by the admin and get extra rescue permissions |
| **Administrators** | Review adoption posts before they are published, screen adoption applications, review reported content, approve Verified Rescuer applications, and send status updates |

---

## ✨ Current Features

### Regular users
- **Landing page and authentication**: Sign In and Create Account
- **Home Dashboard**: welcome message, quick *Report a Stray* action, nearby reports preview, safety guidelines, side drawer, and notification bell
- **Animal Reporting**: one-page form (photo, animal type, urgency, location, condition and behavior, and a "looks like someone's pet" checkbox) with a map preview, *Use my location*, and a full-screen *Pin on map*; no review step
- **Map and Nearby Reports**: color-coded pins, distance filters (5 km, 10 km, 20 km, All), report previews, and directions through Google Maps
- **Reports Bulletin and Report Details**: filter by urgency, full report info, responder count, and *Get Directions*
- **Rescue response**: *I'm on my way!* and *Mark as Rescued* (Needs Rescue → Rescue in Progress → Rescued)
- **Adoption Bulletin and Animal Profile**: filter by Dogs, Cats, or All Pets; *Apply to Adopt* and *Report Post*
- **Post a Pet for Adoption**: one-page form with a short confirmation before publishing; posts are reviewed by an admin before they appear in the Adoption Bulletin, and posters can track the status (Pending, Approved, Rejected) in My Adoption Posts
- **Adoption Application**: one-page form (applicant info, address, living environment, and pet ownership experience) with a required valid-ID agreement and a short confirmation before submitting
- **Forms**: required fields are marked with a red `*`, and the screen scrolls to the first field that needs fixing
- **Profile and My Activity**: My Reports, Adoption Applications, and My Adoption Posts (posters can accept or decline forwarded applications)
- **Side drawer**: Help & Support, About, Settings, Terms & Conditions, Privacy Policy, Sign Out

### Administrators
- **Admin Dashboard**: counts of adoption posts, applications, reported content, and registered users
- **Adoption Posts Management**: review pending posts, then approve them (published to the Adoption Bulletin) or reject them; the poster is notified either way
- **Adoption Application Management**: screen applications, then forward to the poster or reject with a reason
- **Reported Content Management**: review user reports, then dismiss or remove the content

---

## 🛠 Tech Stack

| Category | Tool / Package |
|---|---|
| Language and framework | Flutter, Dart |
| IDE | Android Studio |
| Version control | Git and GitHub |
| Maps | `flutter_map` + `latlong2` (OpenStreetMap tiles), Google Maps for directions |
| Location | `geolocator`, `geocoding` (Android/iOS), OpenStreetMap Nominatim through `http` (web and fallback) |
| Device features | `image_picker` (camera and gallery), `url_launcher` (maps and contact options) |
| UI design | Canva |
| Data | In-memory mock data and services for now; moving to **Supabase** (see [Next Step](#-next-step-supabase-backend)) |

---

## 🚀 Getting Started

### Requirements
- Flutter SDK (Dart SDK `^3.13.4`)
- Android Studio with an Android emulator or a physical Android device

### Run the app
```bash
git clone https://github.com/deynblip/IT331_FinalProject_Pawnder.git
cd IT331_FinalProject_Pawnder
flutter pub get
flutter run
```

### Demo accounts
| Role | Email | Password |
|---|---|---|
| Admin | `admin@pawnder.com` | `admin123` |
| Regular user | Create one on the Sign Up page | — |

> ⚠️ **For demo purposes only.** Accounts and data are stored in memory and reset every time the app restarts. The admin account (shown as **"Partner Org Admin"**) is hardcoded and will be replaced by Supabase Auth with an admin role.

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point and theme
├── data/                     # Mock data (reports, adoption pets)
├── models/                   # StrayReport, AdoptionPet, AdoptionApplication, ContentReport, AppNotification
├── services/                 # Auth, reports, adoption, applications, content reports, notifications (in-memory)
├── screens/                  # User screens (home, maps, reports, adopt, profile, forms, ...)
│   ├── admin/                # Admin dashboard, posts, applications, reported content
│   └── drawer/               # About, Settings, Help & Support, Terms, Privacy Policy
├── utils/                    # Colors, styles, validators, theme controller, responsive layout
└── widgets/                  # Reusable widgets (cards, chips, auth fields, field labels, ...)
```

---

## 🔧 Changes in This Version

These changes are implemented in the `feature/planned-changes` branch (the app still uses in-memory mock data until the [Supabase backend](#-next-step-supabase-backend) is added).

### 1. Responder Check-in Flow
Right now, *I'm on my way!* only adds +1 to the responder count, and anyone can mark a report as rescued. To make rescue responses more trustworthy, we will use the device's GPS (`geolocator`, already used in `report_stray.dart`) so responders must physically reach the animal.

1. **I'm on my way!** The user is saved as a responder (by user ID, not just +1 to the count). A regular user can have **only one active response at a time** (Verified Rescuers can have several), and no one can press the button again on the same report.
2. **I've Arrived.** This button only works when the user's GPS is within **~200 m of the report's pin**. After checking in, the report shows **"Responder on site."**
3. **Cancel / I can't make it.** A responder can withdraw. If **all** responders withdraw, the report goes back to **Needs Rescue**.
4. **Mark as Rescued.** Only the **original reporter** or a **responder who has checked in** can mark the animal as rescued, and they must be within **~200 m of the pin at that moment** (this includes the reporter).

Code changes involved:
- `models/stray_report.dart`: replace `int responders` with a list of responder IDs and their check-in status
- `screens/report_details_screen.dart`: keep *I'm on my way!* visible while the rescue is in progress (so more people can join), and add *I've Arrived*, *Cancel*, and permission checks for *Mark as Rescued*

### 2. Responder Accountability and Trust Levels
Every responder has a **track record** based on what they actually do in the app, whether they are a regular user or a Verified Rescuer. Accountability is the track record for everyone; the [Verified Rescuer Role](#3-verified-rescuer-role) is the credential for people from organizations.

**Where the data comes from (the Check-in Flow):**

| What happens | Counted as |
|---|---|
| Checked in within ~200 m and the report was marked *Rescued* | ✅ **Completed rescue** |
| Tapped *Cancel / I can't make it* | ❌ **Cancelled response** |
| Did not check in within the time limit *(once auto-timeout is added, see Future Enhancements)* | ⏱ **Timed out** |

A rescue only counts as completed if the responder physically checked in at the location, so the numbers are hard to fake.

**Where it is shown:**
- **On the report:** the list of responders with their record, for example *"Juan D. · 8 rescues"* or *"Maria S. · Lead · 25 rescues · Verified Rescuer · Batangas Animal Rescue Network."* (the organization in the sample data)
- **On the profile:** completed rescues, cancelled responses, and completion rate.

**Trust levels for regular users** *(example thresholds, to be finalized)*:

| Level | Requirement |
|---|---|
| **New Helper** | New account, or no completed rescues yet |
| **Active Helper** | 3 or more completed rescues |
| **Trusted Helper** | 10 or more completed rescues and a cancel rate below 30% |

Users who keep abandoning responses lose credibility, while users who really help naturally become trusted.

**How it connects to the Verified Rescuer role:**
- **Track record in admin review:** when a user applies as a Verified Rescuer, the admin sees their completed and cancelled counts in *Rescuer Applications*. A good record supports the application.
- **Trusted Helpers can apply:** independent rescuers without an organization who reach *Trusted Helper* see a prompt in Profile inviting them to apply as a Verified Rescuer.
- **Verified Rescuers stay accountable:** if a Verified Rescuer's cancel rate becomes high, the admin is notified and can review or remove the badge.

Code changes involved:
- Store each user's completed, cancelled (and later, timed-out) counts, updated by the Check-in Flow
- `screens/report_details_screen.dart`: show the responder list with names, record, and badges
- `screens/profile.dart`: show the stats, trust level, and the *Apply as Verified Rescuer* prompt for Trusted Helpers
- Admin *Rescuer Applications*: show the applicant's track record; flag Verified Rescuers with a high cancel rate

### 3. Verified Rescuer Role
Pawnder will have two kinds of responders: **regular users** and **Verified Rescuers** (members of rescue organizations, vets, or LGU animal welfare offices). A regular user only shows that they are willing to help. A Verified Rescuer is **accountable to an organization**, so they get more permissions.

**How a user becomes a Verified Rescuer:**

*Option A: during Sign Up (new users)*
1. On the **Create Account** screen, the user chooses an account type: **Community Member** or **Professional Rescuer**.
2. If they choose **Professional Rescuer**, extra fields appear: organization name, their role in the organization, contact person and number, and the organization's official Facebook page or website.
3. The account is created, and the rescuer status is **Pending Verification**. The user can already use the app as a regular user while waiting.

*Option B: from Profile (existing users)*
1. In **Profile**, the user taps **Apply as Verified Rescuer** and fills out the same form.
2. This is also used by users who were rejected and want to apply again.

*Admin review (both options)*
1. The admin (partner organization) reviews the application in a new **Rescuer Applications** section in the Admin interface, checks the applicant's [track record](#2-responder-accountability-and-trust-levels), and confirms it with the organization through its official page or contact details.
2. The admin **approves** it, or **rejects** it with a reason. The user is notified either way.
3. Once approved, the user gets a **Verified Rescuer · [Organization]** badge on their profile and on reports they respond to. If rejected, the user stays a regular user.

> Choosing *Professional Rescuer* at sign-up does **not** give extra permissions right away. Permissions only unlock after the admin approves the application, so no one can claim to be a rescuer just by picking the option.

> No ID or document is uploaded in the app. The admin verifies the user through the organization itself, in line with the privacy approach in [Adopter and Poster Verification](#8-adopter-and-poster-verification).

**Regular User vs. Verified Rescuer:**

| | Regular User | Verified Rescuer |
|---|---|---|
| **Badge** | None | **Verified Rescuer · [Organization]** |
| **Who can respond** | Any report, with a safety warning on *Urgent* reports | Any report, and shown first on *Urgent* reports |
| **Role in a rescue** | Assisting responder | Can be the **lead responder**; regular users become "assisting" |
| **Active responses** | One at a time | Multiple at a time |
| **Mark as Rescued** | Must check in first | Can also choose outcomes such as *Brought to vet/shelter* or *Unable to locate* |
| **Inactive reports** | — | Can take over a report with no recent updates |
| **After the rescue** | Can post the animal for adoption | Adoption post is tagged **"Rescued by [Organization]"** |

Code changes involved:
- `services/auth_service.dart`: add a rescuer role (for example, `isRescuer` and `organization`) next to the existing `isAdmin`
- `screens/signup.dart`: add the account type choice (Community Member / Professional Rescuer) and the extra rescuer fields
- New screens: *Apply as Verified Rescuer* form in Profile (reuses the same fields) and *Rescuer Applications* list (admin)
- `screens/report_details_screen.dart` and the Check-in Flow: apply the permissions in the table above
- Admin Dashboard: add the number of pending rescuer applications

### 4. Administrator: Partner Animal Welfare Organization
Administrators will be **authorized representatives of a partner animal welfare organization**, not the developers.

- **Proposed partner organization:** [Strays Worth Saving](https://swsph.org/), a Batangas-based, SEC-registered animal rescue foundation that rescues and rehomes dogs and cats. Their strict adopter screening matches the admin's role in Pawnder.
- **Status:** *Proposed / target partner only.* The organization has not been contacted yet and has not agreed to any partnership.
- Admin accounts are issued by the Pawnder team (as developers and maintainers) and cannot be self-assigned.
- In the demo, the admin account is named **"Partner Org Admin"**. It will be renamed to the organization once a partnership is confirmed.
- Pawnder will only partner with rescue groups that **rehome** animals rather than euthanize them. Rescued animals are directed to fosters, shelters, or the Adoption Bulletin.

### 5. Adoption Post Review: Pre-approval
Every new adoption post is **reviewed by an admin before it appears** in the Adoption Bulletin. This is already how the current code works; the changes below complete it and update the documentation to match.

**Flow:**
1. A user posts a pet → the post is saved with a **Pending** status and is **not** shown in the Adoption Bulletin yet.
2. The post appears in the admin's **Adoption Posts** section under **Pending**.
3. The admin opens **Post Details** and checks the photos, information, and contact details.
4. The admin decides:
    - **Approve** → the post is published to the Adoption Bulletin and the poster is notified.
    - **Reject** → the post stays hidden, and the poster is notified **with the reason**.
5. If the poster **edits** an approved post, it goes back to **Pending** for re-review.
6. Posters can see each post's status (**Pending, Approved, Rejected**) in **My Adoption Posts**.

**What the admin checks:**
- Real and clear photos of the animal (not taken from the internet)
- Complete information: age, sex, health status, and location
- No selling, prices, or fees (a common sign of scams)
- Valid contact details, and not a duplicate of a rejected post
- The animal's described condition and care are acceptable

**Common rejection reasons:** unclear or suspicious photos, incomplete information, selling or asking for fees, duplicate post, or inappropriate content.

**Extra protection after approval:** users can still tap **Report Post** on an approved post. The report goes to **Reported Content**, where the admin can dismiss it or remove the post.

Code changes involved:
- `screens/admin/admin_posts_screen.dart`: the Reject dialog currently only asks for confirmation. Add a **required rejection reason** (a dropdown of common reasons plus an optional note).
- `services/adoption_service.dart`: include the rejection reason in the *"Post not approved"* notification and in My Adoption Posts.
- Documentation: replace *"published directly without prior admin approval"* with the pre-approval flow above, and remove *"Admin approval of every submitted adoption post"* from the excluded features.

### 6. Rescued Strays First in Adoption
Pet owners can still post pets for rehoming, but **rescued stray animals are the priority**.

- **New "Pet Source" field** in the Post a Pet form:
    - **Rescued Stray**: an animal rescued from the street (can be linked to a stray report marked *Rescued*)
    - **Owned Pet (Rehoming)**: a pet the owner can no longer care for; a **reason for rehoming is required**
- **Badges** on adoption cards and the Animal Profile: **Rescued Stray** (highlighted) and **Rehoming**
- **Rescued Strays are shown first** in the Adoption Bulletin
- **Extra filter row:** All / Rescued Strays / Rehoming (works together with Dogs / Cats / All Pets)
- **Rules:** no selling, no prices or fees, and no breeding or "for stud" posts. Posts that break the rules are rejected during admin review, or reported and removed if already approved.

### 7. Possible Lost Pets
A reported "stray" may actually be someone's lost pet.
- Add a **"Has a collar / looks like someone's pet"** checkbox to the report form.
- Reports with this checked show a **"Possibly a lost pet"** tag, reminding responders not to take the animal home right away and to ask around or check with the barangay first.

### 8. Adopter and Poster Verification
We will **not** require uploading a valid ID in the app, because government IDs are sensitive personal information under the **Data Privacy Act of 2012 (RA 10173)** and need secure storage, consent, and limited access.
- **Adopters:** a required checkbox in the application: *"I agree to present a valid ID during the in-person meet-up or turnover."* The ID is checked in person, so no ID is stored in the app.
- **Posters:** verified email or phone number, a profile photo, and the existing *Report Post* feature.

### 9. UI Redesign: "Sunset Paws" Palette
The navy and blue UI is replaced with a warm **Sunset Paws** palette. The layout of every screen stays the same; only the colors change.

| Role | Color |
|---|---|
| Text, headings, main dark buttons | Cocoa brown `#3D2C29` |
| Buttons, selected chips, links, icons | Dark orange `#C4531F` (white text is readable on it) |
| Banners and the drawer header | Orange gradient `#E0662E` → `#F59E5B` |
| Page background | Cream `#FFF6EC` |
| Icon circles, soft fills | Peach `#FFE8D6` |
| Cards and panels | Warm white `#FFFCF8` (`kCardColor`) with a `#F5DEC8` border and a soft warm shadow |
| Secondary accent, *Sighted* and *In Progress* | Teal `#2BA59A` |
| *Urgent* / *Needs Help* / *Rescued* | `#E04F4F` / `#E9A23B` / `#4CAF6E` |

- The colors live in `utils/app_colors.dart` and `utils/report_style.dart`. The old names (`kNavy`, `kBlue`, ...) are kept so every screen picks up the new colors.
- The same card style is used on every page, and peach is used for small highlights (chips, unread notifications, info boxes).
- The logo (cocoa brown), Welcome background, and Home banner images were recolored. Home shows the card area of `home_banner.png`, and the Admin Dashboard crops the row of paws from the same image. If the image size changes, update the crop numbers in `home.dart` (`_HomeBanner`) and `admin_dashboard.dart` (`_PawStrip`).
- The default profile picture is now an icon, so the unused `avatar.png`, `adopt_icon.png`, and `report_icon.png` were removed.
- Screenshots in the documentation will be updated to match the final app (for example, the Adopt a Pet screen has no back arrow because it is a tab, and its default filter is *All Pets*).

### 10. One-Page Forms
*Report a Stray*, *Post a Pet* (and *Edit Post*), and *Adoption Application* are now **one scrolling page** instead of 3–4 steps, with the main button always visible at the bottom.
- **Report a Stray:** no review step, so reporting is fast. The location uses a small **map preview** with *Use my location* and *Pin on map* (a full-screen map), so dragging the map never fights with scrolling the form.
- **Post a Pet and Adoption Application:** the review step is replaced by a **short confirmation dialog** that shows the key details (name, location, and contact details) with *Edit* and *Publish/Submit*.
- If something is missing, the form shows the error and **scrolls to the first section that needs fixing**.

### 11. Required Field Markers
Required fields have a red **`*`** (`widgets/field_label.dart`), and each long form starts with *"Fields marked with \* are required."* Optional fields still say *(optional)*. Fields in the Login, Sign Up, and Verified Rescuer forms get the `*` automatically when they have a validator.

### 12. Place Names for Pinned Locations
The `geocoding` package only works on Android and iOS, so in Chrome the address showed as coordinates. On the web (and whenever geocoding fails on a phone), the address is now looked up with **OpenStreetMap Nominatim** using the `http` package, e.g. *"P. Burgos St, Poblacion, Batangas City, Batangas"*.

### 13. Responsive Layout
- Page padding adapts to the screen width: **16 dp** on small phones (< 360 dp), **20 dp** on regular phones, and **24 dp** on large phones and tablets (≥ 400 dp), through `context.hPad` (`utils/responsive.dart`).
- On tablets and wide screens, the app is centered at **600 dp**.
- System font scaling is capped at **1.3×** so fixed-height layouts don't overflow.
- The Adoption Bulletin shows 2 columns on phones and 3 on wider screens.

### 14. Package Name and Code Cleanup
- The package was renamed from `paw_kie` to **`pawnder`**, and the Android app label to **Pawnder**.
- Comments were cleaned up (English only, no outdated notes), and `flutter analyze` reports no issues (deprecated `withOpacity`, `__` parameters, and radio `groupValue` were updated).

---

## 🗄 Next Step: Supabase Backend

The backend will use **Supabase** for everything, replacing the in-memory services one by one. The screens already go through services (`AuthService`, `ReportService`, `AdoptionService`, `ResponseService`, ...), so mainly the services change.

| Supabase feature | Used for |
|---|---|
| **Auth** | Sign up, login, forgot password, and roles (user, Verified Rescuer, admin) |
| **Database (Postgres)** | Reports, responders and check-ins, adoption posts, applications, content reports, rescuer applications, notifications |
| **Storage** | Report photos, pet photos, and profile pictures |
| **Row Level Security** | Users can only change their own data; admins review posts and applications |

**Planned order:** setup and Auth → reports (so new reports appear in the Bulletin and Map) → Check-in Flow and rescue records → adoption posts and applications → notifications and Verified Rescuers → security rules.

---

## 🔮 Future Enhancements

- **Auto-timeout for responders**: if a responder does not check in within a set time, they are removed and the report returns to *Needs Rescue* (needs a backend or background job)
- **Photo proof** when marking an animal as rescued
- **Lost & Found** section for lost pets
- **Optional ID verification** with a *Verified* badge, stored securely and visible only to admins, in compliance with the Data Privacy Act
- **Push notifications** and nearby alerts
- **Dark mode** support for all screens

---

## ⚠️ Known Limitations

- **Submitting a report does not guarantee immediate rescue or assistance.**
- **Stray vs. lost pet:** Pawnder cannot confirm whether a reported animal is a stray or someone's lost pet. The *"Possibly a lost pet"* tag only depends on what the reporter sees.
- **GPS spoofing:** the ~200 m check-in can be bypassed with mock-location apps.
- **No real backend yet:** accounts and data are stored in memory and reset when the app restarts (Supabase is the next step).
- **Reports submitted in the app don't appear in the Bulletin or Map yet:** they are saved in a separate in-memory list until the Supabase backend is added.
- **Free address lookup:** OpenStreetMap Nominatim allows about 1 request per second, which is enough for testing but not for a public release.
- **Demo admin account:** the admin credentials are hardcoded for development only.
- **Partner organization:** Strays Worth Saving is a proposed partner only and has not been contacted.
- **Rescuer verification depends on the admin:** Verified Rescuer applications are checked manually by the partner organization, so approval is not instant.
- **Platforms:** developed for Android; Chrome (web) is used for testing.

---

## 📚 References

- Cebu Daily News. (2025). *"Willing to adopt": Puppies, kittens used as food in reptile facilities.* https://cebudailynews.inquirer.net/624809/willing-to-adopt-puppies-kittens-used-as-food-in-reptile-facilities
- Interaksyon. (2024). *Public urged to provide temporary shelter for stray animals.* https://interaksyon.philstar.com/trends-spotlights/2024/07/23/280154/public-urged-provide-temporary-shelter-stray-animals/
- Philippine Daily Inquirer. (2022). *Saving the homeless: How stray animals struggle to find homes amid pandemic.* https://newsinfo.inquirer.net/1646978/saving-the-homeless-how-stray-animals-struggle-to-find-homes-amid-pandemic
- Strays Worth Saving. https://swsph.org/