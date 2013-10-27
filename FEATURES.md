# Authkit Features

  * Signup (username or email)
  * Login/Logout
  * Database backed unique constraints
  * Email confirmation (you must connect a mailer, see below)
  * Password reset (you must connect a mailer, see below)
  * One time password / Two factor authentication
  * Token support
  * Remember me
  * Account page
  * Time zones
  * Do not track (DNT) support
  * Sign-in Tracking
  * Analytics (coming soon)
  * Lockout for failed attempts (coming soon)

## Basic functionality

Users should be able to sign up, login and logout. Authkit takes the approach that users should
immediately be given access to the site once they have signed up. An email confirmation is
sent, but on sign up the user is immediately logged in and their email address is immediately
active.

Because of this, users are immediately able to reset their password (in case they forget it).
This also makes supporting third-party authentication easier. In order to support password
resets you must implement the +send_reset_password+ in +user.rb+.

    def send_reset_password
      return false unless set_token(:reset_password_token)

      # TODO: insert your mailer logic here
      true
    end


## Email confirmation

In order to properly use email confirmation you must implement the +send_confirmation+
method in +user.rb+

    def send_confirmation
      return false unless set_token(:confirmation_token)

      # TODO: insert your mailer logic here
      true
    end

Email confirmation is deceptively simple. By default you can sign up with any email address
and that address must be unique. A confirmation is immediately sent to the email address.
When editing the user settings the email is not adjusted (so a user cannot lock themselves
out) until it is confirmed. Because of this, the edit form modifies the +confirmation_email+
and sends out a new confirmation if changed. Once the confirmation is accepted the
+confirmation_email+ is copied to the +email+ field and confirmation tokens are cleared.

When changing the confirmation email it is checked for uniqueness against the existing set
of user emails. However, it is possible that a user will change their email and then
sign up with that email after the fact. If the user then confirms the original change it
will fail to confirm because the email will already be in use.

## Remember me

Authkit takes the approach that users always want to be remembered. When users are working on
public computers, it is assumed that they will logout before leaving or their session will
be reset (as is the case in most libraries). If your application contains sensitive data
you may want to change this default. There are a number of approaches to determining that
the user wants to be remembered (checkbox, etc.) but ultimately the +set_remember_cookie+
call in the +login+ must be called conditionally.

