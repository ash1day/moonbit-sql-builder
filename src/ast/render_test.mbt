test "render simple SELECT" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: None,
    group_by: [],
    having: None,
    order_by: [],
    limit: None,
    offset: None,
  }
  let result = render_select(stmt)
  assert_eq(result.sql, "SELECT * FROM \"users\"")
  assert_eq(result.params, [])
}

test "render SELECT with WHERE" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::Expr(Expr::Column(ColumnRef::Column("id"))),
      SelectItem::Expr(Expr::Column(ColumnRef::Column("name"))),
    ],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("age")),
        BinOp::Gt,
        Expr::Value(Value::Int(18)),
      ),
    ),
    group_by: [],
    having: None,
    order_by: [],
    limit: None,
    offset: None,
  }
  let result = render_select(stmt)
  assert_eq(
    result.sql,
    "SELECT \"id\", \"name\" FROM \"users\" WHERE (\"age\" > $1)",
  )
  assert_eq(result.params, [Value::Int(18)])
}

test "render SELECT with ORDER BY and LIMIT" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: None,
    group_by: [],
    having: None,
    order_by: [
      { expr: Expr::Column(ColumnRef::Column("name")), order: Asc },
    ],
    limit: Some(Expr::Value(Value::Int(10))),
    offset: Some(Expr::Value(Value::Int(20))),
  }
  let result = render_select(stmt)
  assert_eq(
    result.sql,
    "SELECT * FROM \"users\" ORDER BY \"name\" ASC LIMIT $1 OFFSET $2",
  )
  assert_eq(result.params, [Value::Int(10), Value::Int(20)])
}

test "render INSERT" {
  let stmt : InsertStatement = {
    table: TableRef::Table("users"),
    columns: ["name", "email"],
    values: [
      [
        Expr::Value(Value::String("Alice")),
        Expr::Value(Value::String("alice@example.com")),
      ],
    ],
    returning: [SelectItem::Expr(Expr::Column(ColumnRef::Column("id")))],
  }
  let result = render_insert(stmt)
  assert_eq(
    result.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2) RETURNING \"id\"",
  )
  assert_eq(
    result.params,
    [Value::String("Alice"), Value::String("alice@example.com")],
  )
}

test "render UPDATE" {
  let stmt : UpdateStatement = {
    table: TableRef::Table("users"),
    assignments: [
      ("name", Expr::Value(Value::String("Bob"))),
      ("active", Expr::Value(Value::Bool(true))),
    ],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("id")),
        BinOp::Eq,
        Expr::Value(Value::Int(1)),
      ),
    ),
    returning: [],
  }
  let result = render_update(stmt)
  assert_eq(
    result.sql,
    "UPDATE \"users\" SET \"name\" = $1, \"active\" = $2 WHERE (\"id\" = $3)",
  )
  assert_eq(
    result.params,
    [Value::String("Bob"), Value::Bool(true), Value::Int(1)],
  )
}

test "render DELETE" {
  let stmt : DeleteStatement = {
    table: TableRef::Table("users"),
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("id")),
        BinOp::Eq,
        Expr::Value(Value::Int(42)),
      ),
    ),
    returning: [],
  }
  let result = render_delete(stmt)
  assert_eq(result.sql, "DELETE FROM \"users\" WHERE (\"id\" = $1)")
  assert_eq(result.params, [Value::Int(42)])
}

test "render SELECT with JOIN" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::Expr(
        Expr::Column(ColumnRef::TableColumn("u", "name")),
      ),
      SelectItem::Expr(
        Expr::Column(ColumnRef::TableColumn("o", "total")),
      ),
    ],
    from: Some(TableRef::TableAlias("users", "u")),
    joins: [
      {
        join_type: JoinType::Inner,
        table: TableRef::TableAlias("orders", "o"),
        on: Expr::Binary(
          Expr::Column(ColumnRef::TableColumn("u", "id")),
          BinOp::Eq,
          Expr::Column(ColumnRef::TableColumn("o", "user_id")),
        ),
      },
    ],
    where_: None,
    group_by: [],
    having: None,
    order_by: [],
    limit: None,
    offset: None,
  }
  let result = render_select(stmt)
  assert_eq(
    result.sql,
    "SELECT \"u\".\"name\", \"o\".\"total\" FROM \"users\" AS \"u\" INNER JOIN \"orders\" AS \"o\" ON (\"u\".\"id\" = \"o\".\"user_id\")",
  )
  assert_eq(result.params, [])
}

test "render SELECT with IN list" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::InList(
        Expr::Column(ColumnRef::Column("id")),
        [
          Expr::Value(Value::Int(1)),
          Expr::Value(Value::Int(2)),
          Expr::Value(Value::Int(3)),
        ],
      ),
    ),
    group_by: [],
    having: None,
    order_by: [],
    limit: None,
    offset: None,
  }
  let result = render_select(stmt)
  assert_eq(
    result.sql,
    "SELECT * FROM \"users\" WHERE \"id\" IN ($1, $2, $3)",
  )
  assert_eq(result.params, [Value::Int(1), Value::Int(2), Value::Int(3)])
}
