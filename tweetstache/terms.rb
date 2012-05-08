#flag to occupy map => worker pulls to to tweets collection
get '/terms/' do 
  @terms = Term.all({:order=>:term.asc})
  haml 'terms/index'.to_sym
end

post '/terms/' do 
  puts params.inspect
  Term.collection.update({:term=>params[:term]}, {:term=>params[:term],:last_checked=>Time.now,:is_active=>params[:is_active]},{:upsert=>true})
  @terms = Term.all({:order=>:term.asc})
  haml 'terms/index'.to_sym
end

get '/terms/edit/:id' do
  @term = Term.find(params[:id])
  @selected = {:yes=>'',:no=>''}
  @selected[@term['is_active']]='selected'
  puts @term.inspect
  puts @selected.inspect
  haml 'terms/edit'.to_sym
end