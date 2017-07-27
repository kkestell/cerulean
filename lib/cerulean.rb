require 'boolean'

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
  class ParamsInvalid < StandardError
    attr_reader :errors
    def initialize(errors)
      @errors = errors
    end
  end

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

    def put(name, &block)
      endpoint(name, &block)
    end

    def delete(name, &block)
      endpoint(name, &block)
    end

    def endpoint(name, &block)
      self.class_variable_set(:@@meta, {}) unless self.class_variable_defined?(:@@meta)

      ActionDSL.new(self, name: name, &block)

      self.class_exec do
        require 'boolean'

        def declared()
          @declared ||= {} #Hashie::Mash.new(params)
        end

        def render_presenter(object, **opts)
          if object.is_a?(Array) || object.is_a?(ActiveRecord::Relation)
            if opts.any?
              object.map { |el| meta[:presenter].new(el).as_json(**opts) }
            else
              object.map { |el| meta[:presenter].new(el).as_json() }
            end
          else
            if opts.any?
              meta[:presenter].new(object).as_json(**opts)
            else
              meta[:presenter].new(object).as_json()
            end
          end
        end

        def present(object, **opts)
          render json: render_presenter(object, **opts)
        end

        def meta
          @meta ||= self.class.class_variable_get(:@@meta)[action_name.to_sym]
        end

        def validate_param_type(val, type)
          if val.is_a?(Array)
            parsed = val.map { |el| validate_param_type(el, type[0]) }
            parsed.all? { |el| !el.nil? } ? parsed : nil
          else
            if type == String
              val
            elsif type == Date
              Date.parse(val) rescue nil
            elsif type == DateTime
              DateTime.parse(val) rescue nil
            else
              Kernel.send(type.to_s, val) rescue nil
            end
          end
        end

        before_action do
          if meta.has_key?(:form)
            p = params
            p = p.permit! if params.respond_to?(:permit!)

            if meta[:form].has_key?(:key) && meta[:form][:key]
              p = params[meta[:form][:key]]
            end

            p = p&.to_hash&.deep_symbolize_keys

            @form = meta[:form][:klass].new(p)
          end

          if meta.has_key?(:params)
            @declared = {}
            errors = {}
            meta[:params].each do |param, opts|
              if params.has_key?(param.to_s)
                p = validate_param_type(params[param.to_s], opts[:type])

                if p.nil?
                  errors[param] ||= []
                  errors[param] << "#{param.to_s} is not a #{opts[:type].to_s.downcase}"
                else
                  if opts.has_key?(:min) || opts.has_key?(:max)
                    unless (Float(p) rescue false)
                      errors[param] ||= []
                      errors[param] << "must be a number"
                    end
                  end

                  if opts.has_key?(:min)
                    if p < opts[:min]
                      errors[param] ||= []
                      errors[param] << "must be greater than or equal to #{opts[:min]}"
                    end
                  end

                  if opts.has_key?(:max)
                    if p > opts[:max]
                      errors[param] ||= []
                      errors[param] << "must be less than or equal to #{opts[:max]}"
                    end
                  end

                  if opts.has_key?(:values)
                    unless opts[:values].map { |val| val.to_s }.include?(p.to_s)
                      errors[param] ||= []
                      errors[param] << "must be one of #{opts[:values]}"
                    end
                  end
                end

                @declared[param] = p
              else
                @declared[param] = opts[:default] if opts.has_key?(:default)
                if opts[:required]
                  errors[param] ||= []
                  errors[param] << "is required"
                end
              end
            end
            raise ParamsInvalid.new(errors) if errors.keys.any?
          end
        end
      end
    end
  end
end
