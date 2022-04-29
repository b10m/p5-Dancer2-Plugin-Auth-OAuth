# NAME

Dancer2::Plugin::Auth::OAuth - OAuth for your Dancer2 app

# SYNOPSIS

    # just 'use' the plugin, that's all.
    use Dancer2::Plugin::Auth::OAuth;

# DESCRIPTION

Dancer2::Plugin::Auth::OAuth is a Dancer2 plugin which tries to make OAuth
authentication easy.

The module is highly influenced by [Plack::Middleware::OAuth](https://metacpan.org/pod/Plack::Middleware::OAuth) and Dancer 1
OAuth modules, but unlike the Dancer 1 versions, this plugin only needs
configuration (look mom, no code needed!). It automatically sets up the
needed routes (defaults to `/auth/$provider` and `/auth/$provider/callback`).
So if you define the Twitter provider in your config, you should automatically
get `/auth/twitter` and `/auth/twitter/callback`.

After a successful OAuth dance, the user info is stored in the session. What
you do with it afterwards is up to you.

# CONFIGURATION

The plugin comes with support for Facebook, Google, Twitter, GitHub, Stack
Exchange and LinkedIn (other providers aren't hard to add, send me a pull
request when you add more!)

All it takes to use OAuth authentication for a given provider, is to add
the configuration for it.

The YAML below shows all available options.

    plugins:
      "Auth::OAuth":
        reauth_on_refresh_fail: 0 [*]
        prefix: /auth [*]
        success_url: / [*]
        error_url: / [*]
        providers:
          Facebook:
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret
            fields: id,email,name,gender,picture
          Google:
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret
          AzureAD:
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret              
          Twitter:
            tokens:
              consumer_key: your_consumer_token
              consumer_secret: your_consumer_secret
          Github:
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret
          Stackexchange:
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret
              key: your_key
            site: stackoverflow
          Linkedin:
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret
            fields: id,num-connections,picture-url,email-address
          VKontakte: # https://vk.com
            tokens:
              client_id: '...'
              client_secret: '...'
            fields: 'first_name,last_name,about,bdate,city,country,photo_max_orig,sex,site'
            api_version: '5.8'
          Odnoklassniki: # https://ok.ru
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret
              application_key: your_application_key
            method: 'users.getCurrentUser'
            format: 'json'
            fields: 'email,name,gender,birthday,location,uid,pic_full'
          MailRU:
            tokens:
              client_id: your_client_id
              client_private: your_client_private
              client_secret: your_client_secret
            method: 'users.getInfo'
            format: 'json'
            secure: 1
          Yandex:
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret
            format: 'json'

\[\*\] default value, may be omitted.

# AUTHENTICATION VS. FUNCTIONAL THIRD PARTY LOGIN

The main purpose of this module is simply to authenticate against third party
identify providers, but your Dancer2 app might additionally use the id_token to
access the API of the same (or other) third parties to enable you to do cool
stuff with your apps, like show a feed, access data etc.

Because access to the third party systems would be cut off when the id_token
expires, Dancer2::Plugin::Auth::OAuth will automatically set up the route
`/auth/$provider/refresh`. Call this when the token has expired to try to
refresh the token without bumping the user back to log in. You can optionally
tell Dancer2::Plugin::Auth::OAuth to bump the user back to the login page if
for whatever reason the refresh fails.

In addition, Dancer2::Plugin::Auth::OAuth will save or generate a auth session
key called "expires", which is (usually) number of seconds from epoch. Check
this to determine if the id_token has expired (see examples below).

## AUTHENTICATION

An example of a simple single system authentication. Note that once
authenticated the user will continue to be authenticated until the Dancer2
session has expired, whenever that might be:

  hook before => sub {
    my $session_data = session->read('oauth');
    my $provider = "facebook"; # Lower case of the authentication plugin used

    if ((!defined $session_data || !defined $session_data->{$provider} || !defined $session_data->{$provider}{id_token}) && request->path !~ m{^/auth}) {
      return forward "/auth/$provider";
    }
  };

If you want to be sure they have a valid id_token at all times:

  hook before => sub {
    my $session_data = session->read('oauth');
    my $provider = "facebook"; # Lower case of the authentication plugin used

    my $now = DateTime->now->epoch;

    if ((!defined $session_data || !defined $session_data->{$provider} || !defined $session_data->{$provider}{id_token}) && request->path !~ m{^/auth}) {
      return forward '/auth/$provider';

    } elsif (defined $session_data->{$provider}{refresh_token} && defined $session_data->{$provider}{expires} && $session_data->{$provider}{expires} < $now && request->path !~ m{^/auth}) {
      return forward "/auth/$provider/refresh";

    }
  };

in the case where you're using the refresh functionality, a failure of the
refresh will send the user back to the error_url. If you want to them to instead
be directed back to the main authentication (log in page) then please set the
configuration option `reauth_on_refresh_fail`.

## FUNCTIONAL THIRD PARTY LOGIN

Authenticate using the same method as above, but be sure to use the 'refresh'
functionality, as the logged in user will need to have a valid id_token at all
times.

Also make sure that you set the scope of your authentication to tell the third
party what you wish to access (and for Microsoft/Azure also set the resource,
for the same reason).

Once you've got an active session you can get the id_token to use in further
calls to the providers backend systems with:

  my $session_data = session->read('oauth');
  my $token = $session_data->{$provider}{id_token};

# SETTING THE SCOPE

If you're authenticating in order to use the id_token issued, or if login
requires a specific 'scope' setting, you can change these values in the initial
calls like this within your yml config (example provided for AzureAD plugin).

  Auth::OAuth:
    providers:
      AzureAD:
        query_params:
          authorize:
            scope: 'Calendars.ReadWrite Contacts.Read Directory.Read.All Files.Read.All Group.Read.All GroupMember.Read.All Mail.ReadWrite openid People.Read Sites.Read.All Sites.ReadWrite.All User.Read User.ReadBasic.All Files.Read.All'

You do not need to list all other authorize attributes sent to the server,
unless you want to change them from the default values set in the provider.
Please view the provider source/documentation for what these default values are.

You may also need to set a value for "resource" in the same way. Refer to your
providers OAuth documentation.

# AUTHOR

Menno Blom &lt;blom@cpan.org>

# COPYRIGHT

Copyright 2014- Menno Blom

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
