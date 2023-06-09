import gleam/bit_builder
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{Request, get_query}
import gleam/http/response
import gleam/io.{debug}
import gleam/result.{unwrap}
import mist
import gleam/list
import gleam/bit_string
import database
import gleam/json
import gleam/dynamic
import account.{Account}

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

pub fn account_to_json(account: Account) -> String {
  json.object([
    #("id", json.string(account.id)),
    #("login", json.string(account.login)),
    #("creation_date", json.string(account.creation_date)),
  ])
  |> json.to_string
}

pub fn main() {
  let assert Ok(_) =
    mist.serve(
      8080,
      mist.handler_func(fn(req) {
        case req.method, request.path_segments(req) {
          Post, ["api", "accounts"] -> add_account(req)
          Post, ["api", "accounts", account_id, "lists"] -> add_list(account_id)
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

fn add_account_(body: BitString) -> Result(String, String) {
  case bit_string.to_string(body) {
    Ok(body_string) -> {
      // parse json
      case add_account_body_from_json(body_string) {
        Ok(add_account_body) -> {
          database.add_account(add_account_body.login)
          |> account_to_json
          |> Ok
        }
        Error(_) -> Error("can't parse JSON")  // Convert DecodeError to string
      }
    }
    Error(err) -> {
      debug(err)
      Error("Error: missing value for login")
    }
  }
}

fn add_account(req: Request(mist.Body)) {
  
  let request_with_body = mist.read_body(req)
  result.map(
    over: request_with_body,
    with: fn(r) {
      case add_account_(r.body) {
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

fn add_list(account_id: String) {
  response.new(200)
  |> mist.bit_builder_response(bit_builder.from_string(
    "TODO add_list" <> account_id,
  ))
}

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
