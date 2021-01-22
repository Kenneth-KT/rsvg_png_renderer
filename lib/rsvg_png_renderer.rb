require 'fileutils'
require 'nokogiri'
require 'typhoeus'

class RsvgPngRenderer
  class << self
    def render_svg_to_png(svg_string: nil, svg_file: nil, rsvg_convert_path: nil)
      rsvg_convert_path ||= ENV['RSVG_CONVERT_PATH'] || 'rsvg-convert'
      svg_string ||= ::File.read(svg_file)
      svg_file = svg_localize_external_images(svg_string)
      output_file = Tempfile.create(['svg-render-', '.png']).tap { |f| f.close }
      system(rsvg_convert_path, svg_file.path, '-o', output_file.path)
      ::FileUtils.rm_rf(::File.dirname(svg_file.path))
      output_file
    end

    private

    def streaming_download_files_concurrently(urls, basedir:)
      hydra = Typhoeus::Hydra.new
      files = urls.map do |url|
        file = ::Tempfile.create(['download-', ''], basedir, binmode: true)
        request = Typhoeus::Request.new(url)
        request.on_body { |chunk| file.write(chunk) }
        request.on_complete { file.close }
        hydra.queue(request)
        file
      end
      hydra.run
      files
    end

    def svg_localize_external_images(svg_string)
      external_images_selector = [
        %{image[href^="http://"]},
        %{image[href^="https://"]},
        %{image[xlink|href^="http://"]},
        %{image[xlink|href^="https://"]}
      ].join(', ')

      tmpdir = ::Dir.mktmpdir

      svg = ::Nokogiri::XML(svg_string)
      external_image_tags = svg.css(external_images_selector)
      image_urls = external_image_tags.map do |t|
        t.attributes['href']&.value || t.attributes['xlink:href']&.value
      end
      image_files = streaming_download_files_concurrently(image_urls, basedir: tmpdir)

      external_image_tags.zip(image_files).each do |image_tag, image_file|
        href = if image_tag.attributes['xlink:href']&.value
                 image_tag.attributes['xlink:href']
               else
                 image_tag.attributes['href']
               end
        href.value = image_file.path
      end

      image_localized_svg_string = svg.to_s

      svg_file = ::Tempfile.create(['localized-', '.svg'], tmpdir)
      svg_file.write(image_localized_svg_string)
      svg_file.close

      svg_file
    end
  end
end
