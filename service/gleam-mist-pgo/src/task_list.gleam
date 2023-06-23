import gleam/json.{Json}
import gleam/list
import task.{Task}

pub type TaskList {
	TaskList(id: String, account_id: String,name: String, creation_date: String, tasks: List(Task))
}

pub fn to_json(task_list: TaskList) -> Json {
  json.object([
    #("id", json.string(task_list.id)),
    #("account_id", json.string(task_list.account_id)),
    #("name", json.string(task_list.name)),
    #("creation_date", json.string(task_list.creation_date)),
    #("tasks", json.array(from: task_list.tasks, of: task.to_json))
  ])  
}

pub fn to_string(task_list: TaskList) -> String {
  task_list
  |> to_json
  |> json.to_string
}