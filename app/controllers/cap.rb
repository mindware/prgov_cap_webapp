require PADRINO_ROOT + "/app/models/email"
require PADRINO_ROOT + "/app/helpers/validations"

PRgovCAPWebApp::App.controllers :cap do

  include PRgov::Validations

  ############################
  #         Filters          #
  ############################

  # Our before filter makes sure we
  # perform certain checks before the action is
  # evaluated. We can exclude specific actions from
  # the check.
  before :except => [:index, :disclaimer, :form, :confirm] do
    validate_terms()
    # Terms accepted. Check Captcha flag.
    # Captcha flag missing? Check captcha input.
    # Captcha accepted. Check email.
    # Email accepted. Check validated email database.
    # Email not validated? Send email.
    # Email validated? Show form.
  end

  before :email_sent do
    validation_complete?
  end

  # For all resources that are accessible once the email
  # has been confirmed, we check for email validation:
  before :form do
    email_confirmed?
  end

  ############################
  #         Resources        #
  ############################

  # RESOURCE AVAILABLE:
  # !!!!!!!!!!!!!!!!
  # TODO: Code this!
  # An unused resource. We can use this to provide
  # information prior to the disclaimer. This should
  # not be mapped to '/'.
  #
  get :index, :map => '/info' do
    render 'info', :layout => :prgov
  end

  # This resource provides the terms and conditions
  # and initiates the session for the user.
  # Only: disclaimer should be mapped to '/'
  # because it has all the proper error handling at this
  # time, and other resources will redirect to '/'
  # when errors ocurr.
  get :disclaimer, :map => '/' do
    # Alawys clear any sessions if the user goes to the
    # disclaimer:
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
       validate_email(params[:email])) # true if error, false if ok
      errors += "email=false"
    end

    # if confirm email is empty or not the same as first email
    if((params[:confirm].to_s.length == 0) or
       (params[:confirm].to_s.strip != params[:email].to_s.strip))
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
  get :confirm, :map => '/confirm' do
      # if address and code were provided:
      if (params["address"].to_s.length > 0 and
          params["code"].to_s.length > 0)
          # try to unpack the base64
          email = Email.decode(params["address"])

          # If the user sent us a base64 encoded proper email
          if(!validate_email(email))
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

  post :form, :map => '/form' do
    form = "dtop"
    if(params[:form].to_s.length == 0 and
       params[:form].to_s.length < 10)
       form = params[:form]
    end
    render 'form_step1', :layout => :prgov,
            :locals => { :form => form }
  end

  post :form2, :map => '/form2' do
    render 'form_step2', :layout => :prgov
  end

  post :form_validate, :map => '/form_validation' do
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

  get :form, :map => '/form' do
    render 'form_step1', :layout => :prgov
  end

  get :form_second, :map => '/form' do
    render 'form_step2', :layout => :prgov
  end

  get :form2, :map => '/form2' do
    render 'form_step2', :layout => :prgov
  end



  # private

  # Everything from here on down is private. Don't
  # add any public actions below this line or they
  # or won't available.

end
