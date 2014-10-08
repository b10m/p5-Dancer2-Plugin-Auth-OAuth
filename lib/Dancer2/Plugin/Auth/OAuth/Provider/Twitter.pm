package Dancer2::Plugin::Auth::OAuth::Provider::Twitter;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

sub config { {
    version => '1.001', # 1.0a
    urls    => {
        access_token_url  => 'https://api.twitter.com/oauth/access_token',
        authorize_url     => 'https://api.twitter.com/oauth/authenticate',
        request_token_url => 'https://api.twitter.com/oauth/request_token',
    }
} }

1;
