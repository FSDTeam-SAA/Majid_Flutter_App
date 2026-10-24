class HelpArticle {
  const HelpArticle({
    required this.topic,
    required this.question,
    required this.answer,
  });

  final String topic;
  final String question;
  final String answer;

  bool matches(String query) => '$topic $question $answer'
      .toLowerCase()
      .contains(query.trim().toLowerCase());
}

abstract final class HelpCenterContent {
  static const topics = [
    'All',
    'Account',
    'Invoices',
    'Device checks',
    'Repairs & stock',
  ];

  static const articles = [
    HelpArticle(
      topic: 'Invoices',
      question: 'How do I download an invoice?',
      answer:
          'Open Create Invoice and select View to see Billing History. Tap Download on an invoice to save its PDF and open the saved file. A success message shows where it was saved. You can also use Print, Email or WhatsApp from the invoice card.',
    ),
    HelpArticle(
      topic: 'Account',
      question: 'Why am I not receiving a verification email?',
      answer:
          'Check that the email address saved in the app matches the inbox you are checking, including any numbers or spelling differences. Search all mail, Spam and Trash for the message. If you request another code, use the code from the latest email. Contact us if the message still does not arrive.',
    ),
    HelpArticle(
      topic: 'Device checks',
      question: 'How do I find a previous device report?',
      answer:
          'Open your device-check history and search for the device using its IMEI or serial number. Open the matching report to review the saved result. Check the report date before using the information, as a device status can change after a check.',
    ),
    HelpArticle(
      topic: 'Repairs & stock',
      question: 'Where can I track a repair request?',
      answer:
          'Open Repair Requests and select the repair to view its details and progress. Use the repair search to find a job by customer, device, reference or IMEI. The tracking link and QR code on repair paperwork can be shared with the customer.',
    ),
    HelpArticle(
      topic: 'Account',
      question: 'How do I reset my password?',
      answer:
          'On the sign-in screen, tap Forgot Password? and follow the email verification steps to choose a new password. Use the email address registered to your account. Never share your password or verification codes with anyone, including support.',
    ),
    HelpArticle(
      topic: 'Invoices',
      question: 'How do I send an invoice to a customer?',
      answer:
          'Open Billing History in the View tab of Create Invoice. Find the invoice and choose Email, SMS or WhatsApp. Check the customer contact details before sending. You can also open the PDF and use its share action.',
    ),
    HelpArticle(
      topic: 'Device checks',
      question: 'What if a device report has missing information?',
      answer:
          'Available information varies by service, device, network and country. Confirm that the IMEI or serial number is correct and review the service you selected. If you need help with a result, email us with the report reference and a description of the issue.',
    ),
    HelpArticle(
      topic: 'Repairs & stock',
      question: 'How do I find an item in stock?',
      answer:
          'Open Stock, choose a category and use the search field to find an item. You can search using the item name or its available SKU, barcode or IMEI. Open the item to review its details before editing it or adding it to checkout.',
    ),
  ];
}
