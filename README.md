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
needed routes (defaults to '/auth/<provider>' and '/auth/<provider>/callback'.

After a successful OAuth dance, the user info is stored in the session.

# CONFIGURATION

The plugin comes with support for Facebook, Google and Twitter (other
providers aren't hard to add, send me a pull request when you add more!)

All it takes to use OAuth authentication for a given provider, is to add
the configuration for it.

The YAML below shows all available options.

    plugins:
      "Auth::OAuth":
        prefix: /auth [*]
        success_url: / [*]
        error_url: / [*]
        providers:
          Facebook:
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret
          Google:
            tokens:
              client_id: your_client_id
              client_secret: your_client_secret
          Twitter:
            tokens:
              consumer_key: your_consumer_token
              consumer_secret: your_consumer_secret

\[\*\] default value, may be omitted.

# AUTHOR

Menno Blom <blom@cpan.org>

# COPYRIGHT

Copyright 2014- Menno Blom

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
