#get all of the photos within a grid size of x and y 
class Mosaic 
  attr_accessor :page_size, :campaign, :conditions
  def grid(skip)
    if @campaign == nil
      @campaign = 'natochicago'
    end
    @conditions = {
      :mayday=>{:limit=>@page_size, :skip=>skip * @page_size,:order=>:timestamp.asc, :conditions=>{'entities.media.0.media_url'=>{:$exists=>true}, 'entities.media.0.sizes.small.h'=>{:$exists=>true}, 'entities.urls.0.expanded_url'=>{'$not'=>/yfrog/}, :timestamp.gte=>1335848461, :timestamp.lte=>1335963661,:block=>{:$exists=>false}}},
      :natochicago=>{:skip=>skip * @page_size,:limit=>30,:order=>:timestamp.desc, :conditions=>{'entities.media.0.media_url'=>{:$exists=>true},'entities.media.0.sizes.small.h'=>{:$exists=>true},:timestamp.gte=>1337302861, :timestamp.lte=>1337602332,:block=>{:$exists=>false}}}
    }
    c = @conditions[@campaign.to_sym]
    if c == nil 
      c = @conditions[:natochicago]
    end
    puts c.inspect
   CrawledTweet.all(c)
  end
end

get '/about' do 
  haml :about
end

#temporarily disable yfrog - images need correct dimensions
get '/.?:campaign?' do
  m = Mosaic.new
  m.campaign = params[:campaign]
  m.page_size = 30
  @squares = m.grid(0)
  @page = 2
  @campaign = m.campaign
  haml 'mosaic/grid'.to_sym  
end

get '/page/?:campaign/:page' do
  @page = params[:page].to_i+1
  m = Mosaic.new
  m.campaign = params[:campaign]
  m.page_size = 30
  @campaign = m.campaign
  @squares =m.grid(@page)
  haml 'mosaic/grid'.to_sym  
end