# Helper methods defined here can be accessed in any controller or view in the
# application. Optimized all i18n methods and allowed support for values passed
# as parameters. Added warnings for new i18n_raw method. 2014 - Andrés Colón 
require 'asciidoctor'

module PRgovCAPWebApp
  class App
    module CAPHelper

      # Our helper method that incorporates asciidoctor,
      # which can format simple strings to formatted html
      # Asciidoctor: https://github.com/asciidoctor/asciidoctor
      def asciidoc(string)
        Asciidoctor.convert string, safe: 'safe'
      end

      # Our raw version of i18n. This method performs internationalization
      # without escaping html. Only use this method if you *absolutely*
      # need it in order to raw html output. This method as it is unsafe
      # by default, do not use it unless you know what you're doing.
      # Do not use this method unless you manually are doing html_safe
      # to its output. Do not ever use this method without html_safe
      # if there is user input involved in the text that will be output.
      def i18n_raw(resource, *arr)
        # Rules for special characters conversion to HTML must be handled
        # by I18n transliteration rules.
        I18n.transliterate(I18n.translate(resource, *arr))
      end

      # Our safe to use, html safe version of our i18n_raw.
      def i18n_t(resource, *arr)
        i18n_raw(resource, arr).html_safe
      end

      # Our internationalized asciidoctor that properly processes
      # accents and special characters into HTML characters.
      def i18n_asciidoc(resource, *arr)
        # puts "Using ansiidoc on file #{resource}"
        asciidoc(i18n_raw(resource, *arr)).html_safe
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
