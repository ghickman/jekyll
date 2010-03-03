module Jekyll

  module Filters
    def textilize(input)
      RedCloth.new(input).to_html
    end

    def date_to_string(date)
      date.strftime("%d %b %Y")
    end

    def date_to_long_string(date)
      date.strftime("%d %B %Y")
    end

    def date_to_xmlschema(date)
      date.xmlschema
    end

    def xml_escape(input)
      CGI.escapeHTML(input)
    end

    def cgi_escape(input)
      CGI::escape(input)
    end

    def number_of_words(input)
      input.split.length
    end

    def array_to_sentence_string(array)
      connector = "and"
      case array.length
      when 0
        ""
      when 1
        array[0].to_s
      when 2
        "#{array[0]} #{connector} #{array[1]}"
      else
        "#{array[0...-1].join(', ')}, #{connector} #{array[-1]}"
      end
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

    def gist(id, file='')
      # If the cache folder exists then attempt to find a cached version.
      if File.directory?('_gist_cache')
        cache = File.join(
          'gist_cache', "#{id}_#{file.gsub(/[^A-Za-z0-9\._]/, '_')}")
        js = open(cache).read if File.exists?(cache)
      end
      # If we have no cached version get the normal one.
      js ||= open("http://gist.github.com/#{id}.js?file=#{CGI.escape(file)}").read

      # If we don't arleady have a cached and the directory exists create one.
      if File.directory?('_gist_cache') && !File.exists?(cache)
        File.open(cache, 'w') { |f| f.write(js) }
      end

      js.match(/document.write\('(<div.+)'\)/)[1].gsub(/\\"/, '"').gsub(/\\\//, '/').gsub(/\\n/, '')
    end
  end
end