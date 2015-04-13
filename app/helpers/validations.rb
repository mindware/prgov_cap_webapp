# We use resolv to validate IPv4 & Ipv6 addresses. It is better
# than ipaddr (ipaddr uses socket lib to validate can trigger dns lookups)
require 'resolv'
require 'date'
require 'base64'                 # used to validate certificates
require 'time'

require PADRINO_ROOT + "/app/helpers/errors"

##########################################################
# The following are methods to be used by our controller #
##########################################################

# Validates the user has accepted the terms and conditions
def validate_terms
  if session["terms"].to_s.length == 0
    # If the user didn't accept the terms, take him back to it
    # and show a proper error.
    if params[:terms].to_s.length == 0 or params[:terms] == false
      redirect to ('/?terms=false')
    # The user properly accepted the terms.
    else
      # Create a session marking him as human.
      session["terms"] = true
    end
  end
end

# This method validates a captcha. This is used on the specific
# page where the user has to solve the captcha.
def validate_captcha
  if !recaptcha_valid?
    return false
  else
    # The user properly passed the captcha.
    # Create a session marking him as human.
    session["captcha"] = true
    return true
  end
end

# If the user is missing a specific session value,
# he hasn't successfully completed the steps to get to this point
# At this time these required steps are: accept the terms and captcha.
def validation_complete?
  # Validate the user accepted the terms
  if session["terms"].to_s.length == 0
      redirect to ('/?terms=false')
  # Validate the user solved the captcha
  elsif session["captcha"].to_s.length == 0
      redirect to ('/email?errors=true&captcha=false')
  elsif session["email"].to_s.length == 0
      redirect to ('/email?errors=true&email=false')
  end
end

# If the user is missing a specific session value,
# he hasn't successfully completed the steps to get to this point
# At this time these required steps are: have email confirmed in session
# AND very important, have email confirmed in db. We can't rely
# on the session alone.
def email_confirmed?
  # Validate if the user has the email confirmed in the
  # server side session. This is set by the controller.
  # after we've validated the email. If the user doesn't
  # have this session value, he can't complete this form.
  #
  # If the user attempts to share/bookmark this url, for example
  # and the incoming session is not found to be valid
  # then the user is redirected to the terms and conditions
  # and a notification that their link has expired is
  # shown.
  if session["email_confirmed"].to_s.length == 0 or
     session["email_confirmed"] == false or
     session["email"].to_s.length == 0 or
     session["locked_address"].to_s.length == 0
      redirect to ('/?expired=true')
  # If the email address and the locked address
  # do not match, we could have a user using
  # multiple tabs at the same time to process different
  # certificate requests. This could happen if a
  # shared computer is left open with a partially
  # uncompleted request that already has access to the
  # form, and another request that is processing an email
  # confirmation. Other than that, and on a more malicious
  # note, an attacker could be trying to exploit our
  # session system, to attempt to send email to an
  # unconfirmed address. We stop both potential situations
  # immediately here.
  elsif (session["locked_address"] != session["email"])
    redirect to ('/?email=false')
  end

end

# This controller method sanitizes input, validates the
# input from the the multiple forms available
# in form1, sets the data in session, and
# redirects if any errors ocurred.
def validate_form1
  errors = ""

  # First, clean up any malicious code.
  params[:form] = escape_html(params[:form])
  params[:dtop_id] = escape_html(params[:dtop_id])
  params[:ssn] = escape_html(params[:ssn])
  params[:passport] = escape_html(params[:passport])

  # Store the data so we can show it again in case of
  # errors, using the session.
  session[:form] = params[:form]
  session[:dtop_id] = params[:dtop_id]
  session[:ssn] = params[:ssn]
  session[:passport] = params[:passport]

  # perform server side validation of form1 data.
  # If the user selected to identify
  # using a dtop id or driver license:
  if(params[:form].to_s == "dtop" or params[:form].to_s == "license")
    if(params[:dtop_id].to_s.length == 0 or
      !validate_dtop_id(params[:dtop_id]))
        errors += "&license=false"
    end
    if(params[:ssn].to_s.length == 0 or
       !validate_ssn(params[:ssn]))
        errors += "&ssn=false"
    end
  # If the user selected to identify using
  # a passport:
  elsif(params[:form] == "passport")
    # if pass port number cannot be validated
    # later add password number validation
    # Normally passwords are 9 digits long, but
    # that could vary through countries. Let's
    # put a a limit on 20 for now.
    if(!validate_passport(params[:passport]))
       errors += "&passport=false"
    end
  # The user chose an unknown form type
  else
    errors += "&invalid_form=true"
  end

  # If any errors ocurred, do a redirect:
  redirect to ("/form?errors=true#{errors}&form=#{params[:form]}") if errors.length > 0
