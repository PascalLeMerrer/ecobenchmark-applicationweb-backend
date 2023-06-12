import gleam/json

pub type TaskList {
	TaskList(id: String, account_id: String,name: String, creation_date: String)
}

pub fn to_json(task_list: TaskList) -> String {
  json.object([
    #("id", json.string(task_list.id)),
    #("account_id", json.string(task_list.account_id)),
    #("name", json.string(task_list.name)),
    #("creation_date", json.string(task_list.creation_date)),
  ])
  |> json.to_string
}