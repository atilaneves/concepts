/**
   Better versions of Phobos's template contraints that emit
   error messages when they fail
   Can be used with concepts.models.models
 */
module concepts.range;

import std.array: front, popFront, empty, put, save, back, popBack;


void checkInputRange(R)(inout int = 0) {
    R r = R.init;     // can define a range object
    if (r.empty) {}   // can test for empty
    r.popFront;       // can invoke popFront()
    auto h = r.front; // can get the front of the range
}

/**
Returns $(D true) if $(D R) is an input range. An input range must
define the primitives $(D empty), $(D popFront), and $(D front). The
following code should compile for any input range.

----
R r;              // can define a range object
if (r.empty) {}   // can test for empty
r.popFront();     // can invoke popFront()
auto h = r.front; // can get the front of the range of non-void type
----

The following are rules of input ranges are assumed to hold true in all
Phobos code. These rules are not checkable at compile-time, so not conforming
to these rules when writing ranges or range based code will result in
undefined behavior.

$(UL
    $(LI `r.empty` returns `false` if and only if there is more data
    available in the range.)
    $(LI `r.empty` evaluated multiple times, without calling
    `r.popFront`, or otherwise mutating the range object or the
    underlying data, yields the same result for every evaluation.)
    $(LI `r.front` returns the current element in the range.
    It may return by value or by reference.)
    $(LI `r.front` can be legally evaluated if and only if evaluating
    `r.empty` has, or would have, equaled `false`.)
    $(LI `r.front` evaluated multiple times, without calling
    `r.popFront`, or otherwise mutating the range object or the
    underlying data, yields the same result for every evaluation.)
    $(LI `r.popFront` advances to the next element in the range.)
    $(LI `r.popFront` can be called if and only if evaluating `r.empty`
    has, or would have, equaled `false`.)
)

Also, note that Phobos code assumes that the primitives `r.front` and
`r.empty` are $(BIGOH 1) time complexity wise or "cheap" in terms of
running time. $(BIGOH) statements in the documentation of range functions
are made with this assumption.

Params:
    R = type to be tested

Returns:
    true if R is an InputRange, false if not
 */
enum isInputRange(R) = is(typeof(checkInputRange!R));

///
@safe pure unittest {

    import concepts.models: models;

    struct A {}
    struct B
    {
        void popFront();
        @property bool empty();
        @property int front();
    }
    static assert(!isInputRange!A);
    static assert( isInputRange!B);
    static assert( isInputRange!(int[]));
    static assert( isInputRange!(char[]));
    static assert(!isInputRange!(char[4]));
    static assert( isInputRange!(inout(int)[]));
}

void checkOutputRange(R, E)(inout int = 0) {
    R r = R.init;
    E e = E.init;
    put(r, e);
}


/++
Returns $(D true) if $(D R) is an output range for elements of type
$(D E). An output range is defined functionally as a range that
supports the operation $(D put(r, e)) as defined above.
 +/
enum isOutputRange(R, E) = is(typeof(checkOutputRange!(R, E)));


///
@safe pure unittest
{
    void myprint(in char[] s) { }
    static assert(isOutputRange!(typeof(&myprint), char));

    static assert(!isOutputRange!(char[], char));
    static assert( isOutputRange!(dchar[], wchar));
    static assert( isOutputRange!(dchar[], dchar));
}

@safe pure unittest
{
    import std.array;
    import std.stdio : writeln;

    auto app = appender!string();
    string s;
    static assert( isOutputRange!(Appender!string, string));
    static assert( isOutputRange!(Appender!string*, string));
    static assert(!isOutputRange!(Appender!string, int));
    static assert(!isOutputRange!(wchar[], wchar));
    static assert( isOutputRange!(dchar[], char));
    static assert( isOutputRange!(dchar[], string));
    static assert( isOutputRange!(dchar[], wstring));
    static assert( isOutputRange!(dchar[], dstring));

    static assert(!isOutputRange!(const(int)[], int));
    static assert(!isOutputRange!(inout(int)[], int));
}