end

# This controller method sanitizes input, validates the
# input from the the form available
# in form2, sets the data in session, and
# redirects if any errors ocurred.
def validate_form2
  errors = ""
  residency_valid = true

  # puts "WE BE VALIDATING #{params[:name]}"
  # First, clean up any malicious code.
  params[:name] = escape_html(params[:name])
  params[:name_initial] = escape_html(params[:name_initial])
  params[:last_name] = escape_html(params[:last_name])
  params[:mother_last_name] = escape_html(params[:mother_last_name])
  params[:purpose] = escape_html(params[:purpose])
  # params[:birthdate] = escape_html(params[:birthdate])
  params[:birthdate] = params[:birthdate]
  params[:residency_country] = escape_html(params[:residency_country])
  params[:residency_city_state] = escape_html(params[:residency_city_state])

  # Store the data so we can show it again in case of
  # errors, using the session.
  session[:name] = params[:name]
  session[:name_initial] = params[:name_initial]
  session[:last_name] = params[:last_name]
  session[:mother_last_name] = params[:mother_last_name]
  session[:purpose] = params[:purpose]
  session[:birthdate] = params[:birthdate]
  session[:residency_country] = params[:residency_country]
  session[:residency_city] = params[:residency_city]
  session[:residency_state] = params[:residency_state]

  # Now let's start validation
  if(params[:name].to_s.length == 0 or
     !validate_name(params["name"]))
        errors += "&name=false"
  end
  if(params[:name_initial].to_s.length > 0 and
     !validate_name(params["name_initial"]))
        errors += "&name_initial=false"
  end
  if(params[:last_name].to_s.length == 0 or
     !validate_name(params["last_name"]))
        errors += "&last_name=false"
  end
  # if(params[:mother_last_name].to_s.length == 0 or
  #    !validate_name(params["mother_last_name"]))
  #       errors += "&mother_last_name=false"
  # end
  # maiden name is optional
  if(!validate_name(params["mother_last_name"]))
        errors += "&mother_last_name=false"
  end
  if(params[:purpose].to_s.length == 0 or
     !validate_reason(params["purpose"]))
        errors += "&purpose=false"
  end
  if(params[:birthdate].to_s.length == 0 or
     !validate_birthdate(params["birthdate"]))
        errors += "&birthdate=false"
  end

  # check minimum age
  if(params[:birthdate].to_s.length == 0 or
     !validate_birthdate(params["birthdate"], true))
        errors += "&age=false"
  end

  if(params[:residency_country].to_s.length == 0 or
     !validate_country(params["residency_country"]))
        residency_valid = false
        errors += "&residency_country=false"
  end

  # if a PR is the country set we proceed
  # to check if we have a municipality set.
  if(residency_valid and params[:residency_country] == "PR" and
     !validate_territory(params[:residency_country], params[:residency_city]))
        errors += "&residency_city=false"
  end

  # if a US is the country set we proceed
  # to check if we have a state set.
  if(residency_valid and params[:residency_country] == "US" and
     !validate_territory(params[:residency_country], params[:residency_state]))
        errors += "&residency_state=false"
  end

  # make sure we deal with any intentional
  # misconfigurations, such as someone playing with
  # html/javascript to submit US as country with PR municipalities
  # etc.
  if(params[:residency_country] == "US")
     session[:residency_city] == ""
  elsif(params[:residency_country] == "PR")
     session[:residency_state] = ""
  else
     # otherwise clear it for everything else
     session[:residency_state] = ""
     session[:residency_city] = ""
  end

  # If any errors ocurred, do a redirect:
  if errors.length > 0
    redirect to ("/form2?errors=true#{errors}")
  else
    # otherwise, we're good to go on.
    territory = ""
    territory += "#{session[:residency_city]}, " if session[:residency_city].to_s.length > 0
    territory += "#{session[:residency_state]}, " if session[:residency_state].to_s.length > 0
    session[:residence] = "#{territory}#{session[:residency_country]}"
  end
end

