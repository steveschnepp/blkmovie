use Benchmark q{cmpthese};
my @arr = ( q{   fdsgehw fw wwfe w    } ) x 5000;
cmpthese -5, {
    "alternation*"   => sub {
        my @new = @arr;
        s{ ^\s* | \s*$ }{}gx for @new;
        },
    "alternation+"   => sub {
        my @new = @arr;
        s{ ^\s+ | \s+$ }{}gx for @new;
        },
    capture       => sub {
        my @new = @arr;
        s{ ^\s* (.*?) \s*$ }{$1}x for @new;
        },
    splitJoin     => sub {
        my @new = @arr;
        $_ = join q{ }, split for @new;
        },
    "twoStage*"      => sub {
        my @new = @arr;
        s{ ^\s* }{}x for @new;
        s{ \s*$ }{}x for @new;
        },
    "twoStage+"      => sub {
        my @new = @arr;
        s{ ^\s+ }{}x for @new;
        s{ \s+$ }{}x for @new;
        },
    "twoStageComma*" => sub {
        my @new = @arr;
        s{ ^\s* }{}x, s{ \s*$ }{}x for @new;
        },
    "twoStageComma+" => sub {
        my @new = @arr;
        s{ ^\s+ }{}x, s{ \s+$ }{}x for @new;
        },
    "twoStageCommaStmt+" => sub {
        my @new = @arr;
        for $string @new {
		$string =~ s/^\s+//;
		$string =~ s/\s+$//;
	}
        },
    };
