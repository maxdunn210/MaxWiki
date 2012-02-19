module ThemeHelper
  def viewvc_graph(name, pathrev, link)
    "<a href='http://cvs/viewvc/dvdo/#{link}?view=graph&hideattic=0&pathrev=#{pathrev}'>#{name}</a>"
  end
  def viewvc_co(name, pathrev, link)
    "<a href='http://cvs/viewvc/dvdo/#{link}?view=co&hideattic=0&pathrev=#{pathrev}'>#{name}</a>"
  end
  def pinnacles(name, link)
    "<a href='http://pinnacles.anchorbaytech.com/fileserv/data/#{link}'>#{name}</a>"
  end
  
  #Don't titleize page name
  def abt_breadcrumb(*items)
    items.flatten!
    html = "<div id='breadcrumb'>"
    items.each do |item| 
      split_item = item.split('|')
      html << wiki_link(split_item[0],split_item[1])
      html << " &gt; "
    end
    #html << "#{@page_name.titleize}\n"
    html << "#{@page_name}\n"
    html << "</div>\n"
    html  
  end
end
