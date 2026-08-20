/// App-wide hook fired when a request definitively proves the current
/// session is dead (a refresh-token attempt was made and failed). Anything
/// can react — normally this just routes back to the login screen — without
/// every feature having to duplicate 401 handling.
class SessionEvents {
  static void Function()? onSessionExpired;
}
