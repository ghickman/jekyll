require File.dirname(__FILE__) + '/helper'

class TestArchive < Test::Unit::TestCase
  def setup_post(file)
    Post.new(@site, source_dir, '', file)
  end

  def do_render(post)
    layouts = { "default" => Layout.new(@site, source_dir('_layouts'), "simple.html")}
    post.render(layouts, {"site" => {"posts" => []}})
  end

  context "when in a site" do
    setup do
      clear_dest
      stub(Jekyll).configuration { Jekyll::DEFAULTS }
      @site = Site.new(Jekyll.configuration)
       @site.process
                     
    end

    should "have to collated posts in years, month and days" do      
      assert_equal(5, @site.collated[2008].size)
      assert_equal(4, @site.collated[2009].size)
      assert_equal(1, @site.collated[2010].size)
      assert_equal(2, @site.collated[2010][1].size)      
      assert_equal(2, @site.collated[2009][5].size)
      assert_equal(4, @site.collated[2009][5][18].size)      
    end
  end
end
