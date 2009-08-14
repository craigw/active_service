module ActiveService
  class Message
    attr_accessor :correlation_id, :processor, :created_at, :payloads, :errors

    def initialize
      self.created_at = Time.now
      self.payloads = []
      self.errors = []
    end

    def correlates_to(message)
      self.correlation_id = (Hpricot(message.body) / "correlation-id text()")[0].to_s
    end

    def created_by(processor)
      self.processor = processor
    end

    def to_xml
      xml = ""
      options = { :target => xml}
      options[:indent] = 2 if $DEBUG
      doc = Builder::XmlMarkup.new(options)
      doc.instruct!
      doc.result {
        doc.tag!("correlation-id", correlation_id)
        doc.tag!("processed-by", processor.id)
        doc.tag!("created-at", created_at.xmlschema(3))
        doc.payloads {
          payloads.each do |content|
            doc.payload { doc.cdata!(content) }
          end
        } if payloads.any?
        doc.errors {
          errors.each do |error|
            doc.error { doc.cdata!(error) }
          end
        } if errors.any?
      }
      xml
    end
  end
end