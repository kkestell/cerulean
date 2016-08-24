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

        def validate_param_type(val, type)
          case type.to_s
          when 'Integer'
            Integer(val) rescue false
          when 'Float'
            Float(val) rescue false
          when 'Boolean'
            %w(true false).include?(val.downcase)
          when 'Array[Integer]'
            !val.any? { |el| !Integer(el) rescue true }
          when 'Array[Float]'
            !val.any? { |el| !Float(el) rescue true }
          when 'Array[Boolean]'
            !val.any? { |el| %w(true false).include?(el.downcase) }
          else
            true
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
                raise "#{param} is not a #{opts[:type]}" unless validate_param_type(params[param.to_s], opts[:type])

                if opts.has_key?(:min)
                  if Float(params[param]) < opts[:min]
                    raise "#{param} must be greater than or equal to #{opts[:min]}"
                  end
                end

                if opts.has_key?(:max)
                  if Float(params[param]) > opts[:max]
                    raise "#{param} must be less than or equal to #{opts[:max]}"
                  end
                end

                if opts.has_key?(:values)
                  unless opts[:values].include?(params[param])
                    raise "#{param} must be one of #{opts[:values]}"
                  end
                end

                @declared[param] = params[param]
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