# Tells us if this session has been marked as completed.
# You only get the done flag after you've completed all the steps
# related to the CAP form and its validations.
def done?
     return true if session[:done]
     return false
end

def is_integer?(str)
  return true if ((str =~ /\A\+?0*[1-9]\d*\Z/)== 0 )
  return false
end

##############################################################
# The following are data validations inherited from the GMQ  #
# and modified for our use. Adding methods is ok, but        #
# beware of modifying methods, as inconsistencies could lead #
# to the API and web app disagreeing on a validation         #
# and could lead to errors from the API not allowing data.   #
##############################################################

# A module for methods used to validate data, such as valid
# transaction parameters, social security numbers, emails and the like.
module PRgov
  module Validations
      ########################################
      ##            Constants:               #
      ########################################

      PASSPORT_MIN_LENGTH     = 9
      PASSPORT_MAX_LENGTH     = 20
      SSN_LENGTH              = 9       # In 2014 SSN length was 9 digits.
      MAX_EMAIL_LENGTH        = 254     # IETF maximum length RFC3696/Errata ID: 1690
      DTOP_ID_MIN_LENGTH      = 7       # Selected based on license length.
      DTOP_ID_MAX_LENGTH      = 9       # Arbitrarily selected length. To support
                                        # any future changes.
      PRPD_USER_ID_MAX_LENGTH = 255     # Arbitrarily selected length.
      MAX_NAME_LENGTH         = 255     # Max length for individual components of
                                        # a full name (name, middle, last names)
      MAX_FULLNAME_LENGTH     = 255     # Max length for full name. 255 is long
                                        # enough. 255 * 255 * 255 * 255 is way too
                                        # too much anyway. Used for analyst names.
      MAX_RESIDENCY_LENGTH    = 255     # max residency length
      MINIMUM_AGE             = 18      # Edad minima para solicitar un certificado

      DATE_FORMAT             = '%d/%m/%Y'  # day/month/year

      ########################################
      ##            Validations:             #
      ########################################

      def validate_reason(str)
        # raise Exception, "TODO: havent coded this method yet in the GMQ or here"
        reasons = []
        # We'll now compare the reason (purpose) given by the user to the
        # allowed list. While there are a total of 10 purposes defined at
        # this time, we have to make room for the possibility that new reasons
        # might be added in the future. Since it is likely that such an addition
        # would be done at the view and locale files, we'll make this method
        # somewhat flexible so that it simply checks against the locale file
        # and allows for atleast X new purposes before having to be rewritten,
        # removing the barrier for a general developer to come in and add
        # new reasons without having to touch the validations. We could later
        # rewrite this so that we simply iterate through the yaml purpose.options
        # children, and use those ids for the iteration.

        (1..20).each do |number|
            # check if this translation exists. If we've exceeded the number
            # of consecutively defined purposes (1..10 for example), we simply
            # break out of the loop. This way, we don't really loop up to the
            # specified maximum of numbers of this loop, unless all of them
            # actually exist. This allows us to offer some flexibility for
            # future changes without sacrificing computation by unecessary
            # iterations.
            break if i18n_t("form.panel.purpose.options.#{number}").include? "translation missing:"
            # puts "looking at reason #{number} - #{i18n_t("form.panel.purpose.options.#{number}")}"
            # if it exists, compare it with str
            if (str == i18n_t("form.panel.purpose.options.#{number}"))
              # if str matches our defined purposes
              return true
            end
        end
        # if none found for this locale
        return false
      end

      # used when SIJC specifies the certificate is ready
      def validate_certificate_ready_parameters(params)
        params["id"] = params["tx_id"] if !params["tx_id"].nil?
        raise MissingTransactionId     if params["id"].to_s.length == 0
        raise InvalidTransactionId     if !validate_transaction_id(params["id"])
        raise MissingCertificateBase64 if params["certificate_base64"].to_s.length == 0
        raise InvalidCertificateBase64 if !validate_certificate_base64(params["certificate_base64"])
        return params
      end

      # used when an PRPD analyst specifies it has completed a manual review
      def validate_review_completed_parameters(params)
        raise MissingTransactionId        if params["id"].to_s.length == 0
        raise InvalidTransactionId        if !validate_transaction_id(params["id"])

        raise MissingAnalystId            if params["analyst_id"].to_s.length == 0
        raise InvalidAnalystId            if !validate_analyst_id(params["analyst_id"])
        raise MissingAnalystFullname      if params["analyst_fullname"].to_s.length == 0
        raise InvalidAnalystFullname      if !validate_analyst_fullname(params["analyst_fullname"])

        raise MissingAnalystApprovalDate  if params["analyst_approval_datetime"].to_s.length == 0
        raise InvalidAnalystApprovalDate  if !validate_date(params["analyst_approval_datetime"])
        raise MissingAnalystTransactionId if params["analyst_transaction_id"].to_s.length == 0
        raise MissingAnalystInternalStatusId if params["analyst_internal_status_id"].to_s.length == 0
        raise MissingAnalystDecisionCode     if params["decision_code"].to_s.length == 0
        raise InvalidAnalystDecisionCode     if !validate_decision_code(params["decision_code"])
        return params
      end

      ########################################
      ##            Creations:               #
      ########################################


      def validate_email_creation_parameters(params, whitelist)
        # deletes all non-whitelisted params, and returns a safe list.
        params = trim_whitelisted(params, whitelist)

        raise MissingEmail           if params["address"].to_s.length == 0
        raise MissingClientIP        if params["IP"].to_s.length == 0
        # raise MissingLanguage        if params["language"].to_s.length == 0
        # Validate the Email
        raise InvalidEmail           if !validate_email(params["address"])
        raise InvalidClientIP        if !validate_ip(params["IP"])
        # raise InvalidLanguage        if !validate_language(params["language"])
        return params

      end

        # validates parameters in a hash, returning proper errors
        # removed any non-whitelisted params
        def validate_transaction_creation_parameters(params, whitelist)

          # delets all non-whitelisted params, and returns a safe list.
          params = trim_whitelisted(params, whitelist)

          # Return proper errors if parameter is missing:
          raise MissingEmail           if params["email"].to_s.length == 0
          # raise MissingSSN             if params["ssn"].to_s.length == 0
          raise MissingPassportOrSSN   if (params["ssn"].to_s.length == 0 and
                                           params["passport"].to_s.length == 0)
          raise MissingLicenseNumber   if (params["license_number"].to_s.length == 0 and
                                          params["passport"].to_s.length == 0)
          raise MissingFirstName       if params["first_name"].to_s.length == 0
          raise MissingLastName        if params["last_name"].to_s.length == 0
          raise MissingResidency       if params["residency"].to_s.length == 0
          raise MissingBirthDate       if params["birth_date"].to_s.length == 0
          raise MissingClientIP        if params["IP"].to_s.length == 0
          raise MissingReason          if params["reason"].to_s.length == 0
          raise MissingLanguage        if params["language"].to_s.length == 0

          # Validate the Email
          raise InvalidEmail           if !validate_email(params["email"])

          # User must provide either passport or SSN. Let's check if
          # one or the other is invalid.

          # Validate the SSN
          # we eliminate any potential dashes in ssn
          params["ssn"] = params["ssn"].to_s.gsub("-", "").strip
          # raise InvalidSSN             if !validate_ssn(params["ssn"])
          raise InvalidSSN             if params["ssn"].to_s.length > 0 and
                                          !validate_ssn(params["ssn"])
          # Validate the Passport
          # we eliminate any potential dashes in the passport before validation
          params["passport"] = params["passport"].to_s.gsub("-", "").strip
          raise InvalidPassport        if params["passport"].to_s.length > 0 and
                                          !validate_passport(params["passport"])

          # Validate the DTOP id:
          raise InvalidLicenseNumber   if !validate_dtop_id(params["license_number"]) and
                                          params["passport"].to_s.length == 0

          raise InvalidFirstName       if !validate_name(params["first_name"])
          raise InvalidMiddleName      if !params["middle_name"].nil? and
                                          !validate_name(params["middle_name"])
          raise InvalidLastName        if !validate_name(params["last_name"])
          raise InvalidMotherLastName  if !params["mother_last_name"].nil? and
                                          !validate_name(params["mother_last_name"])

          raise InvalidResidency       if !validate_residency(params["residency"])

          # This validates birthdate
          raise InvalidBirthDate       if !validate_birthdate(params["birth_date"])
          # This checks minimum age
          raise InvalidBirthDate       if !validate_birthdate(params["birth_date"], true)
          raise InvalidClientIP        if !validate_ip(params["IP"])
          raise InvalidReason          if params["reason"].to_s.strip.length > 255
          raise InvalidLanguage        if !validate_language(params["language"])

          return params
        end


      # validates parameters for transaction validation requests
      # used when users have the transaction id and want us to
      # check if the transaction is really valid to us.
      def validate_transaction_validation_parameters(params, whitelist)
        # delets all non-whitelisted params, and returns a safe list.
        params = trim_whitelisted(params, whitelist)

        # Return proper errors if parameter is missing:
        raise MissingTransactionTxId if params["tx_id"].to_s.length == 0
        raise InvalidTransactionId   if !validate_transaction_id(params["tx_id"])
        raise MissingPassportOrSSN   if (params["ssn"].to_s.length == 0 and
                                         params["passport"].to_s.length == 0)
        raise MissingClientIP        if params["IP"].to_s.length == 0
        # Validate the SSN
        # we eliminate any potential dashes in ssn
        params["ssn"]  = params["ssn"].to_s.gsub("-", "").strip
        raise InvalidSSN             if params["ssn"].to_s.length > 0 and
                                        !validate_ssn(params["ssn"])
        # Validate the Passport
        # we eliminate any potential dashes in the passport before validation
        params["passport"] = params["passport"].to_s.gsub("-", "").strip
        raise InvalidPassport        if params["passport"].to_s.length > 0 and
                                        !validate_passport(params["passport"])
        # everything else:
        raise InvalidClientIP        if !validate_ip(params["IP"])

        return params
      end

      # Validates that a user specified language has been added.
      def validate_language(params)
        if(params.to_s == "english" or params.to_s == "spanish")
          true
        else
          false
        end
      end

      # Given a set of params and an array of whitelisted keys, we
      # delete all keys that weren't invited to the party. No sneaky
      # params allowed in this joint.
      def trim_whitelisted(params, whitelist)
          # remove any parameters that are not whitelisted
          params.each do |key, value|
            # if white listed
            if whitelist.include? key
              # strip the parameters of any extra spaces, save as string
              params[key] = value.to_s.strip
            else
              # delete any unauthorized parameters
              params.delete key
            end
          end
          params
      end

      def validate_decision_code(code)
        # return true
        if (code.to_s == "100" or code.to_s == "200")
          true
        else
          false
        end
      end
      # Validates a date as UTC
      def validate_date(date)
        begin
          Date.parse(date.to_s)
          true
        rescue ArgumentError
          false
        end
      end

      # Validtes a valid 64 bit was received. Doesn't validate that its
      # a specifif filetype in order to be flexible, and allow for
      # different filetypes to be sent in the future, not just pdf.
      def validate_certificate_base64(cert)
        return false if(cert.to_s.length <= 0 )
        # try to decode it by loading the entire decoded thing in memory
        begin
          # A tolerant verification
          # We'll use this only if SIJC's certificates fail in the
          # initial trials, else, we'll stick to the strict one.
          # Next line complies just with RC 2045:
          # decode = Base64.decode64(cert)

          # A strict verification:
          # Next line complies with RFC 4648:
          # try to decode, ArgumentErro is raised
          # if incorrectly padded or contains non-alphabet characters.
          decode = Base64.strict_decode64(cert)

          # Once decoded release it from memory
          decode = nil
          return true
        rescue Exception => e
          return false
        end
      end
      def validate_transaction_id(id)
        # if(puts "#{id.length} vs #{TransactionIdFactory.transaction_key_length()}")
        if(id.to_s.strip.length == TransactionIdFactory.transaction_key_length())
           return true
        end
        return false
      end

      # Validate Social Security Number
      def validate_ssn(value)
        false if value.to_s.length == 0
        # Validate the SSN
        # we eliminate any potential dashes in ssn
        value = value.to_s.gsub("-", "").strip
        # validates if its an integer
        if(validate_str_is_integer(value) and value.length == SSN_LENGTH)
          return true
        else
          return false
        end
      end

      # Validate Passport number
      def validate_passport(value)
        return false if value.to_s.length == 0
        # Validate the Passport
        # we eliminate any potential dashes in the passport
        value = value.to_s.gsub("-", "").strip
        # validates if its has proper length
        if(value.length >= PASSPORT_MIN_LENGTH and
           value.length <= PASSPORT_MAX_LENGTH)
          return true
        else
          return false
        end
      end

      # Check the email address
      def validate_email(value)
        # For email length, the source was:
        # http://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690
        #
        # Optionally we could force DNS lookups using ValidatesEmailFormatOf
        # by sending validate_email_format special options after the value
        # such as mx=true (see gem's github), however, this requires dns
        # availability 24/7, and we'd like this system to work a little more
        # independently, so for now simply check against the RFC 2822,
        # RFC 3696 and the filters in the gem.
        return true if (ValidatesEmailFormatOf::validate_email_format(value).nil? and
                 value.to_s.length < MAX_EMAIL_LENGTH ) #ok
        return false #fail
      end

      # validates if a string is an integer
      def validate_str_is_integer(value)
        !!(value =~ /\A[-+]?[0-9]+\z/)
      end

      # Validates a DTOP id.
      def validate_dtop_id(value)
        return false if value.to_s.length == 0
        return false if(!validate_str_is_integer(value) or
                  value.to_s.length >= DTOP_ID_MAX_LENGTH or
                  value.to_s.length <  DTOP_ID_MIN_LENGTH)
        return true
      end

      def validate_analyst_id(value)
        return false if(value.to_s.length >= PRPD_USER_ID_MAX_LENGTH)
        return true
      end

      def validate_analyst_fullname(value)
        return false if(value.to_s.length >= MAX_FULLNAME_LENGTH)
        return true
      end

      # used to validate names/middle names/last names/mother last name
      def validate_name(value)
        return false if(value.to_s.length >= MAX_NAME_LENGTH)
        return true
      end

      # checks the length
      def validate_residency(value)
        return false if(value.to_s.length >= MAX_RESIDENCY_LENGTH)
        return true
      end

      # check against the list of countries.
      def validate_country(country)
        return false if country.to_s.length == 0
        return false if !validate_residency(country)
        if(PRgovCAPWebApp::App.settings.country_codes.has_key? country)
          return true
        else
          return false
        end
      end

      # check against the list of countries for their territories
      # (states / municipalities)
      def validate_territory(country, territory)
        return false if country.to_s.length == 0 or territory.to_s.length == 0
        return false if !validate_residency(territory)
        if(PRgovCAPWebApp::App.settings.country_codes.has_key? country)
          if(country == "PR" and
             PRgovCAPWebApp::App.settings.pr_municipalities.has_key? territory)
              return true
          elsif(country == "US" and
              PRgovCAPWebApp::App.settings.usa_states.has_key? territory)
            return true
          end
        end
        return false
      end

      def validate_birthdate(value, check_age=false)
        begin
          # check if valid date. if invalid, raise exception ArgumentError
          date = Date.strptime(value, DATE_FORMAT)
          # if it was required for us to validate minimum age
          if(check_age == true)
            if(age(date) >= MINIMUM_AGE)
              return true # date was valid and the person is at least of minimum age
            end
            return false # person isn't of minimum age
          end
          return true # the date is valid
        rescue Exception => e
          # ArgumentError, the user entered an invalid date.
          return false
        end
      end

      # Gets the age of a person based on their date of birth (dob)
      def age(dob)
        now = Date.today
        now.year - dob.year - ((now.month > dob.month ||
        (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
      end

      ###################################
      #  Validate IPv4 and IPv6         #
      ###################################
      def validate_ip(value)
        case value
        when Resolv::IPv4::Regex
          return true
        when Resolv::IPv6::Regex
          return true
        else
          return false
        end
      end
  end
end

# Ripped from https://github.com/alexdunae/validates_email_format_of
# and modified so it doesn't have any dependency on ActiveRecord.
# encoding: utf-8
module ValidatesEmailFormatOf

  VERSION = '1.5.3'

  LocalPartSpecialChars = /[\!\#\$\%\&\'\*\-\/\=\?\+\-\^\_\`\{\|\}\~]/

  def self.validate_email_domain(email)
    domain = email.match(/\@(.+)/)[1]
    Resolv::DNS.open do |dns|
      @mx = dns.getresources(domain, Resolv::DNS::Resource::IN::MX) + dns.getresources(domain, Resolv::DNS::Resource::IN::A)
    end
    @mx.size > 0 ? true : false
  end

  # Validates whether the specified value is a valid email address.  Returns nil if the value is valid, otherwise returns an array
  # containing one or more validation error messages.
  #
  # Configuration options:
  # * <tt>message</tt> - A custom error message (default is: "does not appear to be valid")
  # * <tt>check_mx</tt> - Check for MX records (default is false)
  # * <tt>mx_message</tt> - A custom error message when an MX record validation fails (default is: "is not routable.")
  # * <tt>with</tt> The regex to use for validating the format of the email address (deprecated)
  # * <tt>local_length</tt> Maximum number of characters allowed in the local part (default is 64)
  # * <tt>domain_length</tt> Maximum number of characters allowed in the domain part (default is 255)
  def self.validate_email_format(email, options={})
      default_options = { :message => 'does not appear to be valid',
                          :check_mx => false,
                          :mx_message => 'is not routable',
                          :domain_length => 255,
                          :local_length => 64
                          }
      opts = options.merge(default_options) {|key, old, new| old}  # merge the default options into the specified options, retaining all specified options

      email = email.strip if email

      begin
        domain, local = email.reverse.split('@', 2)
      rescue
        return [ opts[:message] ]
      end

      # need local and domain parts
      return [ opts[:message] ] unless local and not local.empty? and domain and not domain.empty?

      # check lengths
      return [ opts[:message] ] unless domain.length <= opts[:domain_length] and local.length <= opts[:local_length]

      local.reverse!
      domain.reverse!

      if opts.has_key?(:with) # holdover from versions <= 1.4.7
        return [ opts[:message] ] unless email =~ opts[:with]
      else
        return [ opts[:message] ] unless self.validate_local_part_syntax(local) and self.validate_domain_part_syntax(domain)
      end

      if opts[:check_mx] and !self.validate_email_domain(email)
        return [ opts[:mx_message] ]
      end

      return nil    # represents no validation errors
  end


  def self.validate_local_part_syntax(local)
    in_quoted_pair = false
    in_quoted_string = false

    (0..local.length-1).each do |i|
      ord = local[i].ord

      # accept anything if it's got a backslash before it
      if in_quoted_pair
        in_quoted_pair = false
        next
      end

      # backslash signifies the start of a quoted pair
      if ord == 92 and i < local.length - 1
        return false if not in_quoted_string # must be in quoted string per http://www.rfc-editor.org/errata_search.php?rfc=3696
        in_quoted_pair = true
        next
      end

      # double quote delimits quoted strings
      if ord == 34
        in_quoted_string = !in_quoted_string
        next
      end

      next if local[i,1] =~ /[a-z0-9]/i
      next if local[i,1] =~ LocalPartSpecialChars

      # period must be followed by something
      if ord == 46
        return false if i == 0 or i == local.length - 1 # can't be first or last char
        next unless local[i+1].ord == 46 # can't be followed by a period
      end

      return false
    end

    return false if in_quoted_string # unbalanced quotes

    return true
  end

  def self.validate_domain_part_syntax(domain)
    parts = domain.downcase.split('.', -1)

    return false if parts.length <= 1 # Only one domain part

    # Empty parts (double period) or invalid chars
    return false if parts.any? {
      |part|
        part.nil? or
        part.empty? or
        not part =~ /\A[[:alnum:]\-]+\Z/ or
        part[0,1] == '-' or part[-1,1] == '-' # hyphen at beginning or end of part
    }

    # ipv4
    return true if parts.length == 4 and parts.all? { |part| part =~ /\A[0-9]+\Z/ and part.to_i.between?(0, 255) }

    return false if parts[-1].length < 2 or not parts[-1] =~ /[a-z\-]/ # TLD is too short or does not contain a char or hyphen

    return true
  end

  module Validations
    # Validates whether the value of the specified attribute is a valid email address
    #
    #   class User < ActiveRecord::Base
    #     validates_email_format_of :email, :on => :create
    #   end
    #
    # Configuration options:
    # * <tt>message</tt> - A custom error message (default is: "does not appear to be valid")
    # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>allow_nil</tt> - Allow nil values (default is false)
    # * <tt>allow_blank</tt> - Allow blank values (default is false)
    # * <tt>check_mx</tt> - Check for MX records (default is false)
    # * <tt>mx_message</tt> - A custom error message when an MX record validation fails (default is: "is not routable.")
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - See <tt>:if</tt>
    def validates_email_format_of(*attr_names)
      options = { :on => :save,
        :allow_nil => false,
        :allow_blank => false }
      options.update(attr_names.pop) if attr_names.last.is_a?(Hash)

      validates_each(attr_names, options) do |record, attr_name, value|
        errors = ValidatesEmailFormatOf::validate_email_format(value.to_s, options)
        errors.each do |error|
          record.errors.add(attr_name, error)
        end unless errors.nil?
      end
    end
  end
end
