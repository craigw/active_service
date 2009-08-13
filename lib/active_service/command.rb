module ActiveService
  class Command
    def initialize(principal, command_document)
      @principal = principal
      @command_document = command_document
    end

    def execute
      case command
      when :find
        @principal.find(id)
      when :update
        @principal.find(id).update_attributes!(attributes)
        @principal
      when :create
        @principal.create!(attributes)
        @principal
      when :delete
        @principal.destroy(id)
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