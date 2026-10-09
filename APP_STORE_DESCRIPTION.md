# Imoscan — App Store submission copy

## App Store Description

Copy the text in this section into the App Store Connect Description field.

---

Imoscan helps mobile phone retailers, repair shops, and trade-in businesses manage device checks and everyday shop operations in one place.

Check device information, manage stock, track repairs, create invoices, and review transactions directly from your mobile device.

DEVICE CHECKS AND REPORTS

Scan a barcode with your camera or enter an IMEI or serial number to request a device check. You can also select a device-label image to extract its IMEI or serial number. Review available device details, status information, and risk summaries before buying, selling, or accepting a trade-in. Access previous checks and generate downloadable device certificates.

Available results may include model information, blacklist status, network lock, activation lock, and warranty details, depending on the device and selected checking service.

STOCK AND SALES

Browse inventory by category, search for products, review available quantities, and adjust stock. Build a checkout basket, review quantities and prices, and create a sales invoice. Record cash payments or card payments received through your external payment terminal.

REPAIR MANAGEMENT

Create repair requests with customer details, device information, and multiple reported issues. Track repair progress, manage jobs waiting for parts, and complete collection through checkout. Repair paperwork includes a tracking link and QR code so customers can follow their repair status.

INVOICES AND RECEIPTS

Create professional invoices and receipts with your shop details, logo, and a choice of templates. Generate PDFs, send invoices by email, share documents through compatible apps, and print using system printing. View customer outstanding balances while preparing invoices.

CUSTOMERS, SUPPLIERS, AND STAFF

Keep customer and supplier records organised. Access customer history and previous device information to simplify repeat visits. Business owners can manage staff records and available access settings.

TRANSACTIONS AND BUSINESS REPORTS

Review sales, recorded payments, expenses, and cash management activity. View daily, weekly, and monthly reports, search invoices, and access end-of-day summaries to understand your shop's performance.

CUSTOMER CONSENT AND FOLLOW-UP

Request and record customer consent for supported trade-in workflows. Send customer review requests through available email, SMS, and WhatsApp options when initiated by staff.

ACCOUNT AND PRIVACY CONTROLS

Manage your business profile, appearance preferences, and app permissions. Access privacy documents, export your account data, and delete your account from within the app.

Imoscan requires an account and an internet connection for connected services. Device-check coverage and available information vary by service, device, network, and country. Device reports and risk summaries support your assessment; they do not guarantee a device's condition, ownership, or suitability for purchase.

---

## App Review Notes

Replace the placeholders below with a working review account and test identifier before copying these notes into App Store Connect. Provide any additional sign-in instructions required by that account.

---

Imoscan is a business management app for mobile phone retailers, repair shops, and trade-in businesses. Its main workflows include IMEI and serial-number checks, inventory browsing, sales checkout, invoice generation, repair tracking, customer records, and business reports.

Please sign in using the review account provided. The main navigation provides access to inventory, checkout, device scanning, transactions, and repairs. Additional features are available from the profile menu.

Camera access is used to scan device barcodes and capture customer identity-document photos for trade-in paperwork. Device identifiers can also be entered manually. Selected photos can be used for IMEI extraction, identity-document attachments, payment images, profile photos, and invoice logos.

Generated PDFs are saved to the app's Documents folder, accessible through the iOS Files app, or shared and printed through system actions.

The Card option in sales checkout records a payment already received through an external terminal.

Review account email: [Enter review account email]

Review account password: [Enter review account password]

Additional sign-in instructions: [Enter any instructions required for the review account]

Sample IMEI or serial number: [Enter a valid test identifier]

Device-check service to select: [Enter the service that supports the test identifier]

---

## Internal implementation notes — do not paste into the store description

- App Store Description and App Review Notes are submission metadata; they are not stored in Info.plist.
- Camera and photo-library purpose strings reflect the current Flutter workflows.
- The unused photo-library add permission declaration was removed: generated PDFs are saved as files, not added to Photos.
- Existing location and Bluetooth declarations were retained. The app has permission controls for them, but no implemented location-tracking or Bluetooth printer/scanner integration was found in the current Flutter source. The submission copy therefore makes no claim about those integrations.
- Reviewer credentials and a working test device-check service have not been supplied or verified.
