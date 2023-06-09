import gleam/pgo
import gleam/dynamic
import gleeunit/should
import gleam/erlang/os.{get_env}
import gleam/result
import gleam/int
import gleam/bit_string
import gleam/option.{Some}


pub fn connect() -> pgo.Connection {
  //TODO: parse the URL
  let database_url =
    get_env("DATABASE_URL")
    |> result.unwrap(
      "postgresql://postgres:mysecretpassword@127.0.0.1:5432/postgres",
    )

  let database_pool_size =
    get_env("DATABASE_POOL_SIZE")
    |> result.unwrap("20")
    |> int.base_parse(10)
    |> result.unwrap(20)

  pgo.connect(
    pgo.Config(
      ..pgo.default_config(),
      host: "127.0.0.1",
      port: 5432,
      database: "postgres",
      user: "postgres",
      password: Some("mysecretpassword"),
      pool_size: database_pool_size,
    ),
  )
}

pub fn add_account(login: String) {
  // TODO avoid multiple connections
  let db = connect()

  // INSERT INTO account(id, login, creation_date) values ($1, $2, $3);
  let sql = "INSERT INTO account(id, login, creation_date) VALUES ($1, $2, $3)"

  // Run the query against the PostgreSQL database
  let values = [
    pgo.int(42),
    pgo.text("Marcel"),
    pgo.text("2004-10-19 10:23:54+02"),
  ]

  // This is the decoder for the value returned by the query
  let return_type =
    dynamic.tuple3(dynamic.string, dynamic.string, dynamic.bit_string)

  let assert Ok(response) = pgo.execute(sql, db, values, return_type)

  response.count
  |> should.equal(1)
  response.rows
  |> should.equal([#("42", "Marcel", bit_string.from_string("2004-10-19 10:23:54+02"))])
}
