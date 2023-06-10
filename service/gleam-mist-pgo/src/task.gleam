import gleam/json

pub type Task {
	Task(id: String, list_id: String, name: String, description: String, creation_date: String)
}

pub fn to_json(task: Task) -> String {
  json.object([
    #("id", json.string(task.id)),
    #("list_id", json.string(task.list_id)),
    #("name", json.string(task.name)),
    #("description", json.string(task.description)),
    #("creation_date", json.string(task.creation_date)),
  ])
  |> json.to_string
}