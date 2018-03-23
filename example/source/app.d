import std.stdio : writeln;
import concepts : implements;

void main() {
    Foo x;

    x.useFoo;

    writeln("done");
}

interface IFoo {
    int foo(int i, string s) @safe;
    double lefoo(string s) @safe;
}

struct Foo {
    int foo(int i, string s) @safe { return 0; }
    double lefoo(string s) @safe { return 0; }
}

void useFoo(T)(T x)
    if(implements!(T, IFoo))
{
    writeln("Foo");
}
