module ActiveService
  module Configuration
    def initialize
      @client = SMQueue(:configuration => configuration)
    end

    def serviced_class
      base_name = self.class.name.split(/::/, 3)[-1]
      case self
      when ActiveService::Service
        base_name.gsub!(/Service$/, '')
      when ActiveService::Client
        base_name.gsub!(/Client$/, '')
      end
      Kernel.const_get(base_name)
    end

    def reply_configuration
      reply_configuration = configuration.dup
      reply_configuration.delete(:queue)
      reply_configuration[:queue] = "temporary.active-service.client.#{Process.pid}-#{Time.now.to_i}-#{(rand * 1_000_000_000).to_i}"
      reply_configuration
    end

    def configuration
      configuration = YAML.load(raw_configuration)[RAILS_ENV][service_name]
      configuration.keys.each do |k|
        configuration[k.to_s.to_sym] = configuration.delete(k)
      end
      configuration
    end

    def raw_configuration
      if File.exists?(configuration_file)
        open(configuration_file).read
      else
        default_configuration.to_yaml
      end
    end

    def default_configuration
      {
        RAILS_ENV => {
          service_name => {
            :adapter => "AmqpAdapter",
            :queue => "#{service_name}.commands"
          }
        }
      }
    end

    def service_name
      serviced_class.to_s.underscore.downcase.pluralize
    end

    def configuration_file
      File.expand_path(RAILS_ROOT + "/config/services.yml")
    end
  end
end