void checkForwardRange(R)(inout int = 0) {

    checkInputRange!R;

    R r1 = R.init;
    // NOTE: we cannot check typeof(r1.save) directly
    // because typeof may not check the right type there, and
    // because we want to ensure the range can be copied.
    auto s1 = r1.save;
    static assert (is(typeof(s1) == R));
}


/**
Returns $(D true) if $(D R) is a forward range. A forward range is an
input range $(D r) that can save "checkpoints" by saving $(D r.save)
to another value of type $(D R). Notable examples of input ranges that
are $(I not) forward ranges are file/socket ranges; copying such a
range will not save the position in the stream, and they most likely
reuse an internal buffer as the entire stream does not sit in
memory. Subsequently, advancing either the original or the copy will
advance the stream, so the copies are not independent.

The following code should compile for any forward range.

----
static assert(isInputRange!R);
R r1;
auto s1 = r1.save;
static assert (is(typeof(s1) == R));
----

Saving a range is not duplicating it; in the example above, $(D r1)
and $(D r2) still refer to the same underlying data. They just
navigate that data independently.

The semantics of a forward range (not checkable during compilation)
are the same as for an input range, with the additional requirement
that backtracking must be possible by saving a copy of the range
object with $(D save) and using it later.
 */
enum isForwardRange(R) = is(typeof(checkForwardRange!R));

///
@safe pure unittest
{
    static assert(!isForwardRange!(int));
    static assert( isForwardRange!(int[]));
    static assert( isForwardRange!(inout(int)[]));
}

@("BUG 14544")
@safe pure unittest
{
    import concepts.models: models;

    @models!(R14544, isForwardRange)
    struct R14544
    {
        int front() { return 0;}
        void popFront() {}
        bool empty() { return false; }
        R14544 save() {return this;}
    }

    static assert(isForwardRange!R14544);
}


void checkBidirectionalRange(R)(inout int = 0) {
    R r = R.init;
    r.popBack;
    auto t = r.back;
    auto w = r.front;
    static assert(is(typeof(t) == typeof(w)));
}

/**
Returns $(D true) if $(D R) is a bidirectional range. A bidirectional
range is a forward range that also offers the primitives $(D back) and
$(D popBack). The following code should compile for any bidirectional
range.

The semantics of a bidirectional range (not checkable during
compilation) are assumed to be the following ($(D r) is an object of
type $(D R)):

$(UL $(LI $(D r.back) returns (possibly a reference to) the last
element in the range. Calling $(D r.back) is allowed only if calling
$(D r.empty) has, or would have, returned $(D false).))
 */
enum isBidirectionalRange(R) = is(typeof(checkBidirectionalRange!R));

///
@safe pure unittest
{
    alias R = int[];
    R r = [0,1];
    static assert(isForwardRange!R);           // is forward range
    r.popBack();                               // can invoke popBack
    auto t = r.back;                           // can get the back of the range
    auto w = r.front;
    static assert(is(typeof(t) == typeof(w))); // same type for front and back
}

@safe pure unittest
{
    struct A {}
    struct B
    {
        void popFront();
        @property bool empty();
        @property int front();
    }
    struct C
    {
        @property bool empty();
        @property C save();
        void popFront();
        @property int front();
        void popBack();
        @property int back();
    }
    static assert(!isBidirectionalRange!(A));
    static assert(!isBidirectionalRange!(B));
    static assert( isBidirectionalRange!(C));
    static assert( isBidirectionalRange!(int[]));
    static assert( isBidirectionalRange!(char[]));
    static assert( isBidirectionalRange!(inout(int)[]));
}

void checkRandomAccessRange(R)(inout int = 0) {

    import std.traits: isNarrowString;
    import std.range: hasLength, isInfinite;

    if(isBidirectionalRange!R) checkBidirectionalRange!R;
    if(isForwardRange!R) checkForwardRange!R;

    static assert(isBidirectionalRange!R ||
                  isForwardRange!R && isInfinite!R);
    R r = R.init;
    auto e = r[1];
    auto f = r.front;
    static assert(is(typeof(e) == typeof(f)));
    static assert(!isNarrowString!R);
    static assert(hasLength!R || isInfinite!R);

    static if (is(typeof(r[$])))
    {
        static assert(is(typeof(f) == typeof(r[$])));

        static if (!isInfinite!R)
            static assert(is(typeof(f) == typeof(r[$ - 1])));
    }
}


