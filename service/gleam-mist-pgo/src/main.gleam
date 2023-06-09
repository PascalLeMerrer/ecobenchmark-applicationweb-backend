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

pub type AddAccountBody {
  AddAccountBody(login: String)
}


pub fn add_account_body_from_json(json_string: String) -> Result(AddAccountBody, json.DecodeError) {
  let decoder = dynamic.decode1(
    AddAccountBody,
    dynamic.field("login", of: dynamic.string),
  )

  json.decode(from: json_string, using: decoder)
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

fn add_account(req: Request(mist.Body)) {
  req
  |> mist.read_body
  |> result.map(fn(req) {
    response.new(200)
    |> mist.bit_builder_response(bit_builder.from_string({
      case bit_string.to_string(req.body) {
        Ok(body) -> {
          // parse json
          let assert Ok(add_account_body) = add_account_body_from_json(body)
          database.add_account(add_account_body.login)
          "OK"
        }
        Error(err) -> {
          debug(err)
          "Error: invalid or missing value for login"
        }
      }
    }))
  })
  |> result.unwrap(
    response.new(400)
    |> mist.empty_response,
  )
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
