import imports;
import concepts:implements;
import std.datetime: DateTime;


interface RateCalculation
{
    DateTime firstFixingDate();
}

@implements!(Foo, RateCalculation)
struct Foo
{
    DateTime firstFixingDate() {
        return DateTime.init;
    }
}


interface Params {
    void fun(DateTime d, LeParam p);
}

@implements!(Bar, Params)
struct Bar {
    void fun(DateTime d, LeParam p) {

    }
}
