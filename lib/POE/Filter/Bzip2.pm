package POE::Filter::Bzip2;

use strict;
use warnings;
use Carp;
use Compress::Bzip2 qw(compress decompress);
use vars qw($VERSION);
use base qw(POE::Filter);

$VERSION = '1.58';

sub new {
  my $type = shift;
  croak "$type requires an even number of parameters" if @_ % 2;
  my $buffer = { @_ };
  $buffer->{ lc $_ } = delete $buffer->{ $_ } for keys %{ $buffer };
  $buffer->{level} = 1 unless $buffer->{level};
  $buffer->{BUFFER} = [];
  return bless $buffer, $type;
}

sub level {
  my $self = shift;
  my $level = shift;
  $self->{level} = $level if defined $level;
  return $self->{level};
}

sub get {
  my ($self, $raw_lines) = @_;
  my $events = [];

  foreach my $raw_line (@$raw_lines) {
	if ( my $line = decompress( $raw_line ) ) {
		push @$events, $line;
	} 
	else {
		warn "Couldn\'t decompress input\n";
	}
  }
  return $events;
}

sub get_one_start {
  my ($self, $raw_lines) = @_;
  push @{ $self->{BUFFER} }, $_ for @{ $raw_lines };
}

sub get_one {
  my $self = shift;
  my $events = [];

  if ( my $raw_line = shift @{ $self->{BUFFER} } ) {
	if ( my $line = decompress( $raw_line ) ) {
		push @$events, $line;
	} 
	else {
		warn "Couldn\'t decompress input\n";
	}
  }
  return $events;
}

sub put {
  my ($self, $events) = @_;
  my $raw_lines = [];

  foreach my $event (@$events) {
	if ( my $line = compress( $event, $self->{level} ) ) {
		push @$raw_lines, $line;
	} 
	else {
		warn "Couldn\'t compress output\n";
	}
  }
  return $raw_lines;
}

sub clone {
  my $self = shift;
  my $nself = { };
  $nself->{$_} = $self->{$_} for keys %{ $self };
  $nself->{BUFFER} = [ ];
  return bless $nself, ref $self;
}

1;

__END__

=head1 NAME

POE::Filter::Bzip2 - A POE filter wrapped around Compress::Bzip2

=head1 SYNOPSIS

    use POE::Filter::Bzip2;

    my $filter = POE::Filter::Bzip2->new();
    my $scalar = 'Blah Blah Blah';
    my $compressed_array   = $filter->put( [ $scalar ] );
    my $uncompressed_array = $filter->get( $compressed_array );

    use POE qw(Filter::Stackable Filter::Line Filter::Bzip2);

    my ($filter) = POE::Filter::Stackable->new();
    $filter->push( POE::Filter::Bzip2->new(),
		   POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),

=head1 DESCRIPTION

POE::Filter::Bzip2 provides a POE filter for performing compression/decompression using L<Compress::Bzip2|Compress::Bzip2>. It is
suitable for use with L<POE::Filter::Stackable|POE::Filter::Stackable>.

=head1 CONSTRUCTOR

=over

=item new

Creates a new POE::Filter::Bzip2 object. Takes one optional argument, 'level': the level of compression to employ.
Consult L<Compress::Bzip2> for details.

=back

=head1 METHODS

=over

=item get
=item get_one
=item get_one_start

Takes an arrayref which is contains lines of compressed input. Returns an arrayref of decompressed lines.

=item put

Takes an arrayref containing lines of uncompressed output, returns an arrayref of compressed lines.

=item clone

Makes a copy of the filter, and clears the copy's buffer.

=item level

Sets the level of compression employed to the given value. If no value is supplied, returns the current level setting.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright (C) Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<POE|POE>

L<Compress::Bzip2|Compress::Bzip2>

L<POE::Filter::Stackable|POE::Filter::Stackable>

=cut

