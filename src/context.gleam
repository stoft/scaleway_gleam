import gleam/dynamic/decode
import simplifile
import sqlight

pub type Context {
  Context(db_path: String)
}

pub fn new(db_path: String) -> Context {
  Context(db_path: db_path)
}

pub fn database_path(ctx: Context) -> String {
  ctx.db_path
}

pub fn setup_database(ctx: Context) -> Result(Nil, String) {
  let db_path = database_path(ctx)

  // Ensure the database file exists by creating an empty file if it doesn't
  case simplifile.is_file(db_path) {
    Ok(False) -> {
      // Create empty file to ensure SQLite can open it
      case simplifile.write("", to: db_path) {
        Ok(_) -> Ok(Nil)
        Error(_) -> Error("Failed to create database file")
      }
    }
    Ok(True) -> Ok(Nil)
    Error(_) -> Error("Failed to check database file")
  }
}

pub fn increment_visit_counter(ctx: Context) -> Result(Int, String) {
  let db_path = database_path(ctx)

  use conn <- sqlight.with_connection(db_path)

  // Ensure tables exist and perform operations
  let _ =
    sqlight.exec(
      "create table if not exists visits (id integer primary key, timestamp text)",
      conn,
    )

  let _ =
    sqlight.exec(
      "create table if not exists counters (name text primary key, value int not null)",
      conn,
    )

  // Insert a new visit row (audit trail)
  let _ =
    sqlight.exec(
      "insert into visits (timestamp) values (datetime('now'))",
      conn,
    )

  // Increment the durable counter for hello page
  let _ =
    sqlight.exec(
      "insert into counters(name, value) values ('hello_visits', 1)\n"
        <> "on conflict(name) do update set value = counters.value + 1",
      conn,
    )

  // Query the durable counter value
  let count_decoder = {
    use c <- decode.field(0, decode.int)
    decode.success(c)
  }

  case
    sqlight.query(
      "select value from counters where name = 'hello_visits'",
      on: conn,
      with: [],
      expecting: count_decoder,
    )
  {
    Ok([c]) -> Ok(c)
    Ok(_) -> Ok(0)
    Error(_) -> Error("Failed to query counter")
  }
}
