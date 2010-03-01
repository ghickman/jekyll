require 'cgi'

module Jekyll
  module HamlHelpers

    def xml_escape(input)
      CGI.escapeHTML(input)
    end

    def cgi_escape(input)
      CGI::escape(input)
    end

    # Taken from github.com/imathis/octopress
    # A very hackish way to handle partials.  We'll go with it till it breaks...
    def include(partial_name)
      file_ext = partial_name[(partial_name.index('.') + 1)..partial_name.length]
      return '' unless File.exists?("_includes/#{partial_name}")
      contents = IO.read("_includes/#{partial_name}")

      case file_ext
      when 'haml'
        Haml::Engine.new(contents).render(binding)
      when 'textile'
        RedCloth.new(contents).to_html
      when 'markdown'
        RDiscount.new(contents).to_html
      else
        contents
      end
    end

    # Some helpers related to archive support.
    def days_to_post_count(days=[])
      days.inject(0) {|res, days| res + days.last.length }
    end

    def to_month(input)
      return Date::MONTHNAMES[input.to_i]
    end

    def to_month_abbr(input)
      return Date::ABBR_MONTHNAMES[input.to_i]
    end

    def to_month_i(int)
      case int.to_s.size
      when 1 then '0' + int.to_s
      when 2 then int
      end
    end

  end # HamlHelpers
end # Jekyll