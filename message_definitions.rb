class MessageDefinitions
  
  def self.define_message(message_type, opts = {}, &block)
    definer = DefinedMessage.new
    definer.load_message_from(&block)
    @@definitions ||= {}
    @@definitions[message_type.to_s] ||= []
    opts[:version] ||= 1
    definer.version = opts[:version]
    @@definitions[message_type.to_s][opts[:version]] = definer
  end
  
  def self.get_definition_for(message_type, version_or_device = nil)
    @@definitions ||= {}
    @@definitions[message_type.to_s] ||= []
    if version_or_device.is_a?(Device)
      version_to_use = version_or_device.get_version_for_message_type(message_type.to_s)
      if version_to_use == :latest
        @@definitions[message_type.to_s].last
      else
        @@definitions[message_type.to_s][version_to_use]
      end
    elsif version_or_device
      @@definitions[message_type.to_s][version_or_device]
    else
      @@definitions[message_type.to_s].last
    end
  end
    
end