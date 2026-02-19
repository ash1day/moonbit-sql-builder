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

// ========================================================
// SELECT builder: テーブルエイリアス (from_as)
// ========================================================

test "select with from_as alias" {
  let q = select()
    .columns(["id", "name"])
    .from_as("users", "u")
    .build()
  assert_eq!(q.sql, "SELECT \"id\", \"name\" FROM \"users\" AS \"u\"")
  assert_eq!(q.params, [])
}

// ========================================================
// SELECT builder: OR条件
// ========================================================

test "select with or condition" {
  let q = select()
    .all()
    .from("users")
    .where_(col("role").eq(val_str("admin")).or_(col("role").eq(val_str("mod"))))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"role\" = $1) OR (\"role\" = $2))",
  )
  assert_eq!(
    q.params,
    [@ast.Value::String("admin"), @ast.Value::String("mod")],
  )
}

// ========================================================
// SELECT builder: ネストした AND/OR
// ========================================================

test "select with nested and/or" {
  let q = select()
    .all()
    .from("users")
    .where_(
      col("a").eq(val_int(1)).and_(col("b").eq(val_int(2))).or_(
        col("c").eq(val_int(3)),
      ),
    )
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE (((\"a\" = $1) AND (\"b\" = $2)) OR (\"c\" = $3))",
  )
  assert_eq!(
    q.params,
    [@ast.Value::Int(1), @ast.Value::Int(2), @ast.Value::Int(3)],
  )
}

// ========================================================
// SELECT builder: IS NULL
// ========================================================

test "select with is null" {
  let q = select()
    .all()
    .from("users")
    .where_(col("deleted_at").is_null())
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE \"deleted_at\" IS NULL",
  )
  assert_eq!(q.params, [])
}

// ========================================================
// SELECT builder: IS NOT NULL
// ========================================================

test "select with is not null" {
  let q = select()
    .all()
    .from("users")
    .where_(col("email").is_not_null())
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE \"email\" IS NOT NULL",
  )
  assert_eq!(q.params, [])
}

// ========================================================
// SELECT builder: LEFT JOIN
// ========================================================

test "select with left join" {
  let q = select()
    .columns(["name"])
    .from("users")
    .left_join(
      "profiles",
      table_col("users", "id").eq(table_col("profiles", "user_id")),
    )
    .build()
  assert_eq!(
    q.sql,
    "SELECT \"name\" FROM \"users\" LEFT JOIN \"profiles\" ON (\"users\".\"id\" = \"profiles\".\"user_id\")",
  )
  assert_eq!(q.params, [])
}

// ========================================================
// SELECT builder: GROUP BY + HAVING
// ========================================================

test "select with group by and having" {
  let q = select()
    .column("department")
    .from("employees")
    .group_by("department")
    .having(
      @ast.Expr::Binary(
        @ast.Expr::Func({ name: "COUNT", args: [@ast.Expr::Asterisk] }),
        @ast.BinOp::Gt,
        @ast.Expr::Value(@ast.Value::Int(5)),
      ),
    )
    .build()
  assert_eq!(
    q.sql,
    "SELECT \"department\" FROM \"employees\" GROUP BY \"department\" HAVING (COUNT(*) > $1)",
  )
  assert_eq!(q.params, [@ast.Value::Int(5)])
}

// ========================================================
// SELECT builder: 複数 ORDER BY (ASC/DESC混在)
// ========================================================

test "select with multiple order by" {
  let q = select()
    .all()
    .from("users")
    .order_by("last_name", @ast.Asc)
    .order_by("created_at", @ast.Desc)
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" ORDER BY \"last_name\" ASC, \"created_at\" DESC",
  )
  assert_eq!(q.params, [])
}

// ========================================================
// SELECT builder: LIMIT のみ (OFFSET なし)
// ========================================================

test "select with limit only" {
  let q = select().all().from("users").limit(5).build()
  assert_eq!(q.sql, "SELECT * FROM \"users\" LIMIT $1")
  assert_eq!(q.params, [@ast.Value::Int(5)])
}

// ========================================================
// SELECT builder: 3つの WHERE 条件の累積
// ========================================================

