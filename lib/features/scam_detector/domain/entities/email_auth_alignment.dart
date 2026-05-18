/// SPF, DKIM, and DMARC alignment extracted from Authentication-Results.
typedef EmailAuthAlignment = ({
  AuthProtocolResult spf,
  AuthProtocolResult dkim,
  AuthProtocolResult dmarc,
});

enum AuthProtocolResult { pass, fail, none, unknown }
