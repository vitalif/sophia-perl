package Database::Sophia;

use utf8;
use strict;
use vars qw($AUTOLOAD $VERSION $ABSTRACT @ISA @EXPORT);

BEGIN {
	$VERSION = 1.2;
	$ABSTRACT = "Sophia is a modern embeddable key-value database designed for a high load environment (XS for Sophia)";
	@ISA = qw(DynaLoader);
};

bootstrap Database::Sophia $VERSION;

use DynaLoader ();
use Exporter ();

package Database::Sophia::Txn;

sub get
{
    my ($self, $db, $key) = @_;
    $db->get($key, $self);
}

sub delete
{
    my ($self, $db, $key) = @_;
    $db->delete($key, $self);
}

sub set
{
    my ($self, $db, $key, $value) = @_;
    $db->set($key, $value, $self);
}

package Database::Sophia::Snapshot;

*get = *Database::Sophia::Txn::get;

sub cursor
{
    my ($self, $db, $key, $order) = @_;
    $db->cursor($key, $order, $self);
}

1;


__END__

=head1 NAME

Database::Sophia - XS for Sophia 1.2, a modern embeddable key-value database designed for a high load environment.

=head1 SYNOPSIS

 use Database::Sophia;
 
 my $env = Database::Sophia::env();
 my $ctl = $env->ctl;
 
 $ctl->set('sophia.path', './storage');
 $ctl->set('db', 'test');
 
 $env->open;
 
 my $db = $ctl->get('db.test');
 
 if ($db->set('login', 'lastmac') != 0) {
     die $ctl->get('sophia.error');
 }
 
 warn $db->get('login');
 
 $db->delete('login');
 
 my $transaction = $env->begin;
 $transaction->set($db, 'login', 'otherguy');
 $transaction->commit;

=head1 DESCRIPTION

It has unique architecture that was created as a result of research and rethinking of primary algorithmic constraints, associated with a getting popular Log-file based data structures, such as LSM-tree.

See http://sphia.org/


=head1 METHODS

=head2 Database::Sophia

=head3 $env = Database::Sophia::env()

return the environment handle

=head3 $ctl = $env->ctl()

get configuration object (Database::Sophia::Ctl)

=head3 $rc = $env->open()

opens the database

=head3 $txn = $env->begin()

starts a new transaction and returns its object (Database::Sophia::Txn)

=head2 Database::Sophia::Ctl

=head3 $rc = $ctl->set('key', 'value')

set a configuration parameter or call system procedure

=head3 $value = $ctl->get('key')

get the value of a configuration parameter, or database object by 'db.<NAME>' key,
or snapshot object by 'snapshot.<NAME>' key

=head3 $cursor = $ctl->cursor

get an iterator over all configuration values

=head2 Database::Sophia::DB

=head3 $ctl = $db->ctl()

get a configuration object for this database, equivalent to part of the global
Ctl with prefix 'db.<name>'

=head3 $value = $db->get('key')

read a key as a single-statement transaction

=head3 $db->set('key', 'value')

set a key as a single-statement transaction

=head3 $db->delete('key')

delete a key as a single-statement transaction

=head3 $cursor = $db->cursor($starting_key, $order)

get an iterator over database keys, starting with $starting_key in the direction $order,
which may be one of '<', '<=', '>=', '>'

=head2 Database::Sophia::Txn

=head3 $txn->get($db, 'key')

get a key from database $db as a part of transaction $txn.

=head3 $txn->set($db, 'key', 'value')

set a key in database $db as a part of transaction $txn.

=head3 $txn->delete($db, 'key')

delete a key in database $db as a part of transaction $txn.

=head3 $txn->commit

apply a transaction; if you want to rollback it instead of commiting,
just destroy all references to the $txn object

=head2 Database::Sophia::Snapshot

=head3 $snapshot->get($db, 'key')

get a key from the snapshot

=head3 $snapshot->drop

delete (drop) the snapshot

=head3 $snapshot->cursor($db, $starting_key, $order)

get an iterator over database keys in the snapshot, starting with $starting_key in the direction $order,
which may be one of '<', '<=', '>=', '>'

=head2 Database::Sophia::Cursor

=head3 $key = $cursor->cur_key

return the current key.

=head3 $value = $cursor->cur_value

return the current value.

=head3 $next_key = $cursor->next_key

go to the next key and return it; if there's no more keys, return undef

=head1 DESTROY

like usually in Perl, you just need to remove all references to any object to destroy it

=head1 AUTHOR

Vitaliy Filippov <vitalif@mail.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Vitaliy Filippov.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

See libsophia license and COPYRIGHT
http://sphia.org/


=cut
