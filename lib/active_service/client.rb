module ActiveService
  class Client
    include Configuration

    def find(id)
      message = {
        "operation" => "find",
        "id" => id,
        "correlation-id" => correlation_id,
        "reply-to" => reply_channel.configuration
      }

      @return_value = nil
      return_thread = Thread.new do
        message = reply_channel.get
        document = Hpricot(message.body)
        correlation_id = (document / "correlation-id text()")[0]
        if (document / "reply error").to_a.any?
          @return_value = "Error: " + (document / "reply error text()").to_a.join("\n")
        else
          @return_value = (document / "reply result").to_a[0]
        end
      end
      command(message)
      return_thread.join
      @return_value
    end

    private
    def command(message)
      queue(message.to_xml(:root => "command"))
    end

    def queue(message)
      @client.put message
    end

    def correlation_id
      Digest::SHA1.hexdigest(Process.pid.to_s + '-' + Time.now.to_s)
    end

    def reply_channel
      @reply_channel ||= SMQueue.new(:configuration => reply_configuration)
    end
  end
end