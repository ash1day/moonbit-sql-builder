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

// ========================================================
// SELECT: テーブルエイリアス
// ========================================================

test "render SELECT with table alias" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::Expr(Expr::Column(ColumnRef::TableColumn("u", "id"))),
      SelectItem::Expr(Expr::Column(ColumnRef::TableColumn("u", "name"))),
    ],
    from: Some(TableRef::TableAlias("users", "u")),
    joins: [],
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
    "SELECT \"u\".\"id\", \"u\".\"name\" FROM \"users\" AS \"u\"",
  )
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: schema修飾テーブル
// ========================================================

test "render SELECT with schema-qualified table" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::SchemaTable("public", "users")),
    joins: [],
    where_: None,
    group_by: [],
    having: None,
    order_by: [],
    limit: None,
    offset: None,
  }
  let result = render_select(stmt)
  assert_eq(result.sql, "SELECT * FROM \"public\".\"users\"")
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: OR条件
// ========================================================

test "render SELECT with OR condition" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Binary(
          Expr::Column(ColumnRef::Column("role")),
          BinOp::Eq,
          Expr::Value(Value::String("admin")),
        ),
        BinOp::Or,
        Expr::Binary(
          Expr::Column(ColumnRef::Column("role")),
          BinOp::Eq,
          Expr::Value(Value::String("moderator")),
        ),
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
    "SELECT * FROM \"users\" WHERE ((\"role\" = $1) OR (\"role\" = $2))",
  )
  assert_eq(
    result.params,
    [Value::String("admin"), Value::String("moderator")],
  )
}

// ========================================================
// SELECT: ネストした AND/OR
// ========================================================

test "render SELECT with nested AND/OR" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Binary(
          Expr::Binary(
            Expr::Column(ColumnRef::Column("a")),
            BinOp::Eq,
            Expr::Value(Value::Int(1)),
          ),
          BinOp::And,
          Expr::Binary(
            Expr::Column(ColumnRef::Column("b")),
            BinOp::Eq,
            Expr::Value(Value::Int(2)),
          ),
        ),
        BinOp::Or,
        Expr::Binary(
          Expr::Column(ColumnRef::Column("c")),
          BinOp::Eq,
          Expr::Value(Value::Int(3)),
        ),
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
    "SELECT * FROM \"users\" WHERE (((\"a\" = $1) AND (\"b\" = $2)) OR (\"c\" = $3))",
  )
  assert_eq(
    result.params,
    [Value::Int(1), Value::Int(2), Value::Int(3)],
  )
}

// ========================================================
// SELECT: IS NULL / IS NOT NULL
// ========================================================

test "render SELECT with IS NULL" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(Expr::IsNull(Expr::Column(ColumnRef::Column("deleted_at")))),
    group_by: [],
    having: None,
    order_by: [],
    limit: None,
    offset: None,
  }
  let result = render_select(stmt)
  assert_eq(
    result.sql,
    "SELECT * FROM \"users\" WHERE \"deleted_at\" IS NULL",
  )
  assert_eq(result.params, [])
}

test "render SELECT with IS NOT NULL" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::IsNotNull(Expr::Column(ColumnRef::Column("email"))),
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
    "SELECT * FROM \"users\" WHERE \"email\" IS NOT NULL",
  )
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: BETWEEN
// ========================================================

test "render SELECT with BETWEEN" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("products")),
    joins: [],
    where_: Some(
      Expr::Between(
        Expr::Column(ColumnRef::Column("price")),
        Expr::Value(Value::Int(100)),
        Expr::Value(Value::Int(500)),
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
    "SELECT * FROM \"products\" WHERE \"price\" BETWEEN $1 AND $2",
  )
  assert_eq(result.params, [Value::Int(100), Value::Int(500)])
}

// ========================================================
// SELECT: LIKE
// ========================================================

test "render SELECT with LIKE" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("name")),
        BinOp::Like,
        Expr::Value(Value::String("Alice%")),
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
    "SELECT * FROM \"users\" WHERE (\"name\" LIKE $1)",
  )
  assert_eq(result.params, [Value::String("Alice%")])
}

