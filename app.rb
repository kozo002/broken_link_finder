require "nokogiri"
require "open-uri"
require "uri"
require "active_record"
require "sqlite3"
require "tapp"
require "pathname"

base_url = ENV["base_url"]
fail "base_url is required" if base_url == nil

db_file = Pathname.new(File.dirname(__FILE__) + "/db.sqlite")

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database  => db_file.to_s
)

ActiveRecord::Migration.create_table :pages do |t|
  t.string  :url
  t.integer  :status
end

class Page < ActiveRecord::Base
end
