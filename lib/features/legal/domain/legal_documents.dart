/// The three legal documents the client supplied, held as data so the same
/// renderer can present all of them and so the copy lives in one place.
///
/// Headings are lines that start with "## "; everything else is body text or
/// a "- " bullet. Nothing here is generated at runtime — the wording is the
/// client's and must not be paraphrased.
class LegalDocument {
  final String title;
  final String lastUpdated;
  final String body;

  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    required this.body,
  });
}

class LegalDocuments {
  LegalDocuments._();

  static const companyName = 'IMOSCAN LTD, trading as imoscan';
  static const companyNumber = '17165483';
  static const registeredOffice =
      'Unit 22 Mkd Larie Walk, Romford, Romford, United Kingdom, RM1 3RL';
  static const contactEmail = 'reports@imoscan.com';
  static const icoComplaintsUrl = 'https://ico.org.uk/make-a-complaint/';

  static const terms = LegalDocument(
    title: 'Terms & Conditions',
    lastUpdated: '7 September 2026',
    body: '''
## 1. About these Terms
These Terms and Conditions (the Terms) govern access to and use of the imoscan website, applications, software, payment-terminal features and related services (together, the Services).

The Services are provided by IMOSCAN LTD, trading as imoscan, a company registered in England and Wales under company number 17165483. Our registered office is Unit 22 Mkd Larie Walk, Romford, Romford, United Kingdom, RM1 3RL.

By creating an account, starting a trial, buying a subscription or using the Services, you agree to these Terms. If you use imoscan for a business, you confirm that you have authority to accept these Terms on its behalf.

## 2. Business use
imoscan is designed primarily for retailers, gadget stores, repair centres, trade-in businesses and other commercial users. Business account holders must be at least 18 years old and legally able to enter into a contract.

If imoscan offers services that consumers can buy directly, separate consumer terms should be displayed before purchase. Nothing in these Terms removes legal rights that cannot lawfully be excluded.

## 3. Accounts and authorised users
You must provide accurate account information and keep it current. You are responsible for protecting login details, choosing authorised staff, assigning suitable permissions and activity carried out through your users' accounts. Tell us promptly if you suspect unauthorised access or a security incident.

Accounts and login details must not be sold, transferred or shared outside your organisation without our written permission.

## 4. Trials, subscriptions and charges
The plan, features, usage limits, subscription period and charges that apply will be shown on the Pricing page, in an order form or during checkout. A signed order form takes priority if it conflicts with these Terms.

Unless stated otherwise:
- subscription charges are billed in advance;
- usage-based charges are billed according to actual use;
- prices exclude VAT and other applicable taxes;
- a trial may be limited by time, features or usage; and
- unused trial access or promotional credit has no cash value.

You authorise imoscan and its payment provider to collect charges using your selected payment method. Keep your billing details current. We may restrict paid features if an undisputed amount remains overdue after reasonable notice.

## 5. Renewal and cancellation
An automatically renewing subscription renews for the period shown at checkout unless either party cancels before the renewal date. Renewal pricing will be the price notified for the next term.

You may cancel through the account settings or by contacting us. Cancellation stops future renewals but normally does not create a refund for a period that has already started, except where required by law or stated in an order form.

Before closing an account, export any records you are required to keep. We may retain limited information after closure for security, fraud prevention, dispute resolution, accounting or legal obligations.

## 6. Your responsibilities
You are responsible for your business and for information, instructions and decisions made through your account. You must:
- keep product, customer, repair, warranty, tax and transaction records accurate;
- comply with consumer, tax, employment, marketing and data-protection laws;
- provide receipts, notices, warranties and cancellation rights where required;
- have a lawful basis before collecting or using personal information;
- check information generated or suggested by imoscan before relying on it; and
- maintain suitable internet access, devices and other equipment.

## 7. Acceptable use
You must not use the Services to:
- break the law, facilitate fraud or handle goods you know or reasonably suspect are stolen;
- collect identity documents or personal information without a lawful and necessary purpose;
- infringe another person's privacy, intellectual-property or other rights;
- upload malware or bypass the security of the Services;
- access another account, system or dataset without permission;
- scrape, copy, reverse-engineer or resell the Services, except where law does not permit that restriction;
- make misleading claims to customers based on imoscan outputs; or
- submit unlawful, abusive, discriminatory or harmful material.

We may investigate suspected misuse and restrict access where reasonably necessary to protect users, imoscan or third parties.

## 8. Customer data and data protection
As between you and imoscan, you retain control of the business and customer information submitted through your account (Customer Data).

For account administration, billing, security, support and imoscan's own operations, imoscan normally acts as a controller. When imoscan handles Customer Data solely on your instructions, you normally act as controller and imoscan acts as processor.

You instruct imoscan to process Customer Data as necessary to provide and secure the Services. Where required, our Data Processing Agreement forms part of our contract. You are responsible for providing privacy information to your customers and handling their data-protection requests. We will provide reasonable assistance where required.

## 9. Identity-document images
Where enabled, a shop may capture an identity-document image for a lawful trade-in, verification or fraud-prevention purpose. Only necessary information should be collected.

An original identity-document image stored through imoscan may be deleted earlier by the shop and will be deleted automatically no later than 28 days after capture. The feature must not be used as a permanent identity-document archive.

After the image is deleted, a separate record may remain, including the customer's name, contact details, device information and transaction, repair or warranty history, subject to the shop's lawful retention requirements.

## 10. Device checks and third-party data
IMEI, serial-number, device-history, diagnostic and market information may come from third parties. Coverage and update frequency vary by provider, device, network, country and check type.

Results are decision-support information. They do not guarantee that a device is genuine, unencumbered, fully functional, not stolen or suitable for purchase. A status may change after a check. You must review the evidence and make your own decision.

## 11. AI-assisted features
imoscan may use artificial intelligence to explain device information, identify possible risks, suggest product details or prices, draft communications and prepare summaries.

AI output may be incomplete, inaccurate or out of date. It is a recommendation, not professional advice or a final decision. An authorised person must review important outputs, especially decisions involving fraud, trade-in refusal, customer treatment or price.

## 12. Suggested product details and prices
Product descriptions, images, specifications and suggested prices may be generated or obtained from external sources. Availability and accuracy are not guaranteed, and market conditions can change quickly.

You must review every field before saving or publishing a product. You are responsible for the final description, image rights, price, taxes and information shown to customers.

## 13. Payments and terminals
Payment processing, merchant onboarding, terminals, settlement, refunds and chargebacks may be supplied by an authorised third-party payment provider. Availability is subject to that provider's terms, pricing, supported countries, risk checks and approval.

The payment provider may act as an independent controller. imoscan is not a bank, card issuer or acquiring bank. You remain responsible for customer refunds, disputes, chargebacks and payment instructions, except where the provider's terms state otherwise.

## 14. Third-party services
The Services may connect to third-party products, data or websites. Separate terms and privacy notices may apply. We are not responsible for a third party's independent service, decisions or availability, although we remain responsible for our own legal obligations when selecting and managing processors.

## 15. Intellectual property
imoscan and its licensors own the Services, including the software, design, databases, branding and documentation. Subject to these Terms and applicable charges, we grant you a limited, non-exclusive, non-transferable right to use the Services for internal business operations during your subscription.

You retain ownership of material you lawfully upload and grant imoscan the limited rights needed to host, process, transmit and display it to provide the Services. We may use feedback without restriction or payment, but will not identify you publicly without permission.

## 16. Availability, maintenance and changes
We aim to provide a reliable service but do not promise uninterrupted or error-free access. Maintenance, security work, provider outages and events outside our reasonable control may affect availability.

We may update the Services for security, legal or technical reasons or to add or remove features. We will give reasonable notice where a material change is likely to significantly disadvantage an active paid customer, unless urgent legal or security reasons prevent this.

## 17. Confidentiality
Each party must protect the other's confidential information and use it only for the contract. This does not apply to information that is public through no breach, was already lawfully known, is received lawfully from another source or must be disclosed by law.

## 18. Suspension and termination
We may suspend or terminate access if you materially breach these Terms, fail to pay undisputed charges, create a security risk, use the Services unlawfully or expose imoscan or another person to serious harm. Where appropriate, we will give notice and a reasonable opportunity to correct the issue.

Either party may terminate as stated in the applicable plan or order form. Provisions intended to continue after termination — including payment, confidentiality, intellectual property, liability and governing law — will remain in effect.

## 19. Liability
Nothing in these Terms excludes or limits liability where doing so would be unlawful, including liability for death or personal injury caused by negligence, fraud or fraudulent misrepresentation.

Subject to that statement, neither party will be liable for indirect or consequential loss, loss of profit, loss of anticipated savings or loss of goodwill arising from business use of the Services.

imoscan's total liability arising out of or connected with the Services in any 12-month period will not exceed the fees paid or payable by you for the Services during that period.

imoscan is not responsible for loss caused by inaccurate information supplied by you, decisions made without appropriate review, unlawful use, unsupported equipment or a third-party service outside our reasonable control.

## 20. Changes to these Terms
We may update these Terms to reflect changes to the Services, law or security requirements. We will notify account holders of material changes by email, through the Services or on our website. Changes take effect on the stated date. If a material change significantly disadvantages you, you may cancel before it takes effect, subject to any order form.

## 21. Governing law
These Terms and related disputes are governed by the laws of England and Wales. The courts of England and Wales will have exclusive jurisdiction, except where mandatory law provides otherwise.

## 22. Contact us
IMOSCAN LTD, trading as imoscan
Company number: 17165483
Registered office: Unit 22 Mkd Larie Walk, Romford, Romford, United Kingdom, RM1 3RL
Email: reports@imoscan.com
''',
  );

