#get all of the photos within a grid size of x and y 
class Mosaic 
  attr_accessor :page_size, :campaign, :conditions, :meta_info
  def grid(skip)
    if @campaign == nil
      @campaign = 'chicagonato'
    end
    @conditions = {
      :mayday=>{:limit=>@page_size, :skip=>skip * @page_size,:order=>:timestamp.asc, :conditions=>{'entities.media.0.media_url'=>{:$exists=>true}, 'entities.media.0.sizes.small.h'=>{:$exists=>true}, 'entities.urls.0.expanded_url'=>{'$not'=>/yfrog/}, :timestamp.gte=>1335848461, :timestamp.lte=>1336163661,:block=>{:$exists=>false}}},
      :casseroles=>{:limit=>@page_size, :skip=>skip * @page_size,:order=>:timestamp.desc, :conditions=>{'entities.media.0.media_url'=>{:$exists=>true}, 'entities.media.0.sizes.small.h'=>{:$exists=>true}, 'entities.urls.0.expanded_url'=>{'$not'=>/yfrog/}, :timestamp.gte=>1337907661, :timestamp.lte=>1338858061,:block=>{:$exists=>false}}},
      :chicagonato=>{:skip=>skip * @page_size,:limit=>30,:order=>:timestamp.desc, :conditions=>{'entities.media.0.media_url'=>{:$exists=>true},'entities.media.0.sizes.small.h'=>{:$exists=>true},:timestamp.gte=>1337302861, :timestamp.lte=>1380949261,:block=>{:$exists=>false}}}
    }
    @meta = {
      :mayday =>{:page_title =>"Occupy Mosaic - May Day",:description=>"A mosaic of photos that were posted worldwide during the May Day General Strike"},
      :casseroles =>{:page_title =>"Occupy Mosaic - Quebec and Quebec Solidarity",:description=>"A mosaic of the Quebec #manifencours actions and solidarity actions in NYC"},
      :chicagonato => {:page_title => "Occupy Mosaic - Chicago - NATO Summit", :description=>"A mosaic of photos posted on Twitter during the protests against the NATO summit in Chicago"}
    }
    @meta_info = @meta[@campaign.to_sym]
    
    c = @conditions[@campaign.to_sym]
    if c == nil 
      c = @conditions[:chicagonato]
    end
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
  @meta = m.meta_info
  haml 'mosaic/grid'.to_sym  
end

get '/page/?:campaign/:page' do
  @page = params[:page].to_i+1
  m = Mosaic.new
  m.campaign = params[:campaign]
  m.page_size = 30
  @campaign = m.campaign
  @squares =m.grid(@page)
  @meta = m.meta_info
  haml 'mosaic/grid'.to_sym  
end
