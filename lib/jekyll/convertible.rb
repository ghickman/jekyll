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
      end
    end

    # Determine which formatting engine to use based on this convertible's
    # extension
    #
    # Returns one of :textile, :markdown or :unknown
    def content_type
      case self.ext[1..-1]
      when /textile/i
        return 'textile'
      when /markdown/i, /mkdn/i, /md/i, /mkd/i
        return 'markdown'
      end
      return 'unknown'
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
      self.content = Liquid::Template.parse(self.content).render(payload, info)
      if self.respond_to?(:extended) && self.extended
        self.extended = Liquid::Template.parse(self.extended).render(payload, info)
      end
      self.transform

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
        self.output = Liquid::Template.parse(layout.content).render(payload, info)

        layout = layouts[layout.data["layout"]]
      end
    end
  end
end
