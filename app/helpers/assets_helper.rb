module AssetsHelper

  def inline_js(path)
    "<script>#{inline_file path}</script>"
  end

  def inline_css(path)
    "<style>#{inline_file path}</style>"
  end

  private

  def read_file_contents(stylesheet)
    if %w(test development).include?(Rails.env.to_s)
      # if we're running the full asset pipeline,
      # just grab the body of the final output
      stylesheet.source
    else
      # in a production-like environment, read the
      # fingerprinted and compiled file
      File.read(File.join(Rails.root, 'public', 'assets', stylesheet.digest_path))
    end
  end

  def inline_file(path)
    file = Rails.application.assets.find_asset(path)
    file.nil? ? '' : read_file_contents(file)
  end
end
