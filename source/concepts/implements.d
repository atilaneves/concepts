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
        mixin(`auto _ = ` ~ implInterfaceStr ~ `;`);
    }

    private string implInterfaceStr() {
        string implString = "new class Interface {\n";
        foreach(memberName; __traits(allMembers, Interface)) {

            static if(!isPrivate!(Interface, memberName)) {

                alias member = Identity!(__traits(getMember, Interface, memberName));

                static if(__traits(isAbstractFunction, member)) {
                    foreach(overload; __traits(getOverloads, Interface, memberName)) {
                        implString ~= implMethodStr!overload ~ "\n";
                    }
                }
            }

        }

        implString ~= "}";

        return implString;
    }


    // returns a string to mixin that implements the method
    private string implMethodStr(alias method)() {
        import std.traits: ReturnType, Parameters;

        // e.g. int arg0, string arg1
        string typeArgs() {
            import std.array: array, join;
            import std.conv: text;
            string[] args;
            foreach(i, _; Parameters!method) {
                args ~= text(Parameters!method[i].stringof, ` arg`, i);
            }
            return args.join(", ");
        }

        // e.g. arg0, arg1
        string callArgs() {
            import std.range: iota;
            import std.algorithm: map;
            import std.array: array, join;
            import std.conv: text;
            return Parameters!method.length.iota.map!(i => text(`arg`, i)).array.join(`, `);
        }

        enum methodName = __traits(identifier, method);
        alias R = ReturnType!method;
        return `override ` ~ R.stringof ~ " " ~ methodName ~
                  `(` ~ typeArgs ~ `) {` ~
                  ` return T` ~ `.init.` ~ methodName ~ `(` ~ callArgs() ~ `);` ~
                  `}`;
    }

}


@("Foo implements IFoo")
@safe unittest {
    static assert(__traits(compiles, implements!(Foo, IFoo)));
    static assert(!__traits(compiles, implements!(Bar, IFoo)));
    static assert(!__traits(compiles, implements!(Foo, IBar)));
    static assert(__traits(compiles, implements!(Bar, IBar)));
    static assert(!__traits(compiles, implements!(UnsafeBar, IBar)));

    static assert(__traits(compiles, useFoo(Foo())));
    static assert(!__traits(compiles, useBar(Foo())));
    static assert(!__traits(compiles, useFoo(Bar())));
    static assert(__traits(compiles, useBar(Bar())));
}

@("FooBar implements IFoo and IBar")
@safe unittest {
    static assert(__traits(compiles, implements!(FooBar, IFoo)));
    static assert(__traits(compiles, implements!(FooBar, IBar)));

    static assert(__traits(compiles, useFoo(FooBar())));
    static assert(__traits(compiles, useBar(FooBar())));

    static assert(__traits(compiles, useFooandBar(FooBar())));
}

@("FooClass implements IFoo")
@safe unittest {
    static assert(__traits(compiles, implements!(FooClass, IFoo)));
    static assert(__traits(compiles, useFoo(FooClass.init)));
}

@("Foo implements FooAbstractClass")
@safe unittest {
    static assert(__traits(compiles, implements!(Foo, FooAbstractClass)));
}

version(unittest) {

    interface IFoo {
        int foo(int i, string s) @safe;
        double lefoo(string s) @safe;
    }

    interface IBar {
        string bar(double d) @safe;
        void bar(string s) @safe;
    }

    struct Foo {
        int foo(int i, string s) @safe { return 0; }
        double lefoo(string s) @safe { return 0; }
    }

    struct Bar {
        string bar(double d) @safe { return ""; }
        void bar(string s) @safe { }
    }

    struct UnsafeBar {
        string bar(double d) @system { return ""; }
        void bar(string s) @system { }
    }

    struct FooBar {
        int foo(int i, string s) @safe { return 0; }
        double lefoo(string s) @safe { return 0; }
        string bar(double d) @safe { return ""; }
        void bar(string s) @safe { }
    }

    class FooClass {
        int foo(int i, string s) @safe { return 0; }
        double lefoo(string s) @safe { return 0; }
    }

    class FooAbstractClass {
        abstract int foo(int i, string s) @safe;
        final double lefoo(string s) @safe { return 0; }
    }

    void useFoo(T)(T) if(implements!(T, IFoo)) {}
    void useBar(T)(T) if(implements!(T, IBar)) {}
    void useFooandBar(T)(T) if(implements!(T, IFoo) && implements!(T, IBar)) {}
}
