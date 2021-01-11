require 'em-http'
require 'eventmachine'
require 'fileutils'
require 'nokogiri'

class RsvgPngRenderer
  class << self
    def render_svg_to_png(svg_string: nil, svg_file: nil)
      svg_string ||= ::File.read(svg_file)
      svg_file = svg_localize_external_images(svg_string)
      output_file = Tempfile.create(['svg-render-', '.png']).tap { |f| f.close }
      system('rsvg-convert', svg_file.path, '-o', output_file.path)
      ::FileUtils.rm_rf(::File.dirname(svg_file.path))
      output_file
    end

    private

    def streaming_download_files_concurrently(urls, basedir:)
      files = []
      return files if urls.empty?

      ::EventMachine.run do
        multi = ::EventMachine::MultiRequest.new

        urls.each.with_index do |url, index|
          request = ::EventMachine::HttpRequest.new(url).get
          file = ::Tempfile.create(['download-', ''], basedir, binmode: true)
          request.stream { |chunk| file.write(chunk) }
          request.callback { file.close }
          files << file
          multi.add index, request
          multi.callback { ::EventMachine.stop }
        end
      end
      files
    end

    def svg_localize_external_images(svg_string)
      external_images_selector = [
        %{image[href^="http://"]},
        %{image[href^="https://"]}
      ].join(', ')

      tmpdir = ::Dir.mktmpdir

      svg = ::Nokogiri::XML(svg_string)
      external_image_tags = svg.css(external_images_selector)
      image_urls = external_image_tags.map { |t| t.attributes['href'] }
      image_files = streaming_download_files_concurrently(image_urls, basedir: tmpdir)

      external_image_tags.zip(image_files).each do |image_tag, image_file|
        image_tag.attributes['href'].value = image_file.path
      end

      image_localized_svg_string = svg.to_s

      svg_file = ::Tempfile.create(['localized-', '.svg'], tmpdir)
      svg_file.write(image_localized_svg_string)
      svg_file.close

      svg_file
    end
  end
end
