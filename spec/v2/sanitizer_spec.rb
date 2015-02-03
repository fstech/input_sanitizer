require 'spec_helper'

class AddressSanitizer < InputSanitizer::V2::Sanitizer
  string :city
  string :zip
end

class TagSanitizer < InputSanitizer::V2::Sanitizer
  integer :id
  string :name
  nested :addresses, :sanitizer => AddressSanitizer, :collection => true
end

class TestedSanitizer < InputSanitizer::V2::Sanitizer
  integer :array, :collection => true
  string :status, :allow => ['', 'current', 'past']
  nested :address, :sanitizer => AddressSanitizer
  nested :tags, :sanitizer => TagSanitizer, :collection => true

  integer :integer_attribute
  string :string_attribute
  boolean :bool_attribute
  datetime :datetime_attribute

  integer :loose_integer, :strict => false
  boolean :loose_bool, :strict => false

  url :website
end

describe InputSanitizer::V2::Sanitizer do
  let(:sanitizer) { TestedSanitizer.new(@params) }
  let(:cleaned) { sanitizer.cleaned }

  describe "collections" do
    it "is invalid if collection is not an array" do
      @params = { :array => {} }
      sanitizer.should_not be_valid
    end

    it "is valid if collection is an array" do
      @params = { :array => [] }
      sanitizer.should be_valid
    end
  end

  describe 'type strictness' do
    it 'is valid if given an integer as a string' do
      @params = { :loose_integer => '22' }
      sanitizer.should be_valid
      sanitizer[:loose_integer].should eq(22)
    end

    it 'is valid if given a "true" boolean as a string' do
      @params = { :loose_bool => 'true' }
      sanitizer.should be_valid
      sanitizer[:loose_bool].should eq(true)
    end

    it 'is valid if given a "false" boolean as a string' do
      @params = { :loose_bool => 'false' }
      sanitizer.should be_valid
      sanitizer[:loose_bool].should eq(false)
    end
  end

  describe "allow option" do
    it "is valid when given an allowed string" do
      @params = { :status => 'past' }
      sanitizer.should be_valid
    end

    it "is valid when given an allowed empty string" do
      @params = { :status => '' }
      sanitizer.should be_valid
    end

    it "is invalid when given a disallowed string" do
      @params = { :status => 'current bad string' }
      sanitizer.should_not be_valid
      sanitizer.errors[0].field.should eq('/status')
    end
  end

  describe "strict param checking" do
    it "is invalid when given extra params" do
      @params = { :extra => 'test', :extra2 => 1 }
      sanitizer.should_not be_valid
      sanitizer.errors.count.should eq(2)
    end

    it "is invalid when given extra params in a nested sanitizer" do
      @params = { :address => { :extra => 0 }, :tags => [ { :extra2 => 1 } ] }
      sanitizer.should_not be_valid
      sanitizer.errors[0].field.should eq('/address/extra')
      sanitizer.errors[1].field.should eq('/tags/0/extra2')
    end
  end

  describe "strict type checking" do
    it "is invalid when given string instead of integer" do
      @params = { :integer_attribute => '1' }
      sanitizer.should_not be_valid
      sanitizer.errors[0].field.should eq('/integer_attribute')
    end

    it "is valid when given an integer" do
      @params = { :integer_attribute => 999 }
      sanitizer.should be_valid
    end

    it "is invalid when given integer instead of string" do
      @params = { :string_attribute => 0 }
      sanitizer.should_not be_valid
      sanitizer.errors[0].field.should eq('/string_attribute')
    end

    it "is invalid when given a string" do
      @params = { :string_attribute => '#@!#%#$@#ad' }
      sanitizer.should be_valid
    end

    it "is invalid when given 'yes' as a bool" do
      @params = { :bool_attribute => 'yes' }
      sanitizer.should_not be_valid
      sanitizer.errors[0].field.should eq('/bool_attribute')
    end

    it "is valid when given true as a bool" do
      @params = { :bool_attribute => true }
      sanitizer.should be_valid
    end

    it "is valid when given false as a bool" do
      @params = { :bool_attribute => false }
      sanitizer.should be_valid
    end

    it "is invalid when given an incorrect datetime" do
      @params = { :datetime_attribute => "2014-08-2716:32:56Z" }
      sanitizer.should_not be_valid
      sanitizer.errors[0].field.should eq('/datetime_attribute')
    end

    it "is valid when given a correct datetime" do
      @params = { :datetime_attribute => "2014-08-27T16:32:56Z" }
      sanitizer.should be_valid
    end

    it "is valid when given a 'forever' timestamp" do
      @params = { :datetime_attribute => "9999-12-31T00:00:00Z" }
      sanitizer.should be_valid
    end

    it "is valid when given a correct URL" do
      @params = { :website => "https://google.com" }
      sanitizer.should be_valid
    end

    it "is invalid when given an invalid URL" do
      @params = { :website => "ht:/google.com" }
      sanitizer.should_not be_valid
    end

    it "is invalid when given an invalid URL that contains a valid URL" do
      @params = { :website => "watwat http://google.com wat" }
      sanitizer.should_not be_valid
    end

    describe "nested checking" do
      describe "simple array" do
        it "returns JSON pointer for invalid fields" do
          @params = { :array => [1, 'z', '3', 4] }
          sanitizer.errors.length.should eq(2)
          sanitizer.errors[0].field.should eq('/array/1')
          sanitizer.errors[1].field.should eq('/array/2')
        end
      end

      describe "nested object" do
        it "returns JSON pointer for invalid fields" do
          @params = { :address => { :city => 0, :zip => 1 } }
          sanitizer.errors.length.should eq(2)
          sanitizer.errors.map(&:field).should contain_exactly('/address/city', '/address/zip')
        end
      end

      describe "array of nested objects" do
        it "returns JSON pointer for invalid fields" do
          @params = { :tags => [ { :id => 'n', :name => 1 }, { :id => 10, :name => 2 } ] }
          sanitizer.errors.length.should eq(3)
          sanitizer.errors.map(&:field).should contain_exactly(
            '/tags/0/id',
            '/tags/0/name',
            '/tags/1/name'
          )
        end
      end

      describe "array of nested objects that have array of nested objects" do
        it "returns JSON pointer for invalid fields" do
          @params = { :tags => [
            { :id => 'n', :addresses => [ { :city => 0 }, { :city => 1 } ] },
            { :name => 2, :addresses => [ { :city => 3 } ] },
          ] }
          sanitizer.errors.length.should eq(5)
          sanitizer.errors.map(&:field).should contain_exactly(
            '/tags/0/id',
            '/tags/0/addresses/0/city',
            '/tags/0/addresses/1/city',
            '/tags/1/name',
            '/tags/1/addresses/0/city'
          )

          ec = sanitizer.error_collection
          ec.length.should eq(5)
        end
      end
    end
  end
end
