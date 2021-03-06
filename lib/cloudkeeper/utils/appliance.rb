module Cloudkeeper
  module Utils
    module Appliance
      def log_expired(expirable, message)
        logger.info "#{message} #{expirable.identifier.inspect}"
      end

      def clean_image_files(appliance)
        return unless appliance && appliance.image

        logger.debug "Cleaning downloaded image files for appliance #{appliance.identifier.inspect}"
        appliance.image.image_files.each { |image_file| clean_image_file image_file.file }
      rescue ::IOError => ex
        logger.warn "Appliance cleanup error: #{ex.message}"
      end

      def clean_image_file(filename)
        File.delete(filename) if File.exist?(filename)
      end

      def update_image?(image_list_appliance, backend_appliance)
        image_list_appliance.image.digest != backend_appliance.image.digest
      end

      def update_metadata?(image_list_appliance, backend_appliance)
        image_list_appliance.digest != backend_appliance.digest
      end

      def prepare_image!(appliance)
        image_file = Cloudkeeper::Managers::ImageManager.secure_download_image(appliance.image.uri, appliance.image.checksum)
        appliance.image.add_image_file image_file
        return if acceptable_formats.include? image_file.format

        convert_image! appliance, image_file
      end

      def convert_image!(appliance, image_file)
        format = acceptable_formats.find { |acceptable_format| image_file.respond_to? "to_#{acceptable_format}".to_sym }
        unless format
          raise Cloudkeeper::Errors::Image::Format::NoRequiredFormatAvailableError,
                "image #{image_file.inspect} cannot be converted to any acceptable format"
        end

        appliance.image.add_image_file image_file.send("to_#{format}".to_sym)
      rescue Cloudkeeper::Errors::Image::Format::NoRequiredFormatAvailableError, Cloudkeeper::Errors::CommandExecutionError,
             Cloudkeeper::Errors::ArgumentError, ::IOError, ::SystemCallError => ex
        raise Cloudkeeper::Errors::Image::ConversionError, "Image #{appliance.image.uri.inspect} conversion error: #{ex.message}"
      end
    end
  end
end
