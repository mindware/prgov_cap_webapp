# Helper methods defined here can be accessed in any controller or view in the application

module PRgovCAPWebApp
  class App
    module CAPHelper
      # def simple_helper_method
      # ...
      # end

      def i18n_t(resource)
        # Rules for special characters conversion to HTML must be handled
        # by I18n transliteration rules.
        I18n.transliterate(I18n.translate(resource)).html_safe
      end

      def i18n_asciidoc(resource)
        asciidoc(I18n.transliterate(I18n.translate(resource))).html_safe
      end

      # Localized-Bootstrap select_tag
      def select_tag_bs(name, elements, selected)
        is_localized = elements.delete("localized") || false
        list = case is_localized
        when true
          elements.map { |value, resource| [I18n.transliterate(I18n.translate(resource)), value] }
        else
          elements.map { |value, resource| [I18n.transliterate(resource), value] }
        end
        select_tag(name, :options => list, :selected => selected)
      end
    end

    helpers CAPHelper
  end
end
