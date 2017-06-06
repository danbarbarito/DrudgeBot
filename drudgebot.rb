require 'cinch'
require "sqlite3"
require 'rss'
require 'open-uri'


class DrudgeUpdates
  include Cinch::Plugin

  timer 60, method: :drudge_updates
  
  def drudge_updates
    # Open a database
    db = SQLite3::Database.new "drudgebot.db"

    # Create drudge_updates table
    begin
      rows = db.execute <<-SQL
      create table drudge_updates (
        title varchar(100),
        link varchar(100)
      );
      SQL
    rescue SQLite3::SQLException
    end

    url = 'http://feeds.feedburner.com/DrudgeReportFeed'
    open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      feed.items.each do |item|
        title = item.title
        link = item.link

        # Check if update already exists. If it doesn't, put it in the database and send the message to #drudge
        rows = db.execute("select * from drudge_updates where title = ?", title)
        if rows.length == 0
          db.execute "insert into drudge_updates values (?, ?)", title, link
          Channel("#drudge").send("#{title} - #{link}")
        end
      end
    end
    # Channel("#drudge").send(Time.now.to_s)
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    # c.server = "auirc.net"
    # c.channels = ["#drudge"]
    c.nick = "DrudgeBot"
    c.plugins.plugins = [DrudgeUpdates]
  end
  
end

bot.start
