## 0.6.0

* Rails 4.2 compatibility
* Removed unneeded development dependencies
* Updated sample application to invoke out of process
* `UserSession` all session based code has moved into the user session so that all sessions are maintained separately for each device.
    - This fixes a problem where multiple logins would override the remember token
* Remember tokens no longer expire
* Remember tokens are updated on every request (to prevent replay attacks)
* Every access is recorded per session
    - This means a significant number of writes to the database but this behavior also facilitates updating the remember token for each access
* Factory Girl syntax methods moved to support per RSpec recommendation