import account.{Account}
import birl/time
import gleam/dynamic.{Dynamic, DecodeError, DecodeErrors}
import gleam/erlang/os.{get_env}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/pgo
import gleam/result
import gleam/string_builder

import gleeunit/should
import ids/uuid
import stats_by_account.{StatsByAccount}
import task.{Task}
import task_list.{TaskList}


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

pub fn add_list(db: pgo.Connection, account_id: String, name: String) -> TaskList {
  
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

  TaskList(id: id, account_id: account_id, name: name, creation_date: current_datetime, tasks: [])
}

pub fn add_task(db: pgo.Connection, list_id: String, name: String, description: String) -> Task {
  
  // pgo doesn't support yet timestampz so we give a string to PG and ask it to convert it to timestampz
  let sql =
    "INSERT INTO task(id, list_id, name, description, creation_date) VALUES ($1, $2, $3, $4, to_timestamp($5, 'YYY-MM-DDTHH24:MI:SS.FF3+TZH:TZM'))"

  let assert Ok(id) = uuid.generate_v4()
  let current_datetime =
    time.now()
    |> time.to_iso8601

  let values = [pgo.text(id), pgo.text(list_id), pgo.text(name), pgo.text(description), pgo.text(current_datetime)]

  let assert Ok(response) = pgo.execute(sql, db, values, dynamic.dynamic)

  response.count
  |> should.equal(1)

  Task(id: id, list_id: list_id, name: name, description: description, creation_date: current_datetime)
}


pub fn get_stats(db: pgo.Connection) -> List(StatsByAccount) {

    let sql = "SELECT id::text, login, count(list_id) as nb_list, round(avg(nb_tasks),2) as avg_tasks 
               FROM 
               (
                    SELECT account.id, account.login, list.id list_id, count(task.id) nb_tasks 
                    FROM account 
                    INNER JOIN list on (list.account_id=account.id) 
                    LEFT JOIN task on (task.list_id=list.id) 
                    GROUP BY account.id, account.login, list.id
               ) t 
               GROUP BY id, login"

    let return_type = dynamic.tuple4(
      dynamic.string,
      dynamic.string,
      dynamic.int,
      dynamic.float,
    )

    case pgo.execute(query: sql, on: db, with: [], expecting: return_type) {

      Ok(response) -> {

        
        list.map(response.rows, 
            fn(row) { StatsByAccount( 
                        account_id: row.0, 
                        account_login:row.1,
                        list_count:row.2,
                        task_avg:row.3) 
                    } 
          )
      }
      Error(err) -> {
        io.println("Error")
        io.debug(err)
        []
      }
    }
}

external fn decode_tuple8(  
    Dynamic,
  ) -> Result(
    #(Dynamic, Dynamic, Dynamic, Dynamic, Dynamic, Dynamic, Dynamic, Dynamic),
    DecodeErrors,
  ) =
    "tuple8" "decode_tuple8"


fn tuple_errors(
  result: Result(a, List(DecodeError)),
  name: String,
) -> List(DecodeError) {
  case result {
    Ok(_) -> []
    Error(errors) -> {
      io.println("1")
      list.map(errors, push_path(_, name))
    }
      
  }
}    

fn push_path(error: DecodeError, name: t) -> DecodeError {
  let name = dynamic.from(name)
  let decoder = dynamic.any([dynamic.string, fn(x) { result.map(dynamic.int(x), int.to_string) }])
  let name = case decoder(name) {
    Ok(name) -> name
    Error(_) -> {

      io.println("2")

      ["<", dynamic.classify(name), ">"]
      |> string_builder.from_strings
      |> string_builder.to_string
    }
  }
  DecodeError(..error, path: [name, ..error.path])
}


pub fn tuple8(first decode1: fn(Dynamic) ->
    Result(a, List(DecodeError)), second decode2: fn(Dynamic) ->
    Result(b, List(DecodeError)), third decode3: fn(Dynamic) ->
    Result(c, List(DecodeError)), fourth decode4: fn(Dynamic) ->
    Result(d, List(DecodeError)), fifth decode5: fn(Dynamic) ->
    Result(e, List(DecodeError)), sixth decode6: fn(Dynamic) ->
    Result(f, List(DecodeError)), seventh decode7: fn(Dynamic) ->
    Result(g, List(DecodeError)), eight decode8: fn(Dynamic) ->
    Result(h, List(DecodeError))) 
      -> fn(Dynamic) -> 
      Result(#(a, b, c, d, e, f, g, h), List(DecodeError)) {
        
          fn(value) {
            use #(a, b, c, d, e, f, g, h) <- result.try(decode_tuple8(value))
            case
              decode1(a),
              decode2(b),
              decode3(c),
              decode4(d),
              decode5(e),
              decode6(f),
              decode7(g),
              decode8(h)
            {
              Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f) , Ok(g) , Ok(h) -> Ok(#(a, b, c, d, e, f, g, h))
              a, b, c, d, e, f, g, h ->
                tuple_errors(a, "0")
                |> list.append(tuple_errors(b, "1"))
                |> list.append(tuple_errors(c, "2"))
                |> list.append(tuple_errors(d, "3"))
                |> list.append(tuple_errors(e, "4"))
                |> list.append(tuple_errors(f, "5"))
                |> list.append(tuple_errors(g, "6"))
                |> list.append(tuple_errors(h, "7"))
                |> Error
            }
          }
      } 

pub fn get_lists(db: pgo.Connection, account_id: String, page: Int) -> List(TaskList) {

  let sql ="SELECT
                l.id::text,
                l.name,
                TO_CHAR(l.creation_date, 'YYYY/MM/DD HH12:MM:SS'),
                l.account_id::text,
                t.id::text AS task_id,
                t.name AS task_name,
                t.description,
                TO_CHAR(t.creation_date, 'YYYY/MM/DD HH12:MM:SS') AS task_creation_date
            FROM list l
                LEFT JOIN task t ON l.id = t.list_id
            WHERE
                l.account_id = $1
                AND l.id IN (SELECT id FROM list WHERE account_id = $1 LIMIT $2 OFFSET $3)
            "

    let return_type = tuple8(
      dynamic.string, // 0 list id      
      dynamic.string, // 1 list name
      dynamic.string, // 2 list creation date
      dynamic.string, // 3 list account id
      dynamic.string, // 4 task id
      dynamic.string, // 5 task name
      dynamic.string, // 6 task description
      dynamic.string, // 7 task creation_date
    )


    let response = pgo.execute(query: sql, on: db, with: [pgo.text(account_id), pgo.int(10), pgo.int(page * 10)], expecting: return_type)
    
    case response {

      Ok(response) -> {

        io.debug(response.rows)
        let account_lists = []
        
        list.map(response.rows, 
            fn(row) { 
              let id = row.0  
              let task  = Task (id: row.4, list_id: row.0, name: row.5, description: row.6, creation_date: row.7)
              case list.find(in: account_lists, one_that: fn(t:TaskList){ t.id == id } ) {
                Ok(task_list_) -> 
                  TaskList(..task_list_, tasks: [task, ..task_list_.tasks])
                Error(_) ->
                  TaskList(id: id, account_id: row.3, name: row.1, creation_date: row.2, tasks: [task])
              }
            } 
          )
      }
      Error(err) -> {
        io.println("Error")
        io.debug(err)
        []

      }

    }
} 

    

