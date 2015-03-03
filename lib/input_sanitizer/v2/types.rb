require 'active_support/core_ext/object/blank'

module InputSanitizer::V2::Types
  class IntegerCheck
    def call(value, options = {})
      if value == nil && (options[:allow_nil] == false || options[:allow_blank] == false || options[:required] == true)
        raise InputSanitizer::ValueMissingError
      elsif value == nil
        value
      else
        Integer(value).tap do |integer|
          raise InputSanitizer::TypeMismatchError.new(value, :integer) unless integer == value
          raise InputSanitizer::ValueError.new(value, options[:minimum], options[:maximum]) if options[:minimum] && integer < options[:minimum]
          raise InputSanitizer::ValueError.new(value, options[:minimum], options[:maximum]) if options[:maximum] && integer > options[:maximum]
        end
      end
    rescue ArgumentError, TypeError
      raise InputSanitizer::TypeMismatchError.new(value, :integer)
    end
  end

  class CoercingIntegerCheck
    def call(value, options = {})
      Integer(value).tap do |integer|
        raise InputSanitizer::ValueError.new(value, options[:minimum], options[:maximum]) if options[:minimum] && integer < options[:minimum]
        raise InputSanitizer::ValueError.new(value, options[:minimum], options[:maximum]) if options[:maximum] && integer > options[:maximum]
      end
    rescue ArgumentError
      raise InputSanitizer::TypeMismatchError.new(value, :integer)
    end
  end

  class StringCheck
    def call(value, options = {})
      if options[:allow] && !options[:allow].include?(value)
        raise InputSanitizer::ValueNotAllowedError.new(value)
      elsif value.blank? && (options[:allow_blank] == false || options[:required] == true)
        raise InputSanitizer::ValueMissingError
      elsif value == nil && options[:allow_nil] == false
        raise InputSanitizer::ValueMissingError
      elsif value.blank?
        value
      else
        value.to_s.tap do |string|
          raise InputSanitizer::TypeMismatchError.new(value, :string) unless string == value
        end
      end
    end
  end

  class BooleanCheck
    def call(value, options = {})
      if value == nil
        raise InputSanitizer::ValueMissingError
      elsif [true, false].include?(value)
        value
      else
        raise InputSanitizer::TypeMismatchError.new(value, :boolean)
      end
    end
  end

  class CoercingBooleanCheck
    def call(value, options = {})
      if [true, 'true'].include?(value)
        true
      elsif [false, 'false'].include?(value)
        false
      else
        raise InputSanitizer::TypeMismatchError.new(value, :boolean)
      end
    end
  end

  class DatetimeCheck
    def call(value, options = {})
      if value.blank? && (options[:allow_blank] == false || options[:required] == true)
        raise InputSanitizer::ValueMissingError
      elsif value == nil && options[:allow_nil] == false
        raise InputSanitizer::ValueMissingError
      elsif value.blank?
        value
      else
        DateTime.parse(value)
      end

    rescue ArgumentError
      raise InputSanitizer::TypeMismatchError.new(value, :datetime)
    end
  end

  class URLCheck
    def call(value, options = {})
      if value.blank? && (options[:allow_blank] == false || options[:required] == true)
        raise InputSanitizer::ValueMissingError
      elsif value == nil && options[:allow_nil] == false
        raise InputSanitizer::ValueMissingError
      elsif value.blank?
        value
      else
        unless /\A#{URI.regexp(%w(http https)).to_s}\z/.match(value)
          raise InputSanitizer::TypeMismatchError.new(value, :url)
        end
        value
      end
    end
  end

  class SortByCheck
    def call(value, options = {})
      key, direction = value.to_s.split(':', 2)
      direction = 'asc' if direction.blank?

      unless options[:allow].include?(key) && allowed_directions.include?(direction)
        raise InputSanitizer::ValueNotAllowedError.new(value)
      end

      [key, direction]
    end

    private
    def allowed_directions
      ['asc', 'desc']
    end
  end
end
