import gleam/json

pub type Account {
  Account(id: String, login: String, creation_date: String)
}

pub fn to_string(account: Account) -> String {
  json.object([
    #("id", json.string(account.id)),
    #("login", json.string(account.login)),
    #("creation_date", json.string(account.creation_date)),
  ])
  |> json.to_string
}