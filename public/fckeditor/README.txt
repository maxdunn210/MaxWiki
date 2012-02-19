
These are all the required files that come with an install of fckeditor.

Note that there is a java script tag required in the layout to point to fckeditor.js.

In our own javascripts, there is myfckconfig.js, which overrides the other config file.
Among other things, it defines menu configuration(s), and excludes <%...%> tags.

TROUBLESHOOTING:

Visit these pages to narrow down possible integration issues.
http://www.maxwiki.com/fckeditor/_samples/html/sample01.html
http://www.maxwiki.com/_test/fckeditor_sample_1
http://www.maxwiki.com/_test/fckeditor_sample_2
http://www.maxwiki.com/_test/fckeditor_sample_3

VERY IMPORTANT:

Changes have been made in the sources for:
  editor/dialog/fck_link.html
  editor/dialog/fck_link/fck_link.js
to add Wikilink functionality. 
To find the changed sections, search for ****

