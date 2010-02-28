module Jekyll

  class Archive < Page
    # Initialize a new Archive.
    #   +base+ is the String path to the <source>
    #   +dir+ is the String path between <source> and the file
    #
    # Returns <Archive>
    def initialize(site, base, dir, type)
      unless site.layouts['category_index'].nil?
        ext = File.extname(site.layouts['category_index'].name)
      end
      ext ||= '.html'

      @site = site
      @base = base
      @dir = dir
      @name = "index#{ext}"

      self.process(@name)

      self.read_yaml(File.join(base, '_layouts'), type + ext)

      # Default to an empty list of posts.
      self.set_posts!([])

      year, month, day = dir.split('/')
      self.data['year'] = year.to_i
      month and self.data['month'] = month.to_i
      day and self.data['day'] = day.to_i

      unless self.data['title'].nil?
        self.data['title'].gsub!(/%year%/, year)
        if month
          self.data['title'].gsub!(/%month%/, month)
          self.data['title'].gsub!(/%str_month%/, Date::MONTHNAMES[month.to_i])
        end
        self.data['title'].gsub!(/%day%/, day) if day
        self.data['title'].gsub!(/%str_day%/, Date::DAYNAMES[day.to_i])
      end
    end

    def set_posts!(posts=nil)
      self.data['archive_posts'] = posts unless posts.nil?
    end
  end

end