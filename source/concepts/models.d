module concepts.models;

/**
 * A static assertion that a type satisfies a given template constraint.
 * It can be used as a $(LINK2 ../attribute.html#uda, UDA) or
 * in a `static assert` to make sure that a type conforms
 * to the compile-time interface the user expects it to.
 * The difference between using `models` and a simple static assert
 * with the template contraint is that `models` will instantiate the
 * failing code when the constraint is not satisfied,
 * yielding compiler error messages to aid the user.
 *
 * The template contraint predicate must start with the word `is`
 * (e.g. `isInputRange`) and an associated template function
 * with the "is" replaced by "check" should exist (e.g. `checkInputRange`)
 * and be defined in the same module.
 */
template models(alias T, alias P, A...)
{
    static assert(P.stringof[0..2] == "is",
                  P.stringof ~ " does not begin with 'is', which is require by `models`");

    static if(P!(T, A))
    {
        bool models()
        {
            return true;
        }
    }
    else
    {
        bool models()
        {
            import std.algorithm: countUntil;
            import std.traits: moduleName;

            enum openParenIndex = P.stringof.countUntil("(");
            enum untilOpenParen = P.stringof["is".length .. openParenIndex];
            enum checkName = "check" ~ untilOpenParen;
            enum mixinStr = checkName ~ "!(T, A);";
            mixin("import " ~ moduleName!(P) ~ ";"); //make it visible first
            mixin(mixinStr);
            return false;
        }
    }
}

///
@safe pure unittest
{
    // can't assert that, e.g. !models!(Bar, isFoo) -
    // the whole point of `models` is that it doesn't compile
    // when the template constraint is not satisfied
    static assert(!__traits(compiles, models!(Bar, isFoo)));
    static assert(!__traits(compiles, models!(Foo, isBar, byte)));
}


@safe pure unittest {
    enum weirdPred(T) = true;
    //always true, this is a sanity check
    static assert(weirdPred!Foo);
    //shouldn't compile since weirdPred doesn't begin with the word "is"
    static assert(!__traits(compiles, models!(Foo, weirdPred)));
}


@("@models can be applied to serialise")
@safe pure unittest {
    static assert( __traits(compiles, models!(serialise,        isSerialisationFunction)));
    static assert(!__traits(compiles, models!(doesNotSerialise, isSerialisationFunction)));
}

@("@models can be applied to deserialise")
@safe pure unittest {
    static assert( __traits(compiles, models!(deserialise, isDeserialisationFunction)));
    static assert(!__traits(compiles, models!(deserialise, isSerialisationFunction)));
}


version(unittest) {

    private enum isFoo(T) = is(typeof(checkFoo!T));
    @models!(Foo, isFoo) //as a UDA
    private struct Foo {
        void foo() {}
        static assert(models!(Foo, isFoo)); //as a static assert
    }

    private template isBar(T, U) {
        enum isBar = is(typeof(checkBar!(T, U)));
    }

    @models!(Bar, isBar, byte) //as a UDA
    private struct Bar {
        byte bar;
        static assert(models!(Bar, isBar, byte)); //as a static assert
    }

    private void checkFoo(T)()
    {
        T t = T.init;
        t.foo();
    }

    private void checkBar(T, U)()
    {
        U _bar = T.init.bar;
    }

    private void checkSerialisationFunction(alias F)() {
        ubyte[] bytes = F(5);
    }

    private enum isSerialisationFunction(alias F) = is(typeof(checkSerialisationFunction!F));

    @models!(serialise, isSerialisationFunction)
    private ubyte[] serialise(T)(in T val) {
        return [42];
    }

    private void doesNotSerialise(T)(in T val) {

    }

    private void checkDeserialisationFunction(alias F)() {
        ubyte[] bytes;
        int res = F!int(bytes);
    }
    private enum isDeserialisationFunction(alias F) = is(typeof(checkDeserialisationFunction!F));

    private T deserialise(T)(in ubyte[] bytes) {
        return T.init;
    }
}
