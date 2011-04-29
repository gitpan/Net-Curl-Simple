#
#
use strict;
use warnings;
use Test::More;
BEGIN {
	eval 'use Coro';
	plan skip_all => "Coro is required for this test" if $@;
}
plan tests => 20;
use Net::Curl::Simple;

my $pos = 1;

my $ca = async {
	is( $pos, 1, 'started correctly' ); $pos = 2;

	my $curl = Net::Curl::Simple->new;
	$curl->get( "http://google.com/search?q=curl", sub { } );

	is( $pos, 3, 'first returned after second start' );

	ok( defined $curl->code, 'finish callback called' );
	cmp_ok( $curl->code, '==', 0, 'downloaded successfully' );
	ok( ! $curl->{in_use}, 'handle released' );
	is( ref $curl->{headers}, 'ARRAY', 'got array of headers' );
	is( ref $curl->{body}, '', 'got body scalar' );
	cmp_ok( scalar $curl->headers, '>', 3, 'got at least 3 headers' );
	cmp_ok( length $curl->content, '>', 1000, 'got some body' );
	isnt( $curl->{referer}, '', 'referer updarted' );
};

my $cb = async {
	is( $pos, 2, 'did not block' ); $pos = 3;

	my $curl = Net::Curl::Simple->new;
	$curl->get( "http://google.com/search?q=perl", sub { } );

	is( $pos, 3, 'second returned' );

	ok( defined $curl->code, 'finish callback called' );
	cmp_ok( $curl->code, '==', 0, 'downloaded successfully' );
	ok( ! $curl->{in_use}, 'handle released' );
	is( ref $curl->{headers}, 'ARRAY', 'got array of headers' );
	is( ref $curl->{body}, '', 'got body scalar' );
	cmp_ok( scalar $curl->headers, '>', 3, 'got at least 3 headers' );
	cmp_ok( length $curl->content, '>', 1000, 'got some body' );
	isnt( $curl->{referer}, '', 'referer updarted' );
};

cede;
$ca->join;
$cb->join;
