Concepts for D
===============

[![Build Status](https://travis-ci.org/atilaneves/concepts.png?branch=master)](https://travis-ci.org/atilaneves/concepts)

Template constraints in D are one the language's best
features. However, when a constraint fails it can be hard to know
_why_ it failed. This library tries to remedy that by providing a way
to specify that user-defined types are supposed to implement a
compile-time interface, or concept. An example would be
`isInputRange`. If you happen to, say, spell `empty` as `empt` by
mistake your type would not be an input range, but you wouldn't know
_why_ that's the case even though the compiler does. The fix is to use
`models`, which can be used as a UDA or in a static assert:

```d
import concepts.models: models;

void checkFoo(T)()
{
    T t = T.init;
    t.foo();
}

enum isFoo(T) = is(typeof(checkFoo!T));

@models!(Foo, isFoo) //as a UDA
struct Foo
{
    void foo() {}
    static assert(models!(Foo, isFoo)); //as a static assert
}

// can still be used as a template constraint:
void useFoo(T)(auto ref T foo) if(isFoo!T) {

}
```

Here a template constraint `isFoo` is guaranteed to be true for type `Foo`.
The difference between this and a regular static assert is that when the
predicate fails the code for `checkFoo` is instantiated anyway so that
the user knows _why_ it failed to compile. Example error message with dmd 2.074:

```
source/concepts/models.d(111,10): Error: no property 'foo' for type 'Foo', did you mean 'fo'?
source/concepts/models.d-mixin-42(42,1): Error: template instance concepts.models.checkFoo!(Foo) error instantiating
source/concepts/models.d(61,6):        instantiated from here: models!(Foo, isFoo)
```


This library also implements its own versions of the range template
constraints from Phobos so that they can be used with `models`:

```d
import concepts: models, isInputRange;

@models!(Foo, isInputRange)
struct Foo {
    // ...
}
```

Example error message with dmd 2.074 (having implemented `front` and `popFront` but not `empty`):


```
source/concepts/range.d(13,10): Error: template std.range.primitives.empty cannot deduce function from argument types !()(B), candidates are:
/usr/include/dlang/dmd/std/range/primitives.d(2043,16):        std.range.primitives.empty(T)(in T[] a)
source/concepts/models.d-mixin-42(42,1): Error: template instance concepts.range.checkInputRange!(B) error instantiating
source/concepts/range.d(72,6):        instantiated from here: models!(B, isInputRange)
```

Using a D `interface` to specify compile-time template constraints
------------------------------------------------------------------

```d
interface IFoo {
    int foo(int i, string s) @safe;
    double lefoo(string s) @safe;
}

@implements!(Foo, IFoo)
struct Foo {
    int foo(int i, string s) @safe { return 0; }
    double lefoo(string s) @safe { return 0; }
}

// doesn't compile
/*
@implements!(Oops, IFoo)
struct Oops {}
*/
````

Other examples
--------------

Contraining a struct to not have member functions (credit to @jmh530):

```d
void checkOnlyData(T)()
    if (is(T == struct))
{
    import std.traits : isFunction;

    static foreach (mem; __traits(allMembers, T))
    {
        static if (mem != "this")
        {
            static assert(!(isFunction!(__traits(getMember, T.init, mem))),
                          T.stringof ~ " is constrained to not have any member functions, but it has (at least) the member function: " ~ mem);
        }
    }
}

template isOnlyData(T)
    if (is(T == struct))
{
    enum isOnlyData = is(typeof(checkOnlyData!(T)));
}

@models!(Foo, isOnlyData)
struct Foo
{
    int a;
}

Foo foo;
```
