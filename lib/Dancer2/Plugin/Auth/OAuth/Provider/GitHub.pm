package Dancer2::Plugin::Auth::OAuth::Provider::GitHub;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;

sub config { {
    urls => {
        access_token_url => "https://github.com/login/oauth/access_token",
        authorize_url => "https://github.com/login/oauth/authorize",
    }
)}

1;
