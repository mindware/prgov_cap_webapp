require PADRINO_ROOT + "/app/models/email"
require PADRINO_ROOT + "/app/helpers/validations"

# This app component was designed and developed by
# Andés Colón and Alberto Colón.
PRgovCAPWebApp::App.controllers :cap do

  # CAP Web App:
  # ------------
  # On Data:
  # Our application has two types of user data.
  #
  # The Session:
  # The session is a temporary database backed storage that
  # is volatile and expires quickly. It contains data
  # such as the form data the the user enters, and helps
  # automagically fill form data for the user when they
  # make a mistake and the like. It is saved on the backend.
  #
  # Improvement tip:
  # Ideally, the session data should be moved to
  # local storage on the client-side in the future.
  #
  # The Profile objects:
  # The profiles are longer-term database backed
  # stored data, that represents information that we
  # should store and is more long term for a user than a
  # session. This includes information that is created
  # after a user has completed some milestone.
  # An example of a milestone is that a user has
  # passed the first stage, and is awaiting some email
  # from PR.gov. Essentially profile objects are data
  # which must outlive a session.
  # If a user completes the first stage, where by
  # his email is confirmed, he has achieved a milestone
  # and we now store that email profile with its confirmation
  # link, awaiting for the GMQ to send the email user to
  # and for the user to come back and confirm us the codes,
  # there by confirming their email. Profile objects expire
  # as well, and they're not permanent objects, but their
  # life expecancy is much longer than a session.
  # Profile objects are stored on the backend.
  #
  # Stages:
  #
  # Our applications consists of two stages at this point:
  #
  # First Stage: the user accepts terms, and provides email
  #              and awaits email confirmation link.
  # Second Stage: the user has confirmed email, and proceeds
  #               to fill the form, and awaits the certificate
  #               request response.
  #
  # First Stage:
  # In the first stage, we provide a session, where we track
  # that the user has accepted the terms and conditions
  # and validates email information. We use
  # a before_filter, to validate that state is correct.
  #
  # Transition:
  #
  # There are possible transitions from First stage to
  # Second Stage.
  #
  # For users that do not have a confirmed profile (have not
  # recently confirmed their email), they will go through
  # Email Confirmation Transition. For profiles that have
  # already confirmed their email, they will go directly
  # to the Second Stage.
  #
  # Email Confirmation Transition:
  # As we transition from the first stage to the second stage
  # we cannot guarantee that the user is using the same browser
  # and the same session. This ocurrs when we send the email
  # and the user at some unspecified time in the future
  # before his link expires, visits our confirmation page.
  # The user may have filled out the form in one browser,
  # or computer, and eventually click on the link on some
  # other browser or computer. This is important to take note.
  # This may happen because:
  # - The user used one browser and when he clicked
  #   the email, he opened it in another default browser.
  #   Such as when he uses a mail client that opens links using
  #   default browser.
  # - PR.gov took too long to send the email. Days passed
  #   and the 'session' expired, but the profile lives on.
  #
  # By using profiles, we guarantee that session information
  # can be safely discarded. When the user arrives, and
  # he has a valid profile, we can safely accept that
  # he has completed the previous steps, as we have put the
  # guarantees in place to prohibit a user to create a
  # profile without going through the necessary steps.
  #
  # Second Stage:
  # The user has already confirmed their email and
  # has a profile. User fills out the various forms, and is ready
  # to preform his request. He completes the second stage
  # by reviewing and submitting the certificate request forms.
  #
  # Complete:
  # Once the request is being processed by the Governement
  # Messaging Queue and SIJC's RCI, our app has completed
  # its job. The system will message the user with
  # the result of their request. The system will retain
  # the profile until it expires.
  #
  # In the future we may add a third stage, by which
  # the user proceeds to a payment processor, before
  # completing. ACP.

  include PRgov::Validations

  ############################
  #         Filters          #
  ############################

  # Global 'before' check, applies to all resources.
  # Here we check and set a language cookie. Our cookie is
  # completely seperate to our 'sessions' (which are only stored
  # on the server side). These cookies survives
  # 'session.clear'. We only allow specific pre-approved
  # language values in the cookie [en, es]
  before do
      # If the user has his cookie locale set to english
      # apply it for this request.
      if (request.cookies['locale'] == "en")
          I18n.locale = :en
      elsif(request.cookies['locale'] == "es")
          I18n.locale = :es
      else
          # if the user is missing the cookie,
          # give him a spanish cookie.
          request.cookies['locale'] = "es"
          # apply the local language
          I18n.locale = :es
      end
  end

  # Our before filter makes sure we
  # perform certain checks before the action is
  # evaluated. We can exclude specific actions from
  # the check.
  before :except => [:index,
                     :info, :disclaimer, :confirm, :form, :form2,
                     :form2_get, :validate_request, :done] do
    # check if terms have been accepted
    validate_terms()
    # Captcha accepted. Check email.
    # Email accepted. Check validated email database.
    # Email not validated? Send email.
    # Email validated? Show form.
  end

  before :email_sent do
    # Before sending email,
    # Check captcha and email were provided.
    validation_complete?
  end

  # For all resources that are accessible once the email
  # has been confirmed, we need to check for email validation:
  before :form, :form2, :form2_get, :form2_validation,
         :validate_request, :done do
    # Before proceeding to any page in the second stage form,
    # confirm that the user has completed the first stage by
    # confirming their email. This checks if the email
    # session is active.
    email_confirmed?
  end

  # Before proceeding to form2 (via POST), validate form 1.
  before :form2 do
    # Before showing the second form,
    # check the data from the first one to make sure
    # it is correct
    validate_form1
  end

  # used for error handling for form2 GET access.
  before :form2_get do
    # If our session is marked as form2 ready, redirect us to form1.
    if session["form1_complete"] != true
      # make them fill out form1 before attempting form2.
      redirect to ("/form")
    end
  end

  # Before proceeding to complete, validate form 2.
  before :validate_request do
    # Validate the final form before completing the
    # online service
    validate_form2
  end

  # Check if the user has been marked as completing the
  # submission process, only then do they arrive to done.
  # If a user no longer has a session or their session isn't marked as
  # done, or it tries to skip a process in order to jump to the end,
  # they'll get caught, and redirected to the beginning, where
  # their session is destroyed and they will have to start
  # again as a security measure. This also catches users that hit the
  # back button after completing a submission, and attempt to request
  # once again.
  before :done do
     if !done?
       redirect to ('/?expired=true')
     end
  end


  ############################
  #         Resources        #
  ############################

  # We can use this to provide information prior to
  # the disclaimer. This should not be mapped to '/', ever.
  # This could be the main page where we redirect
  # users when we want to show them promotional
  # information or guide about this online service.
  # This cannot be root, as root is used for when
  # the First Stage has started, and it contains
  # error and session handling mechanisms.
  get :index, :map => '/cap' do
    # destroy any existing session.
    session.clear
    # once the main page is done,
    # render this:
    # render 'info', :layout => :prgov
    # Until the page is done, render
    # disclaimer:
    render 'disclaimer', :layout => :prgov
  end

  # This link is left here only as a
  # legacy link referenced to the designers.
  # once the main page is up, we can remove
  # this page.
  get :info, :map => '/info' do
    # destroy any existing session.
    session.clear
    render 'info', :layout => :prgov
  end

  # Begginging for First Stage:
  # This resource provides the terms and conditions
  # and initiates the session for the user.
  # Only: disclaimer should be mapped to '/'
  # because it has all the proper error handling at this
  # time, and other resources will redirect to '/'
  # when errors ocurr.
  get :disclaimer, :map => '/' do
    # This next line is very important. We *must*
    # always clear any sessions if the user goes to the
    # root '/', as the system redirects here upon
    # various errors that requires the session be
    # fully destroyed. Don't modify the next line
    # unless you're fully aware of what you're doing,
    # have taken every absolute precaution and your
    # name is Andrés. Thanks.
    session.clear
    render 'disclaimer', :layout => :prgov
  end

  # This method allows users to fill out a form for the
  # email they wish to receive the certificate in.
  post :email, :map => '/email' do
    render 'email', :layout => :prgov
  end

  post :validate_email, :map => '/validate_email' do
    # Variable that will hold errors.
    errors = ""

    # if first email is not a valid email
    if(params[:email].to_s.length == 0 or
       !validate_email(params[:email]))
      errors += "email=false"
    end

    # if confirm email is empty or not the same as first email
    if((params[:confirm].to_s.length == 0) or
       (params[:confirm].to_s.strip != params[:email].to_s.strip) or
       !validate_email(params[:confirm]))
      errors += "&confirm=false"
    end
    # use our helper method, that validates and sets
    # proper session values
    if(!validate_captcha())
      errors += "&captcha=false"
    end

    # Clean up any rogue html in the data.
    params[:email]   = escape_html(params[:email])
    params[:confirm] = escape_html(params[:confirm])

    # now that we're done with the checks:
    # Store the form data, so that we can show it later
    # if the user needs to review errors or proceed forward.
    session["email"]   = params[:email]
    session["confirm"] = params[:confirm]

    # If we have any errors, redirect
    if(errors.length > 0)
      redirect to ("/email?errors=true&#{errors}")
    end
    # If no errors, we proceed to check if
    # this email has already been validated.

    # if valiadted
      # redirect to form
    # else:
      redirect to 'email_sent'
  end

  get :email_sent, :map => '/email_sent' do
    # Find if the email already confirmed/registered
    email = Email.find(session["email"].to_s)
    # save rack's base url of this server:
    base_url = request.base_url
    # If the email already exists in our db:
    if !email.nil?
        if email.confirmed?
          # redirect to form
          session["email_confirmed"] = true
          # for security purposes, store the email address
          # in a variable that is modified only in this
          # specific section where the email is confirmed
          # and in the :confirm resource. Then identify
          # any disparities in email vs locked_address
          # using a before_filter called email_confirmed?.
          # This will help detect attacks where a
          # a malicious user exploits our ability to
          # process concurrent requests across
          # instances to attempt to modify the session
          # in order to use a confirmed address to
          # send emails to an unconfirmed address.
          # Stop them in their tracks here.
          session["locked_address"] = email.address
          redirect to '/form'
        # Email not yet confirmed but is awaiting confirmation:
        else
          # if a long time has transcured since the email was sent
          # make sure we send a new email
          if(email.should_resend?)
            # update the ip
            email.IP = request.ip
            email.enqueue_confirmation_email(base_url)
            # enqueue and save
            render 'email_sent', :layout => :prgov,
                                 :locals => { :time =>  email.max_minutes }
          else
            render 'email_already_sent', :layout => :prgov,
                                         :locals => { :time => email.max_minutes,
                                                      :count => email.countdown_in_minutes }
          end
        end
    # Otherwise this new email should be saved and confirmed:
    else
        values = {
                    "address" => session["email"],
                    "IP"      => request.ip
        }
        email = Email.create(values)
        # Enqueue the email. If anything fails here
        # our global error handler will catch it.
        # This saves our email to the db as well.
        email.enqueue_confirmation_email(base_url)
        render 'email_sent', :layout => :prgov, :locals => { :time =>  email.max_minutes }
    end
  end

  # We will be validating the code and email in this
  # resource. Before this resource executes, this controller
  # validates the current session.
  #
  # Once we're in this step (of confirming), we
  # start the session a new. This way, if the user
  # opened the form in a non-default browser, but then clicked
  # and opened the email confirmation link in their default
  # browser, they can still work through as we're
  # validating the code and the email.
  #
  # We make sure to delete all session data at this
  # point, so that a malicious user attempting to use
  # this confirmation page for one email that
  # simultaneously alters the session using a form
  # is unable to trick the system, and always
  # gets stuck to the confirmation data.
  # At this point, we don't care about session data
  # confirming the users clicked on the disclaimer,
  # as they could only have gotten to this point
  # by accepting it previously in order to get
  # the confirmation code.
  get :confirm, :map => '/confirm' do
    # Clear the session. Everything else will be
    # built from here using the Profile.
    session.clear
      # if address and code were provided:
      if (params["address"].to_s.length > 0 and
          params["code"].to_s.length > 0)
          # try to unpack the base64
          email = Email.decode(params["address"])

          # If the user sent us a base64 encoded proper email
          if(validate_email(email))
              # attempt to find the email
              email = Email.find(email)
              # if the email is found
              if(!email.nil?)
                  if(email.confirmation_code == params["code"])
                      # update email model's data in the storage.
                      # so that when the email is entered again
                      # we know it has already been confirmed
                      # and skip the validation step
                      email.confirmed = true
                      email.save

                      # Now for the current session:
                      # set the current session data to
                      # email_confirmed, which will be validated
                      # by the form resource.
                      session["email_confirmed"] = true

                      # Immediately lock the email address
                      # this will help us deter a specific
                      # kind of session attack. This assignment
                      # must only ocurr in this resource and
                      # in the email_sent action where we
                      # allow confirmed email addresses
                      # to pass through to the form.
                      # Nowhere else should this occurr in order
                      # to protect the system. Got it? Great.
                      # By only setting this variable in very
                      # precise locations, we can later easily
                      # compare it against the more unreliable
                      # session["email"] information, which
                      # is modified in multiple stages.
                      session["locked_address"] = email.address
                      # Also add/udpate the email session
                      # it may ocurr that a user goes through
                      # the entire process of requesting an
                      # email confirmation, but some time later
                      # clicks the link on an entirely new browser,
                      # such as a default browser or an entirely new
                      # computer. We consider email confirmation
                      # and actually filling the form as two
                      # seperate events. We make sure to
                      # set up the email address here, which will
                      # be used for validation against the
                      # locked address.
                      session["email"]  = email.address

                      session["ssn"] = ""
                      session["passport"] = ""
                      session["dtop_id"] = ""
                      # Give a brief explanation that the email
                      # has been validated, and provide a link
                      # to the form so the user can get started.
                      render 'confirm', :layout => :prgov,
                             :locals => { :expired => false,
                                          :email => email.address }
                  else
                      # Email found but code does not match
                      # the current confirmation code. User may have
                      # clicked on an expired link.
                      # Redirect user to the terms and conditions.
                      redirect to ('/?expired=true')
                  end
              else
                # The email address was not found in the database.
                # The record may have expired. Ther user must
                # start the process from scratch.
                redirect to ('/?expired=true')
              end
          else
            # When the email is invalid, redirect
            # the user to the terms and conditions.
            redirect to ('/?expired=true')
          end
      else
          # When no parameters are provided,
          # redirect user to the terms and conditions.
          redirect to ('/?expired=true')
      end
  end

  get :form, :map => '/form' do
    form = "license"
    # On errors, we get the selected form through
    # the URL.
    if(params[:form].to_s.length > 0)
       form = params[:form]
    # If not provided via URL,
    # use data from the session, if it has
    # any data.
    elsif(session[:form].to_s.length > 0)
        form = params[:form]
    end
    render 'form_step1', :layout => :prgov,
            :locals => { :form => form }
  end

  post :form2, :map => '/form2' do
    session["form1_complete"] = true
    render 'form_step2', :layout => :prgov
  end

  post :validate_request, :map => '/complete' do
    # Our before method must validate all params before
    # arriving here.

    # If a passport is used for identity validation,
    # we will not require the license number nor ssn.
    if(session[:passport].to_s.length > 0)
      payload = {
      		:first_name => session[:name].to_s.strip,
          :middle_name => session[:name_initial].to_s.strip,
      		:last_name  => session[:last_name].to_s.strip,
      		:mother_last_name => session[:mother_last_name].to_s.strip,
      		:passport	=> session[:passport].to_s.strip,
      		:birth_date => session[:birthdate].to_s.strip,
      		:residency  => "#{session[:residency_city_state]}, "+
                         "#{session[:residency_country]}".strip,
      		:IP   	    => request.ip.to_s.strip,
      		:reason	    => session[:purpose].to_s.strip,
      		:birth_place=> "not specified",
      		:email	    => session[:email].to_s.strip,
      		:language   => (I18n.locale == :en ? "english" : "spanish")
  	 }
   end
   # always favor the ssn, if available
   if(session[:ssn].to_s.length > 0)
      payload = {
      		:first_name => session[:name].to_s.strip,
          :middle_name => session[:name_initial].to_s.strip,
      		:last_name  => session[:last_name].to_s.strip,
      		:mother_last_name => session[:mother_last_name].to_s.strip,
      		:ssn	=> session[:ssn].to_s.strip,
      		:license_number => session[:dtop_id].to_s.strip,
      		:birth_date => session[:birthdate].to_s.strip,
      		:residency  => "#{session[:residence]}".strip,
      		:IP   	    => request.ip.to_s.strip,
      		:reason	    => session[:purpose].to_s.strip,
      		:birth_place=> "not specified",
      		:email	    => session[:email].to_s.strip,
      		:language   => (I18n.locale == :en ? "english" : "spanish")
  	 }
   end

   result = GMQ.enqueue_cap_transaction(payload)

   # guessing the code allows one to evade the captcha.
   # here we make this absolutely not worth the computing
   # resources, since on every finished request we
   # make the old email link obsolete. Email link is
   # generated once only and validated. But since the
   # link must be expired, a value is added to it
   # just so that it is never guessable but at the same
   # time usable until the first full certificate
   # submission. Afterwards, it becomes unusable.
   # we could later improve this by having a
   # unique email flag that is added to the email if it
   # is missing after the first succsesful completion,
   # therefore saving us a db write. For now, this works.
   email = Email.find(session["email"])
   # generate a new code.
   email.confirmation_code = Email.generate_code
   email.save
   email = nil

  #  if(result["error"])
  #  else
   session[:tx_id] = result["id"]

   # mark the transaction as done, for validation
   session[:done] = true

   redirect to('done')

    # "#{params.keys.join("<br>")}"
    # render 'complete', :layout => :prgov
    # render 'review', :layout => :prgov
    # perform server side validation of form data.
    # if form data correct,
      # post certificate
      # once certificate is succesfully posted
      # expire the confirmation link and destroy the
      # session, in order to disable cliking back and
      # retrieving history.
      #
      # If a user wants a new certificate, force them to
      # accept terms and conditions again. This is because
      # this system is also used in job fairs, and many
      # people end up using the system one after another using
      # the same browser. By expiring the session, we
      # make sure each user accepts the terms and conditions
      # and uses their own email. If their email is confirmed
      # they won't need
  end

  # Present the final page.
  get :done, :map => '/done' do
       tx_id = session[:tx_id]
       email = session[:email]
       # user is done. delete the session immediately.
       # by destroying the session, we do not let them hit
       # the back button to resubmit again.
       session.clear
       # Now proceed to show them the results:
       render 'complete', :layout => :prgov,
                          :locals => { :id    => tx_id,
                                       :email => email }
  end

  ###########################
  #  Aliases & Redirections #
  ###########################

  # Alias get resource for the post version of validate_email, used
  # here to properly handle users navigation.
  # If someone attempts to visit this resource directly (via GET),
  # they will get redirected to the disclaimer. The original action is
  # supposed to be accessed through POST, hence the redirect.
  get :validate_email, :map => '/validate_email' do
    redirect to('/email')
  end

  # Alias resource for when users use the history.
  # This is just a copy of the 'post' version of this
  # resource.
  get :email, :map => '/email' do
    render 'email', :layout => :prgov
  end

  # If someone attempts to load the form2 using a
  # GET, we simply redirect them to the first
  # form which allows GET requests.
  #
  # We give it a different from post action, as this
  # is simply a redirect that doesn't require before
  # validations directly. The before validations are
  # done on the redirected page.
  # get :form2_redirect, :map => '/form2' do
  #   redirect to('/form')
  # end

  # used when someone needs to redirect to us
  get :form2_get, :map => '/form2' do
    render 'form_step2', :layout => :prgov
  end

  # private

  # Everything from here on down is private. Don't
  # add any public actions below this line or they
  # or won't available.

end
