Concepts for D
--------------


Right now there's only `models`, which can be used as a UDA or in a static assert:

```d
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
```

Here a template constraint `isFoo` is guaranteed to be true for type `Foo`.
The difference between this and a regular static assert is that when the
predicate fails the code for `checkFoo` is instantiated anyway so that
the user knows _why_ it failed to compile.