// ========================================================
// SELECT: LEFT JOIN
// ========================================================

test "render SELECT with LEFT JOIN" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::Expr(Expr::Column(ColumnRef::TableColumn("u", "name"))),
      SelectItem::Expr(
        Expr::Column(ColumnRef::TableColumn("p", "avatar_url")),
      ),
    ],
    from: Some(TableRef::TableAlias("users", "u")),
    joins: [
      {
        join_type: JoinType::Left,
        table: TableRef::TableAlias("profiles", "p"),
        on: Expr::Binary(
          Expr::Column(ColumnRef::TableColumn("u", "id")),
          BinOp::Eq,
          Expr::Column(ColumnRef::TableColumn("p", "user_id")),
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
    "SELECT \"u\".\"name\", \"p\".\"avatar_url\" FROM \"users\" AS \"u\" LEFT JOIN \"profiles\" AS \"p\" ON (\"u\".\"id\" = \"p\".\"user_id\")",
  )
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: GROUP BY + HAVING
// ========================================================

test "render SELECT with GROUP BY and HAVING" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::Expr(Expr::Column(ColumnRef::Column("department"))),
      SelectItem::Expr(
        Expr::Func({ name: "COUNT", args: [Expr::Asterisk] }),
      ),
    ],
    from: Some(TableRef::Table("employees")),
    joins: [],
    where_: None,
    group_by: [Expr::Column(ColumnRef::Column("department"))],
    having: Some(
      Expr::Binary(
        Expr::Func({ name: "COUNT", args: [Expr::Asterisk] }),
        BinOp::Gt,
        Expr::Value(Value::Int(5)),
      ),
    ),
    order_by: [],
    limit: None,
    offset: None,
  }
  let result = render_select(stmt)
  assert_eq(
    result.sql,
    "SELECT \"department\", COUNT(*) FROM \"employees\" GROUP BY \"department\" HAVING (COUNT(*) > $1)",
  )
  assert_eq(result.params, [Value::Int(5)])
}

// ========================================================
// SELECT: ORDER BY 複数カラム、ASC/DESC混在
// ========================================================

test "render SELECT with multiple ORDER BY" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: None,
    group_by: [],
    having: None,
    order_by: [
      { expr: Expr::Column(ColumnRef::Column("last_name")), order: Asc },
      {
        expr: Expr::Column(ColumnRef::Column("created_at")),
        order: Desc,
      },
    ],
    limit: None,
    offset: None,
  }
  let result = render_select(stmt)
  assert_eq(
    result.sql,
    "SELECT * FROM \"users\" ORDER BY \"last_name\" ASC, \"created_at\" DESC",
  )
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: ExprAlias (式のエイリアス)
// ========================================================

test "render SELECT with expression alias" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::ExprAlias(
        Expr::Func({ name: "COUNT", args: [Expr::Asterisk] }),
        "total",
      ),
    ],
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
  assert_eq(result.sql, "SELECT COUNT(*) AS \"total\" FROM \"users\"")
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: TableAllColumns (テーブル.*)
// ========================================================

test "render SELECT with table all columns" {
  let stmt : SelectStatement = {
    columns: [SelectItem::TableAllColumns("users")],
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
  assert_eq(result.sql, "SELECT \"users\".* FROM \"users\"")
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: Unary NOT
// ========================================================

test "render SELECT with NOT expression" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::Unary(
        UnOp::Not,
        Expr::Binary(
          Expr::Column(ColumnRef::Column("active")),
          BinOp::Eq,
          Expr::Value(Value::Bool(true)),
        ),
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
    "SELECT * FROM \"users\" WHERE (NOT (\"active\" = $1))",
  )
  assert_eq(result.params, [Value::Bool(true)])
}

// ========================================================
// SELECT: FuncCall (COUNT, SUM等)
// ========================================================

test "render SELECT with function call" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::Expr(
        Expr::Func({ name: "COUNT", args: [Expr::Asterisk] }),
      ),
    ],
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
  assert_eq(result.sql, "SELECT COUNT(*) FROM \"users\"")
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: パラメータ番号の連番確認
// ========================================================

