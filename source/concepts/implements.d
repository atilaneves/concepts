module concepts.implements;

import std.traits : isAbstractClass, isAggregateType;

alias Identity(alias T) = T;
private enum isPrivate(T, string member) = !__traits(compiles, __traits(getMember, T, member));


template implements(alias T, alias Interface)
    if (isAggregateType!T && isAbstractClass!Interface) {

    static if(__traits(compiles, check())) {
        bool implements() {
            return true;
        }
    } else {
        bool implements() {
            // force compilation error
            check();
            return false;
        }
    }

    private void check() @safe pure {
        enum mixinStr = `auto _ = ` ~ implInterfaceStr ~ `;`;
        //pragma(msg, mixinStr);
        mixin(mixinStr);
    }

    private string implInterfaceStr() {
        string implString = "new class Interface {\n";
        foreach(memberName; __traits(allMembers, Interface)) {

            static if(!isPrivate!(Interface, memberName)) {

                alias member = Identity!(__traits(getMember, Interface, memberName));

                static if(__traits(isAbstractFunction, member)) {
                    foreach(overload; __traits(getOverloads, Interface, memberName)) {
                        foreach(line; implMethodStr!overload) {
                            implString ~= `    ` ~ line ~ "\n";
                        }
                    }
                }
            }

        }

        implString ~= "}";

        return implString;
    }

    // returns a string to mixin that implements the method
    private string[] implMethodStr(alias method)() {

        import std.traits: ReturnType, Parameters, moduleName;
        import std.meta: staticMap;
        import std.algorithm: map;
        import std.range: iota;
        import std.array: join, array;
        import std.conv: text;


        if(!__ctfe) return [];

        // e.g. int arg0, string arg1
        string typeArgs() {
            string[] args;
            foreach(i, _; Parameters!method) {
                args ~= text(Parameters!method[i].stringof, ` arg`, i);
            }
            return args.join(", ");
        }

        // e.g. arg0, arg1
        string callArgs() {
            return Parameters!method.length.iota.map!(i => text(`arg`, i)).array.join(`, `);
        }

        string[] importMixin(T)() {
            static if(__traits(compiles, moduleName!T)) {
                return [`import ` ~ moduleName!T ~ `: ` ~ T.stringof ~ `;`];
            } else
                return [];
        }

        string[] ret;

        ret ~= importMixin!(ReturnType!method);

        foreach(P; Parameters!method) {
            ret ~= importMixin!P;
        }

        enum methodName = __traits(identifier, method);

        ret ~=
            `override ` ~ ReturnType!method.stringof ~ " " ~ methodName ~
            `(` ~ typeArgs ~ `) {` ~
            ` return T` ~ `.init.` ~ methodName ~ `(` ~ callArgs() ~ `);` ~
            ` }`;

        return ret;
    }

}

unittest {

}

@("Foo implements IFoo")
@safe pure unittest {
    static assert(__traits(compiles, implements!(Foo, IFoo)));
    static assert(is(typeof({ implements!(Foo, IFoo); })));
    static assert(!is(typeof({ implements!(Bar, IFoo); })));
    static assert(!__traits(compiles, implements!(Bar, IFoo)));
    static assert(!is(typeof({ implements!(Foo, IBar); })));

    static assert( is(typeof({ implements!(Bar,      IBar); })));
    static assert(!is(typeof({ implements!(UnsafeBar, IBar); })));

    static assert(__traits(compiles, useFoo(Foo())));
    static assert(!__traits(compiles, useBar(Foo())));
    static assert(!__traits(compiles, useFoo(Bar())));
    static assert(__traits(compiles, useBar(Bar())));
}

@("FooBar implements IFoo and IBar")
@safe pure unittest {
    static assert(__traits(compiles, implements!(FooBar, IFoo)));
    static assert(__traits(compiles, implements!(FooBar, IBar)));

    static assert(__traits(compiles, useFoo(FooBar())));
    static assert(__traits(compiles, useBar(FooBar())));

    static assert(__traits(compiles, useFooandBar(FooBar())));
}

@("FooClass implements IFoo")
@safe pure unittest {
    static assert(__traits(compiles, implements!(FooClass, IFoo)));
    static assert(__traits(compiles, useFoo(FooClass.init)));
}

@("Foo implements FooAbstractClass")
@safe pure unittest {
    static assert(__traits(compiles, implements!(Foo, FooAbstractClass)));
}

version(unittest):

private interface IFoo {
    int foo(int i, string s) @safe;
    double lefoo(string s) @safe;
}

private interface IBar {
    string bar(double d) @safe;
    void bar(string s) @safe;
}

private struct Foo {
    int foo(int i, string s) @safe { return 0; }
    double lefoo(string s) @safe { return 0; }
}

private struct Bar {
    string bar(double d) @safe { return ""; }
    void bar(string s) @safe { }
}

private struct UnsafeBar {
    string bar(double d) @system { return ""; }
    void bar(string s) @system { }
}

private struct FooBar {
    int foo(int i, string s) @safe { return 0; }
    double lefoo(string s) @safe { return 0; }
    string bar(double d) @safe { return ""; }
    void bar(string s) @safe { }
}

private class FooClass {
    int foo(int i, string s) @safe { return 0; }
    double lefoo(string s) @safe { return 0; }
}

private class FooAbstractClass {
    abstract int foo(int i, string s) @safe;
    final double lefoo(string s) @safe { return 0; }
}

private void useFoo(T)(T) if(implements!(T, IFoo)) {}
private void useBar(T)(T) if(implements!(T, IBar)) {}
private void useFooandBar(T)(T) if(implements!(T, IFoo) && implements!(T, IBar)) {}
