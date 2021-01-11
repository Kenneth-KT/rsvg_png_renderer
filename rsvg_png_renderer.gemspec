Gem::Specification.new do |s|
  s.name        = 'rsvg_png_renderer'
  s.version     = '1.0.0'
  s.date        = '2021-01-11'
  s.summary     = "RSVG to PNG renderer"
  s.description = "Render SVG to PNG with external images using RSVG"
  s.authors     = ["Kenneth Law"]
  s.email       = 'cyt05108@gmail.com'
  s.files       = ["lib/rsvg_png_renderer.rb"]
  s.homepage    =
    'https://github.com/Kenneth-KT/rsvg_png_renderer'
  s.license       = 'MIT'
  s.add_runtime_dependency 'em-http-request'
  s.add_runtime_dependency 'eventmachine'
  s.add_runtime_dependency 'nokogiri'
  s.post_install_message = <<-END
Notice that `rsvg_png_renderer` gem requires the executable
`rsvg-convert` to be present in your system, the packge is
usually named `librsvg` depending on your operating system 
or distribution.
Visit https://wiki.gnome.org/Projects/LibRsvg to learn more.
END
end
