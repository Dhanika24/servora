# Servora team work allocation

Group 50 · SE303.3 Mobile Application Development · Six members

The coursework assesses individual commit history and each student's ability to explain their contribution. Each person should work using their own GitHub account, keep their changes on their assigned branch, and open a pull request for review. Record actual work and GitHub usernames in the final report. The assignments below are proposed from the submitted project proposal. The team should confirm owners together.

## Member 1 — LBMHA Bandara
**Area:** Accounts and Android setup  
**Branch:** `feature/accounts`

- Set up the Firebase project, Email/Password authentication, and Android app configuration.
- Complete customer and provider registration, sign-in, sign-out, and role-based navigation.
- Document setup steps and test a clean install on an Android emulator or phone.
- Coordinate changes to shared Firebase configuration with the integration owner.

**Done when:** A new user can create an account, select a role, sign out, and sign back in on Android.

## Member 2 — PHDN De Silva
**Area:** Customer requests and location  
**Branch:** `feature/requests`

- Build the service request form with category, title, problem description, area, budget, and optional image.
- Add location permission handling and manual coordinate entry when permission is declined.
- Implement the urgent mechanic request with an optional problem image.
- Test form validation, image size limits, and missing location input.

**Done when:** A customer can submit a normal request and an urgent mechanic request. The request appears for providers in the matching category.

## Member 3 — SMCN Samarakoon
**Area:** Provider discovery and comparison  
**Branch:** `feature/discovery`

- Build the provider search and profile screens.
- Implement ranking based on service match, distance, price fit, ratings, experience, completed work, response history, verified results, and provider level.
- Add customer priority selection and comparison of two providers.
- Explain the ranking inputs and test that changing priority can change provider order.

**Done when:** A customer can see matching available providers, change the ranking priority, compare two profiles, and view ratings and portfolio work.

## Member 4 — KH Godage
**Area:** Provider requests and quotations  
**Branch:** `feature/quotes`

- Build the provider inbox for open tasks in the provider's service category.
- Add quote creation and editing with amount, turnaround time, and included work.
- Show quotations to the customer and let the customer accept one.
- Ensure only the assigned provider can progress the booked job.

**Done when:** Two eligible providers can submit quotations and the customer can choose one. The job has only one accepted provider.

## Member 5 — GCD Weerasuriya
**Area:** Completion, reviews, and provider benefits  
**Branch:** `feature/performance`

- Build the work completion and customer review screens.
- Record customer rating and feedback after work is submitted.
- Update performance points, Bronze/Silver/Gold levels, and corresponding platform fee rates.
- Add completed work to the provider portfolio only when the customer grants photo consent.

**Done when:** A reviewed job updates the provider's history and performance once. A denied photo consent keeps that image out of the portfolio.

## Member 6 — HS Hansani
**Area:** Integration, notifications, and demonstration  
**Branch:** `feature/integration`

- Coordinate shared Firestore fields and callable action names with all feature owners.
- Connect Firebase Cloud Messaging and test job status notifications on two devices.
- Run integration checks for sign-in, task creation, discovery, quotations, completion, and review.
- Track defects, verify fixes, prepare demonstration steps, and collect evidence for the report.

**Done when:** The complete customer-to-provider journey works across two accounts on separate devices, and the team has a repeatable demo checklist.

## Shared working agreement

1. Each member creates their branch from the agreed integration branch and commits only their own work.
2. Before coding, agree on Firestore field names and callable action names in `docs/design.md`.
3. Open a pull request for each feature and ask another member to review it.
4. Resolve integration issues together. Keep the default branch buildable.
5. Test the merged journey on Android and write down actual results and issues.
6. In the report, list each student's GitHub username, commits, feature, tests, and explanation of their contribution. Do not claim work that the commit history and demonstration cannot support.
