require 'rubygems'
require 'sinatra'
require 'mongo_mapper'
require 'twitter'
require 'hpricot'
require 'haml'
require 'open-uri'

#gems for api services for the crawler
require 'youtube_it'
#https://github.com/matthooks/vimeo
require 'vimeo'
#https://github.com/meltingice/ruby-twitpic
#require 'twitpic-full'
require 'config.rb'
#https://github.com/Instagram/instagram-ruby-gem
#require 'instagram'
#subclasses

require 'tweetstache/expand_url.rb'
require 'tweetstache/mosaic.rb'
require 'tweetstache/terms.rb'

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




#get each tweet for services twitpic, via.me,
#lambda for each service to scrape or api
#CrawledTweet.first({:conditions=>{["entities.urls.0.expanded_url"]=>{'$exists'=>true},["entities.urls.0.expanded_url"]=>/#{service}/}})

Twitter.configure do |config|
  config.consumer_key = @twitter_consumer 
  config.consumer_secret = @twitter_consumer_secret
  config.oauth_token = @twitter_oauth_token
  config.oauth_token_secret = @twitter_oauth_secret
end

get '/' do 
  #index of tweets
  @tweets = Tweet.all.reverse
  haml :index
end

#display the save tweet form
get '/save' do
  @tweets = Tweet.all.reverse
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


#gateway to return tweet json to ushahidi form
get '/tweet/*' do
  response['Access-Control-Allow-Origin'] = '*'
  params[:url] = params[:splat].join("/") 
  #yes, it's a tweet, grab the json, parse it, echo it and save it
  if (params[:url].split("youtube.com").size > 1)
  
  
  end
end



#crawl a tweet search term
#m1gs, m1nyc, #baym1gs, #888turk
#chicago, robeson school, 
#between may 1 and may 2
#anything from mapreport, mapreport2 mapreport3
#philly, portland, chicago, sf, boston


get '/crawl' do 
  #fitler out retweets
  
  while 1
    @terms = Term.all({:conditions=>{:is_active=>'yes'},:order=>:last_checked.desc})
    @blocked = BlockedUser.all
    @block = {}
    @blocked.each do |block|
      @block[block["user_id"]] = block["user_id"]
    end
    @time = ['2012-05-02','2012-05-03','2012-05-04']
  
    @terms.each do |term|
      #get an id from may 1, early
      #197149879875813377
      @time.each do |date_until|
        puts term.inspect
        #find one term to get max id
        max = CrawledTweet.find({:conditions=>{:date_until_str=>date_until,:text=>'/'+term+'/'},:limit=>1, :order=>:id_str.asc})
        puts date_until
        15.times do |p|
          begin 
            #m1gs since_id:196982181401341952 until:2012-05-03
            #max id
          tweets = Twitter.search(term.term.to_s + " -rt -facials -amateur",{:rpp=>100, :page => (p+1).to_i,:since_id =>196982181401341952, :until=>date_until,:include_entities=>1})
          rescue Twitter::Error::BadGateway
          rescue NoMethodError
            puts "bad gateway"
            sleep 600
             tweets = Twitter.search(term.term.to_s + " -rt -facials -amateur",{:rpp=>100, :page => (p+1).to_i, :since_id =>196982181401341952, :until=>date_until,:include_entities=>1})
          end
          puts tweets.size
          
          tweets.each do | a_tweet |
            begin 
              a_tweet.attrs["timestamp"] = Time.parse(a_tweet.attrs["created_at"]).to_i
            rescue NoMethodError
              a_tweet.attrs["timestamp"] = 1
            end
      
            #extract vids for embed code
            if a_tweet.attrs["entities"]
              if a_tweet.attrs["entities"]["urls"] !=nil
              a_tweet.attrs["entities"]["urls"].each do |url|
                begin 
                  url["expanded_url"].expand_urls!
                rescue NoMethodError
                  url["expanded_url"] = ""
                end
                if url["expanded_url"].split("youtube.com").size >1 || url["expanded_url"].split("youtu.be").size > 1
                  client = YouTubeIt::Client.new(:dev_key => @devkey)
                  begin 
                    vid = client.video_by(url["expanded_url"])
                    a_tweet.attrs["video_embed"] = vid.embed_html
                  rescue OpenURI::HTTPError => e
                  
                  end
                elsif (url["expanded_url"].split("vimeo.com").size > 1)
                  video_id = url["expanded_url"].split("/").last
                  vid = Vimeo::Simple::Video.info(video_id)
                  a_tweet.attrs["video_embed"] =  '<iframe src="http://player.vimeo.com/video/#{vid.id}" width="500" height="313" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>'
            
                elsif (url["expanded_url"].split("ht.ly").size > 1)
                  a_tweet.attrs["block"] =1
            
                elsif (url["expanded_url"]).split("instagr.am").size > 1
                  #add the media link
                    html = ""
                    open(url["expanded_url"]) {|f|
                      f.each_line {|line| html << line}
                    }
                   @html = Hpricot(html)
                   a_tweet.attrs["entites.media.0.media_url"] =(@html/"img.photo")[0][:src]
                   a_tweet.attrs["entities"]["media"] = [:expanded_url=>  (@html/"img.photo")[0][:src]]
                  
                end
                  #expanded url for twitpic
                  #http://instagr.am/
                  #yfrog
                  #via.me
                  #lockerz
              end
            end
            end


            if @block[a_tweet.attrs["from_user_id"].to_s] !=nil
              a_tweet.attrs["block"] = 1
            end
            begin 

           a_tweet.attrs['id'] = nil  
           a_tweet. CrawledTweet.collection.update({:id_str=>a_tweet.attrs["id_str"].to_s},a_tweet.attrs, {:upsert => true})
          rescue  
          end
          end
          sleep 2
        end
        Term.collection.update({:term=>term.term},{:term=>term.term,:last_checked=>Time.now},{:upsert=>true})
        sleep 30
      end
      
    end
  
  end
  haml :crawl
