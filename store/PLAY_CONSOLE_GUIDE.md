# Liar's Level: Google Play Console guide (answers to every questionnaire)

Package name: `com.dhoola.liarslevel` | Version: 1.0.0 (code 1) | AdMob + Play Billing
Files you upload: `build/LiarsLevel-release.aab`, `store/play_store_icon_512.png`, `store/feature_graphic_1024x500.png`, `store/screenshots/*.png`
Text to paste: `store/STORE_LISTING.md` | Policy to host: `store/PRIVACY_POLICY.md`

Note: Google changes the forms from time to time. If a question below is worded a little differently on screen, use the same intent.
I could not log in to your accounts, so none of this was submitted for you.

---
## 0. Before you start (do these once)
1. **Back up the signing key**: copy the whole folder `C:\Users\user\LiarsLevel_release_key` (keystore + KEY_INFO_KEEP_SAFE.txt) to a USB drive and cloud storage. Never put it in the game folder or a public repo.
2. **Privacy policy URL** (already hosted): https://mrcarkstudios-lang.github.io/liars-level/privacy.html . Its contact is the repo's GitHub Issues page. Play Console still asks for a developer/support email in the store settings; enter the one you want shown.
3. **AdMob**: in admob.google.com open your app "Liar's Level" (App ID ending ~6155036657). Under **Privacy & messaging** create a **GDPR message** (and a US states message if you want) and publish it. Without it, players in Europe/UK get no ads.
4. After the app is published on Google Play, in AdMob > App settings > **link the app to its Play Store listing**. Real ads only start flowing after that.

---
## 1. Create the app (Play Console > Create app)
| Field | Answer |
|---|---|
| App name | Liar's Level |
| Default language | English (United States) |
| App or game | **Game** |
| Free or paid | **Free** |
| Declarations | Tick both (developer program policies, US export laws) |

---
## 2. Set up your app (Dashboard tasks)
### 2.1 Privacy policy
Paste https://mrcarkstudios-lang.github.io/liars-level/privacy.html

### 2.2 App access
**All functionality is available without special access** (no login).

### 2.3 Ads
**Yes, my app contains ads.**

### 2.4 Content rating (IARC questionnaire)
Email: your email. Category: **Game**. Answers:
- Violence: the hero is "killed" by spikes/saws with no blood, cartoon pixel style. Answer **No realistic violence, no blood, no gore**. If a question asks about "fantasy/cartoon violence" answer **Yes, mild, no blood**.
- Sexuality / nudity: **No**
- Profanity / crude humour: **No**
- Controlled substances (drugs, alcohol, tobacco): **No**
- Gambling or simulated gambling: **No**
- Fear / horror themes: **No**
- User-generated content / user interaction / chat: **No**
- Shares user location: **No**
- Allows purchases of digital goods: **Yes** (one-time Remove Ads)
- Unrestricted web access: **No**
Expected result: IARC **3+** / ESRB **Everyone** / PEGI **3** (a mild-cartoon-violence answer may give PEGI 7).

### 2.5 Target audience and content
- Target age groups: tick **13-15, 16-17, 18 and over**. Do **not** tick any under-13 group.
  (If you tick under-13 groups Google applies the Families policy, which restricts ads and requires certified ad SDKs.)
- Does the app appeal to children? **No** (pixel art with a cartoon mascot can look childish; if Google asks, say it is a casual game for teens and adults).

### 2.6 News app: **No**
### 2.7 COVID-19 contact tracing / status apps: **No**
### 2.8 Data safety (see section 4)
### 2.9 Government apps: **No**
### 2.10 Financial features: **No**
### 2.11 Health apps: **No**
### 2.12 Advertising ID declaration
"Does your app use the advertising ID?" **Yes**. Purpose: **Advertising or marketing**.
(The AdMob plugin adds the `com.google.android.gms.permission.AD_ID` permission. Declaring Yes matches that.)

---
## 3. Store presence
### 3.1 Main store listing
Copy from `store/STORE_LISTING.md`.
- App icon: `store/play_store_icon_512.png`
- Feature graphic: `store/feature_graphic_1024x500.png`
- Phone screenshots (2 to 8): the files in `store/screenshots/` (1920x1050 landscape)
- 7-inch and 10-inch tablet screenshots: optional; you can upload the same files
- Category: Game > Arcade. Contact email: your public support email. Privacy policy: the hosted URL.

### 3.2 Pricing and distribution
Free. Pick countries (all is fine). Contains ads: Yes. Content guidelines and US export laws: tick.

---
## 4. Data safety form
**Does your app collect or share any of the required user data types?** Yes (through the Google AdMob SDK).
**Is all of the user data collected by your app encrypted in transit?** Yes.
**Do you provide a way for users to request that their data be deleted?** No. (We store no account data; game progress stays on the device and is removed by uninstalling or clearing app storage.)

Data types. For each, "Collected" = Yes, "Shared" = Yes (with Google as the ad provider), "Processed ephemerally" = No, "Required or optional" = **Required**, purpose = **Advertising or marketing** (and **Analytics** only where noted):
| Category > Type | Collected | Shared | Purpose |
|---|---|---|---|
| Location > Approximate location | Yes | Yes | Advertising or marketing |
| App activity > App interactions | Yes | Yes | Advertising or marketing, Analytics |
| App info and performance > Crash logs | Yes | Yes | Analytics |
| App info and performance > Diagnostics | Yes | Yes | Analytics |
| Device or other IDs > Device or other IDs (advertising ID) | Yes | Yes | Advertising or marketing |

Everything else (personal info, financial info, health, messages, photos, audio, files, calendar, contacts, web browsing, search history): **No**.
Purchases are handled by Google Play Billing; you do not collect payment info.
Before submitting, compare with Google's current page "Google Mobile Ads SDK data disclosure" (search that title) and add any type it lists.

---
## 5. In-app product (Monetise with Play > Products > In-app products)
| Field | Value |
|---|---|
| Product ID | `remove_ads` (exactly this; the game looks for it) |
| Name | Remove Ads |
| Description | Removes full-screen ads between levels. Optional rewarded ads stay available. |
| Price | for example 2.99 USD (set local prices) |
| Status | **Active** |
Purchases only work in builds installed from Google Play (internal/closed testing is fine), not via adb.

---
## 6. Upload and test
1. **Test and release > Testing > Internal testing > Create release**. Accept **Play App Signing** when asked. Upload `build/LiarsLevel-release.aab`. Release name `1.0.0 (1)`. Paste the release notes. Add yourself as tester (email list) and install from the opt-in link.
2. On your phone check: intro, menu, a few levels, rewarded skip/hint, an interstitial after 3 clears, the Remove Ads purchase (add your Google account under Setup > License testing so you are not charged).
3. **Closed testing**: personal developer accounts created after November 2023 must run a closed test with **at least 12 testers opted in for 14 days** before applying for production access. Create a Google Group with 12+ testers, add it to a closed track and upload the same AAB.
4. After the 14 days, **Apply for production**, answer the short questionnaire (how testing went) and publish.
5. Every later update needs a **higher version code** (Project > Export preset "Android Release" > Version Code) and the same upload key.

---
## 7. Ads safety rules
- Do **not** click your own live ads or ask friends to. Google can ban the AdMob account. Debug builds use Google's test ads; the release build uses your real ad units.
- While testing the release build, add your phone as a test device in AdMob (Settings > Test devices).

## 8. What is NOT finished
- Nothing could be tested on a Google-signed build before upload. Billing and live ads can only be verified once the app is on an internal testing track.
- The first install of a newly created AdMob unit can take a few hours to serve ads.
- The privacy policy, support email and public URL are yours to add.
