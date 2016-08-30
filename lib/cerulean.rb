module Boolean; end

class ActionDSL
  def initialize(controller, name:, &block)
    @controller = controller
    @name = name
    @meta = {}

    instance_eval(&block)

    # yuck
    meta = @controller.class_variable_get(:@@meta)
    meta[name] = @meta
    @controller.class_variable_set(:@@meta, meta)
  end

  def params(&block)
    instance_eval(&block)
  end

  def param(name, type=String, opts={})
    @meta[:params] ||= {}
    @meta[:params][name] = opts.merge({ type: type })
  end

  def presenter(presenter)
    @meta[:presenter] = presenter
  end

  def form(key=nil, klass)
    @meta[:form] = { key: key, klass: klass }
  end

  def request(&block)
    @controller.send(:define_method, @name, &block)
  end
end

module Cerulean
  def self.included(receiver)
    receiver.extend(ClassMethods)
  end

  module ClassMethods
    def get(name, &block)
      endpoint(name, &block)
    end

    def post(name, &block)
      endpoint(name, &block)
    end

    def endpoint(name, &block)
      self.class_variable_set(:@@meta, {}) unless self.class_variable_defined?(:@@meta)

      ActionDSL.new(self, name: name, &block)
    
      self.class_exec do
        def declared()
          @declared ||= {} #Hashie::Mash.new(params)
        end

        def present(object, **opts)
          if object.is_a?(Array) || object.is_a?(ActiveRecord::Relation)
            if opts.any?
              render json: object.map { |el| meta[:presenter].new(el).as_json(**opts) }
            else
              render json: object.map { |el| meta[:presenter].new(el).as_json() }
            end
          else
            if opts.any?
              render json: meta[:presenter].new(object).as_json(**opts)
            else
              render json: meta[:presenter].new(object).as_json()
            end
          end
        end

        def meta
          @meta ||= self.class.class_variable_get(:@@meta)[action_name.to_sym]
        end

        def parse_integer(val)
          Integer(val) rescue nil
        end

        def parse_float(val)
          Float(val) rescue nil
        end

        def parse_boolean(val)
          case val.to_s.downcase
          when 'true'
            true
          when 'false'
            false
          else
            nil
          end
        end

        def validate_param_type(val, type)
          if val.is_a?(Array)
            parsed = val.map { |el| validate_param_type(el, type[0].to_s) }
            parsed.all? ? parsed : nil
          else
            case type.to_s
            when 'Integer'
              parse_integer(val)
            when 'Float'
              parse_float(val)
            when 'Boolean'
              parse_boolean(val)
            when 'String'
              val
            end
          end
        end

        before_action do
          if meta.has_key?(:form)
            if meta[:form].has_key?(:key) && meta[:form][:key]
              @form = meta[:form][:klass].new(params[meta[:form][:key]])
            else
              @form = meta[:form][:klass].new(params)
            end
          end
          
          if meta.has_key?(:params)
            @declared = {}
            meta[:params].each do |param, opts|
              if params.has_key?(param.to_s)
                p = validate_param_type(params[param.to_s], opts[:type])
                
                if p.nil?
                  raise "#{param} is not a #{opts[:type]}"
                end

                if opts.has_key?(:min)
                  if p < opts[:min]
                    raise "#{param} must be greater than or equal to #{opts[:min]}"
                  end
                end

                if opts.has_key?(:max)
                  if p > opts[:max]
                    raise "#{param} must be less than or equal to #{opts[:max]}"
                  end
                end

                if opts.has_key?(:values)
                  unless opts[:values].map { |val| val.to_s }.include?(p.to_s)
                    raise "#{param} must be one of #{opts[:values]}"
                  end
                end

                @declared[param] = p
              else
                params[param] = opts[:default] if opts.has_key?(:default)
                raise "#{param} is required" if opts[:required]
              end
            end
          end
        end
      end
    end
  end
end