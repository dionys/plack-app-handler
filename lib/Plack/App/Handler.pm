package Plack::App::Handler;

use Moo;

use Plack::App::Handler::Context ();

use namespace::clean;

use overload '&{}' => sub { shift()->_to_app(@_) }, fallback => 1;


sub _to_app {
	my ($self, $env) = @_;

	return sub {
		my ($ret) = @_;

		$self->handle(Plack::App::Handler::Context->new($env, $ret));

		return;
	};
}

sub handle {
	my ($self, $ctx) = @_;

	$ctx->res->code(200);
	$ctx->res->body("Ok!\n");

	$ctx->finalize();

	return;
}


1;
