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
      config = @context.registers[:site].config
      cache_dir = config['gist_cache']

      # Is cache enabled?
      if cache_dir
        # Construct the filenames for the cache and etags store; file_id is used
        # as the etag key and also the gist cache filename.
        file_id = "#{id}_#{file.gsub(/[^A-Za-z0-9\._]/, '_')}"
        filename = File.join(cache_dir, file_id)
        etag_filename = File.join(cache_dir, 'etags.yml')

        # Create the cache directory if it doesn't exist.
        FileUtils.mkdir_p(cache_dir) unless File.directory?(cache_dir)

        begin
          # Attempt to load the etags YAML store, if it isn't aleady loaded.
          @etags_store ||= YAML::load_file(etag_filename)
          # Now attempt to load the cache file.
          js = File.open(filename, 'r') { |f| f.read }
        rescue Errno::ENOENT
          @etags_store ||= {}
        end
      end

      # Should we be checking github for this gist?
      if js.nil? || config['reload_gists']
        sess = Patron::Session.new
        sess.timeout = 30
        sess.base_url = 'http://gist.github.com'

        # Set the etag header if we know that we have a local cache.
        sess.headers['If-None-Match'] = @etags_store[file_id] if js

        # Fetch the gist data from github, can you dig it?
        resp = sess.get("/#{id}.js?file=#{CGI.escape(file)}")

        if resp.status == 200
          js = resp.body

          # If we have the cache_dir setting then assume caching is enabled.
          if cache_dir
            File.open(filename, 'w') { |f| f.write(js) }

            # Update the etag stuff.
            @etags_store[file_id] = resp.headers['ETag']
            # Write to the store file.
            File.open(etag_filename, 'w') { |f| YAML::dump(@etags_store, f) }
          end
        end
      end

      js = js.match(/document.write\('(<div.+)'\)/)[1]
      js = js.gsub(/\\"/, '"').gsub(/\\\//, '/').gsub(/\\n/, '').gsub(/\\'/, '');
      # Attempt to create valid HTML.
      js = js.gsub(/ id="LC([0-9]+)"/, '').gsub(/ id="gist-([0-9]+)"/, '')
      js = js.gsub(/<pre>(.*)<\/pre>/) { |s|
        "<pre>#{$1.gsub(/<div/, '<span').gsub(/<\/div>/, '</span>')}</pre>"
      }
      js.gsub(/href="([^"]*)"/) { |s| %Q{href="#{$1.gsub(/\s/, '%20')}"} }
    end
  end
end