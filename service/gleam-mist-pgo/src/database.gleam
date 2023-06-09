import gleam/pgo
import gleam/dynamic
import gleeunit/should
import gleam/erlang/os.{get_env}
import gleam/result
import gleam/int
import gleam/option.{Some}
import ids/uuid
import birl/time


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
  let sql = "INSERT INTO account(id, login, creation_date) VALUES ($1, $2, to_timestamp($3, 'YYY-MM-DDTHH24:MI:SS.FF3+TZH:TZM'))"

  // Run the query against the PostgreSQL database
  let assert Ok(id) = uuid.generate_v4()
  let current_datetime = time.now()
    |> time.to_iso8601

  let values = [
    pgo.text(id),
    pgo.text(login),
    pgo.text(current_datetime),
  ]

  let assert Ok(response) = pgo.execute(sql, db, values, dynamic.dynamic)

  response.count
  |> should.equal(1)
}
