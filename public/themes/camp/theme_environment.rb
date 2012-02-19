#Camp theme overrides
MY_CONFIG[:max_signups] = 0

MY_CONFIG[:signup_text] = "" +
    "There are 3 steps to signing up for an account.<br\>\n" +
    "1. Complete this form. You will be sent an email.<br\>\n" +
    "2. Click on the link in the email to activate your account.<br\>\n" +
    "3. Login using your email address and password.<br\>\n"
    "<br\>\n" +
    "We will be sent an email and then will give you an Editor role.\n"

# Ruby on Rails camp
#MY_CONFIG[:signup_text] = "The fee for the camp is $25 <a href=\"/Fee+Explanation\">(Fee explanation)</a>. " +
#    "There are 4 steps to signing up:<br\><br\>\n" +
#    "1. Complete this form. You will be sent an email.<br\>\n" +
#    "2. Click on the link in the email to activate your account.<br\>\n" +
#    "3. Login using your email address and password.<br\>\n" +
#    "4. On the welcome page click on the PayPal payment button.<br\>\n" +
#    "<br\>\n" +
#    "Once we get payment confirmation, you will receive an Editor role on this wiki so you can update your profile and add session ideas.\n"
MY_CONFIG[:signup_closed_text] = "<b>Signups are now closed!</b> However, you can complete this form to be added to the waiting list. " +
    "There are 2 steps to get on the waiting list:<br\><br\>\n" +
    "1. Complete this form. You will be sent an email.<br\>\n" +
    "2. Click on the link in the email to activate your account.<br\>\n" +
    "<br\>\n" +
    "You will be notified if space becomes available.\n"
MY_CONFIG[:signup_ask_company] = true 
MY_CONFIG[:signup_email_note] = ''
MY_CONFIG[:user_list_columns] = [
{:name => 'email', :caption => 'Email'},
{:name => 'role', :caption => 'Role'}, 
{:name => 'wait_list_pos', :caption => 'Wait List'}, 
{:name => 'paid', :caption => 'Paid?'}, 
{:name => 'company', :caption => 'Company'}, 
]
