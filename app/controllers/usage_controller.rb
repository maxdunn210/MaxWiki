#MD Aug 2011# require 'gruff'

class UsageController < ApplicationController 
  
  def show
    @location = params[:location]
    @return_link = params[:page_link] || @page.link rescue nil
    
    @categories = [
      {:name => 'Electricity', :unit => 'kWh/house/month'}, 
      {:name => 'Water', :unit => 'Gallons/person/day'}, 
      {:name => 'Car', :unit => 'Thousand miles/year'}
    ]
    
    @locations = Location.gather(@location)
    create_graph
    
    render :action => 'show'
  end
  
#--------  
private  
  
  def create_graph
  
    # Put file in cache directory
    filename = "usage_graph_#{@location}.png"
    path = File.expand_path(ActionController::Base.page_cache_directory)
    web_path = path["#{RAILS_ROOT}/public".size, 1024]
    graph_system_filename = File.join(path, filename)
    @graph_web_filename = File.join(web_path, filename)
    
    # If file already created for this location, return
    return if File.exists?(graph_system_filename)
     
    g = Gruff::Bar.new(500)
    g.theme = {
      :colors => %w(orange purple green white red),
      :marker_color => 'blue',
      :background_colors => 'white'
    }
    g.title = "Average Usage"
    
    @categories.each do |category|
      data = []
      @locations.each do |location|
        data << (location[category[:name]] || 0)
      end
      g.data("#{category[:name]} (#{category[:unit]})", data)
    end
    
    num = 0
    g.labels = {}
    @locations.each do |location|
      g.labels[num] = location[:name]
      num += 1
    end
    
    g.write(graph_system_filename)
  end  
  
end