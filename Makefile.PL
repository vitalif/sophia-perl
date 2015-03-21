use strict;
use utf8;

use File::Fetch;
use Archive::Extract;

use FindBin;
use ExtUtils::MakeMaker;

my $rc = eval
{
	require 5.010;
	Term::ReadKey->import();
	1;
};

if($rc && !-e "sophia-master")
{
	eval {
		my $ff = File::Fetch->new(uri => "http://github.com/pmwkaa/sophia/archive/master.zip");
		
		if(my $file = $ff->fetch())
		{
			my $ae = Archive::Extract->new( archive => $file );
			$ae->extract( to => '.' );
		}
	};
}

my $sophia     = $FindBin::Bin ."/sophia-master";
my $sophia_src = $sophia;

`make -C $sophia_src libsophia.a`;


WriteMakefile(
    AUTHOR         => 'Vitaliy Filippov <vitalif@mail.ru>',
    ABSTRACT_FROM  => 'Sophia.pm',
    VERSION_FROM   => 'Sophia.pm',
    NAME           => 'Database::Sophia',
    LICENSE        => 'perl',
    LINKTYPE       => 'dynamic',
    CCFLAGS        => '-Wall',
    LIBS           => ["-L$sophia_src -lsophia -lpthread"],
    INC            => '-I'. $sophia_src
);