  static const privacyPolicy = LegalDocument(
    title: 'Privacy Policy',
    lastUpdated: '3 September 2026',
    body: '''
## 1. Who we are
imoscan is a retail, inventory, repair, trade-in and payment-management platform operated by IMOSCAN LTD, trading as imoscan.

IMOSCAN LTD is registered in England and Wales under company number 17165483. Our registered office is Unit 22 Mkd Larie Walk, Romford, Romford, United Kingdom, RM1 3RL.

This Policy explains how personal information is collected and used through the imoscan website, applications, payment-terminal features and related services.

## 2. Our data-protection role
- imoscan is normally a controller for account registration, subscriptions, security, support, service communications, marketing and our own operations.
- When a shop uses imoscan to record information about customers, staff, repairs, purchases, trade-ins or warranties, the shop normally acts as controller and imoscan acts as its processor.
- Payment providers, banks, identity-verification providers and certain partners may act as separate controllers under their own privacy notices.

If a shop entered your information, contact that shop first. It decides why the information is used and how long the underlying customer record is needed. imoscan will assist with valid requests where required.

## 3. Information we may process
Depending on the features used, we may process:
- name, email address, telephone number and postal address;
- business, shop, account and staff information;
- login, authentication, role and permission records;
- purchase, sale, trade-in, repair, warranty and collection records;
- device information, including make, model, condition, IMEI, serial number, photographs and diagnostics;
- identity-document information for a lawful verification or fraud-prevention purpose;
- signatures, permissions, consent records and transaction evidence;
- invoice, refund, payment status and limited card information, such as card type and last four digits;
- delivery details and location information when delivery tracking is enabled;
- support messages and communications; and
- IP address, device information, app activity, security logs, crash reports and cookie information.

Complete card details are normally collected and processed directly by the authorised payment provider rather than stored by imoscan.

## 4. Where information comes from
We may receive information directly from you; from a shop using imoscan; automatically from your device or use of the Services; from authorised payment, IMEI, device-history, identity, address, analytics and security providers; or from public or licensed product-information sources when product search is used.

## 5. Why we use information
- Create and operate accounts — performance of a contract.
- Provide subscriptions and requested features — performance of a contract.
- Process billing and maintain financial records — contract and legal obligation.
- Protect accounts and prevent fraud, misuse and unauthorised access — legitimate interests and, where applicable, legal obligation.
- Provide support and essential communications — contract and legitimate interests.
- Diagnose faults and improve reliability, performance and usability — legitimate interests.
- Establish, exercise or defend legal claims — legitimate interests and legal obligation where applicable.
- Send optional marketing — consent or legitimate interests where permitted by law.
- Use non-essential cookies or similar technologies — consent.

Our legitimate interests include operating a secure and reliable service, supporting customers, preventing fraud, improving the platform and protecting legal rights. We consider whether processing is necessary and whether an individual's rights override those interests. When imoscan acts only as processor, the shop is responsible for identifying its lawful basis.

## 6. Customer records and identity documents
imoscan processes shop customer information to provide features selected by the shop. imoscan does not sell that information or use shop customer records for its own marketing.

An original identity-document image may be captured for a lawful trade-in, verification or fraud-prevention purpose. The shop may delete it earlier, and imoscan will delete it automatically no later than 28 days after capture. It will then cease to be accessible through imoscan.

After the image is deleted, necessary information may remain as a separate record, including the customer's name, telephone number, email address, device details and transaction, repair or warranty history.

The shop may use those records to process orders, issue receipts, provide repair and order updates, manage warranties, prevent fraud and respond to enquiries or legal claims. It may send promotional emails, personalised discounts or special offers only where it has permission or another lawful basis and complies with electronic-marketing rules. Marketing messages must provide an appropriate way to opt out.

## 7. AI-assisted features
imoscan may use AI to explain device checks, estimate condition or market value, highlight possible risks, suggest product fields or prices, prepare summaries and draft business communications.

AI output is decision support. imoscan does not intend these tools to make decisions with legal or similarly significant effects solely by automated means. Important decisions should be reviewed by an authorised person.

imoscan does not use identifiable shop customer records to train public or general-purpose AI models. Where an AI provider processes information to return a requested result, we limit the information supplied and apply appropriate contractual and security controls.

## 8. Who we share information with
We may share information where necessary with:
- cloud-hosting, database, backup and security providers;
- payment processors, acquiring banks and terminal providers;
- IMEI, serial-number, device-history and diagnostic providers;
- identity-verification and fraud-prevention providers;
- email, SMS, notification and communication providers;
- AI providers when an AI-assisted feature is requested;
- analytics, monitoring and crash-reporting providers;
- address, map and delivery providers;
- professional advisers, insurers and auditors;
- regulators, law-enforcement bodies or courts where required; and
- a buyer, investor or successor involved in a proposed or completed business sale or reorganisation.

We do not sell personal information or allow providers to use shop customer records for their own marketing.

To protect commercially sensitive supplier information, imoscan does not publish a complete provider list. Further information about relevant recipients is available to verified business customers or affected individuals on reasonable request where required for data-protection compliance.

## 9. International transfers
Some providers may process information outside the United Kingdom. Where required, we use a lawful transfer mechanism, such as UK adequacy regulations, the UK International Data Transfer Agreement or the UK Addendum to approved standard contractual clauses. Contact us for information about safeguards relevant to your data.

## 10. Retention
We keep information only as long as necessary for contractual, security, fraud-prevention, accounting and legal purposes.
- Original identity-document images — up to 28 days after capture; a shop may delete them earlier.
- imoscan account information — while active and for a limited period after closure where needed for support, disputes, fraud prevention or legal obligations.
- Subscription, invoice and accounting records — normally up to six years after the relevant financial period.
- Shop customer, repair, trade-in and warranty records — according to the shop's instructions, settings and legal responsibilities.
- Support communications — as long as reasonably needed to resolve the request and maintain a suitable record.
- Security and application logs — a limited period based on security, operational and legal requirements.
- System backups — until overwritten or deleted under the backup schedule.
- imoscan marketing information — until consent is withdrawn, the recipient opts out or it is no longer needed.

Anonymised information that can no longer identify a person may be kept for analytics, security and service improvement.

## 11. Security
We use technical and organisational measures designed to protect information. Depending on the service, these may include encrypted connections, access controls, permissions, authentication, activity logging, backups, monitoring and incident-response procedures.

Shops are responsible for protecting login details, assigning suitable permissions and preventing unauthorised device access. No online service is entirely risk-free. We investigate suspected incidents and make notifications where legally required.

## 12. Your rights
Depending on the circumstances, you may have the right to request access, correction or deletion; restrict or object to processing; receive certain information in a portable format; withdraw consent; and request human review of a significant decision made solely through automated processing.

These rights are not absolute and may depend on our role, the lawful basis and legal retention duties. We may verify your identity before responding.

Right to object: you have the right to object at any time to the use of your personal information for direct marketing. If you object, that marketing will stop.

If a shop collected your information, contact that shop first. You may also email reports@imoscan.com.

You may complain to the Information Commissioner's Office through its complaints service at https://ico.org.uk/make-a-complaint/. We would appreciate the opportunity to address your concern first, but you do not have to contact us before approaching the ICO.

## 13. Marketing
imoscan may send marketing where you have consented or another lawful route applies. Unsubscribe through the email link or contact us. We may keep a minimal suppression record to respect your opt-out.

Shops are responsible for their own customer marketing. For individual subscribers, this normally requires consent or a valid existing-customer exception, with an opt-out when details are collected and in every message. Sole traders and some partnerships are treated like individuals for these rules.

Service, billing and security messages are not marketing and may still be sent where necessary.

## 14. Cookies and similar technologies
We use essential technologies needed for security, login and core operation. Analytics, advertising or other non-essential technologies are used only after the required permission has been obtained. More information and preference controls should be available in the Cookie Policy and cookie banner.

## 15. Children
imoscan business accounts are not intended for people under 18. If a shop records information about a child, the shop is responsible for establishing a lawful basis and providing suitable privacy information.

## 16. Changes to this Policy
We may update this Policy when our Services, providers or legal responsibilities change. Material changes will be communicated through the website, application or account email where appropriate. The latest version will show its effective date.

## 17. Contact us
IMOSCAN LTD, trading as imoscan
Company number: 17165483
Registered office: Unit 22 Mkd Larie Walk, Romford, Romford, United Kingdom, RM1 3RL
Email: reports@imoscan.com
''',
  );

