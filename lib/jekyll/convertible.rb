# Convertible provides methods for converting a pagelike item
# from a certain type of markup into actual content
#
# Requires
#   self.site -> Jekyll::Site
#   self.content=
#   self.data=
#   self.ext=
#   self.output=
module Jekyll
  module Convertible
    # Return the contents as a string
    def to_s
      if self.respond_to?(:extended)
        (self.content || '') + (self.extended || '')
      else
        self.content || ''
      end
    end

    # Read the YAML frontmatter
    #   +base+ is the String path to the dir containing the file
    #   +name+ is the String filename of the file
    #
    # Returns nothing
    def read_yaml(base, name)
      self.content = File.read(File.join(base, name))

      if self.content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
        self.content = self.content[($1.size + $2.size)..-1]
        self.data = YAML.load($1)
        # if we have an extended section, separate that from content
        if self.respond_to?(:extended)
          if self.data && self.data.key?('extended')
            marker = self.data['extended']
            self.content, self.extended = self.content.split(marker + "\n", 2)
          end
        end
      end

      self.data ||= {}

      self.data = Hashie::Mash.new(self.data) if self.site.config['haml']
    end

    # Generate a usable hash of HAML options from _config.yml.
    #
    # Returns hash
    def haml_engine_options
      # Default to using " for attribute wrapping, this can be overridden in
      # the _config.yml if needs be? O_o
      options = { :attr_wrapper => %{"} }
      # Convert the keys to symbols, so we don't have to do
      # ::format in the yml.
      options.merge!(site.config['haml'].inject({}) { |result, item|
        result[item.first.to_sym] = item.last
        result
      }) if site.config['haml'].is_a?(Hash)

      options
    end

    # Transform the contents based on the file extension.
    #
    # Returns nothing
    def transform
      case self.content_type
      when 'textile'
        self.ext = ".html"
        self.content = self.site.textile(self.content)
        if self.respond_to?(:extended) and self.extended
          self.extended = RedCloth.new(self.extended).to_html
        end
      when 'markdown'
        self.ext = ".html"
        self.content = self.site.markdown(self.content)
        if self.respond_to?(:extended) and self.extended
          self.extended = self.site.markdown(self.extended)
        end
      when 'haml'
        self.ext = self.data[:output_ext] || '.html'
        self.content = Haml::Engine.new(self.content, self.haml_engine_options)
      end
    end

    # Determine which formatting engine to use based on this convertible's
    # extension
    #
    # Returns one of :textile, :markdown, :haml or :unknown
    def content_type
      case self.ext[1..-1]
      when /textile/i
        return 'textile'
      when /markdown/i, /mkdn/i, /md/i, /mkd/i
        return 'markdown'
      when /haml/i
        return 'haml'
      end
      return 'unknown'
    end

    # Sets up a context for Haml and renders in it. The context has accessors
    # matching the passed-in hash, e.g. "site", "page" and "content", and has
    # helper modules mixed in.
    #
    # Returns String.
    def render_haml_in_context(haml_engine, params={})
      context = Hashie::Mash.new(params)
      context.extend(HamlHelpers)
      haml_engine.render(context)
    end

    # Add any necessary layouts to this convertible document
    #   +layouts+ is a Hash of {"name" => "layout"}
    #   +site_payload+ is the site payload hash
    #
    # Returns nothing
    def do_layout(payload, layouts)
      info = { :filters => [Jekyll::Filters], :registers => { :site => self.site } }
      
      # render and transform content (this becomes the final content of the object)
      payload["content_type"] = self.content_type

      if self.content_type == "haml"
        haml_payload = {
          :site => self.site,
          :page => Hashie::Mash.new(payload['page'])
        }
        haml_payload.merge!(
          :paginator => Hashie::Mash.new(payload['paginator'])
        ) unless payload['paginator'].nil?
        self.transform
        self.content = render_haml_in_context(self.content, haml_payload)
      else
        self.content = Liquid::Template.parse(self.content).render(payload, info)
        if self.respond_to?(:extended) && self.extended
          self.extended = Liquid::Template.parse(self.extended).render(payload, info)
        end
      self.transform
      end

      # output keeps track of what will finally be written
      if self.respond_to?(:extended) && self.extended
        self.output = self.content + self.extended
      else
        self.output = self.content
      end

      # recursively render layouts
      layout = layouts[self.data["layout"]]
      while layout
        
        payload = payload.deep_merge({"content" => self.output, "page" => layout.data})

        if site.config['haml'] && layout.content.is_a?(Haml::Engine)
          haml_payload = {
            :site => Hashie::Mash.new(payload['site']),
            :page => Hashie::Mash.new(payload['page']),
            :content => payload['content']
          }
          haml_payload.merge!(
            :paginator => Hashie::Mash.new(payload['paginator'])
          ) unless payload['paginator'].nil?

          self.output = render_haml_in_context(layout.content, haml_payload)
        else
          self.output = Liquid::Template.parse(layout.content).render(payload, info)
        end

        layout = layouts[layout.data["layout"]]
      end
    end
  end
end
