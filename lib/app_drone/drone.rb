module AppDrone

Param = Struct.new('Param',:name,:type,:options)

class Drone
  # align: set up variables, pass off to other scripts
  # execute: actual install process

  # New
  def initialize(template,*params)
    @template = template
    @params = params.first # weird.. no idea why
    setup
  end

  def param(sym)
    (@params || {})[sym]
  end

  # DSL
  def ^; @template end # This is never used, not even sure if it works (something about a misplaced '.' error)
  def >>(klass); @template.hook(klass); end

  def method_missing(meth, *args, &block)
    if Drone.drones.include?(meth)
      klass = meth.to_app_drone_class
      return (self >> klass)
    else
      super
    end
  end

  def pair?(drone_symbol)
    drone_klass = ('AppDrone::' + drone_symbol.to_s.classify).constantize
    return @template.hook?(drone_klass)
  end

  # Expected implementations
  def align; end
  def execute; end

  # Optional implementations
  def setup; end

  def render(partial, opts={})
    class_name = self.class.to_s.split('::').last.underscore
    template_path = "/drones/#{class_name}/#{partial}.erb"
    full_path = File.dirname(__FILE__) + template_path
    snippet = ERB.new File.read(full_path)
    output = snippet.result(binding)
    output = "# --- \n# #{self.class.to_s}\n# ---\n" + output unless opts[:skip_stamp]
    return output
  end

  def do!(partial)
    @template.do! render(partial), self
  end

  # DSL: Integration-specific options
  attr_accessor :params
  class << self  
    def param_with(drone_klass, name, type, *options)
      param(name,type,options.first.merge({ with: drone_klass }))
    end

    def param(name, type, *options)
      (@params ||= []) << Param.new(name, type, options.first)
    end
    def params
      @params
    end

    def desc(d='')
      return @description if d.blank?
      @description = d
    end

    def depends_on(*klass_symbols); @dependencies = klass_symbols end
    def dependencies
      (@dependencies || []).map(&:to_app_drone_class)
    end

    def pairs_with(*klass_symbols); @pairs = klass_symbols end
    def pairs
      (@pairs || []).map(&:to_app_drone_class)
    end

    def owns_generator_method(m); @generator_method = m end
    def generator_method; @generator_method end

    def drones
      self.descendants.map { |d| d.to_s.split('::').last.underscore.to_sym }
    end

  end

end

end