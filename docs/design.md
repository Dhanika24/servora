# Mobile design
Customer journey: home → service request → my jobs → ranked discovery → comparison and profile → quotations → accepted job → review. Roadside assistance preselects Mechanic and flags the request as urgent. Provider journey: home → service profile → matching open requests → quotation → assigned jobs → start → result → portfolio and performance.

| Firestore path | Owns |
| --- | --- |
| members/{uid} | Role and display name |
| providers/{uid} | Service, town, coordinates, availability, starting rate, experience, performance totals and level |
| jobs/{id} | Customer, service requirements, budget, location, emergency flag, selected quote, status, completion and customer confirmation |
| jobs/{id}/quotes/{uid} | One editable quote per provider including amount, terms and promised turnaround |
| providers/{uid}/work/{job} | Customer-reviewed result and consented portfolio image |
| devices/{uid} | Private notification token |

Ranking uses a content-based recommender. Filter by service and availability, then score candidates using budget fit, GPS distance, smoothed ratings, response and completion history, verified work and level. The selected priority adds weight to budget, proximity or quality. New providers start with a smoothed rating. The quality estimate uses nearest-neighbour regression on the three closest past job budgets in log space. It weights their customer ratings by similarity and blends them with the smoothed provider average. The server retains up to 30 reviewed examples per provider. New providers use the smoothed prior. The final multi-factor weights are hand-set. Test two different preferences with deliberately different provider strengths and record when the order changes. Rates in discovery are starting prices. Quotes on the request are the binding amounts.

Suggested policy for the demonstration: 10 points per confirmed job, 5 for at least four stars, 4 for on-time completion, 3 for a first quote within one hour and 3 for a customer-approved result photo. At 50 and 120 points the service fee for subsequent jobs falls from 10% to 8% and 5%. Level adds a small ranking bonus. Customer confirmation runs in one transaction and cannot award points twice. The fee is recorded as a calculation only.

## Integration acceptance checks
1. A customer cannot submit a provider quote or start another user's job. Two concurrent accept attempts yield one winner.
2. An unavailable electrician cannot quote for a plumbing request. Quote revisions retain the original response timestamp.
3. A provider cannot review their own work. A second review does not change points. Denied image consent leaves the portfolio photo empty.
4. Sign out and use a different device to verify data persistence. Check FCM while the recipient's app is in the background.
5. Run the same workflow in portrait and landscape, with permission denied, on a small screen, after reconnecting and with no matching providers.
6. Use sample or consented images only. Document actual results, defects, fixes and device configuration in the final report.
