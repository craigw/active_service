module ActiveService
  class Service
    include Configuration

    def self.run
      new.run
    end

    def process(message)
      result = nil

      begin
        case
        when command?(message)
          result = process_command(*extract_commands(message))
        else
          error message, "Unrecognised message"
        end
      rescue => e
        error message, "Exception (#{e.class}): #{e.message}.\n#{e.backtrace.join("\n")}"
      end

      if result
        reply_to(message, result)
      end
    end

    def error(trigger, value)
      reply_to(trigger, value, :error)
    end

    def reply_to(trigger, value, mode = :result)
      Thread.new do
        destination = reply_channel(trigger)
        message = {
          "processor-id" => id,
          "processed-at" => Time.now.strftime("%Y-%m-%dT%H:%M:%S%Z"),
          "correlation-id" => (Hpricot(trigger.body) / "correlation-id text()")[0].to_s,
          "#{mode}" => value
        }
        xml = message.to_xml(:root => "reply")
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

    def process_command(*commands)
      commands.map do |command|
        Command.new(serviced_class, command).execute
      end
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