test "render SELECT param numbering is sequential" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Binary(
          Expr::Column(ColumnRef::Column("age")),
          BinOp::Gt,
          Expr::Value(Value::Int(18)),
        ),
        BinOp::And,
        Expr::Binary(
          Expr::Column(ColumnRef::Column("name")),
          BinOp::Like,
          Expr::Value(Value::String("%test%")),
        ),
      ),
    ),
    group_by: [],
    having: None,
    order_by: [],
    limit: Some(Expr::Value(Value::Int(10))),
    offset: Some(Expr::Value(Value::Int(0))),
  }
  let result = render_select(stmt)
  assert_eq(
    result.sql,
    "SELECT * FROM \"users\" WHERE ((\"age\" > $1) AND (\"name\" LIKE $2)) LIMIT $3 OFFSET $4",
  )
  assert_eq(
    result.params,
    [Value::Int(18), Value::String("%test%"), Value::Int(10), Value::Int(0)],
  )
}

// ========================================================
// SELECT: Null値パラメータ
// ========================================================

test "render SELECT with null parameter" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("name")),
        BinOp::Eq,
        Expr::Value(Value::Null),
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
    "SELECT * FROM \"users\" WHERE (\"name\" = $1)",
  )
  assert_eq(result.params, [Value::Null])
}

// ========================================================
// SELECT: 複数JOINの結合
// ========================================================

test "render SELECT with multiple JOINs" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("orders")),
    joins: [
      {
        join_type: JoinType::Inner,
        table: TableRef::Table("users"),
        on: Expr::Binary(
          Expr::Column(ColumnRef::TableColumn("orders", "user_id")),
          BinOp::Eq,
          Expr::Column(ColumnRef::TableColumn("users", "id")),
        ),
      },
      {
        join_type: JoinType::Left,
        table: TableRef::Table("products"),
        on: Expr::Binary(
          Expr::Column(ColumnRef::TableColumn("orders", "product_id")),
          BinOp::Eq,
          Expr::Column(ColumnRef::TableColumn("products", "id")),
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
    "SELECT * FROM \"orders\" INNER JOIN \"users\" ON (\"orders\".\"user_id\" = \"users\".\"id\") LEFT JOIN \"products\" ON (\"orders\".\"product_id\" = \"products\".\"id\")",
  )
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: empty columns → SELECT *
// ========================================================

test "render SELECT with empty columns defaults to star" {
  let stmt : SelectStatement = {
    columns: [],
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

// ========================================================
// SELECT: Negation (単項マイナス)
// ========================================================

test "render SELECT with negation" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::Expr(
        Expr::Unary(UnOp::Neg, Expr::Column(ColumnRef::Column("balance"))),
      ),
    ],
    from: Some(TableRef::Table("accounts")),
    joins: [],
    where_: None,
    group_by: [],
    having: None,
    order_by: [],
    limit: None,
    offset: None,
  }
  let result = render_select(stmt)
  assert_eq(result.sql, "SELECT (-\"balance\") FROM \"accounts\"")
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: 比較演算子 Ne, Lt, Le, Ge
// ========================================================

test "render SELECT with Ne operator" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("status")),
        BinOp::Ne,
        Expr::Value(Value::String("deleted")),
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
    "SELECT * FROM \"users\" WHERE (\"status\" <> $1)",
  )
  assert_eq(result.params, [Value::String("deleted")])
}

test "render SELECT with Le operator" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("products")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("price")),
        BinOp::Le,
        Expr::Value(Value::Int(1000)),
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
    "SELECT * FROM \"products\" WHERE (\"price\" <= $1)",
  )
  assert_eq(result.params, [Value::Int(1000)])
}

test "render SELECT with Ge operator" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("products")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("stock")),
        BinOp::Ge,
        Expr::Value(Value::Int(0)),
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
    "SELECT * FROM \"products\" WHERE (\"stock\" >= $1)",
  )
  assert_eq(result.params, [Value::Int(0)])
}

// ========================================================
// SELECT: 算術演算子
// ========================================================

