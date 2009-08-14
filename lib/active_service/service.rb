module ActiveService
  class Service
    include Configuration

    def self.run
      new.run
    end

    def process(message)
      reply = Message.new
      reply.created_by(self)
      reply.correlates_to(message)

      begin
        case
        when command?(message)
          extract_commands(message).each { |command|
            result = Command.new(serviced_class, command).execute
            reply.payloads << result.to_xml
          }
        else
          reply.errors << Error.new("Unrecognised message format")
        end
      rescue => e
        reply.errors << "Exception (#{e.class}): #{e.message}.\n#{e.backtrace.join("\n")}"
      end

      reply_to(message, reply)
    end

    def reply_to(trigger, reply)
      Thread.new do
        destination = reply_channel(trigger)
        xml = reply.to_xml
        puts xml if $DEBUG
        destination.put(xml)
        destination.close
      end
    end

    def id
      "/#{hostname}/#{service_name}/#{Process.pid}"
    end

    def hostname
      @hostname ||= `hostname`.strip
    end

    def reply_channel(reply_to)
      reply_configuration = configuration.dup
      reply_configuration.merge!(
        :queue => (Hpricot(reply_to.body) / "reply-to queue text()")[0].to_s
      )
      SMQueue(:configuration => reply_configuration)
    end

    def command?(message)
      extract_commands(message).any?
    end

    def extract_commands(message)
      (Hpricot(message.body) / "command").to_a
    end

    def run
      @client.get { |message| process message }
    end
  end
end