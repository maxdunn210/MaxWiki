#!/usr/bin/env ruby
require(File.join(File.dirname(__FILE__), 'config', 'boot'))
require File.expand_path('../config/environment', __FILE__)

#wiki = Wiki.find_by_name('maxwiki')

Wiki.find(:all).each do |wiki|
  wiki.pages.each do |page|
    count = page.revisions.count
    if count > 10
      puts "Pruning #{wiki.name}:#{page.name} => #{count}"
      ids = page.revisions.map {|p| p.id}.sort.first(count - 10)
      Revision.delete(ids)
    end
  end
end