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
        if (document / "result errors error").to_a.any?
          @return_value = "Error: " + (document / "result errors error").to_a.map{ |error| error.children }.join("\n")
        else
          @return_value = (document / "result payloads payload").to_a[0].children
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