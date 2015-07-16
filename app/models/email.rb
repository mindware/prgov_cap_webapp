# A class that represents emails in the storage.
# Email addresses are validated by sending an email to the user.
# Once an email has been validated as a delivery mechanism, we can
# confirm it by using this class.
# by: Andrés Cólon Pérez 2014 / for PR.gov DevTeam
# Require the GMQ CAP API class
require PADRINO_ROOT + "/app/models/base"
require PADRINO_ROOT + '/app/helpers/cap_helper'
require 'securerandom'
require 'base64'
require 'json'

class Email < PRgov::Base

    include PRgovCAPWebApp::App::CAPHelper

    # Add Padrino helpers so we can use link_to properly
    # These are all required by Padrino.
    include Padrino::Helpers::AssetTagHelpers
    include Padrino::Helpers::TagHelpers
    include Padrino::Helpers::OutputHelpers

    # attr_reader :from, :MAX_MINUTES, :MAX_MINUTES_IN_SECONDS

    attr_accessor :address,             # The user's email address
                  :confirmation_code,   # The generated confirmation code
                                        # to validate an email address.
                  :confirmed,           # Flag that determines if email
                                        # has been confirmed.
                  :created_at,          # Date of request
                  :updated_at,          # Last update/lookup.
                  :sent_at,             # Time the email was requested
                                        # by the webapp to be sent.
                  :IP,                  # IP of the requestor at time of email
                                        # confirmation
                  :requests             # Counter that determines how many
                                        # requests this email has performed.

    # TODO, we need to store language here
    # this should become a Profile class.
    # we should have a state where we define in
    # what Stage we're in (state) First stage or Second etc.
    # we should save some information regarding the
    # request here as well. Remember to save statistics later.

    # What it is:
    # This value is used both as a limiter and also as a
    # presentation to the user. Modifying this value, modifies
    # the number of minutes that a user is presented with in the UI.
    # What it does:
    # Wait at most MAX_MINUTES minutes before allowing users to request
    # a resend of an email to confirm their address. This
    # is to give time to the mail server to empty its queue.
    MAX_MINUTES = 10
    # Turns MAX_MINUTES minutes into seconds
    MAX_MINUTES_IN_SECONDS = 60 * MAX_MINUTES

    # How many months should we remember an email that has
    # been confirmed by the user to receive emails from pr.gov,
    # so that the user doesn't have to go through the process
    # of revalidating his email through this period:
    MONTHS_TO_EXPIRATION_OF_EMAIL = 8
    # The expiration is going to be Z months, in seconds.
    # Time To Live - Math:
    # 604800 seconds in a week X 4 weeks = 1 month in seconds
    # We multiply this amount for the Z amount of months that an email
    # can last before expiring.
    EXPIRATION = (604800 * 4) * MONTHS_TO_EXPIRATION_OF_EMAIL
    # Emails awaiting user to click on the confirmation link
    # last one week unless confirmed.
    UNCONFIRMED_EXPIRATION = 604800 # one week.

    # Newly created objects from user input
    def self.create(params)
      # The following parameters are allowed to be input by the user
      # everything else will be discarded from the user params
      # by the validate_email_creation_parameters() method
      whitelist = ["address", "IP"]
      params = validate_email_creation_parameters(params, whitelist)

      email = self.new.setup(params)
      # Add important system defined parameters here:
      email.confirmation_code   = generate_code()
      email.confirmed           = false
      email.created_at          = Time.now.utc
      email.updated_at          = Time.now.utc
      email.sent_at             = nil
      # email.request
      return email
    end

    # Tries to find a record, if nothing is found, returns nil
    def self.find(email)
        # get the data from the store
        values = $redis.get db_id(email)
        # load it
        if(values.to_s.length > 0)
          values = JSON.parse(values)
          return Email.new.setup(values)
        else
          nil
        end
    end

    # Generates a unique identifier
    def self.generate_code
      code = SecureRandom.uuid
    end

    # Class method
    # defines the email as this class's id
    # we use this in the base class for determing
    # how to store the data related to the class
    def self.id
      self.address
    end

    # Instance method
    # defines the email as this class's id
    # we use this in the base class for determing
    # how to store the data related to the class
    def id
      self.address
    end

    # Loads values from a hash into this object
    def setup(params)
      if params.is_a? Hash
              self.confirmation_code = params["confirmation_code"]
              self.address           = params["address"]
              self.confirmed         = params["confirmed"]
              self.IP                = params["IP"]
              self.created_at        = params["created_at"]
              self.sent_at           = params["sent_at"]
              self.updated_at        = params["updated_at"]
      else
        raise Exception, "Invalid parameters class for method. Expecting Hash."
      end
      return self
    end

    # returns the configured from address
    def from
      ENV["PRGOV_FROM_EMAIL"]
    end

    # Email addresses cannot be duplicated in the database.
    # If an attempt to create a duplicate is performed, an
    # exception must be raised.

    # Returns true if confirmed, false otherwise.
    def confirmed?
      self.confirmed == true
    end

    def registered?
      !self.confirmed?
    end

    # returns the count down number in minutes
    def resend_countdown
      time = ((Time.parse(self.sent_at.to_s) + MAX_MINUTES_IN_SECONDS) - Time.now.utc) / 60
      time.to_i
    end

    # returns minutes taking into consideration
    # internationalization ("1 minute" or "2 minutos")
    def countdown_in_minutes
      time = resend_countdown
      if(time <= 1 and time >= 0)
        time = 1
        minutes = "#{i18n_t("email_sent.minute")}"
      else
        # make minute/minuto plural by adding an s
        minutes = "#{i18n_t("email_sent.minute")}s"
      end
      "#{time} #{minutes}"
    end

    def should_resend?
      # if email is confirmed we shouldn't resend
      return false if confirmed?
      # if email doesn't have a sent_at date we must
      # send an email.
      return true if self.sent_at.nil?
      # if email confirmation is older than MAX_MINUTES_IN_SECONDS
      time = (Time.parse(self.sent_at) - (Time.now.utc - (MAX_MINUTES_IN_SECONDS)))
      if (time <= 0)
        return true
      else
        return false
      end
    end

    # Grab all global global variables in this Object, and turn it into
    # a hash.
    def to_hash
       h =  self.instance_variables.each_with_object({}) { |var,hash|
       hash[var.to_s.delete("@")] = self.instance_variable_get(var) }
      # add any values that aren't variables, but are the result of methods:
      return h
    end

    # turns this object to a json object
    def to_json
      to_hash.to_json
    end

    # simple accessor for the constant
    def max_minutes
      MAX_MINUTES
    end

    # simple accessor for the constant
    def max_minutes_in_seconds
      MAX_MINUTES_IN_SECONDS
    end

    # enqueues a mail in the gateway, requires the client
    # ip to be recieved in order to log it.
    def enqueue_confirmation_email(url)
      # Attempt to queue the email using the preferred
      # mailing method:

      # Create the expected email payload
      payload = {
                  "from" => from(),
                  "to"   => self.address,
                  "subject" => i18n_raw("email.confirmation.subject"),
                  "text"    => i18n_raw("email.confirmation.body",
                                  :link => get_link(url)
                               ),
                  "html"    => i18n_asciidoc("email.confirmation.body",
                                  :link => "#{url}#{generate_confirmation_path()}"
                                ).gsub("\n", "<br>"),
      }

      if(GMQ.enqueue_email(payload))
        self.sent_at = Time.now.utc
        self.save
        return
      else
        # Our mail gateway is down and we couldn't enqueue
        raise PRgov::GMQUnavailable, "Couldn't enqueue confirmation emails in the GMQ."
      end
    end

    def save
     # update the last updated_at timestamp
     self.updated_at = Time.now.utc
     # If TTL is not nil, update the Time to Live everytime
     # a transaction is saved/updated
     $redis.pipelined do |db|
       db.set db_id, self.to_json
       db.expire(db_id, EXPIRATION)
     end
    end

    # Class method to decode an email
    # If it fails we return empty string.
    def self.decode(str)
       begin
         Base64.decode64(str)
       rescue Exception => e
         ""
       end
    end

    # Class method to encode an email.
    # If it fails we return empty string.
    def self.encode(str)
       begin
         Base64.encode64(str)
       rescue Exception => e
         ""
       end
    end

    # Generates the confirmation path for
    # this email. It includes confirmation code and the
    # email address base64 encoded.
    def generate_confirmation_path()
      "/confirm?code=#{self.confirmation_code}&"+
      "address=#{Email.encode(self.address)}"
    end

    # Generates an html link for confirmation.
    def get_link(url)
      # puts "value of variable is #{url}"
      # link_to('confirm email',
      link_to("#{url}#{generate_confirmation_path()}",
      "#{url}#{generate_confirmation_path()}")
    end

end
