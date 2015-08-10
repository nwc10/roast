use v6;
use Test;
plan 20;

# Is there a better reference for the spec for how return return works? 
# There is "return function" but that's a more advanced feature.
#L<S04/"Control Exceptions">

=begin pod

Basic tests for "return"

=end pod

sub bar { return }
is(bar(), Nil, '... bare return statement returned Nil');

sub bar2 { return() }
is(bar2(), Nil, '... bare return statement w/ parens returned Nil');

sub baz { return 10 if 1; }
is(baz(), 10, '... return worked with a statement modifier');

sub foobar { return if 1; };
is(foobar(), Nil, '... bare return worked with a statement modifier');

sub foobar2 { return() if 1; }
is(foobar2(), Nil, '... bare return worked with a statement modifier');

my $should_ret_empty_list1 = sub { return; 1 };
is $should_ret_empty_list1().elems, 0, "our sub returned an empty list (1)";

sub return_1 { return 1; }
is(return_1(), 1, '... return_1() returned 1 correctly');

is( try { sub foo { my $x = 1; while $x-- { return 24; }; return 42; }; foo() }, 24, 'return in while');

# S04: "A return always exits from the lexically surrounding sub or method definition"
{
    eval-dies-ok('return 1', 'bare return fails');
    eval-dies-ok('for 1 {return 2}', 'cannot return out of a bare for block');
    eval-dies-ok('my $i = 1; while $i-- {return 3}', 'cannot return out of a bare while');
    eval-dies-ok('my $i = 0; until $i++ {return 4}', 'cannot return out of a bare until');
    eval-dies-ok('loop (my $i = 0; $i < 1; $i++) {return 5}', 'cannot return out of a bare loop');
    # XXX: Not 100% sure on this one
    eval-dies-ok('do {return 5}', 'cannot return out of a do block');

    #?rakudo todo 'lexotic return'
    is (try EVAL 'my $double = -> $x { return 2 * $x }; sub foo($x) { $double($x) }; foo 42').defined, False, 'return is lexotic only; must not attempt dynamic return';
}

{
    sub list_return { return (42, 1) }
    my $bar = ~list_return();
    is($bar, '42 1', 'Should not return empty string');
}

# RT #81962
{
    my $tracker = '';
    my &r = &return;
    sub f {
        my &return := -> $v {
            $tracker ~= 'LOL';
            &r($v * 2);
        };
        return(21);
    }
    is f(), 42, 'proxied return produces the correct value';
    is $tracker, 'LOL', 'proxied return produced the right side effect';
}

{
    sub a { .return with 42 }
    is a, 42, 'does .return work?';
    sub b { (1|2|3).return }  # don't auto-thread on return
    isa_ok b, Junction;
}

# vim: ft=perl6
