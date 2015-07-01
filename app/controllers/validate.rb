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

    ##################################
    # Incoming payload from QR code: #
    ##################################
    # certid is how the value arrives from the QR code scan.
    if(params["certid"].to_s =~ /^[0-9a-zA-Z]*$/ and
      (params["certid"].to_s.length > 6 and params["certid"].to_s.length <= 36))
      cert_id = params["certid"]
    end
    # add a case for our secondary type of UUID type-4 added by LoS for
    # request manually created by supervisors at PRPD. This was added later,
    # and was not according to spec. But we need to be able to validate
    # everything, so it was added.
    if(params["certid"] =~ /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-4[0-9A-Fa-f]{3}-[89ABab][0-9A-Fa-f]{3}-[0-9A-Fa-f]{12}$/)
      cert_id = params["certid"]
    end

    #################################
    # Incoming payload from app     #
    #################################
    # cert_id is how we use it on the rest of the app
    if(params["cert_id"].to_s =~ /^[0-9a-zA-Z]*$/ and
      (params["cert_id"].to_s.length > 6 and params["cert_id"].to_s.length <= 36))
      cert_id = params["cert_id"]
    end
    # add a case for our secondary type of UUID type-4 added by LoS for
    # request manually created by supervisors at PRPD. This was added later,
    # and was not according to spec. But we need to be able to validate
    # everything, so it was added.
    if(params["cert_id"] =~ /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-4[0-9A-Fa-f]{3}-[89ABab][0-9A-Fa-f]{3}-[0-9A-Fa-f]{12}$/)
      cert_id = params["cert_id"]
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
    # reset the percentage
    session["percent"] = nil
    # clean up any spaces
    params["cert_id"]   = params["cert_id"].to_s.strip
    params["person_id"] = params["person_id"].to_s.strip

    # default value for flags to detect if we found a passport
    # or ssn.
    ssn = false
    passport = false

    # Add errors if required values are empty
    error = ""
    error << "&cid=false" if(params["cert_id"].length == 0)
    error << "&person_id=false" if(params["person_id"].length == 0)
    error << "&captcha=false" if(!recaptcha_valid?)

    # Now lets validate the cert_id structure.
    # We can expect:
    # PR.gov: PRCAP<numbers>
    # RCI ventanilla: <numbers>  (starts with numeric id 1)
    # RCI PRPD supervisor: <UUID> (type-4 UUID)
    #
    # So, in order to allow for the new type of UUID, we are including
    # a secondary validation for the UUID type-4.
    # catch:
    # if it exceeds our expected length
    # if it doesn't conform to our expected standards
    if(params["cert_id"].length < 7 or params["cert_id"].length > 36)
        # puts "invalid length"
        error << "&cid=false"
    end


    # flag to determine if a cap id has error has ocurred, in which
    # the current cert_id has been found to not be a proper id.
    cert_id_error = false

    # If this cert id matches a proper CAP tx_id
    # that consists of: PRCAP<numbers> (prgov) or 1<numbers> (rci)
    # then we should enforce upper casing, since RCI API is not currently
    # able to perform case insensitive searches, which makes it difficult
    # for our users. Here we make sure we treat these matching IDs as
    # uppercase
    if ((params["cert_id"] =~ /^[0-9a-zA-Z]*$/).nil?)
      cert_id_error = true
    else
      # capitalize these matching IDs as they're expected in uppercase.
      params["cert_id"] = params["cert_id"].upcase

      # just in case, check if its a PRCAP tx_id, and detect
      # any errors in length
      if(params["cert_id"].include? "PRCAP" and params["cert_id"].length != 24)
        cert_id_error = true
      else
        # otherwise, this is either a PRCAP or RCI transaction that is properly
        # entered, mark the flag properly as there are no errors.
        cert_id_error = false
      end
    end


    # If this cert id matches a proper CAP tx_id
    # that consists of: UUID type-4
    # then we should enforce LOWER case, since RCI API is not currently
    # able to perform case insensitive searches, which makes it difficult
    # for our users. Here we make sure we treat these matching IDs as
    # lowercase, per the UUID type-4 standard.
    if ((params["cert_id"] =~ /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-4[0-9A-Fa-f]{3}-[89ABab][0-9A-Fa-f]{3}-[0-9A-Fa-f]{12}$/).nil?)
      # improper format, did not match the regexp
      # so mark this as an error, only if a previous cert_id has not been
      # found.
      cert_id_error = true if cert_id_error
    else
      # proper format, search matched the regexp
      cert_id_error = false
      params["cert_id"] = params["cert_id"].downcase
    end

    # Now add the proper error if cert_id_error is still true
    error << "&cid=false" if(cert_id_error)

    # make sure people aren't entering any combination of 0s as their license/
    # person id (ie, 000, 000000, etc.) - which has been a common attempt.
    if(params["person_id"].gsub("0", "").length == 0)
        error << "&person_id=false"
    end


    # now check the person_id to see if it's a valid ssn or passport
    # if numeric only and SSN(4) and max passport length (9)
    if(params["person_id"] =~ /^[0-9]*$/ and params["person_id"].length == 4)
        ssn = true
    # if it is a passport (length 9)
    # should we have flexibility for passports?
    # Online standards suggest a length of 9 at this time.
    elsif(params["person_id"] =~ /^[0-9a-zA-Z]*$/ and
          params["person_id"].length == 9)
          # params["person_id"].length >= 6 and
          # params["person_id"].length <= 20)
          passport = true
    else
      error << "&person_id=false"
    end

    if(error.length > 0)
       redirect to ("/validar/cap?errors=true#{error}&cert_id=#{params['cert_id']}")
    else
       # Set up the payload. Append
       # the data that we'll send to GMQ.

       # here we make sure to make the tx_id capitalized (upcase),
       # as all our CAP tx_ids require a capitalized tx_id, ie: PRCAP not prcap.
       # So let's fix it for the user for this specific transaction.
       payload = {
                    "tx_id" => params["cert_id"],
                    "IP" => request.ip
                 }
      if(ssn)
        payload["ssn"] = params["person_id"]
      end
      if(passport)
        payload["passport"] = params["person_id"]
      end

       begin
         result = GMQ.validate_cap_request(payload)
         redirect to ("/validar/cap/status?id=#{result['id']}")
       rescue GMQ_ERROR => e
         # this shouldn't happen unless something is wrong at the
         # GMQ. Usually it would mean that there's a difference between
         # our validation, and the GMQ's.
         redirect to ("/validar/cap?errors=true&gmq=true&type=#{e.class}&cert_id=#{params['cert_id']}")
       end
    end
  end

  get :status, :map => '/validar/cap/status' do
    # ideally we should make sure we only get here through the
    # check post page. We should set some flag here, but
    # have to take into consideration session flushing
    # from cap controller. update: since we incorporate
    # now captcha, if the captcha isnt valid, we won't make it
    # to this point.

    # Check if the ID isn't empty and check that it isn't
    # absurdly long.
    if(params["id"].to_s.length == 0 or params["id"].length >= 256)
      redirect to ("/validar/cap?errors=true&id=false")
    else
      begin
        # set the autorefresh value to off by default
        refresh = false
        # marks as completed
        completed = false
        # marks as a validation failure
        failed = false
        # the default percentage
        percent = 33
        # marks the remote system as experincing downtime
        downtime = false
        # perform the request to the gmq for certificate validation
        result = GMQ.validate_cap_response(params)

        # if the result has a proper status
        if result.has_key? "status"
          # if it matches any of these, we've completed
          if result["status"] == "completed" or
             result["status"] == "done"

             # Now do our internal comparison of the data the user submitted
             # vs that returned by RCI.
             if result.has_key? "result"
               if(result["result"].has_key? "ids")
                 # loop through each of the ids
                  result["result"]["ids"].each do |id|
                    puts "Looping through #{id}"
                    if(id.has_key? "ssn" or id.has_key? "passport")
                       puts "NOW COMPARING SSN AND PASSPORT vs RESULT"
                       puts "#{id["ssn"].to_s[-4..-1]} == #{result["ssn"].to_s[-4..-1]}"
                        # if the requested ssn and the result ssn match, then we
                        # have a proper match
                        if(result["ssn"].to_s.length > 0)
                          if(id["ssn"].to_s[-4..-1] == result["ssn"].to_s[-4..-1])
                               # stop refreshing
                               refresh = false
                               # mark us as done
                               completed = true
                               failed = false
                               percent = 100
                          end
                        end
                        # else if the user supplied a passport and it
                        # matches
                        if(result["passport"].to_s.length > 0)
                          if(id["passport"].to_s == result["passport"].to_s)
                               # stop refreshing
                               refresh = false
                               # mark us as done
                               completed = true
                               failed = false
                               percent = 100
                          end
                        end
                    end # end of checking ssn or passport keys
                  end # end of ids loop
               end # end of checking of ids
             end # end of checking for results
              # The certificate was found, but
              # we will mark this attempt as failed,
              # since we found an information mismatch between
              # user's input and cert input.
              if(!completed)
                puts "Cert found but information mismatch in certificate validation. Failing."
                failed = true
                completed = true
                refresh = false
                percent = 100
              end
          elsif (result["status"] == "failed")
              failed = true
              completed = false
              refresh = false
              percent = 100
          else
            # if retrying or waiting
            # check how many errors have ocurred
            # if more than x error counts
            # this number is based on the amount of retries
            # of the capvalidationworker of the GMQ's
            # exponential backoff strategy.
            # if (result["error_count"].to_i >= 19)
            if (result["error_count"].to_i >= 1)
              percent = 100
              # do not continue refreshing if we've
              # encountered too many errors.
              refresh = false
              completed = false
              failed = false
              # mark this as a critical error
              downtime = true
            else
              if(session["percent"].nil?)
                  # if empty set to default value
                 session["percent"] = percent
              else
                 # only raise percantage if we're not 'waiting'
                 if(result["status"].to_s != "waiting")
                   session["percent"] = session["percent"] + rand(8)
                   # stick it to 99 if it went above 99.
                   session["percent"] = 99 if session["percent"] > 99
                end
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
                                                         :downtime => downtime,
                                                         :result => result}

      rescue GMQ_ERROR => e
        # if the request expired or an error ocurred
        # GMQ_ERROR could also mean other types of errors tho, like 500s
        # we could consider identifying if its a 400 or 500 error.
        # update: let's just let the app handle its own critical failures
        # such as 500 errors or uncatched exceptions with its already
        # built in defaulte error pages. Unless it was a GMQ_ERROR, in which
        # case we redirect here:

        # if there was a serious error in the GMQ backend, report it.
        if(e.message.to_s[0..2] == "500" or e.message.to_s[0..2] == "403")
          redirect to ("/validar/cap?errors=true&gmq=true&type=#{e.class}")
        else
        # just let the user know that request expired.
          redirect to ("/validar/cap?errors=true&expired=true&type=#{e.class}")
        end
        # any other error, simply fail.
      end
    end
  end
end
