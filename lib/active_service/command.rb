module ActiveService
  class Command
    def initialize(principal, command_document)
      @principal = principal
      @command_document = command_document
    end

    def execute
      case command
      when :find
        resource = @principal.find(id)
        resource
      when :update
        resource = @principal.find(id)
        resource.update_attributes!(attributes)
        resource
      when :create
        resource = @principal.create!(attributes)
        resource
      when :delete
        resource = @principal.find(id)
        resource.destroy
        resource
      else
        raise ArgumentError, "Unknown command: `#{command}`"
      end
    end

    def command
      (@command_document / "operation text()")[0].to_s.to_sym
    end

    def id
      (@command_document / "id text()")[0].to_s
    end
  end
end