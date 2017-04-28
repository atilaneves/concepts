Concepts for D
===============

[![Build Status](https://travis-ci.org/atilaneves/concepts.png?branch=master)](https://travis-ci.org/atilaneves/concepts)

The main attraction is `models`, which can be used as a UDA or in a static assert:

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
the user knows _why_ it failed to compile.

This library also implements its own versions of the range template
constraints from Phobos so that they can be used with `models`:

```d
import concepts: models, isInputRange;

@models!(Foo, isInputRange)
struct Foo {
    // ...
}
```
