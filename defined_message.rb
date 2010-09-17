class DefinedMessage
  
  attr_accessor :version
  
  def load_message_from(&block)
    @last_to_s = 0
    @part_definitions = {}
    load_from_string = self.instance_eval(&block)
    # puts "loading from string: " + load_from_string
    @loaded_message = YAML::load(load_from_string)    
    # puts "looaded message: " + @loaded_message.to_yaml
  end
  
  def for_message_version(run_if_version_is)
    if(run_if_version_is.to_i == self.version.to_i)
      yield
    end
  end  
  
  def match_it(object, match_this, against_this)
    if match_this.is_a?(Hash)
      # puts "matching hash... " + match_this.inspect + "\nAgainst" + against_this.inspect
      match_this.each do |key, value|
        against_value = (against_this[key.to_sym] || against_this[key.to_s])

        #this line used to be "if against_value", but we need it to pass and populate 'false' values
        unless against_value.nil?
          # puts "key #{key} matches value #{against_value} " + " from: " +  against_this.inspect
          match_it(object, value, against_value)
        end
      end
    else
      # puts "now do something with " + match_this.inspect + " and " + against_this.inspect
      methods_to_call = @part_definitions[match_this]
      # puts "methods_to_call " + methods_to_call.inspect
      if methods_to_call.is_a?(Proc)
        unless methods_to_call.is_a?(ReadOnlyProc)
          methods_to_call.call(object, against_this)
        end
      elsif methods_to_call.is_a?(Array)
        # last_method = (methods_to_call.last.to_s+"=").to_sym
        # puts methods_to_call.inspect
        # puts last_method.inspect
        
        methods_to_call.each_with_index do |method_to, index|
          if(index == (methods_to_call.size - 1))
            object.send((methods_to_call.last.to_s+"=").to_sym, against_this)
          else
            object = object.send(method_to)
          end
        end
      end
    end
  end
  
  def create_it(object, match_this)

    to_return = {}
    if match_this.is_a?(Hash)
      match_this.each do |key, value|
        # puts "creating for key #{key}" if @logging
        to_return[key] = create_it(object, value)
        # puts "key #{key} yields value #{value} " + " which we store as: " +  to_return[key].inspect if @logging
      end
    else
      # puts "now do something with " + match_this.inspect if @logging
      
      methods_to_call = @part_definitions[match_this]
      
      # puts "methods_to_call " + methods_to_call.inspect if @logging
      
      if methods_to_call == nil && match_this.is_a?(Array) && object.respond_to?(:each)
        to_return = []
        object.each do |obj|
          to_return << create_it(obj, match_this.first)
        end
        return to_return
        # puts "ok we have array place holder, and object is #{object}"
      elsif methods_to_call.is_a?(Proc)
        if methods_to_call.is_a?(ReadOnlyProc)
          return methods_to_call.call(object)
        else
          raise "Proc is unsupported for create_it"
        end
      elsif methods_to_call.is_a?(Array)
        # puts "methods to call is an array! " if @logging
        methods_to_call.each_with_index do |method_to, index|
          return nil if object.nil?
          if(index == (methods_to_call.size - 1))
            return object.send(methods_to_call.last.to_sym)
          else
            object = object.send(method_to)
          end
        end
      elsif methods_to_call.nil?
        return match_this
      end
    end
    return to_return
  end
    
  def create_from(object)
    create_it(object, @loaded_message)
  end
  
  def apply_to(object, message_hash)
    # puts "apply_to"
    # puts message_hash.inspect
    # puts @loaded_message.inspect
    match_it(object, @loaded_message, message_hash)
  end
  
  def to_handle(named, &block)
    @procs_defined ||= {}
    @procs_defined[named] = "DefinedMessageProc#{@procs_defined.size.to_s}"
    @part_definitions[@procs_defined[named]] = block
  end
  
  class ReadOnlyProc < Proc
  end
  
  def to_handle_read_only(named, &block)
    @procs_defined ||= {}
    @procs_defined[named] = "DefinedMessageProc#{@procs_defined.size.to_s}"
    @part_definitions[@procs_defined[named]] = ReadOnlyProc.new(&block)
  end
  
  def method_missing(symbol, *args, &block)
    @procs_defined ||= {}
    @methods_to_call ||= []
    
    return @procs_defined[symbol.to_s] if @procs_defined[symbol.to_s]

    # puts symbol.inspect
    # puts args.inspect
    @methods_to_call << symbol
    self
  end
  
  def to_s
    to_return = "DefinedMessage"+ @methods_to_call.size.to_s
    # puts to_return + " is " + @methods_to_call[@last_to_s..-1].inspect
    @part_definitions[to_return] = @methods_to_call[@last_to_s..-1]
    @last_to_s = @methods_to_call.size
    return to_return
  end
  
end