import account.{Account}
import database
import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{Request, get_query}
import gleam/http/response
import gleam/io.{debug}
import gleam/json
import gleam/list
import gleam/pgo
import gleam/result.{unwrap}
import list as task_list
import mist
import gleam/function.{curry2, curry3}

pub fn main() {
  let db = database.connect()

  let assert Ok(_) =
    mist.serve(
      8080,
      mist.handler_func(fn(req) {
        case req.method, request.path_segments(req) {
          Post, ["api", "accounts"] -> create(req, curry2(add_account)(db))
          Post, ["api", "accounts", account_id, "lists"] -> create(req, curry3(add_list)(account_id)(db))
          Post, ["api", "lists", list_id, "tasks"] -> add_task_to_list(list_id)
          Get, ["api", "accounts", account_id, "lists"] ->
            get_lists(account_id, unwrap(get_query(req), []))
          Get, ["api", "stats"] -> get_stats()
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
      case add_account_body_from_json(body_string) {
        Ok(add_account_body) -> {
          database.add_account(db, add_account_body.login)
          |> account.to_json
          |> Ok
        }
        Error(_) -> Error("can't parse JSON")  // Convert DecodeError to string
      }
    }
    Error(err) -> {
      Error("Error: missing value for login")
    }
  }
}

pub type AddAccountBody {
  AddAccountBody(login: String)
}

pub fn add_account_body_from_json(
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
      case add_list_body_from_json(body_string) {
        Ok(add_list_body) -> {
          database.add_list(db, account_id, add_list_body.name)
          |> task_list.to_json
          |> Ok
        }
        Error(_) -> Error("can't parse JSON")  // Convert DecodeError to string
      }
    }
    Error(err) -> {
      Error("Error: missing value for list name")
    }
  }
}

pub type AddListBody {
  AddListBody(name: String)
}

pub fn add_list_body_from_json(
  json_string: String,
) -> Result(AddListBody, json.DecodeError) {
  let decoder =
    dynamic.decode1(AddListBody, dynamic.field("name", of: dynamic.string))

  json.decode(from: json_string, using: decoder)
}

// add task to list

fn add_task_to_list(list_id: String) {
  response.new(200)
  |> mist.bit_builder_response(bit_builder.from_string(
    "TODO add_task_to_list:" <> list_id,
  ))
}

fn get_lists(account_id: String, query_params: List(#(String, String))) {
  let page: String =
    query_params
    |> list.key_find("page")
    |> unwrap("0")

  response.new(200)
  |> mist.bit_builder_response(bit_builder.from_string(
    "TODO get_lists " <> account_id <> " page: " <> page,
  ))
}

fn get_stats() {
  response.new(200)
  |> mist.bit_builder_response(bit_builder.from_string("TODO stats"))
}
