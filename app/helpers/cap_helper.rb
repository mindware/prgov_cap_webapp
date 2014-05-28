# Helper methods defined here can be accessed in any controller or view in the application

module CAPWebApp
  class App
    module CAPHelper
      # def simple_helper_method
      # ...
      # end

      def i18n_t(resource)
        # Rules for special characters conversion to HTML must be handled
        # by I18n transliteration rules.
        I18n.transliterate(I18n.t(resource)).html_safe
      end

      def i18n_asciidoc(resource)
        asciidoc(I18n.transliterate(I18n.t(resource))).html_safe
      end
    end

    helpers CAPHelper
  end
end
