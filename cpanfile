requires 'perl', '5.008005';
requires 'Dancer2', '0.150000';
requires 'DateTime';
requires 'Digest::MD5';
requires 'File::Slurp';
requires 'JSON::Any';
requires 'Module::Load';
requires 'Net::OAuth';
requires 'Scalar::Util';
requires 'URI::Query';

on test => sub {
    requires 'Plack::Test';
    requires 'Test::Mock::LWP::Dispatch';
    requires 'Test::More', '0.96';
};
