package Dancer2::Plugin::Auth::OAuth;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use Dancer2;
use Dancer2::Plugin;
use Module::Load;

# setup the plugin
on_plugin_import {
    my $dsl      = shift;
    my $settings = plugin_setting;

    $settings->{prefix} ||= '/auth';

    for my $provider ( keys %{$settings->{providers} || {}} ) {

        # load the provider plugin
        my $provider_class = __PACKAGE__."::Provider::".$provider;
        eval { load $provider_class; 1; } or do {
            $dsl->debug("Couldn't load $provider_class");
            next;
        };
        $dsl->app->{_oauth}{$provider} ||= $provider_class->new($settings);

        # add the routes
        $dsl->app->add_route(
            method => 'get',
            regexp => sprintf( "%s/%s", $settings->{prefix}, lc($provider) ),
            code   => sub {
                $dsl->redirect(
                    $dsl->app->{_oauth}{$provider}->authentication_url(
                        $dsl->app->request->uri_base
                    )
                )
            },
        );
        $dsl->app->add_route(
            method => 'get',
            regexp => sprintf( "%s/%s/callback", $settings->{prefix}, lc($provider) ),
            code   => sub {
                my $redirect;
                if( $dsl->app->{_oauth}{$provider}->callback($dsl->app->request, $dsl->session) ) {
                    $redirect = $settings->{success_url} || '/';
                } else {
                    $redirect = $settings->{error_url}   || '/';
                }

                $dsl->redirect( $redirect );
            },
        );
    }
};

register_plugin;

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Plugin::Auth::OAuth - OAuth for your Dancer2 app

=head1 SYNOPSIS

  use Dancer2::Plugin::Auth::OAuth;



=head1 DESCRIPTION

Dancer2::Plugin::Auth::OAuth is a Dancer2 plugin which tries to make OAuth
authentication easy.

=head1 AUTHOR

Menno Blom E<lt>blom@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Menno Blom

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO


=cut
