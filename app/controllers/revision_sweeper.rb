class RevisionSweeper < ActionController::Caching::Sweeper

  include CacheHelper
  
  observe Page, Revision
  
  # For saves, look at when the Revision changes since this will only be called once
  # If we look at the Page, then it will call this several times since at the beginning of edit
  # the lock information is written into the Page
  def after_save(record)
    if record.is_a?(Revision)
      expire_page_and_affected(record.page)
    end
  end
  
  def after_delete(record)
    if record.is_a?(Page)
      expire_page_and_affected(record)
    end
  end
   
end
