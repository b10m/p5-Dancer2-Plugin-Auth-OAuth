use strict;

use File::Basename;
use File::Slurp qw( read_file );
use FindBin qw( $Bin );
use HTTP::Request::Common;
use JSON::Any;
use Module::Load;
use Plack::Test;
use Test::More;
use Test::Mock::LWP::Dispatch;
use URI;

# setup LWP mocking
my %http_responses;
for my $file (<"$Bin/responses/*">) {
    $http_responses{basename($file)} = read_file($file);
}
$mock_ua->map(qr{^https://graph.facebook.com/oauth/access_token}, HTTP::Response->parse($http_responses{'facebook-access_token'}));
$mock_ua->map(qr{^https://graph.facebook.com/me},                 HTTP::Response->parse($http_responses{'facebook-user_info'}));
$mock_ua->map(qr{^https://accounts.google.com/o/oauth2/token},    HTTP::Response->parse($http_responses{'google-access_token'}));
$mock_ua->map(qr{^https://www.googleapis.com/oauth2/v2/userinfo}, HTTP::Response->parse($http_responses{'google-user_info'}));
$mock_ua->map(qr{^https://api.twitter.com/oauth/request_token},   HTTP::Response->parse($http_responses{'twitter-request_token'}));
$mock_ua->map(qr{^https://api.twitter.com/oauth/access_token},    HTTP::Response->parse($http_responses{'twitter-access_token'}));

# setup dancer app
{
    package App;
    use Dancer2;
    use Dancer2::Plugin::Auth::OAuth;

    get '/dump_session' => sub {
        content_type 'application/json';
        return to_json session('oauth');
    };

    true;
}

# setup plack
my $app = App->psgi_app;
is( ref $app, 'CODE', 'Got app' );

test_psgi
    app    => $app,
    client => sub {
        my $cb  = shift;

        for my $provider ( qw( facebook google twitter ) ) {
            ### setup
            my $provider_module = "Dancer2::Plugin::Auth::OAuth::Provider::".ucfirst($provider);
            load $provider_module;
            my $p = $provider_module->new;

            my %wanted_q = (
                twitter => {
                    callback => "http://localhost/auth_test/$provider/callback",
                    oauth_token => 'some_dummy_token',
                },
                facebook => {
                    response_type=> 'code',
                    scope        => 'email',
                    client_id    => 'some_client_id',
                    redirect_uri =>  "http://localhost/auth_test/$provider/callback",
                },
                google => {
                    response_type=> 'code',
                    scope        => 'openid email',
                    client_id    => 'some_client_id',
                    redirect_uri =>  "http://localhost/auth_test/$provider/callback",
                },
            );
            my $wanted_uri = URI->new( $provider_module->config->{urls}{authorize_url} );
               $wanted_uri->query_form( $wanted_q{$provider} );

            ### login
            my $res = $cb->(GET "/auth_test/$provider");
            ok($res->code == 302, "[$provider] Response code (302)");

            my $got_uri = URI->new($res->header('Location'));
            #print $got_uri."\n";
            for ( qw(scheme host path) ) {
                ok($got_uri->$_ eq $wanted_uri->$_, "[$provider] Redirect URL ($_)");
            }

            is_deeply( +{ $got_uri->query_form }, +{ $wanted_uri->query_form }, "[$provider] Redirect URL (query)" );

            ### callback
            $res = $cb->(GET "/auth_test/$provider/callback?oauth_token=foo&oauth_verifier=bar&code=foobar"); # mixing oauth versions
            ok($res->code == 302, "[$provider][cb] Response code (302)");
            ok($res->header('Location') eq 'http://localhost/users', "[$provider] success_url setting");

            my $cookie = $res->header('Set-Cookie');
               $cookie =~ s/;.*$//;
            ok($cookie =~ m/^dancer.session=/, "[$provider] Cookie");

            ### session dump
            my %wanted_session = (
                'twitter' => {
                    'access_token_secret' => 'some_dummy_s3kret',
                    'access_token' => 'some_dummy_token',
                    'extra' => { 'user_id' => '666', 'screen_name' => 'b10m' }
                },
                'facebook' => {
                    'expires' => 666, 'access_token' => 'accesstoken',
                    'user_info' => {
                        'email' => 'blom\\u0040cpan.org', 'first_name' => 'Menno',
                        'id' => '666', 'last_name' => 'Blom',
                        'link' => 'https:\\/\\/image', 'locale' => 'en_US',
                        'name' => 'Menno Blom', 'timezone' => 2,
                        'updated_time' => '1970-01-01T00:00:00+0000',
                        'verified' => '1'
                    }
                },
                'google' => {
                    'id_token' => 'id_token', 'token_type' => 'Bearer',
                    'expires_in' => 3600, 'access_token' => 'accesstoken',
                    'user_info' => {
                         'family_name' => 'Blom', 'id' => '666', 'verified_email' => 1,
                         'link' => 'https://plus.google.com/666', 'gender' => 'male',
                         'picture' => 'https://image', 'email' => 'blom@cpan.org',
                         'name' => 'Menno Blom', 'given_name' => 'Menno'
                     }
                },
            );
            $res = $cb->(GET "/dump_session", ( Cookie => $cookie ));
            my $session = JSON::Any->new->jsonToObj( $res->content );
            is_deeply( $session->{$provider}, $wanted_session{$provider}, "[$provider] Session data");
        }

    };

# all done!
done_testing;
