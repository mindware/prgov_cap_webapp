require PADRINO_ROOT + "/app/models/email"
require PADRINO_ROOT + "/app/helpers/validations"

# This app component was designed and developed by
# Andés Colón
PRgovCAPWebApp::App.controllers :validate do

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

  # index provides general info about
  # the system.
  get :index, :map => '/validate/' do
    render 'index', :layout => :prgov
  end

  # the actual form to validate the
  # certificate of antecedentes penales
  get :validator_cap, :map => '/validar/cap' do
    # destroy any existing session.
    # session.clear
    # render 'validator_cap', :layout => :prgov
    # render 'index', :layout => :prgov
    cert_id = ""
    # TODO: update this to increase security
    if(params["certid"] =~ /^[0-9a-zA-Z]*$/ and
      (params["certid"].length > 6 and params["certid"].length < 36))
      cert_id = params["certid"]
    end
    render 'cap', :layout => :prgov, :locals => { :cert_id => cert_id }
  end

  # An internal alias
  # get :cap, :map => '/validate/cap' do
  #   render 'cap', :layout => :prgov
  # end

  # A page that provides optional certificate
  # validators.
  get :validator_option, :map => '/validadores' do
    # destroy any existing session.
    # session.clear
    render 'validator_option', :layout => :prgov
  end

  post :check, :map => '/validar/cap/check' do
    error = ""
    error << "&cid=false" if(params["cert_id"].to_s.length == 0)
    error << "&person_id=false" if(params["person_id"].to_s.length == 0)
    error << "&captcha=false" if(!recaptcha_valid?)

    if(error.length > 0)
       redirect to ("/validar/cap?errors=true#{error}")
    else
       # TODO: we should either receive passport or ssn, for now just hack
       # it to always be ssn.
       payload = {
                    "tx_id" => params["cert_id"],
                    "ssn"   => params["person_id"],
                    "passport" => params["passport"],
                    "IP" => request.ip
                 }
       # TODO: should we catch errors here?
       begin
         result = GMQ.validate_cap_request(payload)
         redirect to ("/validar/cap/status?id=#{result['id']}")
       rescue GMQ_ERROR => e
         redirect to ("/validar/cap?errors=true&gmq=false&type=#{e.class}")
       end
    end
  end

  get :status, :map => '/validar/cap/status' do
    # TODO
    # ideally we should make sure we only get here through the
    # check post page. We should set some flag here, but
    # have to take into consideration session flushing
    # from cap controller.

    # Check if the ID isn't empty and check that it isn't
    # absurdly long.
    if(params["id"].to_s.length == 0 or params["id"].length >= 256)
      redirect to ("/validar/cap?errors=true&id=false")
    else
      begin
        # set the autorefresh value to off by default
        refresh = false
        completed = false
        failed = false
        percent = 50
        # perform the request to the gmq for certificate validation
        result = GMQ.validate_cap_response(params)

        # if the result has a proper status
        if result.has_key? "status"
          # if it matches any of these, we've completed
          if result["status"] == "completed" or
             result["status"] == "done"
             # stop refreshing
             refresh = false
             # mark us as done
             completed = true
             failed = false
             percent = 100
          elsif (result["status"] == "failed")
              failed = true
              completed = false
              refresh = false
              percent = 100
          else
            # if retrying or waiting
            # check how many errors have ocurred
            # if more than x error counts
            if (result["error_count"].to_i > 5)
              percent = 100
              # do not continue refreshing if we've
              # encountered too many errors.
              refresh = false
              completed = false
              # mark us as failed
              failed = true
            else
              if(session["percent"].nil?)
                 session["percent"] = percent
              elsif session["percent"] >= 98
                 session["percent"] = 98
              else
                 # after 6 attempts should be 8
                 session["percent"] = session["percent"] + rand(8)
              end
              percent = session["percent"]
              # continue to refresh
              completed = false
              failed = false
              refresh = true
            end
          end
        end
        render 'status', :layout => :prgov, :locals => { :refresh => refresh,
                                                         :completed => completed,
                                                         :percent => percent,
                                                         :failed => failed,
                                                         :result => result}

      rescue GMQ_ERROR => e
        # if the request expired or an error ocurred
        # GMQ_ERROR could also mean other types of errors tho, like 500s
        # TODO catch special errors here too and handle them gracefully.
        # update: let's just let the app handle its own critical failures
        # such as 500 errors or uncatched exceptions with its already
        # built in defaulte rror pages. Unless it was a GMQ_ERROR, in which
        # case we redirect here:
        redirect to ("/validar/cap?errors=true&expired=true&type=#{e.class}")
        # any other error, simply fail.
      # rescue Exception => e
      #   # some system is experience failure
      #   # Todo proper logging
      #   redirect to ("/validar/cap?errors=true&downtime=true")
      end
    end
  end
end
