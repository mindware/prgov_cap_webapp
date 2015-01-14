# A base class that represents objects in the storage.
# by: Andrés Cólon Pérez 2014 / for PR.gov DevTeam
# Require the GMQ CAP API class
require PADRINO_ROOT + "/app/models/gmq"
require PADRINO_ROOT + "/app/helpers/validations"
# require PADRINO_ROOT + "/app/helpers/store"

module PRgov
  class Base
    include PRgov::Validations
    extend  PRgov::Validations

    attr_accessor :id

    ############################################################
    #                       Class Methods                      #
    ############################################################

    ########################
    #      Key Strategy    #
    ########################
    # Consistent Key Strategy for our Storage:
    # In order to have a consistent key storing strategy for our
    # key/value database, we define a series of class methods that
    # contain the proper prefixes for our keys. This way
    # we have a consistent storage strategy for our keys in the
    # database. For example, per our strategy, we've decided that
    # all of our keys will be stored under 'prgov:cap:'.
    # If we had a new model named 'Users', we'd redefine the
    # db_list_prefix methods, as follows:
    #
    # =>  require 'app/models/base'
    # =>  class Users < Base
    # =>    def self.db_prefix
    # =>        'users'
    # =>    end
    # =>    def db_prefix
    # =>        self.db_prefix
    # =>    end
    # =>  end
    #
    # In this way, all keys would be stored under
    # 'prgov:cap:users' when using Users.db_global_prefix
    # and all ids, such as the first user would be found
    # under 'prgov:cap:users:1' via the method user.db_id.
    # Using a consistent key strategy is important, so that
    # when multiple applications use the same key/value storage
    # we can quickly identify what record belongs to which system
    # in each (redis) database.

    # The global system's prefix.
    # All records will be stored behind this global system prefix.
    def self.system_prefix
      "prgov"
    end

    # This method will be redefined by each child class
    # This prefix is the equivalent of a storage group for this class
    # under the system. If you think as the system_prefix as the app,
    # the db_prefix is the database name, and everything under is the tables
    # (of course, this is a NoSQL DB so thinking in terms of relational
    # databases structures doesn't really do it justice)
    def self.db_prefix
      "cap"
    end

    # The prefix to be used to store lists of this class
    def self.db_list_prefix
      "list"
    end

    # Grabs the prefix and adds this classes's
    # db_prefix. Classes that inherit this Base class
    # won't have to redefined this.
    def self.db_global_prefix
      "#{self.system_prefix}:#{self.db_prefix}"
    end

    def self.queue_pending_prefix
      "pending"
    end

    # Displays the proper id for this object in the db
    def self.db_id(id)
      "#{self.db_global_prefix}:#{id}"
    end

    def self.db_list
      "#{self.db_global_prefix}:#{self.db_list_prefix}"
    end

    # Queues are stored at the system level and are not specific
    # to a db. For example, new transactions to be processed are
    # stored in the queue called pending, regardless if they're
    # Transactions for service A or any other service.
    def self.queue_pending
      "#{self.system_prefix}:#{self.queue_pending_prefix}"
    end

    # Redefine this per class to store whatever information
    # is important to you
    def self.db_cache_info
      "#{self.class}"
    end

    # Base method for newly created instances
    def self.create(params)
    end

    ############################################################
    #                      Instance Methods                    #
    ############################################################

    # Base method for loading values from a hash into the object
    def setup(params)
    end

    # Base method for saving a record
    def save
    end

    ########################
    #      Key Strategy    #
    ########################

    # These following are just methods to make class methods available to
    # instances of this class.

    def global_prefix
      self.class.global_prefix
    end
    def db_prefix
      self.class.db_prefix
    end
    def db_id
      self.class.db_id(self.id)
    end

    def db_list
      self.class.db_list
    end

    def db_cache_info
      self.class.db_cache_info
    end

    def system_prefix
      self.class.system_prefix
    end

  end # end of class
end # end of module
