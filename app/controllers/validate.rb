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

  get :validator_cap, :map => '/validar/cap' do
    # destroy any existing session.
    # session.clear
    # render 'validator_cap', :layout => :prgov
    render 'index', :layout => :prgov
  end

  # provides specific validation information
  # for the cap certificates
  get :cap, :map => '/validate/cap' do
    render 'cap', :layout => :prgov
  end

  post :check, :map => '/validate/cap/check' do
    if(params["cert_id"].to_s.length == 0 or
       params["person_id"].to_s.length == 0 or
       !recaptcha_valid?)
       redirect to ("/validate/cap?errors=true&cert_id=error&person_id=error")
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
         redirect to ("/validate/cap/status?id=#{result['id']}")
       rescue GMQ_ERROR => e
         redirect to ("/validate/cap?errors=true&gmq=error&type=#{e}")
       end
    end
  end

  get :status, :map => '/validate/cap/status' do
    # TODO
    # ideally we should make sure we only get here through the
    # check post page. We should set some flag here, but
    # have to take into consideration session flushing
    # from cap controller.

    # Check if the ID isn't empty and check that it isn't
    # absurdly long.
    if(params["id"].to_s.length == 0 or params["id"].length >= 256)
      redirect to ("/validate/cap?errors=true&id=error")
    else
      begin
        # set the autorefresh value to off by default
        @refresh = false
        # perform the request to the gmq for certificate validation
        @result = GMQ.validate_cap_response(params)

        if @result.has_key? "status"
          if @result["status"] == "completed"
            @refresh = false
          else
            @refresh = true
          end
        end
        render 'status', :layout => :prgov # no refresh.

      rescue GMQ_ERROR => e
        # if the request expired or an error ocurred
        # GMQ_ERROR could alos mean other types of errors tho, like 500s
        # TODO catch special errors here too and handle them gracefully.
        redirect to ("/validate/cap?errors=true&request=expired&type=#{e}")
        # any other error, simply fail.
      end
    end
  end
end
