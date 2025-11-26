# frozen_string_literal: true

namespace :extension do
  desc "Generate .env files for the Chrome extension"
  task :env do
    require 'yaml'

    rails_env = ENV['RAILS_ENV'] || 'development'
    extension_config = YAML.load_file(Rails.root.join('config/extension.yml'))[rails_env]

    env_content = <<~ENV
      # DexIQ Extension Environment Configuration
      # Generated at: #{Time.current}
      # Rails environment: #{rails_env}

      VITE_API_BASE_URL=#{extension_config['api_base_url']}
      VITE_WS_URL=#{extension_config['ws_url']}
      VITE_ENVIRONMENT=#{rails_env}
    ENV

    env_file_path = Rails.root.join("extensions/dexiq/.env.#{rails_env}")
    File.write(env_file_path, env_content)

    puts "✓ Extension environment file generated: #{env_file_path}"
  end

  desc "Generate manifest.json from template"
  task :manifest do
    require 'yaml'
    require 'erb'
    require 'json'

    rails_env = ENV['RAILS_ENV'] || 'development'
    extension_config = YAML.load_file(Rails.root.join('config/extension.yml'))[rails_env]

    template_path = Rails.root.join('extensions/dexiq/public/manifest.template.json')
    template_content = File.read(template_path)

    # Use ERB to render the template
    renderer = ERB.new(template_content)
    name = extension_config['name']
    version = extension_config['version']
    description = extension_config['description']
    host_permissions = extension_config['host_permissions']
    content_scripts_matches = extension_config['content_scripts_matches']

    rendered = renderer.result(binding)

    # Parse and re-format as JSON for consistency
    manifest_data = JSON.parse(rendered)
    manifest_json = JSON.pretty_generate(manifest_data)

    output_path = Rails.root.join('extensions/dexiq/public/manifest.json')
    File.write(output_path, manifest_json)

    puts "✓ Manifest generated: #{output_path}"
    puts "  Name: #{manifest_data['name']}"
    puts "  Version: #{manifest_data['version']}"
  end

  desc "Build the Chrome extension"
  task :build => [:env, :manifest] do
    extension_dir = Rails.root.join('extensions/dexiq')

    puts "Building Chrome extension..."

    # Check if node_modules exists
    unless Dir.exist?(extension_dir.join('node_modules'))
      puts "Installing dependencies..."
      system("cd #{extension_dir} && npm install") or abort("npm install failed")
    end

    # Run vite build
    puts "Running Vite build..."
    system("cd #{extension_dir} && npm run build") or abort("Build failed")

    puts "✓ Extension built successfully at: #{extension_dir}/dist"
  end

  desc "Package the extension for distribution"
  task :package => :build do
    require 'zip'

    extension_dir = Rails.root.join('extensions/dexiq')
    dist_dir = extension_dir.join('dist')
    rails_env = ENV['RAILS_ENV'] || 'development'

    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    zip_filename = "dexiq_v2_#{rails_env}_#{timestamp}.zip"
    zip_path = extension_dir.join(zip_filename)

    puts "Packaging extension..."

    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      Dir.glob("#{dist_dir}/**/*").each do |file|
        next if File.directory?(file)

        relative_path = file.sub("#{dist_dir}/", '')
        zipfile.add(relative_path, file)
      end
    end

    file_size = File.size(zip_path)
    puts "✓ Extension packaged: #{zip_path}"
    puts "  Size: #{(file_size / 1024.0 / 1024.0).round(2)} MB"
    puts "\n📦 Ready for upload to Chrome Web Store!"
  end

  desc "Clean build artifacts"
  task :clean do
    extension_dir = Rails.root.join('extensions/dexiq')

    puts "Cleaning build artifacts..."

    # Remove dist directory
    dist_dir = extension_dir.join('dist')
    FileUtils.rm_rf(dist_dir) if Dir.exist?(dist_dir)

    # Remove generated manifest
    manifest_path = extension_dir.join('public/manifest.json')
    File.delete(manifest_path) if File.exist?(manifest_path)

    # Remove env files
    Dir.glob(extension_dir.join('.env.*')).each do |env_file|
      File.delete(env_file)
    end

    puts "✓ Cleaned build artifacts"
  end

  desc "Development mode: build with watch"
  task :dev => [:env, :manifest] do
    extension_dir = Rails.root.join('extensions/dexiq')

    puts "Starting extension development server..."
    puts "Press Ctrl+C to stop"

    exec("cd #{extension_dir} && npm run dev")
  end
end
