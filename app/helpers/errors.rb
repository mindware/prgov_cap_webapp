module PRgov

  # Base Error, our Internal Server Error.
  class AppError < RuntimeError
    # data is the method used to return hashes with http and app errors.
    def self.data
      # sprinkle some errors and print the Exception name with self.to_s
      {"error" => { "http_error" => "An Internal Server Error ocurred",
                    "http_code" => 500,
                    "app_error" => "An unexpected internal error "+
                                   "has occurred.",
                    "app_code" => 6000
                  }
      }
    end
    # This method is used to retrieve the http error code.
    def self.http_code
        #+ Add logging capability here.
        self.data["error"]["http_code"]
    end

    def self.message
        self.data["error"][""]
    end
  end

  ################################################################
  ########                   Missing                      ########
  ################################################################

  class MissingTransactionId < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: id is required.",
                     "app_code" => 1000
                  }
      }
    end
  end

  class MissingEmail < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: email is required.",
                     "app_code" => 1001
                  }
      }
    end
  end

  class MissingCertificateBase64 < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: certificate_base64 is required.",
                     "app_code" => 1002
                  }
      }
    end
  end

  class MissingSSN < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: ssn is required.",
                     "app_code" => 1003
                  }
      }
    end
  end

  class MissingLicenseNumber < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: license_number is required.",
                     "app_code" => 1004
                  }
      }
    end
  end

  class MissingFirstName < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: first_name is required.",
                     "app_code" => 1005
                  }
      }
    end
  end

  class MissingLastName < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: last_name is required.",
                     "app_code" => 1006
                  }
      }
    end
  end

  class MissingBirthDate < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: birth_date is required.",
                     "app_code" => 1007
                  }
      }
    end
  end

  class MissingResidency < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: residency is required.",
                     "app_code" => 1008
                  }
      }
    end
  end

  class MissingClientIP < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: Client's IP is required.",
                     "app_code" => 1009
                  }
      }
    end
  end

  class MissingStatus < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: status is required.",
                     "app_code" => 1010
                  }
      }
    end
  end

  class MissingReason < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: reason is required.",
                     "app_code" => 1011
                  }
      }
    end
  end


  class MissingAnalystApprovalDate < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: analyst_approval_datetime is"+
                                    " required.",
                     "app_code" => 1012
                  }
      }
    end
  end
  class MissingAnalystTransactionId < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: analyst_transaction_id is"+
                                    " required.",
                     "app_code" => 1013
                  }
      }
    end
  end

  class MissingAnalystInternalStatusId < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: analyst_internal_status_id "+
                                    "is required.",
                     "app_code" => 1014
                  }
      }
    end
  end

  class MissingAnalystDecisionCode < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: decision_code "+
                                    "is required.",
                     "app_code" => 1015
                  }
      }
    end
  end

  class MissingAnalystId < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: analyst_id "+
                                    "is required.",
                     "app_code" => 1016
                  }
      }
    end
  end

  class MissingAnalystFullname < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: analyst_fullname "+
                                    "is required.",
                     "app_code" => 1017
                  }
      }
    end
  end

  class MissingLanguage < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Parameter: language "+
                                    "is required.",
                     "app_code" => 1018
                  }
      }
    end
  end


  ################################################################
  ########                   Invalid                      ########
  ################################################################

  class InvalidTransactionId < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid transaction id provided.",
                     "app_code" => 2000
                  }
      }
    end
  end

  class InvalidEmail < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid email provided.",
                     "app_code" => 2001
                  }
      }
    end
  end

  class InvalidStatus < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid transaction status. A valid "+
                     "transaction status is one of the following: completed,"+
                     " pending, retry, processing, failed.",
                     "app_code" => 2002
                  }
      }
    end
  end

  class InvalidSSN < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid ssn provided.",
                     "app_code" => 2002
                  }
      }
    end
  end

  class InvalidSSN < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid ssn provided.",
                     "app_code" => 2003
                  }
      }
    end
  end

  class InvalidLicenseNumber < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid license_number provided.",
                     "app_code" => 2004
                  }
      }
    end
  end

  class InvalidFirstName < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid name provided.",
                     "app_code" => 2005
                  }
      }
    end
  end


  class InvalidBirthDate < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid birth_date provided.",
                     "app_code" => 2006
                  }
      }
    end
  end

  class InvalidResidency < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid residency provided.",
                     "app_code" => 2007
                  }
      }
    end
  end

  class InvalidClientIP < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid Client IP provided.",
                     "app_code" => 2008
                  }
      }
    end
  end

  class InvalidReason < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid reason provided.",
                     "app_code" => 2009
                  }
      }
    end
  end

  class InvalidCertificateBase64 < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid certificate_base64 provided.",
                     "app_code" => 2010
                  }
      }
    end
  end

  class InvalidMiddleName < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid middle name provided.",
                     "app_code" => 2011
                  }
      }
    end
  end

  class InvalidLastName < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid last name provided.",
                     "app_code" => 2012
                  }
      }
    end
  end

  class InvalidMotherLastName < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid mother last name provided.",
                     "app_code" => 2013
                  }
      }
    end
  end

  class NotOldEnough < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Cannot issue a certificate for minors.",
                     "app_code" => 2014
                  }
      }
    end
  end

  class InvalidAnalystApprovalDate < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid analyst_approval_date. You must"+
                                    " supply a valid utc timestamp (example:"+
                                    " 2014-05-29 13:23:39 UTC).",
                     "app_code" => 2015
                  }
      }
    end
  end

  class InvalidAnalystDecisionCode < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid decision_code provided.",
                     "app_code" => 2016
                  }
      }
    end
  end

  class InvalidAnalystId < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid analyst_id provided.",
                     "app_code" => 2017
                  }
      }
    end
  end

  class InvalidAnalystFullname < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid analyst_fullname provided.",
                     "app_code" => 2018
                  }
      }
    end
  end

  class InvalidLanguage < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid language provided.",
                     "app_code" => 2019
                  }
      }
    end
  end


  ################################################################
  ########          Additional Validation Errors          ########
  ################################################################


  class InvalidCredentials < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "401 Unauthorized",
                     "http_code" => 401,
                     "app_error" => "Unauthorized: Username or "+
                                   "password is incorrect.",
                     "app_code" => 4000
                  }
      }
    end
  end

  class InvalidAccess < PRgov::AppError
    def self.data
      { "error" => {  "http_error" => "403 Forbidden",
                      "http_code" => 403 ,
                      "app_error" => "Forbidden: Your credentials do"+
                      " not allow you access to that resource.",
                      "app_code" => 4500
                  }
      }
    end
  end

  class InvalidParameters < PRgov::AppError
    def self.data
      { "error" => { "http_error" => "400 Bad Request",
                     "http_code" => 400,
                     "app_error" => "Invalid Parameters",
                     "app_code" => 2999
                  }
      }
    end
  end


  ################################################################
  ########                 Not Found                      ########
  ################################################################

  class ResourceNotFound < PRgov::AppError
    def self.data
      { "error" => {  "http_error" => "404 Not Found",
                      "http_code" => 404,
                      "app_error" => "The resource"+
                      " provided in the URL doesn't exist. Check the API "+
                      "documentation and version for valid URL resources "+
                      "and their corresponding HTTP verbs (ie: GET, PUT, "+
                      "POST, DELETE).",
                      "app_code" => 5000
                  }
      }
    end
  end

  class ItemNotFound < PRgov::AppError
    def self.data
      { "error" => {  "http_error" => "404 Not Found",
                      "http_code" => 404,
                      "app_error" => "The requested item could not be found."+
                      " The item might've expired, been deleted or may have "+
                      "never existed.",
                      "app_code" => 5001
                  }
      }
    end
  end

  # Same as ItemNotFound but with a class name that is more explicit.
  # Returned by the API and the Transaction class.
  class TransactionNotFound < PRgov::AppError
    def self.data
      { "error" => {  "http_error" => "404 Not Found",
                      "http_code" => 404,
                      "app_error" => "The requested item could not be found."+
                      " The item might've expired, been deleted or may have "+
                      "never existed.",
                      "app_code" => 5001
                  }
      }
    end
  end

  ################################################################
  ########               Internal Errors                  ########
  ################################################################

  class InvalidAccessGroup < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "500 Internal Server Error",
                     "http_code" => 500,
                     "app_error"  => "Internal Server Error: The user has an "+
                     "improperly configured access group. "+
                     "The administrator needs to set a proper array as a "+
                     "data structure for the access group.",
                     "app_code" => 6001
                  }
      }
    end
  end

  class MissingConfigFile < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "500 Internal Server Error",
                     "http_code" => 500,
                     "app_error"  => "The configuration file is missing or "+
                                     "access to it is unavailable",
                     "app_code" => 6002
                  }
      }
    end
  end

  class InvalidConfigFile < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "500 Internal Server Error",
                     "http_code" => 500,
                     "app_error"  => "The API's configuration file is "+
                                     "invalid and could not be parsed.",
                     "app_code" => 6003
                  }
      }
    end
  end

  class MissingAccessGroup < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "500 Internal Server Error",
                     "http_code" => 500,
                     "app_error"  => "The user's config is missing "+
                                     "a security group.",
                     "app_code" => 6004
                  }
      }
    end
  end

  class InvalidPasskeyLength < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "500 Internal Server Error",
                     "http_code" => 500,
                     "app_error"  => "The system configured passkey for "+
                                  "the user is of an invalid length.",
                     "app_code" => 6005
                  }
      }
    end
  end

  class InvalidNonJsonRecord < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "500 Internal Server Error",
                     "http_code" => 500,
                     "app_error"  => "The record found "+
                     "was in an improper format and could not be "+
                     "properly parsed.",
                     "app_code" => 6006
                  }
      }
    end
  end

  class InvalidErrorProvided < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "500 Internal Server Error",
                     "http_code" => 500,
                     "app_error"  => "An invalid error was raised. This is "+
                     "a programming error. Someone raised an error but did "+
                     "not properly define it for the API, as children of "+
                     "the AppError class.",
                     "app_code" => 6106
                  }
      }
    end
  end


  ################################################################
  ########          External Systems  Unavailable         ########
  ################################################################


  class GMQUnavailable < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "502 Internal Server Error",
                     "http_code" => 502,
                     "app_error"  => "The Government Message "+
                                     "Queue could not be accessed.",
                     "app_code" => 7000
                  }
      }
    end
  end

  class StoreUnavailable < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "502 Internal Server Error",
                     "http_code" => 502,
                     "app_error"  => "The Transaction Store could not be "+
                                     "accessed.",
                     "app_code" => 7001
                  }
      }
    end
  end

  ################################################################
  ########            Down for Maintenance                ########
  ################################################################

  class ServiceUnavailable < PRgov::AppError
    def self.data
      { "error" => { "http_message" => "503 Service Unavailable",
                     "http_code" => 503,
                     "app_error"  => "This service is currently "+
                                     "unavailable. Down for maintenance.",
                     "app_code" => 8000
                  }
      }
    end
  end

end


class GMQ_ERROR < RuntimeError
end
