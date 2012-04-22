require 'rubygems'
require 'sinatra'
require 'mongo_mapper'
require 'twitter'
require 'hpricot'
require 'haml'
require 'open-uri'
require 'youtube_it'
require 'config.rb'

MongoMapper::connection = Mongo::Connection.new(@db_server)
MongoMapper::database = @db_name

class Tweet
  include MongoMapper::Document
end

class Youtube
  include MongoMapper::Document
end

Twitter.configure do |config|
  config.consumer_key = @twitter_consumer 
  config.consumer_secret = @twitter_consumer_secret
  config.oauth_token = @twitter_oauth_token
  config.oauth_token_secret = @twitter_oauth_secret
end

get '/' do 
  #index of tweets
  @tweets = Tweet.all
  haml :index
end

#display the save tweet form
get '/save' do
  @tweet = nil
  haml :save
end

#fetch one tweet from a twitter url, get the json, save as json
post '/save' do
  #parse the id string out of the url
  #fetch the tweet and save it to mongo cache
  #is it twitter? (is twitter.com in the url?)
  #save some meta data 
  #client ip, originating site, meta tags, cache timestamp, processed timestamp
  
  if (params[:url].split("twitter.com").size >1)
    #ugly split
    id = params[:url].split("twitter.com")[1].split("/")[4]
    a_tweet = Twitter.status(id).attrs
    Tweet.collection.update({:id_str=>a_tweet["id_str"].to_s},a_tweet, {:upsert => true})
    #now view the tweet
    @tweet = a_tweet["text"]
  else
    #if not, parse what we can with hpricot and just save the whole page
    html = ""
    open(params[:url]) {|f|
      f.each_line {|line| html << line}
    }
    @html = Hpricot(html)
    title = (@html/"title")[0].inner_html
    Tweet.collection.update({:url=>params[:url]}, {:html=>html, :url=>params[:url],:title=>title}, {:upsert => true}) 
    @tweet = title
  end
    
  haml :save
end




#grab a youtube video thru the api and return json of the same, for ajax within occupymap
get '/video/*' do 
  response['Access-Control-Allow-Origin'] = '*'
  params[:url] = params[:splat].join("/") 
  if (params[:url].split("youtube.com").size > 1)
    params[:url] << "?v=" + params[:v]
    client = YouTubeIt::Client.new(:dev_key => @devkey)
    vid = client.video_by(params[:url])
    #buid a json out
    json = {:url =>params[:url], :title=>vid.title, :description=>vid.description, :username=>vid.author.name, :date =>vid.published_at}
    Youtube.collection.update({:url=>params[:url]},json,{:upsert=>true})
    content_type 'application/json'
    @json = json.to_json
  else 
    @json = "could not parse video"
  end
  haml :video
  
end



#get one tweet by its id string from the mongo cache, echo it as json 
get '/tweets/json/:id' do 
  response['Access-Control-Allow-Origin'] = '*'
  @json = Tweet.first(:id_str=>:id.to_s).to_json
  #just echo it as a json string
  content_type 'application/json'
  haml :view
end

