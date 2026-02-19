test "get_str: existing column" {
  let row : @pg.Row = { data: { "name": @pg.Str("Alice"), "age": @pg.Int(30) } }
  assert_eq(get_str(row, "name"), "Alice")
}

test "get_str: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_str(row, "name"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("name")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

test "get_str: type mismatch" {
  let row : @pg.Row = { data: { "name": @pg.Int(42) } }
  let result = try {
    Result::Ok(get_str(row, "name"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("name", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_int: existing column" {
  let row : @pg.Row = { data: { "age": @pg.Int(30) } }
  assert_eq(get_int(row, "age"), 30)
}

test "get_int: type mismatch" {
  let row : @pg.Row = { data: { "age": @pg.Str("thirty") } }
  let result = try {
    Result::Ok(get_int(row, "age"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("age", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_bool: existing column" {
  let row : @pg.Row = { data: { "active": @pg.Bool(true) } }
  assert_eq(get_bool(row, "active"), true)
}

test "get_bool: type mismatch" {
  let row : @pg.Row = { data: { "active": @pg.Str("yes") } }
  let result = try {
    Result::Ok(get_bool(row, "active"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::TypeMismatch("active", _)) => ()
    _ => fail("expected TypeMismatch")
  }
}

test "get_double: from Double" {
  let row : @pg.Row = { data: { "price": @pg.Double(9.99) } }
  assert_eq(get_double(row, "price"), 9.99)
}

test "get_double: from Int" {
  let row : @pg.Row = { data: { "price": @pg.Int(10) } }
  assert_eq(get_double(row, "price"), 10.0)
}

test "get_int64: from Int64" {
  let row : @pg.Row = { data: { "big_id": @pg.Int64(9999999999L) } }
  assert_eq(get_int64(row, "big_id"), 9999999999L)
}

test "get_int64: from Int" {
  let row : @pg.Row = { data: { "id": @pg.Int(42) } }
  assert_eq(get_int64(row, "id"), 42L)
}

test "get_optional_str: present value" {
  let row : @pg.Row = { data: { "bio": @pg.Str("hello") } }
  assert_eq(get_optional_str(row, "bio"), Some("hello"))
}

test "get_optional_str: null value" {
  let row : @pg.Row = { data: { "bio": @pg.Null } }
  assert_eq(get_optional_str(row, "bio"), None)
}

test "get_optional_str: column not found" {
  let row : @pg.Row = { data: {} }
  let result = try {
    Result::Ok(get_optional_str(row, "bio"))
  } catch {
    err => Err(err)
  }
  match result {
    Err(DecodeError::ColumnNotFound("bio")) => ()
    _ => fail("expected ColumnNotFound")
  }
}

test "get_optional_int: present value" {
  let row : @pg.Row = { data: { "score": @pg.Int(100) } }
  assert_eq(get_optional_int(row, "score"), Some(100))
}

test "get_optional_int: null value" {
  let row : @pg.Row = { data: { "score": @pg.Null } }
  assert_eq(get_optional_int(row, "score"), None)
}

test "get_optional_bool: present value" {
  let row : @pg.Row = { data: { "verified": @pg.Bool(false) } }
  assert_eq(get_optional_bool(row, "verified"), Some(false))
}

test "get_optional_bool: null value" {
  let row : @pg.Row = { data: { "verified": @pg.Null } }
  assert_eq(get_optional_bool(row, "verified"), None)
}