/**
Returns $(D true) if $(D R) is a random-access range. A random-access
range is a bidirectional range that also offers the primitive $(D
opIndex), OR an infinite forward range that offers $(D opIndex). In
either case, the range must either offer $(D length) or be
infinite. The following code should compile for any random-access
range.

The semantics of a random-access range (not checkable during
compilation) are assumed to be the following ($(D r) is an object of
type $(D R)): $(UL $(LI $(D r.opIndex(n)) returns a reference to the
$(D n)th element in the range.))

Although $(D char[]) and $(D wchar[]) (as well as their qualified
versions including $(D string) and $(D wstring)) are arrays, $(D
isRandomAccessRange) yields $(D false) for them because they use
variable-length encodings (UTF-8 and UTF-16 respectively). These types
are bidirectional ranges only.
 */
enum isRandomAccessRange(R) = is(typeof(checkRandomAccessRange!R));

///
@safe pure unittest
{
    import std.traits : isNarrowString;
    import std.range: isInfinite, hasLength;

    alias R = int[];

    // range is finite and bidirectional or infinite and forward.
    static assert(isBidirectionalRange!R ||
                  isForwardRange!R && isInfinite!R);

    R r = [0,1];
    auto e = r[1]; // can index
    auto f = r.front;
    static assert(is(typeof(e) == typeof(f))); // same type for indexed and front
    static assert(!isNarrowString!R); // narrow strings cannot be indexed as ranges
    static assert(hasLength!R || isInfinite!R); // must have length or be infinite

    // $ must work as it does with arrays if opIndex works with $
    static if (is(typeof(r[$])))
    {
        static assert(is(typeof(f) == typeof(r[$])));

        // $ - 1 doesn't make sense with infinite ranges but needs to work
        // with finite ones.
        static if (!isInfinite!R)
            static assert(is(typeof(f) == typeof(r[$ - 1])));
    }
}

@safe pure unittest
{
    import concepts.models: models;

    struct A {}
    struct B
    {
        void popFront();
        @property bool empty();
        @property int front();
    }
    struct C
    {
        void popFront();
        @property bool empty();
        @property int front();
        void popBack();
        @property int back();
    }

    @models!(D, isRandomAccessRange)
    struct D
    {
        @property bool empty();
        @property D save();
        @property int front();
        void popFront();
        @property int back();
        void popBack();
        ref int opIndex(uint);
        @property size_t length();
        alias opDollar = length;
        //int opSlice(uint, uint);
    }
    struct E
    {
        bool empty();
        E save();
        int front();
        void popFront();
        int back();
        void popBack();
        ref int opIndex(uint);
        size_t length();
        alias opDollar = length;
        //int opSlice(uint, uint);
    }
    static assert(!isRandomAccessRange!(A));
    static assert(!isRandomAccessRange!(B));
    static assert(!isRandomAccessRange!(C));
    static assert( isRandomAccessRange!(D));
    static assert( isRandomAccessRange!(E));
    static assert( isRandomAccessRange!(int[]));
    static assert( isRandomAccessRange!(inout(int)[]));
}

@safe pure unittest
{
    // Test fix for bug 6935.
    struct R
    {
        @disable this();

        @property bool empty() const { return false; }
        @property int front() const { return 0; }
        void popFront() {}

        @property R save() { return this; }

        @property int back() const { return 0; }
        void popBack(){}

        int opIndex(size_t n) const { return 0; }
        @property size_t length() const { return 0; }
        alias opDollar = length;

        void put(int e){  }
    }
    static assert(isInputRange!R);
    static assert(isForwardRange!R);
    static assert(isBidirectionalRange!R);
    static assert(isRandomAccessRange!R);
    static assert(isOutputRange!(R, int));
}
