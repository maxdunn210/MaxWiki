<div class='scroll_area'>
<code><pre>


Processing AdminController#expire_cache (for 127.0.0.1 at 2007-02-07 14:32:54) [GET]
  Session ID: c9ca3acea9a1b4120e1345e0e5ea9abf
  Parameters: {&quot;action&quot;=&gt;&quot;expire_cache&quot;, &quot;controller&quot;=&gt;&quot;admin&quot;}
Wiki Columns (0.056093)  SHOW FIELDS FROM wikis
Wiki Load (0.014527)  SELECT * FROM wikis WHERE (wikis.`name` = 'maxwiki') LIMIT 1
System Columns (0.001921)  SHOW FIELDS FROM system
System Load (0.000278)  SELECT * FROM system LIMIT 1
User Columns (0.012999)  SHOW FIELDS FROM adults
User Load (0.000555)  SELECT * FROM adults WHERE (adults.wiki_id = 1) AND (adults.id = 4) 
Cookie set: role=Admin; path=/; expires=Tue, 01 Jan 2030 00:00:00 GMT
Page Columns (0.002399)  SHOW FIELDS FROM pages
Page Load (0.000376)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.wiki_id = 1 AND (name = 'header')) LIMIT 1
Revision Columns (0.002082)  SHOW FIELDS FROM revisions
Revision Load (0.000811)  SELECT * FROM revisions WHERE (revisions.wiki_id = 1) AND (revisions.page_id = 1) ORDER BY id DESC LIMIT 1
Page Load (0.000253)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.wiki_id = 1 AND (name = 'menu')) LIMIT 1
Revision Load (0.000636)  SELECT * FROM revisions WHERE (revisions.wiki_id = 1) AND (revisions.page_id = 2) ORDER BY id DESC LIMIT 1
Page Load (0.000230)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.wiki_id = 1 AND (name = 'footer')) LIMIT 1
Revision Load (0.000596)  SELECT * FROM revisions WHERE (revisions.wiki_id = 1) AND (revisions.page_id = 3) ORDER BY id DESC LIMIT 1
Rendering  within layouts/main
Rendering admin/expire_cache
Page Load (0.000407)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.id = 1) 
Wiki Load (0.000256)  SELECT * FROM wikis WHERE (wikis.id = 1) 
Rendered layouts/_edit_links (0.01436)
Page Load (0.000588)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.id = 2) 
Wiki Load (0.000282)  SELECT * FROM wikis WHERE (wikis.id = 1) 
SQL (0.000797)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'HomePage') 
SQL (0.000763)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Products') 
SQL (0.000793)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Editing') 
SQL (0.000749)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Install') 
SQL (0.000741)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'About Us') 
SQL (0.000881)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Business Plan') 
SQL (0.000763)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Contact Us') 
Rendered layouts/_edit_links (0.01137)
Rendered layouts/_header (0.19689)
Rendered reg_admin/_reg_admin_left_menu (0.00823)
Rendered layouts/_columns (0.01343)
Page Load (0.000383)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.id = 3) 
Wiki Load (0.000251)  SELECT * FROM wikis WHERE (wikis.id = 1) 
Rendered layouts/_edit_links (0.01342)
Rendered layouts/_footer (0.05652)
Session #19837588: remembered URL '/_action/admin/expire_cache'
Completed in 0.48115 (2 reqs/sec) | Rendering: 0.32411 (67%) | DB: 0.10141 (21%) | 200 OK [http://local.maxwiki.com/_action/admin/expire_cache]


Processing AdminController#expire_cache (for 127.0.0.1 at 2007-02-07 14:33:36) [GET]
  Session ID: c9ca3acea9a1b4120e1345e0e5ea9abf
  Parameters: {&quot;action&quot;=&gt;&quot;expire_cache&quot;, &quot;controller&quot;=&gt;&quot;admin&quot;}
Wiki Columns (0.003489)  SHOW FIELDS FROM wikis
Wiki Load (0.146298)  SELECT * FROM wikis WHERE (wikis.`name` = 'maxwiki') LIMIT 1
System Columns (0.002310)  SHOW FIELDS FROM system
System Load (0.000544)  SELECT * FROM system LIMIT 1
Wiki Columns (0.002889)  SHOW FIELDS FROM wikis
User Load (0.000535)  SELECT * FROM adults WHERE (adults.wiki_id = 1) AND (adults.id = 4) 
Cookie set: role=Admin; path=/; expires=Tue, 01 Jan 2030 00:00:00 GMT
Page Columns (0.002306)  SHOW FIELDS FROM pages
Page Load (0.000373)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.wiki_id = 1 AND (name = 'header')) LIMIT 1
Revision Columns (0.002261)  SHOW FIELDS FROM revisions
Revision Load (0.001628)  SELECT * FROM revisions WHERE (revisions.wiki_id = 1) AND (revisions.page_id = 1) ORDER BY id DESC LIMIT 1
Page Load (0.000480)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.wiki_id = 1 AND (name = 'menu')) LIMIT 1
Revision Load (0.000894)  SELECT * FROM revisions WHERE (revisions.wiki_id = 1) AND (revisions.page_id = 2) ORDER BY id DESC LIMIT 1
Page Load (0.000319)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.wiki_id = 1 AND (name = 'footer')) LIMIT 1
Revision Load (0.000807)  SELECT * FROM revisions WHERE (revisions.wiki_id = 1) AND (revisions.page_id = 3) ORDER BY id DESC LIMIT 1
Rendering  within layouts/main
Rendering admin/expire_cache
Page Load (0.000405)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.id = 1) 
Wiki Load (0.000259)  SELECT * FROM wikis WHERE (wikis.id = 1) 
Rendered layouts/_edit_links (0.01291)
Page Load (0.000449)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.id = 2) 
Wiki Load (0.000253)  SELECT * FROM wikis WHERE (wikis.id = 1) 
SQL (0.000784)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'HomePage') 
SQL (0.001015)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Products') 
SQL (0.000828)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Editing') 
SQL (0.000763)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Install') 
SQL (0.000745)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'About Us') 
SQL (0.000741)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Business Plan') 
SQL (0.000738)  SELECT count(*) AS count_all FROM pages WHERE (pages.wiki_id = 1) AND (name = 'Contact Us') 
Rendered layouts/_edit_links (0.01225)
Rendered layouts/_header (0.12406)
Rendered reg_admin/_reg_admin_left_menu (0.00398)
Rendered layouts/_columns (0.00435)
Page Load (0.000372)  SELECT * FROM pages WHERE (pages.wiki_id = 1) AND (pages.id = 3) 
Wiki Load (0.000260)  SELECT * FROM wikis WHERE (wikis.id = 1) 
Rendered layouts/_edit_links (0.01190)
Rendered layouts/_footer (0.01846)
Session #19994788: remembered URL '/_action/admin/expire_cache'
Completed in 0.44030 (2 reqs/sec) | Rendering: 0.20715 (47%) | DB: 0.17274 (39%) | 200 OK [http://local.maxwiki.com/_action/admin/expire_cache]

</pre></code>
</div>