end

get "/crawl/tweets/:page/?:media:?" do
  if params[:page]==nil
    page = 0
  else
    page = params[:page].to_i 
  end
  
  if params[:media] !=nil
  # 0 = everything
  # 1 = videos, no photos
  # 2 = photos, no videos
  # 3 = photos and videos
  filter_media = [{:video_embed=>{'$exists'=>true}},{:image_url=>{'$exists'=>true}}]
  
    if params[:media]==1
      filter_media = [{:video_embed=>{'$exists'=>true}}]
    else 
      filter_media = [{}]
    end
  end
  @media = params[:media]
  if page > 0 
    @prev = page -1
  end
  @next = page + 1
  #not blocked users
  @tweets = CrawledTweet.all({:conditions=>{:block=>{'$exists'=>false}},:limit=>25, :skip=>25*page,:order=>:timestamp.asc}.merge(filter_media[0]))
  haml :tweets
end

#grab a youtube video thru the api and return json of the same, for ajax within occupymap
get '/video/*' do 
  response['Access-Control-Allow-Origin'] = '*'
  params[:url] = params[:splat].join("/") 
  if (params[:url].split("youtube.com").size > 1)
    params[:url] << "?v=" + params[:v]
    params[:url].gsub!("http:/","http://")
    client = YouTubeIt::Client.new(:dev_key => @devkey)
    vid = client.video_by(params[:url])
    #buid a json out
    json = {:url =>params[:url], :title=>vid.title, :description=>vid.description, :username=>vid.author.name, :date =>vid.published_at}
    Youtube.collection.update({:url=>params[:url]},json,{:upsert=>true})
    content_type 'application/json'
    @json = json.to_json
    
    
  elsif (params[:url].split("vimeo.com").size > 1)
    #parse out the vimeo id
    video_id = params[:url].split("/").last
    params[:url].gsub!("http:/","http://")
    v = Vimeo::Simple::Video.info(video_id).parsed_response[0]
    json = {:url =>params[:url], :title=>v["title"], :description=>v["description"],
       :username=>v["user_url"], :date =>v["upload_date"]}
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

get '/users/block/:user_id' do 
  #add user to blocks table
  #flag all existing tweets and crawled tweets to hide
  BlockedUser.collection.update({:user_id=>params[:user_id]},{:user_id=>params[:user_id]},{:upsert=>true})
  @tweets = CrawledTweet.all({:conditions=>{:user.id=>params[:user_id]}})
  @tweets.each do |tweet|
    tweet["block"] = 1
    CrawledTweet.collection.update({:id_str=>tweet.attrs["id_str"].to_s},tweet.attrs, {:upsert => true})
  end
end

#compile videos from crawled tweets
get '/videos/compile?' do
  @tweets = CrawledTweets.all({:conditions=>{:video_embed=>{'$exists'=>true}}})
  @tweets.each do |tweet|
    Video.collection.update({:url=>tweet[]})
  end
end

#get videos from the video collection - thumbnail, embed, who tweeted it
get '/videos/index/:page?' do
  
end
