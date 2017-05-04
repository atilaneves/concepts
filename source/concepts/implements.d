module concepts.implements;

alias Identity(alias T) = T;
private enum isPrivate(T, string member) = !__traits(compiles, __traits(getMember, T, member));


version(unittest) {

    interface IFoo {
        int foo(int i, string s) @safe;
    }

    interface IBar {
        string bar(double d) @safe;
    }

    struct Foo {
        int foo(int i, string s) @safe;
    }

    struct Bar {
        string bar(double d) @safe;
    }

    struct UnsafeBar {
        string bar(double d) @system;
    }
}

template implements(alias T, alias Interface, A...) {

    bool implements() @safe {

        auto ret = true;
        foreach(memberName; __traits(allMembers, Interface)) {

            static if(!isPrivate!(Interface, memberName)) {

                alias member = Identity!(__traits(getMember, Interface, memberName));

                static if(__traits(isAbstractFunction, member)) {
                    // foreach(i, overload; __traits(getOverloads, Interface, memberName)) {
                    //     pragma(msg, memberName);
                    // }
                    if(!__traits(compiles, createClass!member))
                        ret = ret && false;
                }
            }

        }
        return ret;
    }

    private Interface createClass(alias method)() {
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

        return new class Interface {
            enum methodName = __traits(identifier, method);
            mixin(q{ override ReturnType!method } ~  methodName ~
                  `(` ~ typeArgs ~ `) {` ~
                  ` return ` ~ T.stringof ~ `.init.` ~ methodName ~ `(` ~ callArgs() ~ `);` ~
                  `}`);
        };
    }
}

@("Foo implements IFoo")
@safe unittest {
    static assert(implements!(Foo, IFoo));
    static assert(!implements!(Bar, IFoo));
    static assert(!implements!(Foo, IBar));
    static assert(implements!(Bar, IBar));
    static assert(!implements!(UnsafeBar, IBar));
}
