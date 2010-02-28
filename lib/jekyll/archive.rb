module Jekyll

  class Archive < Page
    # Initialize a new Archive.
    #   +base+ is the String path to the <source>
    #   +dir+ is the String path between <source> and the file
    #
    # Returns <Archive>
    def initialize(site, base, dir, type)
      ext = File.extname(site.layouts['category_index'].name)
      @site = site
      @base = base
      @dir = dir
      @name = "index#{ext}"

      self.process(@name)

      self.read_yaml(File.join(base, '_layouts'), type + ext)

      year, month, day = dir.split('/')
      self.data['year'] = year.to_i
      month and self.data['month'] = month.to_i
      day and self.data['day'] = day.to_i

      unless self.data['title'].nil?
        self.data['title'].gsub!(/%year%/, year)
        self.data['title'].gsub!(/%month%/, month) if month
        self.data['title'].gsub!(/%day%/, day) if day
      end
    end
  end

end