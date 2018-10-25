#!perl

use Test::Most;
use Test::DZil;

use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                [ 'GatherDir' ],
                [ 'MetaConfig' ],
                [ 'Generate::ManifestSkip' ],
            ),
            'source/lib/Module.pm' => <<'MODULE'
package Module;

1;
MODULE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $content = $tzil->slurp_file('build/MANIFEST.SKIP');

ok $content, 'has content';

note $content;

done_testing;
