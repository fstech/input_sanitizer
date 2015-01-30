module InputSanitizer::V2::Types
  class IntegerCheck
    def call(value)
      Integer(value).tap do |integer|
        raise InputSanitizer::TypeMismatchError.new(value, :integer) unless integer == value
      end
    rescue ArgumentError
      raise InputSanitizer::TypeMismatchError.new(value, :integer)
    end
  end

  class NonStrictIntegerCheck
    def call(value)
      Integer(value)
    rescue ArgumentError
      raise InputSanitizer::TypeMismatchError.new(value, :integer)
    end
  end

  class StringCheck
    def call(value)
      value.to_s.tap do |string|
        raise InputSanitizer::TypeMismatchError.new(value, :string) unless string == value
      end
    end
  end

  class BooleanCheck
    def call(value)
      if [true, false].include?(value)
        value
      else
        raise InputSanitizer::TypeMismatchError.new(value, :boolean)
      end
    end
  end

  class NonStrictBooleanCheck
    def call(value)
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
    def call(value)
      DateTime.parse(value)
    rescue ArgumentError
      raise InputSanitizer::TypeMismatchError.new(value, :datetime)
    end
  end
end