  static const cookiePolicy = LegalDocument(
    title: 'Cookie & Tracking Policy',
    lastUpdated: '7 September 2026',
    body: '''
## 1. About this Policy
This Cookie and Tracking Policy explains how IMOSCAN LTD, trading as imoscan, uses cookies, mobile application software development kits (SDKs), local storage, device identifiers and similar technologies through the imoscan website, mobile applications and related services.

IMOSCAN LTD is registered in England and Wales under company number 17165483. Our registered office is Unit 22 Mkd Larie Walk, Romford, Romford, United Kingdom, RM1 3RL.

This Policy should be read together with the imoscan Privacy Policy.

## 2. What are cookies and tracking technologies?
Cookies are small files stored on a browser or device when someone visits a website.

Mobile applications do not always use traditional browser cookies. They may use SDKs, local app storage, authentication tokens, push-notification tokens, device information and similar technologies.

These technologies may help imoscan to:
- Keep users securely signed in.
- Protect accounts and prevent unauthorised access.
- Remember settings and privacy choices.
- Provide requested app and website features.
- Identify technical errors and crashes.
- Measure performance and understand how features are used.
- Deliver notifications requested by the user.
- Measure marketing where permission has been provided.

## 3. Technologies we may use
Strictly necessary technologies are required to provide services requested by the user and support functions such as:
- Secure login and authentication.
- Session management.
- Two-factor authentication.
- Fraud and security protection.
- Load balancing and service availability.
- Remembering privacy choices.
- Shopping, subscription or payment-session functionality.
- Protecting forms and APIs from misuse.
- Maintaining the security of customer, repair and transaction records.

These technologies cannot normally be disabled through imoscan's privacy controls because the website or app may not function correctly without them.

Preference and functionality technologies may, with permission where required, remember:
- Language and display preferences.
- Selected shop or location.
- Accessibility choices.
- Light or dark appearance settings.
- Saved filters and dashboard preferences.
- Optional notification preferences.
- Previously selected non-essential settings.

Disabling these technologies may mean that some preferences must be selected again.

Analytics and performance technologies may, with permission where required, be used to understand:
- Which website or app features are used.
- How users move between screens.
- Whether pages and features load correctly.
- App crashes, errors and failed requests.
- Device type, operating-system version and app version.
- Approximate usage patterns and performance.
- Whether a new feature improves the user experience.

We use this information to maintain, secure and improve imoscan. Analytics should be configured to collect only the information reasonably required for these purposes.

Communications and notification technologies may use notification tokens and communication tools to provide:
- Security and login alerts.
- Subscription and account notices.
- Repair or order updates.
- Low-stock notifications.
- Daily or monthly business reports.
- Payment and transaction notifications.
- Customer support responses.
- Other notifications selected by the user.

Users can manage optional push notifications through imoscan's settings or their device settings. Essential security or account communications may still be delivered by email or another appropriate method.

Marketing notifications will not be sent without the permission or other lawful basis required by applicable law.

Advertising and campaign-measurement technologies are not used for cross-app advertising tracking unless they are clearly disclosed through the relevant privacy controls and the user has provided any required consent. If imoscan introduces advertising or campaign-measurement technologies, they will remain disabled until the required permission has been obtained. Users will be able to reject them without losing access to essential imoscan functions.

Where Apple's App Tracking Transparency requirements apply, the app will request permission through Apple's system before carrying out covered tracking.

## 4. Website technologies
The imoscan website may use:
- First-party cookies set directly by imoscan.
- Third-party cookies set through a feature or service used by imoscan.
- Browser local storage.
- Session storage.
- Security and authentication tokens.
- Pixels, tags or similar measurement technologies, where permitted.
- Technologies used in embedded payment or support functions.

Non-essential website technologies must not be activated before the user makes a valid choice.

## 5. Mobile app technologies
The imoscan mobile apps may use:
- Secure authentication and session tokens.
- Local app storage.
- Push-notification tokens.
- Crash-reporting and performance SDKs.
- Security and fraud-prevention tools.
- Limited device and app information.
- Camera or photo access when the user selects a scanning, repair-evidence, product-image or identity-document feature.
- Location access only when a location-dependent feature is actively requested.
- Payment-provider technology when a supported payment feature is used.

The app should not access protected device information merely because permission is technically available. Access must be connected to a clear imoscan feature.

## 6. Camera, photographs and identity documents
imoscan may request camera or photo access when a user chooses to:
- Scan a barcode, IMEI or serial number.
- Add a product image.
- Record device condition or repair evidence.
- Capture an identity document for a lawful trade-in, verification or fraud-prevention purpose.
- Scan a receipt, certificate or QR code.

Permission to use the camera or photo library does not allow imoscan to access unrelated content unnecessarily.

Original identity-document images stored through imoscan may be deleted earlier by the shop and will be deleted automatically no later than 28 days after capture, subject to the process described in the imoscan Privacy Policy.

## 7. Location information
imoscan will request location access only when it is reasonably required for an enabled feature, such as delivery or location-based shop functionality.

Where possible, users will be given an appropriate choice about whether location access is allowed only while using the app or not allowed.

imoscan will not continuously track a user's precise location unless this is necessary for a clearly explained feature and the required permission has been obtained.

## 8. Our lawful basis
Strictly necessary technologies may be used where they are required to provide a service requested by the user, protect the service or maintain essential functionality.

Where consent is required, optional technologies will not be activated until the user provides it through a clear affirmative choice.

Where personal information is processed through these technologies, the lawful basis may include:
- Performance of a contract.
- Compliance with a legal obligation.
- imoscan's legitimate interests in operating and protecting a reliable service.
- Consent for optional analytics, advertising or similar technologies where required.

Users may withdraw consent at any time without affecting processing that occurred lawfully before withdrawal.

## 9. Privacy choices
The imoscan website and app should provide a Manage Privacy Choices section where users can:
- Accept all optional technologies.
- Reject all optional technologies.
- Choose individual categories.
- Review or change previous choices.
- Manage optional notifications.
- Access this Cookie and Tracking Policy.
- Access the imoscan Privacy Policy.

Rejecting optional technologies must be as easy as accepting them.

Withdrawing permission will stop future optional collection where technically possible. It will not automatically delete information collected lawfully before permission was withdrawn. Users may separately request access to or deletion of their personal information.

## 10. Device and browser controls
Users may also manage technologies through:
- Browser cookie and storage settings.
- Apple iOS privacy and tracking settings.
- Android privacy and permission settings.
- Camera, photo and location permissions.
- Push-notification settings.
- Advertising-identifier settings, where applicable.

Blocking strictly necessary technologies may prevent some imoscan functions from working properly.

## 11. Third-party technologies
imoscan may use carefully selected third parties to provide functions such as:
- Secure hosting and authentication.
- Payment processing.
- Fraud prevention and security monitoring.
- Crash reporting and performance analysis.
- Notifications, email or SMS delivery.
- Customer support.
- Analytics, where permission has been provided.
- Maps or delivery features.
- Device, IMEI or product-information services.

A live technology register should be available through imoscan's privacy preference centre. It should identify each client-side cookie or SDK, its provider, purpose, category and duration.

imoscan does not need to disclose confidential backend infrastructure that does not store or access information on the user's device merely because it appears in a private supplier register. However, technologies that access a user's device or receive personal information must be disclosed as required by law.

We require relevant service providers to protect information and use it only for authorised purposes or as otherwise permitted by law.

## 12. Technology duration
The duration depends on the technology and its purpose:
- Session technologies normally expire when the session or browser closes.
- Authentication technologies may remain for a limited period to keep the account securely signed in.
- Privacy-choice records may remain long enough to remember the user's selection.
- Security records may be retained where reasonably necessary to detect and investigate misuse.
- Analytics information will be retained for a limited period consistent with its purpose.
- Push-notification tokens remain active until they expire, are replaced, the user disables notifications or the app is removed.
- App information stored locally may remain until it expires, is cleared, the user signs out or the app is deleted.

The specific duration of each client-side technology should be shown in the live technology register.

## 13. International processing
imoscan currently provides its services primarily to businesses in the United Kingdom. However, some of our technology providers or their support teams may store or access personal information from outside the UK.

Where personal information is transferred outside the UK, we take steps required by UK data-protection law. Depending on the destination and provider, these may include UK adequacy regulations, the UK International Data Transfer Agreement, the UK Addendum to the EU Standard Contractual Clauses, and any required transfer risk assessment.

You may contact us at reports@imoscan.com for further information about the safeguards relevant to your personal information.

## 14. Children
imoscan business accounts are not intended for people under 18.

We do not knowingly use advertising or profiling technologies to track children. Shops using imoscan remain responsible for ensuring that any information about a child is handled lawfully and appropriately.

## 15. Changes to this Policy
We may update this Policy when our website, applications, technologies or legal responsibilities change.

Material changes may be communicated through the website, app or account email where appropriate. The latest version will display its effective date.

Users may be asked to make a new privacy choice if we introduce a materially different optional purpose.

## 16. Contact us
For questions about cookies, app tracking or privacy choices, contact:

IMOSCAN LTD, trading as imoscan
Company number: 17165483
Registered office: Unit 22 Mkd Larie Walk, Romford, Romford, United Kingdom, RM1 3RL
Email: reports@imoscan.com

You may also complain to the Information Commissioner's Office through https://ico.org.uk/make-a-complaint/.
''',
  );
}
