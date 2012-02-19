# The theme environment defaults
# Be sure to include every possible variable that appears in any theme_environment.rb file otherwise
# there will be problems with multi-hosted sites 
MY_CONFIG[:hide_empty_left_column] = false
MY_CONFIG[:hide_empty_right_column] = true
MY_CONFIG[:hide_breadcrumb] = false
MY_CONFIG[:hide_byline_on_page] = false
MY_CONFIG[:hide_byline_if_not_logged_in] = false
MY_CONFIG[:hide_byline_author_link] = false   
MY_CONFIG[:byline_under_footer] = false
MY_CONFIG[:footer_edit_on_right] = false
MY_CONFIG[:hide_menu] = false
MY_CONFIG[:menu_on_left] = false
MY_CONFIG[:menu_in_header_buffer_on_home_page] = false
MY_CONFIG[:buffer_header_short] = false
MY_CONFIG[:max_signups] = 0
MY_CONFIG[:signup_text] = "There are 3 steps to signing up for an account.<br\><br\>\n" +
    "1. Complete this form. You will be sent an email.<br\>\n" +
    "2. Click on the link in the email to activate your account.<br\>\n" +
    "3. Login using your email address and password.<br\>\n"
    "<br\>\n" +
    "We will be sent an email and then will give you an Editor role.\n"
MY_CONFIG[:signup_closed_text] = "<b>Signups are now closed!</b> However, you can complete this form to be added to the waiting list. " +
    "There are 2 steps to get on the waiting list:<br\><br\>\n" +
    "1. Complete this form. You will be sent an email.<br\>\n" +
    "2. Click on the link in the email to activate your account.<br\>\n" +
    "<br\>\n" +
    "You will be notified if space becomes available.\n"
MY_CONFIG[:signup_ask_company] = false
MY_CONFIG[:signup_email_note] = ''
MY_CONFIG[:user_list_columns] = [
     {:name => 'email', :caption => 'Email'},
     {:name => 'role', :caption => 'Role'}
   ]
MY_CONFIG[:tric] = false
MY_CONFIG[:flickr_per_page] = 5  #Probably no longer used May-4-2007

   