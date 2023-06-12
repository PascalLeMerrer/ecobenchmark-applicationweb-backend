import account.{Account}
import birl/time
import gleam/bit_string
import gleam/dynamic
import gleam/erlang/os.{get_env}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/pgo
import gleam/result
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

  TaskList(id: id, account_id: account_id, name: name, creation_date: current_datetime)
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

    // TODO return a result instead of doing an assertion?
    case pgo.execute(query: sql, on: db, with: [], expecting: return_type) {

      Ok(response) -> {

        
        list.map(response.rows, 
            fn(row) { io.debug(row.0)
                      
                      StatsByAccount( 
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




    

