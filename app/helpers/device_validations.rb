module DeviceValidations
  extend ActiveSupport::Concern

  def ensure_daemon_exists
    if self.daemon_name.blank? || @daemon.blank?
      raise Device::NoDaemonException.new("No daemon")
    end
  end

  included do
    def self.before_method(method_names, prepend, &block)
      @_override_methods ||= {}
      method_names = Array.wrap(method_names)
      method_names.each do |method_name|
        @_override_methods[method_name] = prepend || block
      end
    end
    def self.method_added(method_name)
      @_override_methods ||= {}
      if prepend = @_override_methods.delete(method_name)
        instance_method = self.instance_method(method_name)
        define_method(method_name) do |*args, &orig_block|
          if prepend.is_a?(Proc)
            prepend.bind(self).call
          else
            self.send(prepend)
          end
          instance_method.bind(self).call(*args, &orig_block)
        end
      end
    end


    before_save :check_valid_address
    validates_uniqueness_of :address, :scope => :type
  end
  
end
