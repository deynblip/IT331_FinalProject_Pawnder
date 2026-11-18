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
- [Planned Changes](#-planned-changes)
- [Future Enhancements](#-future-enhancements)
- [Known Limitations](#-known-limitations)
- [References](#-references)

---

## 👥 Team

**Group 2**

- Aninon, Shanea May B.
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
5. Provide an administrator dashboard for reviewing reported content and monitoring platform activity.

---

## 🧑‍🤝‍🧑 Target Users

| User | Description |
|---|---|
| **Community members** | Report stray animals and help in rescue situations |
| **Pet owners and rescuers** | Post animals for adoption to find them new homes |
| **Potential adopters** | Browse available pets and submit adoption applications |
| **Verified Rescuers** *(planned)* | Members of rescue organizations, vets, or LGU animal welfare offices who are verified by the admin and get extra rescue permissions |
| **Administrators** | Screen adoption applications, review reported content, approve Verified Rescuer applications, and send status updates |

---

## ✨ Current Features

### Regular users
- **Landing page and authentication**: Sign In and Create Account
- **Home Dashboard**: welcome message, quick *Report a Stray* action, nearby reports preview, safety guidelines, side drawer, and notification bell
- **Animal Reporting**: 3-step form (photo + type + urgency + description → location pin → review and submit)
- **Map and Nearby Reports**: color-coded pins, distance filters (5 km, 10 km, 20 km, All), report previews, and directions through Google Maps
- **Reports Bulletin and Report Details**: filter by urgency, full report info, responder count, and *Get Directions*
- **Rescue response**: *I'm on my way!* and *Mark as Rescued* (Needs Rescue → Rescue in Progress → Rescued)
- **Adoption Bulletin and Animal Profile**: filter by Dogs, Cats, or All Pets; *Apply to Adopt* and *Report Post*
- **Post a Pet for Adoption**: 4-step form; posters can edit or remove their own posts
- **Adoption Application**: applicant info, living environment, pet ownership experience, and reason for applying
- **Profile and My Activity**: My Reports, Adoption Applications, and My Adoption Posts (posters can accept or decline forwarded applications)
- **Side drawer**: Help & Support, About, Settings, Terms & Conditions, Privacy Policy, Sign Out

### Administrators
- **Admin Dashboard**: counts of adoption posts, applications, reported content, and registered users
- **Adoption Posts Management**: view, search, filter, and remove posts
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
| Location | `geolocator`, `geocoding` |
| Device features | `image_picker` (camera and gallery), `url_launcher` (maps and contact options) |
| UI design | Canva |
| Data | In-memory mock data and services (temporary, no backend yet) |

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

> ⚠️ **For demo purposes only.** Accounts and data are stored in memory and reset every time the app restarts. The admin password is hardcoded and will be replaced once a real backend (for example, Firebase Auth with an admin role) is added.

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
├── utils/                    # Colors, styles, validators, theme controller
└── widgets/                  # Reusable widgets (cards, chips, auth fields, ...)
```

---

## 🔧 Planned Changes

These are the changes we plan to make to the current version of the app.

### 1. Responder Check-in Flow
Right now, *I'm on my way!* only adds +1 to the responder count, and anyone can mark a report as rescued. To make rescue responses more trustworthy, we will use the device's GPS (`geolocator`, already used in `report_stray.dart`) so responders must physically reach the animal.

1. **I'm on my way!** The user is saved as a responder (by user ID, not just +1 to the count). Each user can have **only one active response at a time**, and cannot press the button again on the same report.
2. **I've Arrived.** This button only works when the user's GPS is within **~200 m of the report's pin**. After checking in, the report shows **"Responder on site."**
3. **Cancel / I can't make it.** A responder can withdraw. If **all** responders withdraw, the report goes back to **Needs Rescue**.
4. **Mark as Rescued.** Only the **original reporter** or a **responder who has checked in** can mark the animal as rescued.

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
- **On the report:** the list of responders with their record, for example *"Juan D. · 8 rescues"* or *"Maria S. · Verified Rescuer · Strays Worth Saving · 25 rescues."*
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

> No ID or document is uploaded in the app. The admin verifies the user through the organization itself, in line with the privacy approach in [Adopter and Poster Verification](#8-adopter-and-poster-verification-proposed).

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
- Pawnder will only partner with rescue groups that **rehome** animals rather than euthanize them. Rescued animals are directed to fosters, shelters, or the Adoption Bulletin.

### 5. Adoption Post Moderation: Post-moderation
New adoption posts are **published directly** to the Adoption Bulletin **without prior admin approval**. Admins only review posts that users **report**.

**Flow:**
1. A user posts a pet → it appears in the Adoption Bulletin right away.
2. Another user taps **Report Post** and picks a reason (scam, misleading, inappropriate, ...).
3. The report goes to the admin's **Reported Content** section.
4. The admin opens the report, then:
   - **Dismiss** → the post stays up, or
   - **Remove** → the post is taken down and the poster is notified with a reason.

**What the admin checks:** real and clear photos, complete information, no selling or fees, valid contact details, no duplicate posts, and no signs of scams.

The current code still uses **pre-approval**, so it will be updated:
- `services/adoption_service.dart`: new posts are published immediately (not `PostStatus.pending`), and edits do not send posts back to review
- `screens/adopt.dart`: show all published posts, not only approved ones
- `screens/admin/admin_posts_screen.dart`: remove Approve/Reject and the Pending/Approved/Rejected tabs; keep View and Remove
- Notifications: replace "post approved/rejected" with "post removed by admin"
- My Adoption Posts: replace the Pending/Approved/Rejected status with Active/Removed
- Documentation: remove "Listing Status: Pending, Approved, or Rejected" and admin "Approve / Reject" from the screen descriptions

### 6. Rescued Strays First in Adoption
Pet owners can still post pets for rehoming, but **rescued stray animals are the priority**.

- **New "Pet Source" field** in the Post a Pet form:
  - **Rescued Stray**: an animal rescued from the street (can be linked to a stray report marked *Rescued*)
  - **Owned Pet (Rehoming)**: a pet the owner can no longer care for; a **reason for rehoming is required**
- **Badges** on adoption cards and the Animal Profile: **Rescued Stray** (highlighted) and **Rehoming**
- **Rescued Strays are shown first** in the Adoption Bulletin
- **Extra filter row:** All / Rescued Strays / Rehoming (works together with Dogs / Cats / All Pets)
- **Rules:** no selling, no prices or fees, and no breeding or "for stud" posts. Posts that break the rules can be reported and removed.

### 7. Possible Lost Pets *(proposed)*
A reported "stray" may actually be someone's lost pet.
- Add a **"Has a collar / looks like someone's pet"** checkbox to the report form.
- Reports with this checked show a **"Possibly a lost pet"** tag, reminding responders not to take the animal home right away and to ask around or check with the barangay first.

### 8. Adopter and Poster Verification *(proposed)*
We will **not** require uploading a valid ID in the app, because government IDs are sensitive personal information under the **Data Privacy Act of 2012 (RA 10173)** and need secure storage, consent, and limited access.
- **Adopters:** a required checkbox in the application: *"I agree to present a valid ID during the in-person meet-up or turnover."* The ID is checked in person, so no ID is stored in the app.
- **Posters:** verified email or phone number, a profile photo, and the existing *Report Post* feature.

### 9. UI Redesign
The current UI (mostly navy and blue) will be **updated and replaced**. The new color palette and layout are still being finalized. Screenshots in the documentation will be updated to match the final app (for example, the Adopt a Pet screen has no back arrow because it is a tab, and its default filter is *All Pets*).

---

## 🔮 Future Enhancements

- **Auto-timeout for responders**: if a responder does not check in within a set time, they are removed and the report returns to *Needs Rescue* (needs a backend or background job)
- **Photo proof** when marking an animal as rescued
- **Lost & Found** section for lost pets
- **Optional ID verification** with a *Verified* badge, stored securely and visible only to admins, in compliance with the Data Privacy Act
- **Backend integration** (authentication, database, and image storage) to replace the in-memory mock data
- **Push notifications** and nearby alerts
- **Dark mode** support for all screens

---

## ⚠️ Known Limitations

- **Submitting a report does not guarantee immediate rescue or assistance.**
- **Stray vs. lost pet:** Pawnder cannot confirm whether a reported animal is a stray or someone's lost pet.
- **GPS spoofing:** the ~200 m check-in can be bypassed with mock-location apps.
- **No real backend yet:** accounts and data are stored in memory and reset when the app restarts.
- **Demo admin account:** the admin credentials are hardcoded for development only.
- **Partner organization:** Strays Worth Saving is a proposed partner only and has not been contacted.
- **Rescuer verification depends on the admin:** Verified Rescuer applications are checked manually by the partner organization, so approval is not instant.
- **Android only:** the app has been developed and tested for Android.

---

## 📚 References

- Cebu Daily News. (2025). *"Willing to adopt": Puppies, kittens used as food in reptile facilities.* https://cebudailynews.inquirer.net/624809/willing-to-adopt-puppies-kittens-used-as-food-in-reptile-facilities
- Interaksyon. (2024). *Public urged to provide temporary shelter for stray animals.* https://interaksyon.philstar.com/trends-spotlights/2024/07/23/280154/public-urged-provide-temporary-shelter-stray-animals/
- Philippine Daily Inquirer. (2022). *Saving the homeless: How stray animals struggle to find homes amid pandemic.* https://newsinfo.inquirer.net/1646978/saving-the-homeless-how-stray-animals-struggle-to-find-homes-amid-pandemic
- Strays Worth Saving. https://swsph.org/