test "render SELECT with arithmetic expression" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::ExprAlias(
        Expr::Binary(
          Expr::Column(ColumnRef::Column("price")),
          BinOp::Mul,
          Expr::Column(ColumnRef::Column("quantity")),
        ),
        "total",
      ),
    ],
    from: Some(TableRef::Table("order_items")),
    joins: [],
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
    "SELECT (\"price\" * \"quantity\") AS \"total\" FROM \"order_items\"",
  )
  assert_eq(result.params, [])
}

// ========================================================
// SELECT: Double値
// ========================================================

test "render SELECT with double value" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("products")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("rating")),
        BinOp::Ge,
        Expr::Value(Value::Double(4.5)),
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
    "SELECT * FROM \"products\" WHERE (\"rating\" >= $1)",
  )
  assert_eq(result.params, [Value::Double(4.5)])
}

// ========================================================
// SELECT: CROSS JOIN (ON句なし)
// ========================================================

test "render SELECT with CROSS JOIN" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("colors")),
    joins: [
      {
        join_type: JoinType::Cross,
        table: TableRef::Table("sizes"),
        on: Expr::Value(Value::Bool(true)),
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
    "SELECT * FROM \"colors\" CROSS JOIN \"sizes\"",
  )
  assert_eq(result.params, [])
}

// ========================================================
// INSERT: 複数行
// ========================================================

test "render INSERT with multiple rows" {
  let stmt : InsertStatement = {
    table: TableRef::Table("users"),
    columns: ["name", "email"],
    values: [
      [
        Expr::Value(Value::String("Alice")),
        Expr::Value(Value::String("alice@example.com")),
      ],
      [
        Expr::Value(Value::String("Bob")),
        Expr::Value(Value::String("bob@example.com")),
      ],
    ],
    returning: [],
  }
  let result = render_insert(stmt)
  assert_eq(
    result.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2), ($3, $4)",
  )
  assert_eq(
    result.params,
    [
      Value::String("Alice"),
      Value::String("alice@example.com"),
      Value::String("Bob"),
      Value::String("bob@example.com"),
    ],
  )
}

// ========================================================
// INSERT: RETURNING複数カラム
// ========================================================

test "render INSERT with multiple returning columns" {
  let stmt : InsertStatement = {
    table: TableRef::Table("users"),
    columns: ["name"],
    values: [[Expr::Value(Value::String("Charlie"))]],
    returning: [
      SelectItem::Expr(Expr::Column(ColumnRef::Column("id"))),
      SelectItem::Expr(Expr::Column(ColumnRef::Column("created_at"))),
    ],
  }
  let result = render_insert(stmt)
  assert_eq(
    result.sql,
    "INSERT INTO \"users\" (\"name\") VALUES ($1) RETURNING \"id\", \"created_at\"",
  )
  assert_eq(result.params, [Value::String("Charlie")])
}

// ========================================================
// UPDATE: WHERE条件なし (全行更新)
// ========================================================

test "render UPDATE without WHERE" {
  let stmt : UpdateStatement = {
    table: TableRef::Table("settings"),
    assignments: [("value", Expr::Value(Value::String("default")))],
    where_: None,
    returning: [],
  }
  let result = render_update(stmt)
  assert_eq(
    result.sql,
    "UPDATE \"settings\" SET \"value\" = $1",
  )
  assert_eq(result.params, [Value::String("default")])
}

// ========================================================
// UPDATE: RETURNING句
// ========================================================

test "render UPDATE with RETURNING" {
  let stmt : UpdateStatement = {
    table: TableRef::Table("users"),
    assignments: [("name", Expr::Value(Value::String("Updated")))],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("id")),
        BinOp::Eq,
        Expr::Value(Value::Int(1)),
      ),
    ),
    returning: [
      SelectItem::Expr(Expr::Column(ColumnRef::Column("id"))),
      SelectItem::Expr(Expr::Column(ColumnRef::Column("name"))),
    ],
  }
  let result = render_update(stmt)
  assert_eq(
    result.sql,
    "UPDATE \"users\" SET \"name\" = $1 WHERE (\"id\" = $2) RETURNING \"id\", \"name\"",
  )
  assert_eq(
    result.params,
    [Value::String("Updated"), Value::Int(1)],
  )
}

