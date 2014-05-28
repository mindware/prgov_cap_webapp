# Helper methods defined here can be accessed in any controller or view in the application

module CAPWebApp
  class App
    module CAPHelper
      # def simple_helper_method
      # ...
      # end
      def i18n_t(resource)
        I18n.t resource
      end
    end

    helpers CAPHelper
  end
end
