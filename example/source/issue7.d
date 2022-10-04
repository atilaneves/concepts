import concepts;

private interface DatabaseDriver { void foo(); }
private enum isDatabaseDriver(T) = implements!(T, DatabaseDriver);

final class SQLite3 : DatabaseDriver { void foo() { } }
static assert(isDatabaseDriver!SQLite3);
