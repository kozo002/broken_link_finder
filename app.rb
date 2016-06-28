require "nokogiri"
require "open-uri"
require "uri"
require "active_record"
require "sqlite3"
require "tapp"
require "pathname"

@base_url = ENV["base_url"]
fail "base_url is required" if @base_url == nil
@base_url = URI.parse(@base_url)

db_file = Pathname.new(File.dirname(__FILE__) + "/db.sqlite")

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database  => db_file.to_s
)

unless db_file.exist?
  ActiveRecord::Migration.create_table :pages do |t|
    t.string  :url
    t.integer  :status
  end
end

class Page < ActiveRecord::Base
end

def get_all_hrefs(page)
  sanitized_url = URI.encode(page.url)
  urls = Nokogiri::HTML(open(sanitized_url).read).css("a")
    .map{ |a| a.attribute("href").value }
    .select{ |url|
      url.start_with?("/") || url.start_with?("http://#{ @base_url.host }") || url.start_with?("https://#{ @base_url.host }")
    }
    .map{ |url|
      if url.start_with?("/")
        "https://#{ @base_url.host }" + url
      else
        url
      end
    }
  page.status = 200
  page.save
  urls
rescue OpenURI::HTTPError => e
  page.status = 404
  page.save
  []
end

# Page.where(url: 'https://www.pandorahouse.net/awards/9-%E7%AC%AC%E4%B9%9D%E5%9B%9E%E3%83%91%E3%83%B3%E3%83%89%E3%83%A9%E5%A4%A7%E8%B3%9E/creations.html?award=5').inspect.tapp
# Page.find(1017).url.tapp

Page.find_each do |page|
  urls = get_all_hrefs(page)
  urls.each do |url|
    if Page.exists?(url: url)
      puts "Already saved: #{url}"
    else
      Page.create(url: url)
      puts "New record: #{ url }"
    end
  end
end
