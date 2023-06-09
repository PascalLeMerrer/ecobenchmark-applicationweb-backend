import gleam/pgo
import gleam/dynamic
import gleeunit/should
import gleam/erlang/os.{get_env}
import gleam/result
import gleam/int
import gleam/option.{Some}
import ids/uuid
import birl/time
import account.{Account}
import list.{List}

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

pub fn add_account(db: pgo.Connection, login: String) -> Account {
  
  // pgo doesn't support yet timestampz so we give a string to PG and ask it to convert it to timestampz
  let sql =
    "INSERT INTO account(id, login, creation_date) VALUES ($1, $2, to_timestamp($3, 'YYY-MM-DDTHH24:MI:SS.FF3+TZH:TZM'))"

  let assert Ok(id) = uuid.generate_v4()
  let current_datetime =
    time.now()
    |> time.to_iso8601

  let values = [pgo.text(id), pgo.text(login), pgo.text(current_datetime)]

  let assert Ok(response) = pgo.execute(sql, db, values, dynamic.dynamic)

  response.count
  |> should.equal(1)

  Account(id: id, login: login, creation_date: current_datetime)
}

pub fn add_list(db: pgo.Connection, account_id: String, name: String) -> List {
  
  // pgo doesn't support yet timestampz so we give a string to PG and ask it to convert it to timestampz
  let sql =
    "INSERT INTO list(id, account_id, name, creation_date) VALUES ($1, $2, $3, to_timestamp($4, 'YYY-MM-DDTHH24:MI:SS.FF3+TZH:TZM'))"

  let assert Ok(id) = uuid.generate_v4()
  let current_datetime =
    time.now()
    |> time.to_iso8601

  let values = [pgo.text(id), pgo.text(account_id), pgo.text(name), pgo.text(current_datetime)]

  let assert Ok(response) = pgo.execute(sql, db, values, dynamic.dynamic)

  response.count
  |> should.equal(1)

  List(id: id, account_id: account_id, name: name, creation_date: current_datetime)
}
