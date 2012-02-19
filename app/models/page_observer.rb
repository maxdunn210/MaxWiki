# This class maintains the state of wiki references for newly created or newly deleted pages
#
# The references should be stored with the page name in "referenced_name". However, it is possible
# that a page is created with a reference to the link of a non-existent and then the page is created later.
# So we need to handle cases where the page link is used instead of the page name.
class PageObserver < ActiveRecord::Observer

  def after_create(page)
    WikiReference.update_all(['link_type = ?',WikiReference::LINKED_PAGE], 
        ['referenced_name = ?', page.name])
    WikiReference.update_all(['link_type = ?, referenced_name = ?',WikiReference::LINKED_PAGE, page.name], 
        ['referenced_name = ?', page.link])
  end

  def before_destroy(page)
    WikiReference.delete_all ['page_id = ?', page.id]
    WikiReference.update_all("link_type = '#{WikiReference::WANTED_PAGE}'", 
        ['referenced_name = ?', page.name])
    WikiReference.update_all("link_type = '#{WikiReference::WANTED_PAGE}'", 
        ['referenced_name = ?', page.link])
  end

end