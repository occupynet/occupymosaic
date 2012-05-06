#get all of the photos within a grid size of x and y 
get '/mosaic/' do
  #not blocked users
#  @squares = CrawledTweet.all({:limit=>30,:order=>:timestamp.asc, :conditions=>{:$or=>[{'entities.media.0.media_url'=>{:$exists=>true}},{:video_embed=>{:$exists=>true}}],:block=>{:$exists=>false}}})

#may day timestamps
# 1335848461
# 1335963661


  @squares = CrawledTweet.all({:limit=>30,:order=>:timestamp.asc, :conditions=>{'entities.media.0.media_url'=>{:$exists=>true}, :timestamp.gte=>1335848461, :timestamp.lte=>1335963661,:block=>{:$exists=>false}}})
  puts @squares.size
  @page = 2
  haml 'mosaic/grid'.to_sym  
end

get '/mosaic/json/:page' do
  @page = params[:page].to_i+1
  @squares = CrawledTweet.all({:limit=>30, :skip=>30*(@page-1),:order=>:timestamp.asc, :conditions=>{'entities.media.0.media_url'=>{:$exists=>true},:timestamp.gte=>1335848461, :timestamp.lte=>1335963661,:block=>{:$exists=>false}}})
  haml 'mosaic/grid'.to_sym
end

#get the content for a single grid square on the mosaic
get '/mosaic/square/:id' do

end