test "select with three where conditions" {
  let q = select()
    .all()
    .from("users")
    .where_(col("age").gt(val_int(18)))
    .where_(col("active").eq(val_bool(true)))
    .where_(col("role").eq(val_str("user")))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE (((\"age\" > $1) AND (\"active\" = $2)) AND (\"role\" = $3))",
  )
  assert_eq!(
    q.params,
    [
      @ast.Value::Int(18),
      @ast.Value::Bool(true),
      @ast.Value::String("user"),
    ],
  )
}

// ========================================================
// SELECT builder: table_col (テーブル修飾カラム)
// ========================================================

test "select with table qualified columns" {
  let q = select()
    .all()
    .from("users")
    .where_(table_col("users", "id").eq(val_int(1)))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"users\".\"id\" = $1)",
  )
  assert_eq!(q.params, [@ast.Value::Int(1)])
}

// ========================================================
// SELECT builder: val_null ヘルパー
// ========================================================

test "select with val_null helper" {
  let q = select()
    .all()
    .from("users")
    .where_(col("name").eq(val_null()))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"name\" = $1)",
  )
  assert_eq!(q.params, [@ast.Value::Null])
}

// ========================================================
// SELECT builder: Ne (不等号) 演算子
// ========================================================

test "select with ne operator" {
  let q = select()
    .all()
    .from("users")
    .where_(col("status").ne(val_str("deleted")))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"status\" <> $1)",
  )
  assert_eq!(q.params, [@ast.Value::String("deleted")])
}

// ========================================================
// SELECT builder: Lt (小なり) 演算子
// ========================================================

test "select with lt operator" {
  let q = select()
    .all()
    .from("products")
    .where_(col("price").lt(val_int(100)))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"products\" WHERE (\"price\" < $1)",
  )
  assert_eq!(q.params, [@ast.Value::Int(100)])
}

// ========================================================
// SELECT builder: Gte (以上) 演算子
// ========================================================

test "select with gte operator" {
  let q = select()
    .all()
    .from("products")
    .where_(col("stock").gte(val_int(0)))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"products\" WHERE (\"stock\" >= $1)",
  )
  assert_eq!(q.params, [@ast.Value::Int(0)])
}

// ========================================================
// SELECT builder: Lte (以下) 演算子
// ========================================================

test "select with lte operator" {
  let q = select()
    .all()
    .from("products")
    .where_(col("price").lte(val_int(1000)))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"products\" WHERE (\"price\" <= $1)",
  )
  assert_eq!(q.params, [@ast.Value::Int(1000)])
}

// ========================================================
// INSERT builder: 複数行
// ========================================================

test "insert multi-row" {
  let q = insert_into("users")
    .columns(["name", "email"])
    .values([val_str("Alice"), val_str("alice@example.com")])
    .values([val_str("Bob"), val_str("bob@example.com")])
    .build()
  assert_eq!(
    q.sql,
    "INSERT INTO \"users\" (\"name\", \"email\") VALUES ($1, $2), ($3, $4)",
  )
  assert_eq!(
    q.params,
    [
      @ast.Value::String("Alice"),
      @ast.Value::String("alice@example.com"),
      @ast.Value::String("Bob"),
      @ast.Value::String("bob@example.com"),
    ],
  )
}

// ========================================================
// INSERT builder: RETURNING複数カラム
// ========================================================

test "insert with multiple returning" {
  let q = insert_into("users")
    .columns(["name"])
    .values([val_str("Charlie")])
    .returning(["id", "created_at"])
    .build()
  assert_eq!(
    q.sql,
    "INSERT INTO \"users\" (\"name\") VALUES ($1) RETURNING \"id\", \"created_at\"",
  )
  assert_eq!(q.params, [@ast.Value::String("Charlie")])
}

// ========================================================
// UPDATE builder: WHERE条件なし
// ========================================================

test "update without where" {
  let q = update("settings").set("value", val_str("default")).build()
  assert_eq!(q.sql, "UPDATE \"settings\" SET \"value\" = $1")
  assert_eq!(q.params, [@ast.Value::String("default")])
}

// ========================================================
// UPDATE builder: RETURNING句
// ========================================================

test "update with returning" {
  let q = update("users")
    .set("name", val_str("Updated"))
    .where_(col("id").eq(val_int(1)))
    .returning(["id", "name"])
    .build()
  assert_eq!(
    q.sql,
    "UPDATE \"users\" SET \"name\" = $1 WHERE (\"id\" = $2) RETURNING \"id\", \"name\"",
  )
  assert_eq!(
    q.params,
    [@ast.Value::String("Updated"), @ast.Value::Int(1)],
  )
}

// ========================================================
// UPDATE builder: 複数SET + 複数WHERE
// ========================================================

