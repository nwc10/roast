use v6;

use Test;

# L<S03/Assignment operators/A op= B>

plan 32;

{
    my @a = (1, 2, 3);
    lives-ok({@a .= map: { $_ + 1 }}, '.= runs with block');
    is(@a[0], 2, 'inplace map [0]');
    is(@a[1], 3, 'inplace map [1]');
    is(@a[2], 4, 'inplace map [2]');
}

{
    my @b = <foo 123 bar 456 baz>;
    lives-ok { @b.=grep(/<[a..z]>/)},
             '.= works without surrounding whitespace';
    is @b[0], 'foo', 'inplace grep [0]';
    is @b[1], 'bar', 'inplace grep [1]';
    is @b[2], 'baz', 'inplace grep [2]';
}

{
    my $a=3.14;
    $a .= Int;
    is($a, 3, "inplace int");
}

#?rakudo skip "Method '' not found for invocant of class 'Str' RT #124528"
{
    my $b = "a_string"; $b .= WHAT;
    my $c =         42; $c .= WHAT;
    my $d =      42.23; $d .= WHAT;
    my @e = <a b c d>;  @e .= WHAT;
    isa-ok($b,    Str,   "inplace WHAT of a Str");
    isa-ok($c,    Int,   "inplace WHAT of a Num");
    isa-ok($d,    Rat,   "inplace WHAT of a Rat");
    isa-ok(@e[0], Array, "inplace WHAT of an Array");
}

my $f = "lowercase"; $f .= uc;
my $g = "UPPERCASE"; $g .= lc;
my $h = "lowercase"; $h .= tc;
is($f, "LOWERCASE", "inplace uc");
is($g, "uppercase", "inplace lc");
is($h, "Lowercase", "inplace tc");

# L<S12/"Mutating methods">
my @b = <z a b d e>;
@b .= sort;
is ~@b, "a b d e z", "inplace sort";

{
    $_ = -42;
    .=abs;
    is($_, 42, '.=foo form works on $_');
}

# RT #64268
{
    my @a = 1,3,2;
    my @a_orig = @a;

    my @b = @a.sort: {1};
    is @b, @a_orig,            'worked: @a.sort: {1}';

    @a.=sort: {1};
    is @a, @a_orig,            'worked: @a.=sort: {1}';

    @a.=sort;
    is @a, [1,2,3],            'worked: @a.=sort';
}

# RT #70676
{
   my $x = 5.5;
   $x .= Int;
   isa-ok $x, Int, '.= Int (type)';
   is $x, 5, '.= Int (value)';

   $x = 3;
   $x .= Str;
   isa-ok $x, Str, '.= Str (type)';
   is $x, '3', '.= Str (value)';

   $x = 15;
   $x .= Bool;
   isa-ok $x, Bool, '.= Bool (type)';
   is $x, True, '.= Bool (value)';
}

# RT #69204
{
    my $a = 'oh hai';
    my $b = 'uc';
    is $a.="uc"(), 'OH HAI', 'quoted method call with .= works with parens';
    is $a.="$b"(), 'OH HAI', 'quoted method call (variable) with .= works with parens';
    is $a .= "uc"(), 'OH HAI', 'quoted method call with .= works with parens and whitespace';
    is $a .= "$b"(), 'OH HAI', 'quoted method call (variable) with .= works with parens and whitespace';
}

# https://github.com/rakudo/rakudo/commit/7fe23136da
subtest 'coverage for performance optimizations' => {
    plan 4;

    isa-ok (my class Foo {
        method STORE ($x) {
            is-deeply $x, 42, 'called STORE during .= on class instantiation'
        }
        method foo { 42 }
    }.new).=foo, Foo, '.= on a class instantiation';

    subtest 'Scalar' => {
        plan 11;
        my $a = 'foo';
        with $a { .=uc; is $a, 'FOO', '.= with implied $_' }

        sub foo (*@) {}
        foo $a.=lc, 42;
        is $a, 'foo', 'embedded in args of routine';
        foo $a .= uc, 42;
        is $a, 'FOO', 'embedded in args of routine (spaced)';
        foo ($a.=lc), 42;
        is $a, 'foo', 'embedded in args of routine (parenthesized)';
        foo ($a .= uc), 42;
        is $a, 'FOO', 'embedded in args of routine (parens + spaces)';

        is $a.=lc,   'foo', 'return value (no space)';
        is $a .= uc, 'FOO', 'return value (spaced)';

        $a.=lc;
        is $a, 'foo', 'standard; no space';
        $a .= uc;
        is $a, 'FOO', 'standard; spaced';

        ($a = $a.self).=lc;
        is $a, 'foo', 'statement; no space';
        ($a = $a.self) .= uc;
        is $a, 'FOO', 'statement; spaced';
    }

    subtest 'Array' => {
        plan 11;
        my @a = 'foo';
        with @a { .=uc; is-deeply @a, ['FOO'], '.= with implied $_' }

        sub foo (*@) {}
        foo @a.=lc, 42;
        is-deeply @a, ['foo'], 'embedded in args of routine';
        foo @a .= uc, 42;
        is-deeply @a, ['FOO'], 'embedded in args of routine (spaced)';
        foo (@a.=lc), 42;
        is-deeply @a, ['foo'], 'embedded in args of routine (parenthesized)';
        foo (@a .= uc), 42;
        is-deeply @a, ['FOO'], 'embedded in args of routine (parens + spaces)';

        is-deeply @a.=lc,   ['foo'], 'return value (no space)';
        is-deeply @a .= uc, ['FOO'], 'return value (spaced)';

        @a.=lc;
        is-deeply @a, ['foo'], 'standard; no space';
        @a .= uc;
        is-deeply @a, ['FOO'], 'standard; spaced';

        (@a.self).=lc;
        is-deeply @a, ['foo'], 'statement; no space';
        (@a.self) .= uc;
        is-deeply @a, ['FOO'], 'statement; spaced';
    }
}

# vim: ft=perl6
