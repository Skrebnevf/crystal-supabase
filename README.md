# Supabase Crystal Client

<p align="center">
  <a href="https://github.com/Skrebnevf/crystal-supabase/blob/main/LICENSE" style="text-decoration:none">
    <img src="https://img.shields.io/github/license/Skrebnevf/crystal-supabase" alt="License">
  </a>
  <a href="https://crystal-lang.org/" style="text-decoration:none">
    <img src="https://img.shields.io/badge/language-Crystal-000?logo=crystal&logoColor=white" alt="Crystal">
  </a>
  <a href="https://github.com/Skrebnevf/crystal-supabase/commits/main" style="text-decoration:none">
    <img src="https://img.shields.io/github/last-commit/Skrebnevf/crystal-supabase" alt="Last Commit">
  </a>
</p>


Crystal client for Supabase REST API supporting basic CRUD operations with query building.  
## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     crystal-supabase:
       github: Skrebnevf/crystal-supabase
   ```

2. Run `shards install`

## Usage

```crystal
require "crystal-supabase"
```

### Select

```crystal
response = client
  .from("users")
  .select("*")
  .eq("active", "true")
  .execute()
puts response
```

### Insert

```crystal
payload = %({"name": "Alice", "age": 30})
response = client
  .from("users")
  .insert(payload)
  .execute()
puts response
```

### Update

```crystal
payload = %({"name": "Charlie"})
response = client
  .from("users")
  .eq("id", "1")
  .update(payload)
  .execute()
puts response
```

### Upsert

```crystal
payload = %({"id": 1, "name": "Bob"})
response = client
  .from("users")
  .upsert(payload, ["id"])
  .execute()
puts response
```

### Delete

```crystal
response = client
  .from("users")
  .eq("id", "1")
  .delete()
  .execute()
puts response
```

### Query Filters Examples

```crystal
response = client
  .from("products")
  .select("id,name,price")
  .gt("price", "100")
  .lt("price", "500")
  .like("name", "%book%")
  .order_desc("price")
  .limit(10)
  .execute()
puts response
```

### RPC

```crystal
response = client.rpc("hello_world")
puts response
```

## TODO

- [x] Add basic CRUD
- [x] Add filters
- [x] Implement bulk for multiple rows
- [x] Add call of Postgres functions
- [ ] Add modifiers


## Contributing

1. Fork it (<https://github.com/Skrebnevf/crystal-supabase/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [f.skrebnev](https://github.com/Skrebnevf) - creator and maintainer
- [@hope_you_die](https://t.me/hope_you_die) - TG
