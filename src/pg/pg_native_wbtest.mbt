///| Test inline_params replaces $1, $2 placeholders with literal values
test "inline_params replaces placeholders" {
  let sql = "SELECT * FROM users WHERE id = $1 AND name = $2"
  let params : Array[@ast.Value] = [@ast.Value::Int(42), @ast.Value::String("alice")]
  let result = inline_params(sql, params)
  assert_eq!(result, "SELECT * FROM users WHERE id = 42 AND name = 'alice'")
}

///| Test inline_params with no parameters returns sql unchanged
test "inline_params with empty params" {
  let sql = "SELECT 1"
  let result = inline_params(sql, [])
  assert_eq!(result, "SELECT 1")
}

///| Test inline_params escapes single quotes in strings
test "inline_params escapes single quotes" {
  let sql = "SELECT * FROM users WHERE name = $1"
  let params : Array[@ast.Value] = [@ast.Value::String("O'Brien")]
  let result = inline_params(sql, params)
  assert_eq!(result, "SELECT * FROM users WHERE name = 'O''Brien'")
}

///| Test inline_params with NULL, Bool, Int64, Double
test "inline_params with various types" {
  let sql = "INSERT INTO t VALUES ($1, $2, $3, $4)"
  let params : Array[@ast.Value] = [
    @ast.Value::Null,
    @ast.Value::Bool(true),
    @ast.Value::Int64(9999999999L),
    @ast.Value::Double(3.14),
  ]
  let result = inline_params(sql, params)
  assert_eq!(result, "INSERT INTO t VALUES (NULL, TRUE, 9999999999, 3.14)")
}

///| Test value_to_sql_literal for each variant
test "value_to_sql_literal" {
  assert_eq!(value_to_sql_literal(@ast.Value::Null), "NULL")
  assert_eq!(value_to_sql_literal(@ast.Value::Bool(true)), "TRUE")
  assert_eq!(value_to_sql_literal(@ast.Value::Bool(false)), "FALSE")
  assert_eq!(value_to_sql_literal(@ast.Value::Int(42)), "42")
  assert_eq!(value_to_sql_literal(@ast.Value::Int64(100L)), "100")
  assert_eq!(value_to_sql_literal(@ast.Value::Double(1.5)), "1.5")
  assert_eq!(value_to_sql_literal(@ast.Value::String("hello")), "'hello'")
  assert_eq!(
    value_to_sql_literal(@ast.Value::String("it's")), "'it''s'",
  )
}

///| Test str_to_column_value parses booleans
test "str_to_column_value booleans" {
  assert_eq!(str_to_column_value("t"), ColumnValue::Bool(true))
  assert_eq!(str_to_column_value("f"), ColumnValue::Bool(false))
}

///| Test str_to_column_value parses integers
test "str_to_column_value integers" {
  assert_eq!(str_to_column_value("42"), ColumnValue::Int(42))
  assert_eq!(str_to_column_value("0"), ColumnValue::Int(0))
  assert_eq!(str_to_column_value("-1"), ColumnValue::Int(-1))
}

///| Test str_to_column_value parses doubles
test "str_to_column_value doubles" {
  assert_eq!(str_to_column_value("3.14"), ColumnValue::Double(3.14))
  assert_eq!(str_to_column_value("1.0e2"), ColumnValue::Double(100.0))
}

///| Test str_to_column_value falls back to string
test "str_to_column_value strings" {
  assert_eq!(str_to_column_value("hello"), ColumnValue::Str("hello"))
  assert_eq!(
    str_to_column_value("2024-01-01"), ColumnValue::Str("2024-01-01"),
  )
}
