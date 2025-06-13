require "json"

struct ExecuteError
  include JSON::Serializable
  
  @[JSON::Field(key: "hint")]   
  property hint : String | Nil

  @[JSON::Field(key: "message")]
  property message : String | Nil

  @[JSON::Field(key: "code")]
  property code : String | Nil

  @[JSON::Field(key: "details")]
  property details : String | Nil
end