// ========================================================
// UPDATE: SET複数カラム
// ========================================================

test "render UPDATE with multiple SET columns" {
  let stmt : UpdateStatement = {
    table: TableRef::Table("products"),
    assignments: [
      ("name", Expr::Value(Value::String("Widget"))),
      ("price", Expr::Value(Value::Int(999))),
      ("active", Expr::Value(Value::Bool(false))),
    ],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("id")),
        BinOp::Eq,
        Expr::Value(Value::Int(42)),
      ),
    ),
    returning: [],
  }
  let result = render_update(stmt)
  assert_eq(
    result.sql,
    "UPDATE \"products\" SET \"name\" = $1, \"price\" = $2, \"active\" = $3 WHERE (\"id\" = $4)",
  )
  assert_eq(
    result.params,
    [
      Value::String("Widget"),
      Value::Int(999),
      Value::Bool(false),
      Value::Int(42),
    ],
  )
}

// ========================================================
// DELETE: WHERE条件なし (全行削除)
// ========================================================

test "render DELETE without WHERE" {
  let stmt : DeleteStatement = {
    table: TableRef::Table("temp_data"),
    where_: None,
    returning: [],
  }
  let result = render_delete(stmt)
  assert_eq(result.sql, "DELETE FROM \"temp_data\"")
  assert_eq(result.params, [])
}

// ========================================================
// DELETE: RETURNING句
// ========================================================

test "render DELETE with RETURNING" {
  let stmt : DeleteStatement = {
    table: TableRef::Table("users"),
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("active")),
        BinOp::Eq,
        Expr::Value(Value::Bool(false)),
      ),
    ),
    returning: [SelectItem::Expr(Expr::Column(ColumnRef::Column("id")))],
  }
  let result = render_delete(stmt)
  assert_eq(
    result.sql,
    "DELETE FROM \"users\" WHERE (\"active\" = $1) RETURNING \"id\"",
  )
  assert_eq(result.params, [Value::Bool(false)])
}

// ========================================================
// SELECT: FuncCallの複数引数
// ========================================================

test "render SELECT with multi-arg function" {
  let stmt : SelectStatement = {
    columns: [
      SelectItem::Expr(
        Expr::Func(
          {
            name: "COALESCE",
            args: [
              Expr::Column(ColumnRef::Column("nickname")),
              Expr::Column(ColumnRef::Column("name")),
              Expr::Value(Value::String("Anonymous")),
            ],
          },
        ),
      ),
    ],
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
  assert_eq(
    result.sql,
    "SELECT COALESCE(\"nickname\", \"name\", $1) FROM \"users\"",
  )
  assert_eq(result.params, [Value::String("Anonymous")])
}

// ========================================================
// SELECT: 同じ値でも別パラメータ番号
// ========================================================

test "render SELECT same values get separate param numbers" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("users")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Binary(
          Expr::Column(ColumnRef::Column("a")),
          BinOp::Eq,
          Expr::Value(Value::Int(1)),
        ),
        BinOp::And,
        Expr::Binary(
          Expr::Column(ColumnRef::Column("b")),
          BinOp::Eq,
          Expr::Value(Value::Int(1)),
        ),
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
    "SELECT * FROM \"users\" WHERE ((\"a\" = $1) AND (\"b\" = $2))",
  )
  assert_eq(result.params, [Value::Int(1), Value::Int(1)])
}

// ========================================================
// SELECT: Int64値
// ========================================================

test "render SELECT with Int64 value" {
  let stmt : SelectStatement = {
    columns: [SelectItem::AllColumns],
    from: Some(TableRef::Table("events")),
    joins: [],
    where_: Some(
      Expr::Binary(
        Expr::Column(ColumnRef::Column("timestamp")),
        BinOp::Gt,
        Expr::Value(Value::Int64(1700000000L)),
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
    "SELECT * FROM \"events\" WHERE (\"timestamp\" > $1)",
  )
  assert_eq(result.params, [Value::Int64(1700000000L)])
}
