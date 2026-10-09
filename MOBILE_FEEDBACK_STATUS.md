# October 03 mobile feedback status

Updated: 09 October 2026. Latest work: Flutter app fixes using the existing APIs. Earlier local backend staff-session, invoice-email and security changes remain intact and are **not deployed**. Website source is absent. No live customer payment, message, stock adjustment or paid re-scan was made.

Recording evidence: the full Fathom transcript was compared with source code. The player returned “Unable to play media”; the 81-minute recording was not visually watched. Screen-dependent design requests remain unverified. See [VIDEO_FEEDBACK_AUDIT.md](VIDEO_FEEDBACK_AUDIT.md).

“Implemented locally” means the code and listed automated checks are complete; it does not mean production deployment or live acceptance testing is complete.

## Latest app fixes

| Feedback | Implemented locally / limit |
| --- | --- |
| Previous-invoice balance and payment | Expandable invoice references, dates and individual dues. Checkout offers Pay All or Pay Total Today Only before confirmation. Pay All sends old invoice IDs/amounts through the existing allocation API; today's invoice total stays separate. Cancel leaves the draft intact. Balance-load failure permits Today Only and retry; different explicit currencies cannot be combined. Legacy records without a currency use the shop currency. |
| Accurate payment totals / partial invoices | Monetary totals and balances use consistent two-decimal precision. Invalid quantities/non-finite or negative prices/payment amounts are rejected. All six sales invoice themes display the actual paid amount, remaining balance and PAID/PART PAID/DUE status. Repair receipts use the same discount/deposit calculation as collection checkout. |
| Repair search and scanner | All Repairs searches customer/contact/device/reference/IMEI across older API pages; debounced search, scan input, loading/retry and Load Older. Repair home scanner opens this lookup instead of searching only the newest repairs. Server-side search would improve very large histories. |
| Full transaction history | Both View All actions open All Transactions. Browsable history, search by customer/reference/device/IMEI, scanner, method filters, incremental rendering, retry and refresh. Partial payments retain paid/due values and are not labelled fully paid. Uses the existing all-invoices endpoint; server paging remains an optimization. |
| Parts Required | Picker filters handset inventory out using part categories/names/catalog markers. Add New Part persists a reusable zero-stock catalog record through the existing inventory API; a typed repair-only entry also remains available. Shows fetch/save failures and prevents duplicate save taps. Live catalog permissions/schema still need staging verification. |
| Timeline stage ticks | Assignment sends the supported order-assigned status. Assignment, diagnosis, quote approval, repair, waiting and terminal statuses map to their actual stages; active stage icon no longer runs an endless loading spinner. Existing backend collection eligibility/status rules are unchanged. |
| Compact printing | Sales/checkout, purchase and repair flows offer an 80 mm receipt alongside the original/full PDF. Includes available customer, payment, staff and tracking QR/link details. Newly created receipts retain their item snapshot after the form clears. Historical API records without item prices print a clearly labelled payment summary; original PDF remains available. System/physical printer compatibility is untested. |
| Orders panel and bell | Collection panel renamed Orders. Orange bell badge shows the number of remaining orders. Loads all completed-order pages, refreshes after commerce changes and app resume; failed refresh retains the last list with retry. The badge is a remaining-order count, not a persistent unread count. |
| Previously checked report | Cache/history notice and Generate New moved to the top. Historical reports are identified as previously checked; fresh reports show their check time. Existing charge confirmation remains before a paid re-scan. |
| Stock barcode lookup | Search includes SKU, UPC/barcode aliases returned by the API, and the existing IMEI/product-code field. No unsupported backend UPC field was introduced. |
| Immediate invoice email | Checkout now passes the separate tracking URL as well as the PDF. Real delivery depends on the earlier backend email deployment. |
| Device security acknowledgement | Device registration/removal only changes the local list after an explicit server acknowledgement; failures retain the pending/list state. Server empty device lists clear stale local entries, and current-device ID is sent on lookup. The new-device screen describes confirmation on this install; it no longer claims remote approval. Backend token revocation and trusted-device approval are still required. |

## Earlier fixes retained

