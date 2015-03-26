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
      # need it in order to raw html output. This method as it tries to be
      # unsafe by default, do not use it unless you know what you're doing.
      # This method properly processes accents and special characters
      # found in our locale file into proper HTML entities.
      def i18n_raw(resource, *arr)
        # Rules for special characters conversion to HTML must be handled
        # by I18n transliteration rules.
        i18n_t(resource, *arr).html_safe
      end

      # Our safe to use version of our i18n.
      # it only unesescapes accents that have would otherwise be
      # doubly escaped.
      def i18n_t(resource, *arr)
        I18n.transliterate(I18n.translate(resource, *arr)).html_safe
      end

      # Our internationalized asciidoctor
      # This is not safe, do not allow anything through asciidoc that
      # has user input. You've been warned - ACP.
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


    # def base_url
    #   @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    # end

    helpers CAPHelper
  end
end
