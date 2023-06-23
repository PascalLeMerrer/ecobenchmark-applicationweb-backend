import gleam/json.{Json}

pub type Task {
	Task(id: String, list_id: String, name: String, description: String, creation_date: String)
}

pub fn to_json(task: Task) -> Json {
  json.object([
    #("id", json.string(task.id)),
    #("list_id", json.string(task.list_id)),
    #("name", json.string(task.name)),
    #("description", json.string(task.description)),
    #("creation_date", json.string(task.creation_date)),
  ])
}

pub fn to_string(task: Task) -> String {
  task
  |> to_json
  |> json.to_string
}