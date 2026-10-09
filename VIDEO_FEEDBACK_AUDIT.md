# October 03 recording cross-check

Reviewed and updated: 09 October 2026.

Source: [Mobile app feedbacks recording](https://fathom.video/share/xKoSroVkY8W3Q_ED4JS7x_NzBzqVjxMh).

The public recording page exposed its full transcript, which was read and compared with Flutter and local backend source. The player reported **Unable to play media**, including after reload, and exposed no downloadable video asset. This is a transcript/code audit, not a visual review of the 81-minute video or a live acceptance test.

The initial audit identified missing app work. The table now includes the subsequent app-only implementation. “Implemented locally” means source and automated verification; deployment/live acceptance are separate. Full results and dependencies: [MOBILE_FEEDBACK_STATUS.md](MOBILE_FEEDBACK_STATUS.md).

## Transcript requirements and current status

| Requirement | App result / remaining work |
| --- | --- |
| Automatic email on repair completion | Backend already sends a completion email, status PDF and tracking link. Live delivery remains unverified. Attachment still differs from the selected invoice theme/QR. |
| Correct currency in repair emails | **Backend remaining:** email.templates.ts and repairPdf.service.ts hardcode dollars. App-generated PDFs now use shop currency. |
| Correct stage ticks / stuck spinner | **App implemented:** actual order-assigned status and assignment/diagnosis/quote/repair/waiting/terminal mapping; no endless stage loading animation. Backend workflow eligibility remains unchanged. |
| Parts-only picker / reusable Add New Part | **App implemented:** category/name/marker filtering, reusable zero-stock catalog creation, repair-only typed entry and save/error handling through existing inventory APIs. Staging catalog verification remains. |
| Previous invoices / Pay All / Today Only | **App implemented:** expandable individual bills, payment choice and old-invoice allocation payload separate from today's invoice total. Failure/cancellation/currency guards and two-decimal totals covered by tests. Backend stale/overpaid allocation validation and real transaction verification remain. |
| Repair customer/device/IMEI search with scanner | **App implemented:** lookup across older repair pages; home scan opens unified search, not just newest loaded repairs. Existing APIs require client traversal for search. |
| Transaction View All exposes old records | **App implemented:** both actions open full history, incremental rendering, customer/device/IMEI/reference search, scanner, method filters, retry and refresh. Backend returns all invoices rather than a paged search API. |
| Small receipt printing alongside PDF | **App implemented:** 80 mm receipt option on sales/checkout, purchase and repair; original PDF preserved. Old records without line prices provide a payment summary. Real printer checks remain. |
| Customer phone/email on transaction details | Implemented for records containing contact fields; older/live data verification remains. |
| Rename collection panel Orders | **App implemented.** Website source/change remains. |
| Orange bell for unseen/remaining orders | **App implemented:** remaining-order count badge on Orders; paged list and resume/commerce refresh. Does not claim persisted unread/acknowledgement state. |
| Previously checked notice / Generate New at top | **App implemented:** history/cache notice and top re-scan action, retaining charge confirmation. Fresh reports identify their check time. |
| Manage Stock lookup by UPC | **App implemented:** SKU plus UPC/barcode aliases and existing product/IMEI code search. A dedicated server UPC field depends on the API. |
| Old phone receives new-device approval | **Backend remaining:** server pending sign-in, trusted-device delivery, approval decision and token enforcement. App's own-device confirmation now requires registration acknowledgement and is worded accurately. Device removal also requires server acknowledgement; token/session revocation still needs backend enforcement. |
| Staff management unavailable to acting staff | Local owner/staff context guards exist; deployed permissions must be verified. |
| Page called ugly near Shop ID/review discussion | **Unverified:** transcript does not identify the exact visible page. Needs recording frames/reference before an accurate redesign. QR export is fixed separately. |
| ScorePlus supplied icon / manual review requests | Manual app Email/SMS/WhatsApp actions exist. Supplied artwork and website implementation remain. Review QR and invoice tracking QR are separate purposes. |
| Extra printer permission screen | Withdrawn in the discussion; no custom permission screen required. OS/printer compatibility remains untested. |

## Original summary requirements

| Area | Current local status / limit |
| --- | --- |
| Performance and camera | Lazy retained pages, concurrent dashboard requests and serialized scanner lifecycle. Real-device benchmarks remain. |
| Charge / collection completion | Cash/Card confirmation saves a paid invoice tied to the repair and refreshes screens. One repair per payment; real terminal charging is external. |
| Refund / Exchange | Missing supported financial/stock reversal endpoints and policy. |
| Multiple issues / customer history | Multiple repair issue fields and returning-customer/device suggestions exist. |
| Email / WhatsApp / SMS / Print | App actions, new PDF tracking QR/link and immediate checkout email tracking argument implemented. Updated email backend deployment remains. |
| Invoice theme / partial payment | Selected theme on new app invoices; all six themes show actual paid/due amounts. Old saved PDFs are unchanged; server completion attachments follow their separate template. |
| Purchase invoices | PDF and 80 mm receipt printing available; native printer behavior needs verification. |
| Staff PIN / served by | Owner-authenticated PIN context and server-recorded actor implemented locally in earlier work. Coordinated deployment and website changes remain. |
| Stock permissions / quantity | Restricted general Add/Edit actions, supplier access and variation adjustment exist. Server atomic adjustment remains. |
| Reports | Invoice/history/device search and scanner exist; customer associations and server paging/search determine coverage and scale. |
| Certificate | Draft disclaimer fits; replacement logo and confirmed final wording remain. |
| Authenticator | Server-confirmed setup/verification and device acknowledgements exist. Server pending-2FA/token enforcement, SMS integration and live testing remain. |

## Remaining work order

1. Deploy app/backend together to staging and verify collection, Pay All allocations, parts persistence and PIN/session behavior with real database records.
2. Correct backend repair-email currency and selected invoice/QR attachment parity; add allocation/concurrent stock safeguards and Refund/Exchange contracts.
3. Implement trusted-device approval, pending-2FA/token enforcement and effective device/session revocation; configure SMS and verify Authenticator.
4. Complete website changes and obtain supplied logo/ScorePlus artwork plus recording frames for the unidentified design issue.
5. Perform physical-device camera/performance, printer, live delivery and paid re-scan acceptance checks.

The latest pass changed app code and these documents only. Existing local backend changes were preserved. No production deployment or live customer payment/message/stock mutation was performed.
