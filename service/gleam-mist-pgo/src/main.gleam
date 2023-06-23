import account
import database
import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/erlang/process
import gleam/function.{curry2, curry3}
import gleam/http.{Get, Post}
import gleam/http/request.{Request, get_query}
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/pgo
import gleam/result.{unwrap}
import gleam/string
import mist
import stats_by_account
import task
import task_list

pub fn main() {
  let db = database.connect()

  let assert Ok(_) =
    mist.serve(
      8080,
      mist.handler_func(fn(req) {
        case req.method, request.path_segments(req) {
          Post, ["api", "accounts"] -> create(req, curry2(add_account)(db))
          Post, ["api", "accounts", account_id, "lists"] -> create(req, curry3(add_list)(account_id)(db))
          Post, ["api", "lists", list_id, "tasks"] -> create(req, curry3(add_task_to_list)(list_id)(db))  
          Get, ["api", "accounts", account_id, "lists"] ->
            get_lists(db, account_id, unwrap(get_query(req), []))
          Get, ["api", "stats"] -> get_stats(db)
          _, _ ->
            response.new(404)
            |> mist.bit_builder_response(bit_builder.from_string("Not found"))
        }
      }),
    )
  process.sleep_forever()
}

fn create(req: Request(mist.Body), 
          fun: fn(BitString) -> Result(String, String) ) 
  {
  
  let request_with_body = mist.read_body(req)
  result.map(
    over: request_with_body,
    with: fn(r) {
      case fun(r.body) {
        Ok(s) -> {
          mist.bit_builder_response(
            response.new(201),
            bit_builder.from_string(s)
          )
        }
        Error(s) -> {
          mist.bit_builder_response(
            response.new(400),
            bit_builder.from_string(s)
          )
        }
      }
    }
  )
  |> result.unwrap(mist.empty_response(response.new(400)))
}

// add account

fn add_account( db: pgo.Connection, body: BitString) -> Result(String, String) {
  case bit_string.to_string(body) {
    Ok(body_string) -> {
      // parse json
      case decode_add_account_body(body_string) {
        Ok(add_account_body) -> {
          database.add_account(db, add_account_body.login)
          |> account.to_string
          |> Ok
        }
        Error(_) -> Error("can't parse JSON")  // Convert DecodeError to string
      }
    }
    Error(_err) -> {
      Error("Error: missing value for login")
    }
  }
}

pub type AddAccountBody {
  AddAccountBody(login: String)
}

pub fn decode_add_account_body(
  json_string: String,
) -> Result(AddAccountBody, json.DecodeError) {
  let decoder =
    dynamic.decode1(AddAccountBody, dynamic.field("login", of: dynamic.string))

  json.decode(from: json_string, using: decoder)
}

// add list

fn add_list(account_id: String, db: pgo.Connection, body: BitString) -> Result(String, String) {
  case bit_string.to_string(body) {
    Ok(body_string) -> {
      case decode_add_list_body(body_string) {
        Ok(add_list_body) -> {
          database.add_list(db, account_id, add_list_body.name)
          |> task_list.to_string
          |> Ok
        }
        Error(_) -> Error("can't parse JSON")  // Convert DecodeError to string
      }
    }
    Error(_err) -> {
      Error("Error: missing value for list name")
    }
  }
}

pub type AddListBody {
  AddListBody(name: String)
}

pub fn decode_add_list_body(
  json_string: String,
) -> Result(AddListBody, json.DecodeError) {
  let decoder =
    dynamic.decode1(AddListBody, dynamic.field("name", of: dynamic.string))

  json.decode(from: json_string, using: decoder)
}

// add task to list

pub type AddTaskBody {
  AddTaskBody(name: String, description: String)
}

pub fn decode_add_task_body(
  json_string: String,
) -> Result(AddTaskBody, json.DecodeError) {
  let decoder =
    dynamic.decode2(AddTaskBody, 
      dynamic.field("name", of: dynamic.string), 
      dynamic.field("description", of: dynamic.string)
      )

  json.decode(from: json_string, using: decoder)
}


fn add_task_to_list(list_id: String, db: pgo.Connection, body: BitString) -> Result(String, String) {
  case bit_string.to_string(body) {
    Ok(body_string) -> {
      case decode_add_task_body(body_string) {
        Ok(add_task_body) -> {
          database.add_task(db, list_id, add_task_body.name, add_task_body.description)
          |> task.to_string
          |> Ok
        }
        Error(_) -> Error("can't parse JSON")  // Convert DecodeError to string
      }
    }
    Error(_err) -> {
      Error("Error: missing value for task name or description")
    }
  }
}

// get lists

fn get_lists(db: pgo.Connection, account_id: String, query_params: List(#(String, String))) {
  let page: Int =
    query_params
    |> list.key_find("page")
    |> unwrap("0")
    |> int.base_parse(10)
    |> unwrap(0)
  
  let tasks = database.get_lists(db, account_id, page)
      |> list.map(task_list.to_string)
      |> string.concat

  mist.bit_builder_response(
    response.new(200),
    bit_builder.from_string(tasks)
  )
}

// get stats by account


fn get_stats(db: pgo.Connection) {
  let stats = database.get_stats(db)
    |> list.map(stats_by_account.to_string)
    |> string.concat

  mist.bit_builder_response(
        response.new(200),
        bit_builder.from_string(stats)
     )
}
