module MaxWiki
  module MaxWikiActiveRecordInclude
    
    def self.included(c)
      c.extend ClassMethods
    end
    
    module ClassMethods   
      
      def count(*args)
        with_scope(wiki_filter) do
          super
        end  
      end 
      
      private
      
      def find_every(*args)
        with_scope(wiki_filter) do
          super
        end  
      end
      
      def delete_all(*args)
        with_scope(wiki_filter) do
          super
        end  
      end
      
      def wiki_filter
        if current_wiki.nil?
          return {}
        elsif self.class == Class 
          return {} unless column_names.include?('wiki_id')
        else  
          return {} unless respond_to?('wiki_id')
        end 
        
        #TODO It doesn't filter the "wikis" table. Might want to do this for security.
        
        filter = {:find => {:conditions => "#{self.table_name}.wiki_id = #{current_wiki.id}"}}
        filter 
      end    
    end
  end
end

# Since MaxWikiActiveRecord is a model, it will get created before this plugin. Therefore
# we need to patch it here. However, with mongrel or fast_cgi, MaxWikiActiveRecord will be
# created on each access, but this plugin won't be recreated. Therefore the following line
# will work the first time, and then the :include in MaxWikiActiveRecord will work the
# subsequent times.
MaxWikiActiveRecord.extend(MaxWiki::MaxWikiActiveRecordInclude::ClassMethods)
