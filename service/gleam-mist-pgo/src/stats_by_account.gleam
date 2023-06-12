import gleam/json

pub type StatsByAccount {
  StatsByAccount(
  	account_id:    String,
	account_login: String,
	list_count:    Int,
	task_avg:      Float,)
}

pub fn to_json(stats: StatsByAccount) -> String {
  json.object([
    #("accountId", json.string(stats.account_id)),
    #("account_login", json.string(stats.account_login)),
    #("list_count", json.int(stats.list_count)),
    #("task_avg", json.float(stats.task_avg)),
  ])
  |> json.to_string
}


