#!/usr/bin/perl

package MooseX::App::Cmd::Simple;
use Moose;
use MooseX::NonMoose;

extends qw(MooseX::App::Cmd::Command App::Cmd::Simple);

use Sub::Install;
use SUPER qw();

# Need to relax the requirements.
has "+app" => (
    isa => 'App::Cmd',
);

sub usage_desc {
  return "%c %o";
}

# The following implements the same method modifier on execute_command
# as in MX::App::Cmd, only it does it without using Moose, because
# App::Cmd and therefore the autogenerated $cmd_pkg are not based on
# Moose.
around import => sub {
    my ($orig, $class) = @_;

    # This signals that something has already set the target up.
    return $class if $class->_cmd_pkg;

    my $return_value = $class->$orig();

    my $cmd_pkg = $class->_cmd_pkg;

    Sub::Install::install_sub({
        into => $cmd_pkg,
        as => 'execute_command',
        code => sub {
            my ($self, $cmd, $opt, @args) = @_;

            if ($cmd->can('_compute_getopt_attrs')) {
                ### Adding option defaults...
              ATTR:
                for my $attr ( $cmd->_compute_getopt_attrs ) {
                    my $attr_name = $attr->name;
                    next ATTR if $attr_name eq 'help_flag';
                    my $reader = $attr->get_read_method;
                    my $attr_value = $cmd->$reader();
                    ### Attribute: {$attr_name, $attr_value}
                    $opt->{$attr_name} = $attr_value;
                }

            }
            # Need to do some weird things to get and call the parent
            # method. The standard ways of doing this fail because I'm
            # installing this method from another package using
            # Sub::Install.
            my $parent_method = (SUPER::find_parent( $cmd_pkg, 'execute_command' ))[0]
                or die;
            $self->$parent_method($cmd, $opt, @args);
        }
    });

    return $return_value;
};

__PACKAGE__;

__END__

=pod

=head1 NAME

MooseX::App::Cmd::Simple - Base class for L<MooseX::Getopt> based L<App::Cmd::Simple>.

=head1 SYNOPSIS

    use Moose;

    extends qw(MooseX::App::Cmd::Simple);

    # no need to set opt_spec
    # see MooseX::Getopt for documentation on how to specify options
    has option_field => (
        isa => "Str",
        is  => "rw",
        required => 1,
    );

    sub execute {
        my ( $self, $opts, $args ) = @_;

        print $self->option_field; # also available in $opts->{option_field}
    }

=head1 DESCRIPTION

This is a replacement base class for L<App::Cmd::Simple> classes that includes
L<MooseX::Getopt> and the glue to combine the two.

=head1 METHODS

=over 4

=item _process_args

Replaces L<App::Cmd::Simple>'s argument processing in in favour of
L<MooseX::Getopt> based processing.

=back

=head1 TODO

Full support for L<Getopt::Long::Descriptive>'s abilities is not yet written.

This entails taking apart the attributes and getting at the descriptions.

This might actually be added upstream to L<MooseX::Getopt>, so until we decide
here's a functional but not very helpful (to the user) version anyway.

=cut

