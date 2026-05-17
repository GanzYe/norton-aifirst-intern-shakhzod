abstract final class ExampleMessages {
  static const List<({String title, String body})> samples = [
    (
      title: 'Fake bank alert',
      body:
          'URGENT: Your bank account will be suspended within 24 hours. '
          'Verify immediately at http://secure-bank-verify.xyz/login '
          'or call 1-800-555-0199.',
    ),
    (
      title: 'Prize scam SMS',
      body:
          'Congratulations! You won \$1,000,000 in the Norton Loyalty Draw. '
          'Claim your prize now: bit.ly/prize-winner-claim. '
          'Reply STOP to opt out.',
    ),
    (
      title: 'IRS impersonation',
      body:
          'Final Notice from IRS: A warrant has been issued for your arrest '
          'due to unpaid taxes. Pay \$4,250 today via gift cards to avoid '
          'legal action. Contact agent Smith immediately.',
    ),
  ];
}
