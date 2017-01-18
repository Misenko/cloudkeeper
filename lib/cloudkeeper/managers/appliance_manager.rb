module Cloudkeeper
  module Managers
    class ApplianceManager
      attr_reader :backend_connector, :image_list_manager, :acceptable_formats

      def initialize
        @backend_connector = Cloudkeeper::BackendConnector.new
        @image_list_manager = Cloudkeeper::Managers::ImageListManager.new
        @acceptable_formats = Cloudkeeper::Settings[:formats].map(&:to_sym)
      end

      def synchronize_appliances
        backend_image_lists = backend_connector.image_lists
        image_list_manager.download_image_lists

        backend_connector.pre_action

        sync_expired_image_lists
        sync_new_image_lists(backend_image_lists)
        sync_old_image_lists(backend_image_lists)

        backend_connector.post_action
      end

      private

      def sync_expired_image_lists
        logger.debug 'Removing appliances from expired image lists...'
        image_list_manager.image_lists.each_value do |image_list|
          backend_connector.remove_image_list image_list if image_list.expired?
        end
      end

      def sync_new_image_lists(backend_image_lists)
        logger.debug 'Registering appliances from new image lists...'
        add_list = image_list_manager.image_lists.keys - backend_image_lists
        add_list.each do |image_list_identifier|
          image_list_manager.image_lists[image_list_identifier].appliances.each_value { |appliance| add_appliance appliance }
        end
      end

      def sync_old_image_lists(backend_image_lists)
        logger.debug 'Synchronizing registered appliances...'
        sync_list = image_list_manager.image_lists.keys & backend_image_lists
        sync_list.each { |image_list_identifier| sync_image_list image_list_identifier }
      end

      def sync_image_list(image_list_identifier)
        backend_appliances = backend_connector.appliances image_list_identifier
        image_list_appliances = image_list_manager.image_lists[image_list_identifier].appliances

        remove_appliances backend_appliances, image_list_appliances
        add_appliances backend_appliances, image_list_appliances
        update_appliances backend_appliances, image_list_appliances
      end

      def remove_appliances(backend_appliances, image_list_appliances)
        logger.debug 'Removing previously registered appliances...'
        remove_list = backend_appliances.keys - image_list_appliances.keys
        remove_list.each { |appliance_identifier| backend_connector.remove_appliance image_list_appliances[appliance_identifier] }
      end

      def add_appliances(backend_appliances, image_list_appliances)
        logger.debug 'Registering new appliances...'
        add_list = image_list_appliances.keys - backend_appliances.keys
        add_list.each { |appliance_identifier| add_appliance image_list_appliances[appliance_identifier] }
      end

      def update_appliances(backend_appliances, image_list_appliances)
        logger.debug 'Updating appliances...'
        update_list = backend_appliances.keys & image_list_appliances.keys
        update_list.each do |appliance_identifier|
          image_list_appliance = image_list_appliances[appliance_identifier]
          backend_appliance = backend_appliances[appliance_identifier]

          image_update = update_image?(image_list_appliance, backend_appliance)
          image_list_appliance.image = nil unless image_update
          update_appliance image_list_appliance if image_update || update_metadata?(image_list_appliance, backend_appliance)
        end
      end

      def clean_image_files(appliance)
        return unless appliance.image

        logger.debug "Cleaning downloaded image files for appliance #{appliance.identifier.inspect}"
        appliance.image.image_files.each { |image_file| File.delete(image_file.file) if File.exist?(image_file.file) }
      end

      def update_image?(image_list_appliance, backend_appliance)
        image_list_image = image_list_appliance.image
        backend_image = backend_appliance.image

        image_list_image.uri != backend_image.uri ||
          image_list_image.checksum != backend_image.checksum ||
          image_list_image.size != backend_image.size
      end

      def update_metadata?(image_list_appliance, backend_appliance)
        image_list_appliance.attributes != backend_appliance.attributes
      end

      def update_appliance(appliance)
        modify_appliance :update_appliance, appliance
      end

      def add_appliance(appliance)
        modify_appliance :add_appliance, appliance
      end

      def modify_appliance(method, appliance)
        prepare_image!(appliance) if appliance.image
        backend_connector.send method, appliance
        clean_image_files appliance
      end

      def prepare_image!(appliance)
        image_file = Cloudkeeper::Managers::ImageManager.download_image(appliance.image.uri)
        appliance.image.add_image_file image_file
        return if acceptable_formats.include? image_file.format

        convert_image! appliance, image_file
      end

      def convert_image!(appliance, image_file)
        format = acceptable_formats.find { |acceptable_format| image_file.respond_to? "to_#{acceptable_format}".to_sym }
        raise NoRequiredFormatAvailableError, "image #{image.inspect} cannot be converted to any acceptable format" unless format

        appliance.image.add_image_file image_file.send("to_#{format}".to_sym)
      end
    end
  end
end