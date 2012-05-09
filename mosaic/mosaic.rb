#get all of the photos within a grid size of x and y 
class Mosaic 
  attr_accessor :page_size
  def grid(skip)
   CrawledTweet.all({:limit=>@page_size, :skip=>skip * @page_size,:order=>:timestamp.asc, :conditions=>{'entities.media.0.media_url'=>{:$exists=>true}, 'entities.urls.0.expanded_url'=>{'$not'=>/yfrog/}, :timestamp.gte=>1335848461, :timestamp.lte=>1335963661,:block=>{:$exists=>false}}})
  end
end



#temporarily disable yfrog - images need correct dimensions
get '/mosaic/.?:campaign?' do
  m = Mosaic.new
  m.page_size = 30
  @squares = m.grid(0)
  @page = 2
  haml 'mosaic/grid'.to_sym  
end

get '/mosaic/json/?:campaign/:page' do
  @page = params[:page].to_i+1
  m = Mosaic.new
  m.page_size = 30
  @squares =m.grid(@page)
  haml 'mosaic/grid'.to_sym  
end