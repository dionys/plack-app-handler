package Plack::App::Handler::Context;

use Moo;
use MooX::Aliases;
use MooX::Types::MooseLike::Base qw(:all);

use Plack::Request ();

use namespace::clean;


has request => (
	is       => 'ro',
	isa      => InstanceOf['Plack::Request'],
	required => 1,
	alias    => 'req',
	handles  => [qw(env)],
);

has response => (
	is       => 'ro',
	isa      => InstanceOf['Plack::Response'],
	alias    => 'res',
	init_arg => undef,
	lazy     => 1,
	builder  => 1,
);

has stash => (
	is       => 'ro',
	isa      => HashRef,
	default  => sub { {} },
	init_arg => undef,
);

has _is_finalized => (
	is       => 'rw',
	isa      => Bool,
	default  => 0,
	init_arg => undef,
);

has _responder => (
	is       => 'ro',
	isa      => CodeRef,
	required => 1,
);


sub BUILDARGS {
	my ($self, $env, $ret) = @_;

	my $req  = Plack::Request->new($env);
	my $args = {
		request    => $req,
		_responder => $ret,
	};

	return $self->next::method($args);
}


sub finalize {
	my ($self) = @_;

	return if $self->_is_finalized;

	$self->_is_finalized(1);
	$self->_responder->($self->response->finalize());

	return;
}

around stash => sub {
	my ($meth, $self, @args) = @_;

	my $val = $meth->($self);

	return $val unless @args;

	my %set;

	if (@args == 1) {
		if (is_ArrayRef($args[0])) {
			my @res = map { $val->{$_} } @{$args[0]};

			return wantarray() ? @res : \@res;
		}
		elsif (is_HashRef($args[0])) {
			%set = %{$args[0]};
		}
		else {
			return $val->{$args[0]};
		}
	}
	elsif (scalar(@args) % 2 == 0) {
		%set = @args;
	}
	else {
		die('Stash expects to be passed a hash, hash reference, array reference, scalar, or nothing');
	}

	$val->{$_} = $set{$_} for keys(%set);

	return $val;
};

sub _build_response {
	return $_[0]->request->new_response(200);
}


1;
