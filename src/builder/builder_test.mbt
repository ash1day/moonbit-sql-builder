test "select all" {
  let q = select().all().from("users").build()
  assert_eq!(q.sql, "SELECT * FROM \"users\"")
  assert_eq!(q.params, [])
}

test "select with columns" {
  let q = select().columns(["id", "name", "email"]).from("users").build()
  assert_eq!(q.sql, "SELECT \"id\", \"name\", \"email\" FROM \"users\"")
  assert_eq!(q.params, [])
}

test "select with where" {
  let q = select()
    .columns(["id", "name"])
    .from("users")
    .where_(col("age").gt(val_int(18)))
    .build()
  assert_eq!(
    q.sql, "SELECT \"id\", \"name\" FROM \"users\" WHERE (\"age\" > $1)",
  )
  assert_eq!(q.params, [@ast.Value::Int(18)])
}

test "select with multiple where (AND)" {
  let q = select()
    .all()
    .from("users")
    .where_(col("age").gt(val_int(18)))
    .where_(col("active").eq(val_bool(true)))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"age\" > $1) AND (\"active\" = $2))",
  )
  assert_eq!(q.params, [@ast.Value::Int(18), @ast.Value::Bool(true)])
}

test "select with join" {
  let q = select()
    .columns(["name", "total"])
    .from("users")
    .join(
      "orders",
      table_col("users", "id").eq(table_col("orders", "user_id")),
    )
    .build()
  assert_eq!(
    q.sql,
    "SELECT \"name\", \"total\" FROM \"users\" INNER JOIN \"orders\" ON (\"users\".\"id\" = \"orders\".\"user_id\")",
  )
  assert_eq!(q.params, [])
}

test "select with order by and limit" {
  let q = select()
    .all()
    .from("users")
    .order_by("name", @ast.Asc)
    .limit(10)
    .offset(20)
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" ORDER BY \"name\" ASC LIMIT $1 OFFSET $2",
  )
  assert_eq!(q.params, [@ast.Value::Int(10), @ast.Value::Int(20)])
}

test "select with like" {
  let q = select()
    .all()
    .from("users")
    .where_(col("name").like("%Alice%"))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"name\" LIKE $1)",
  )
  assert_eq!(q.params, [@ast.Value::String("%Alice%")])
}

test "select with in list" {
  let q = select()
    .all()
    .from("users")
    .where_(col("id").in_list([val_int(1), val_int(2), val_int(3)]))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE \"id\" IN ($1, $2, $3)",
  )
  assert_eq!(
    q.params,
    [@ast.Value::Int(1), @ast.Value::Int(2), @ast.Value::Int(3)],
  )
}

test "insert basic" {
  let q = insert_into("users")
    .columns(["name", "email"])
    .values([val_str("Alice"), val_str("alice@example.com")])
    .build()
  assert_eq!(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2)",
  )
  assert_eq!(
    q.params,
    [@ast.Value::String("Alice"), @ast.Value::String("alice@example.com")],
  )
}

test "insert with returning" {
  let q = insert_into("users")
    .columns(["name", "email"])
    .values([val_str("Bob"), val_str("bob@example.com")])
    .returning(["id"])
    .build()
  assert_eq!(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2) RETURNING \"id\"",
  )
  assert_eq!(
    q.params,
    [@ast.Value::String("Bob"), @ast.Value::String("bob@example.com")],
  )
}

test "update basic" {
  let q = update("users")
    .set("name", val_str("Bob"))
    .set("active", val_bool(true))
    .where_(col("id").eq(val_int(1)))
    .build()
  assert_eq!(
    q.sql,
    "UPDATE \"users\" SET \"name\" = $1, \"active\" = $2 WHERE (\"id\" = $3)",
  )
  assert_eq!(
    q.params,
    [@ast.Value::String("Bob"), @ast.Value::Bool(true), @ast.Value::Int(1)],
  )
}

test "delete basic" {
  let q = delete_from("users").where_(col("id").eq(val_int(42))).build()
  assert_eq!(q.sql, "DELETE FROM \"users\" WHERE (\"id\" = $1)")
  assert_eq!(q.params, [@ast.Value::Int(42)])
}
