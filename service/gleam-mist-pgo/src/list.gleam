import gleam/json

pub type List {
	List(id: String, account_id: String,name: String, creation_date: String)
}

pub fn to_json(list: List) -> String {
  json.object([
    #("id", json.string(list.id)),
    #("account_id", json.string(list.account_id)),
    #("name", json.string(list.name)),
    #("creation_date", json.string(list.creation_date)),
  ])
  |> json.to_string
}