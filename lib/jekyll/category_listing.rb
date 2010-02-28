module Jekyll
  # Detects the presence of category_index.html in the _layouts directory to
  # generate a listing of posts for that given category.
  #
  # The template has access to page.category and page.category_posts, as well as
  # the usual Jekyll stuff.
  #
  # The title, if set in the category_index.html file, will have %cat% replaced
  # with the category.
  # For example you could put;
  # title: Posts categorised as %cat%
  class CategoryListing < Page
    def initialize(site, base, dir, cat, posts)
      ext = File.extname(site.layouts['category_index'].name)

      @site = site
      @base = base
      @dir = dir
      @name = "index#{ext}"

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), "category_index#{ext}")

      self.data['category'] = cat
      self.data['category_posts'] = posts

      self.data['title'].gsub!(/%cat%/, cat) unless self.data['title'].nil?
    end
  end # CategoryListing
end # Jekyll