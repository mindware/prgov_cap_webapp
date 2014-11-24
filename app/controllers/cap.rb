require PADRINO_ROOT + "/app/models/email"
require PADRINO_ROOT + "/app/helpers/validations"

PRgovCAPWebApp::App.controllers :cap do

  include PRgov::Validations

  # Our before filter makes sure we
  # perform certain checks before the action is
  # evaluated. We can exclude specific actions from
  # the check.
  before :except => :index do
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

  # get :index, :map => '/foo/bar' do
  #   session[:foo] = 'bar'
  #   render 'index'
  # end

  # get :sample, :map => '/sample/url', :provides => [:any, :js] do
  #   case content_type
  #     when :js then ...
  #     else ...
  # end

  # get :foo, :with => :id do
  #   'Maps to url '/foo/#{params[:id]}''
  # end

  # get '/example' do
  #   'Hello world!'
  # end

  get :index, :map => '/' do
    # Alawys clear any sessions if the user goes to the
    # disclaimer:
    session.clear
    render 'disclaimer', :layout => :prgov
  end

  # If someone attempts to visit this resource directly (via GET),
  # they will get redirected to the disclaimer. This action is
  # supposed to be accessed through POST, hence the redirect.
  get :validate_email, :map => '/validate_email' do
    redirect to('/email')
  end

  # Let's use a GET. Users will be able to visit this form
  # only after receiving an email with a confirmation link
  # with the URL to this form.
  get :certificate, :map => '/certificate', :with => :id do
    # TODO: Recaptcha & session validation
    render 'form', :layout => :prgov
  end

  # # POST: email
  # # This method allows users to fill out a form for the
  # # email they wish to receive the certificate in.
  # # Note: Users will be able to access this resource via a POST.
  # # The recaptcha is validated here and proper sessions are created
  # # and checked for.
  # post :email, :map => '/email' do
  #   # If the user is missing a specific session value,
  #   # he hasn't successfully completed the captcha in the past.
  #   if session["captcha"].to_s.length == 0
  #     # Let's see if he filled it out properly right now.
  #     # If the user hasn't passed the captcha, take him back to it
  #     # and show a proper error.
  #     if !recaptcha_valid?
  #       redirect to ('/?captcha=false#error')
  #     # The user properly passed the captcha.
  #     else
  #       # Create a session marking him as human.
  #       session["captcha"] = true
  #       "You've got a session: #{session["captcha"]}"
  #     end
  #   # For users that arrive to this page, and already
  #   # had passed captcha recently, let them through.
  #   # This is mainly useful for users that reload the page (ie mobile users)
  #   else
  #     "You've already filled it out. #{session["captcha"]}"
  #   end
  #   # render 'form', :layout => :prgov
  # end

  # This method allows users to fill out a form for the
  # email they wish to receive the certificate in.
  get :email, :map => '/email' do
    render 'email', :layout => :prgov
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
    # If the email already exists in our db:
    if !email.nil?
        if email.confirmed?
          # redirect to form
          redirect to '/form'
        # Email not yet confirmed but is awaiting confirmation:
        else
          # if a long time has transcured since the email was sent
          # make sure we send a new email
          if(email.should_resend?)
            # update the ip
            email.IP = request.ip
            email.enqueue
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
        email.enqueue
        render 'email_sent', :layout => :prgov, :locals => { :time =>  email.max_minutes }
    end
  end

  # Do we need this as a post?
  # post :certificate, :map => '/certificate' do
  #   # TODO: Recaptcha & session validation
  #   render 'form', :layout => :prgov
  # end

  post :validate, :map => '/validation' do
    # TODO: Recaptcha & session validation
  end

  # # Provide form for email delivery validation
  # post :delivery_form, :map => '/register' do
  #   # TODO: Recaptcha & session validation
  #   render 'delivery', :layout => :prgov
  # end
  #
  # # Provide confirmation of when an email has been sent.
  # post :delivery_sent, :map => '/delivered' do
  #   # TODO: Recaptcha & session validation
  #   render 'delivered', :layout => :prgov
  # end
  #
  # post :delivery_confirmed, :map => '/confirm' do
  #  # No captcha required.
  # end

  # private

  # Everything from here on down is private. Don't
  # add any public actions below this line or they
  # or won't available.

end
