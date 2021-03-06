require 'desktop/osx/database'

module Desktop
  class OSX
    attr_reader :desktop_image_path, :skip_reload, :skip_database
    class DesktopImagePermissionsError < StandardError; end
    class DesktopImageMissingError < StandardError; end

    def self.desktop_image=(image)
      self.new.desktop_image = image
    end

    def self.update_desktop_image_permissions
      self.new.update_desktop_image_permissions
    end

    def self.chown_command
      self.new.chown_command
    end

    def self.chmod_command
      self.new.chmod_command
    end

    def initialize(options = nil)
      options ||= {}
      @skip_reload = options[:skip_reload]
      @skip_database = options[:skip_database]
      @desktop_image_path = \
        options[:desktop_image_path] || default_desktop_image_path
    end

    def desktop_image=(image)
      write_default_desktop image
      clear_custom_desktop_image unless skip_database
      reload_desktop unless skip_reload
    rescue Errno::EACCES => e
      raise DesktopImagePermissionsError.new(e)
    rescue Errno::ENOENT => e
      raise DesktopImageMissingError.new(e)
    end

    def update_desktop_image_permissions
      system(chown_command) && system(chmod_command)
    end

    def chown_command
      "sudo chown root:staff #{desktop_image_path}"
    end

    def chmod_command
      "sudo chmod 664 #{desktop_image_path}"
    end

    private

    def write_default_desktop(image)
      File.open(desktop_image_path, 'w') do |desktop|
        desktop.write image.data
      end
    end

    def clear_custom_desktop_image
      db = Database.new
      db.clear_desktop_image
      db.close
    end

    def reload_desktop
      system 'killall Dock'
    end

    def default_desktop_image_path
      '/System/Library/CoreServices/DefaultDesktop.jpg'
    end
  end
end
