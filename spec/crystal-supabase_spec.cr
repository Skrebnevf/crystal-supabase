require "spec"
require "../src/crystal-supabase/client.cr"
require "../src/crystal-supabase/query.cr"
require "webmock"

describe Supabase::Query do
  url = "https://mock.supabase.co"
  key = "test-api-key"
  headers = {"apikey" => key, "Authorization" => "Bearer #{key}"}
  client = Supabase::Client.new(url, key)

  before_each do
    WebMock.reset
  end

  it "builds SELECT query" do
    WebMock.stub(:get, "#{url}/rest/v1/users?select=*")
      .with(headers: headers)
      .to_return(body: %([{"id":1,"name":"Test", "email":"new@new.new"}]), status: 200)

    result = client
      .from("users")
      .select("*")
      .execute

    result.should contain("Test")
    result.should contain("new@new.new")
  end

  it "builds INSERT query" do
    payload = %({ "id":2, "name":"Alice" })
    WebMock.stub(:post, "#{url}/rest/v1/users")
      .with(headers: headers)
      .to_return(body: %([{"id":2,"name":"Alice"}]), status: 201)

    result = client
      .from("users")
      .insert(payload)
      .execute

    result.should contain("Alice")
    result.should contain("2")
  end

  it "builds UPSERT query" do
    payload = %({"id":3, "name":"John"})
    WebMock.stub(:post, "#{url}/rest/v1/users?on_conflict=id")
      .with(headers: headers)
      .to_return(body: %([{"id":3,"name":"John"}]), status: 201)

    result = client
      .from("users")
      .upsert(payload, on_conflict: ["id"])
      .execute

    result.should contain("John")
    result.should contain("3")
  end

  it "builds UPDATE query" do
    payload = %({"id":4, "name":"Fred"})
    WebMock.stub(:patch, "#{url}/rest/v1/users?id=eq.4")
      .with(headers: headers)
      .to_return(body: %([{"id":4,"name":"Fred"}]), status: 200)

    result = client
      .from("users")
      .update(payload)
      .eq("id", "4")
      .execute

    result.should contain("Fred")
    result.should contain("4")
  end

  it "builds Delete query" do
    WebMock.stub(:delete, "#{url}/rest/v1/users?id=eq.5")
      .to_return(body: %({"id":5, "name":"Anna"}), status: 200)

    result = client
      .from("users")
      .delete
      .eq("id", "5")
      .execute

    result.should contain("Anna")
    result.should contain("5")
  end
end
require "./spec_helper"
