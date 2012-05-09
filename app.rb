require 'rubygems'
require 'sinatra'
require 'mongo_mapper'
require 'haml'
require 'config.rb'
require 'mosaic/mosaic.rb'

#mongo
MongoMapper::connection = Mongo::Connection.new(@db_server)
MongoMapper::database = @db_name

#mongodb collection classes

#these are tweets that are intentionally saved for republishing
class Tweet
  include MongoMapper::Document
end

#these are all tweets crawled
class CrawledTweet
  include MongoMapper::Document
end

class Term
  include MongoMapper::Document
  timestamps!
end

class BlockedUser
  include MongoMapper::Document
end
#really this needs to be migrated to videos
class Youtube
  include MongoMapper::Document
end

class Video
  include MongoMapper::Document
end


get '/' do 
  haml 'mosaic/grid'.to_s
end
