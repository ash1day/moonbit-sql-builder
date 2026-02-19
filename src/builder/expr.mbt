/// Helper functions for constructing Expr values

/// Create a column reference expression
pub fn col(name : String) -> @ast.Expr {
  @ast.Expr::Column(@ast.ColumnRef::Column(name))
}

/// Create a table-qualified column reference expression
pub fn table_col(table : String, name : String) -> @ast.Expr {
  @ast.Expr::Column(@ast.ColumnRef::TableColumn(table, name))
}

/// Create an integer value expression
pub fn val_int(v : Int) -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::Int(v))
}

/// Create a string value expression
pub fn val_str(v : String) -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::String(v))
}

/// Create a boolean value expression
pub fn val_bool(v : Bool) -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::Bool(v))
}

/// Create a null value expression
pub fn val_null() -> @ast.Expr {
  @ast.Expr::Value(@ast.Value::Null)
}