| Feedback | Local implementation / limit |
| --- | --- |
| Scanner blank / controller already running | Serialized start/stop/retry/disposal, permission and lifecycle handling. Physical iPhone verification remains necessary. |
| Slow navigation / repeated requests | Lazy retained pages and concurrent dashboard requests; response/token dumps removed. Real-device performance benchmark remains. |
| Charge loops / collection queue | Cash/Card selection, payment-received confirmation, paid invoice associated with the repair, and commerce refresh. Draft clears only after successful save. Card records a payment received on a terminal. Existing API supports one repair per collection invoice. |
| Multi-issue repair / returning customers | Add/remove issue fields and customer/previous-device suggestions through existing APIs. |
| Invoice delivery / selected theme | Email, WhatsApp PDF sharing, prefilled SMS and OS printing; selected theme and tracking QR/link on new app PDFs. Saved older PDFs retain their original design. Backend automatic completion attachments use a separate format. |
| ScorePlus | Manual review request on invoices/transactions/checkout via Email, SMS or WhatsApp; no automatic review request. Supplied artwork and website implementation remain. |
| Inventory restrictions / quantity | General inventory/category Add/Edit actions hidden; Supplier and Manage Stock retained; variation quantity adjustment re-reads stock before save. Existing stock PUT is not atomic. Add New Part is specifically available inside the repair parts workflow. |
| Reports and certificate | Invoice/device report lookup and scanner, older history, re-scan action, supplied draft disclaimer and visible footer. Device-report customer-name lookup depends on API associations. Replacement logo remains absent. |
| Staff PIN / served by | Owner-authenticated four-digit PIN switching, owner-password-protected PIN management/return, secure context and invoice/PDF staff attribution. Earlier local backend hashes PINs, limits attempts and enforces expiry/context; disables standalone staff password/tokens. Deploy app/backend together and verify with staging persistence. |
| Authenticator | Server-confirmed setup/settings/challenge verification; no cached-secret bypass. Unconfigured SMS reports failure. Full pending-2FA login enforcement remains a backend requirement. |
| Other mobile fixes | Safe-area Back header for New Repair, invoice header overflow, independent QR PNG export, selectable purchase payment rows, six Recent Scans with further-drag See All. Requested button-colour changes remain undone. |

## Remaining dependencies

- **Backend deployment and live payment checks:** earlier backend changes are local. Verify PIN persistence/lock expiry, actor attribution, collection and old-invoice allocations against staging MongoDB. Existing allocation handling needs server validation of stale/overpaid/customer-mismatched allocations and response acknowledgement before production acceptance; app selection tests use mocks.
- **Repair completion email/PDF:** automatic completion email already exists, but backend email/status-PDF templates hardcode dollars and do not produce the selected invoice theme with tracking QR. These cannot be fixed by the app email button.
- **Refund / Exchange:** financial and stock reversal APIs/policies are unavailable; the app does not fabricate a reversal.
- **Security:** remote trusted-device request/push/approval, enforced pending-2FA before full token issuance, actual session-token revocation, real SMS provider and live Google Authenticator account verification remain.
- **Website:** staff-login removal/PIN settings, ScorePlus, Orders naming and other website parity require website source.
- **Inventory concurrency:** server must provide atomic stock adjustment for concurrent devices.
- **Assets / visual design:** replacement certificate logo, supplied ScorePlus icon and identifiable frames for the unclear page-design complaint are absent. Draft disclaimer still needs final wording confirmation.
- **API data:** historical itemized compact receipts require item lines/prices from the API; customer-name device-report search requires customer associations. Dedicated server history search/paging and a confirmed UPC field would improve scale/data coverage.
- **Real devices:** physical printer, camera, performance, live messaging/payment/parts catalog and paid re-scan checks remain. No server or app-store build was deployed.

## Verification

- Final full `flutter test`: **94 tests passed**.
- Final `flutter analyze`: no issues. Repository diff whitespace checks passed.
- `flutter build ios --simulator --debug --no-pub`: succeeded with the app changes. Physical-device/release/App Store testing is separate.
- Device release archive also succeeded: version 1.0.0, build 29, bundle com.majid.imoscan, team TDR6PCPA8Y. App Store IPA export failed with `PLA Update available` and missing Distribution signing identity. The Account Holder must resolve the updated Apple agreement, then distribution signing/export can be retried using the existing archive. No TestFlight upload is confirmed. The build also reports a default launch-image placeholder warning.
- Regression coverage includes Pay All vs Today Only allocation payloads, cancellation, balance-fetch failure, mixed currencies, decimal payment precision, discounted/deposit repair totals, older-page IMEI lookup, history beyond the first display batch, reusable zero-stock parts, timeline mapping and explicit device registration/removal acknowledgement.
- Six partial-payment invoice themes and two 80 mm receipt samples (2 and 40 lines) were generated/rendered. The six samples show paid 70.00 / balance 210.00. Receipt page width is 80 mm; the 40-line sample retains the final item on a continuous roll page. Tracking QR decoded to the expected URL. This is PDF verification, not a physical print.
- Earlier local backend verification: 10 mobile-feedback tests and TypeScript `tsc --noEmit` passed. No backend code changed during this latest app-only pass.
- Existing scanner, staff-session, Authenticator, draft persistence, purchase payment and QR-export regressions remain passing.

API/deployment notes: [MOBILE_FEEDBACK_APIS.md](majid_9990-backend/docs/MOBILE_FEEDBACK_APIS.md).