test "update with multiple set and where" {
  let q = update("products")
    .set("name", val_str("Widget"))
    .set("price", val_int(999))
    .set("active", val_bool(false))
    .where_(col("id").eq(val_int(42)))
    .where_(col("version").eq(val_int(3)))
    .build()
  assert_eq!(
    q.sql,
    "UPDATE \"products\" SET \"name\" = $1, \"price\" = $2, \"active\" = $3 WHERE ((\"id\" = $4) AND (\"version\" = $5))",
  )
  assert_eq!(
    q.params,
    [
      @ast.Value::String("Widget"),
      @ast.Value::Int(999),
      @ast.Value::Bool(false),
      @ast.Value::Int(42),
      @ast.Value::Int(3),
    ],
  )
}

// ========================================================
// DELETE builder: WHERE条件なし
// ========================================================

test "delete without where" {
  let q = delete_from("temp_data").build()
  assert_eq!(q.sql, "DELETE FROM \"temp_data\"")
  assert_eq!(q.params, [])
}

// ========================================================
// DELETE builder: RETURNING句
// ========================================================

test "delete with returning" {
  let q = delete_from("users")
    .where_(col("active").eq(val_bool(false)))
    .returning(["id"])
    .build()
  assert_eq!(
    q.sql,
    "DELETE FROM \"users\" WHERE (\"active\" = $1) RETURNING \"id\"",
  )
  assert_eq!(q.params, [@ast.Value::Bool(false)])
}

// ========================================================
// DELETE builder: 複数WHERE条件
// ========================================================

test "delete with multiple where" {
  let q = delete_from("logs")
    .where_(col("level").eq(val_str("debug")))
    .where_(col("age_days").gt(val_int(30)))
    .build()
  assert_eq!(
    q.sql,
    "DELETE FROM \"logs\" WHERE ((\"level\" = $1) AND (\"age_days\" > $2))",
  )
  assert_eq!(
    q.params,
    [@ast.Value::String("debug"), @ast.Value::Int(30)],
  )
}

// ========================================================
// SELECT builder: パラメータ番号の連番確認
// ========================================================

test "select param numbering across clauses" {
  let q = select()
    .all()
    .from("users")
    .where_(col("age").gt(val_int(18)))
    .where_(col("name").like("%test%"))
    .limit(10)
    .offset(0)
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"age\" > $1) AND (\"name\" LIKE $2)) LIMIT $3 OFFSET $4",
  )
  assert_eq!(
    q.params,
    [
      @ast.Value::Int(18),
      @ast.Value::String("%test%"),
      @ast.Value::Int(10),
      @ast.Value::Int(0),
    ],
  )
}

// ========================================================
// SELECT builder: 同じ値でも別パラメータ番号
// ========================================================

test "select same values get separate params" {
  let q = select()
    .all()
    .from("users")
    .where_(col("a").eq(val_int(1)))
    .where_(col("b").eq(val_int(1)))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE ((\"a\" = $1) AND (\"b\" = $2))",
  )
  assert_eq!(q.params, [@ast.Value::Int(1), @ast.Value::Int(1)])
}

// ========================================================
// SELECT builder: 単一カラム (column)
// ========================================================

test "select single column" {
  let q = select().column("id").from("users").build()
  assert_eq!(q.sql, "SELECT \"id\" FROM \"users\"")
  assert_eq!(q.params, [])
}

// ========================================================
// SELECT builder: JOIN + WHERE 複合
// ========================================================

test "select with join and where" {
  let q = select()
    .columns(["name", "total"])
    .from("users")
    .join(
      "orders",
      table_col("users", "id").eq(table_col("orders", "user_id")),
    )
    .where_(col("total").gt(val_int(100)))
    .build()
  assert_eq!(
    q.sql,
    "SELECT \"name\", \"total\" FROM \"users\" INNER JOIN \"orders\" ON (\"users\".\"id\" = \"orders\".\"user_id\") WHERE (\"total\" > $1)",
  )
  assert_eq!(q.params, [@ast.Value::Int(100)])
}

// ========================================================
// SELECT builder: IN + LIKE 複合WHERE
// ========================================================

test "select with in list and like combined" {
  let q = select()
    .all()
    .from("users")
    .where_(col("id").in_list([val_int(1), val_int(2), val_int(3)]))
    .where_(col("name").like("A%"))
    .build()
  assert_eq!(
    q.sql,
    "SELECT * FROM \"users\" WHERE (\"id\" IN ($1, $2, $3) AND (\"name\" LIKE $4))",
  )
  assert_eq!(
    q.params,
    [
      @ast.Value::Int(1),
      @ast.Value::Int(2),
      @ast.Value::Int(3),
      @ast.Value::String("A%"),
    ],
  )
}
