require 'spec_helper'

describe InputSanitizer::V1::IntegerConverter do
  let(:converter) { InputSanitizer::V1::IntegerConverter.new }

  it "casts string to integer" do
    converter.call("42").should == 42
  end

  it "casts integer to integer" do
    converter.call(42).should == 42
  end

  it "raises error if cannot cast" do
    lambda { converter.call("f") }.should raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::V1::DateConverter do
  let(:converter) { InputSanitizer::V1::DateConverter.new }

  it "casts dates in iso format" do
    converter.call("2012-05-15").should == Date.new(2012, 5, 15)
  end

  it "raises error if cannot cast" do
    lambda { converter.call("2012-02-30") }.should raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::V1::BooleanConverter do
  let(:converter) { InputSanitizer::V1::BooleanConverter.new }

  it "casts 'true' to true" do
    converter.call('true').should eq(true)
  end

  it "casts true to true" do
    converter.call(true).should eq(true)
  end

  it "casts '1' to true" do
    converter.call('1').should eq(true)
  end

  it "casts 'yes' to true" do
    converter.call('yes').should eq(true)
  end

  it "casts 'false' to false" do
    converter.call('false').should eq(false)
  end

  it "casts false to false" do
    converter.call(false).should eq(false)
  end

  it "casts '0' to false" do
    converter.call('0').should eq(false)
  end

  it "casts 'no' to false" do
    converter.call('no').should eq(false)
  end

  it "raises error if cannot cast" do
    lambda { converter.call("notboolean") }.should raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::V1::TimeConverter do
  let(:converter) { InputSanitizer::V1::TimeConverter.new }

  it "raises if timezone part given" do
    lambda { converter.call("2012-05-15 13:42:54 +01:00") }.should raise_error(InputSanitizer::ConversionError)
  end

  it "casts date time in iso format" do
    t = Time.utc(2012, 5, 15, 13, 42, 54)
    converter.call("2012-05-15 13:42:54").should == t
    converter.call("2012-05-15T13:42:54").should == t
    converter.call("20120515134254").should == t
  end

  it "works with miliseconds" do
    t = Time.utc(2012, 5, 15, 13, 42, 54)
    converter.call("2012-05-15 13:42:54.000").should == t
    converter.call("2012-05-15T13:42:54.000").should == t
    converter.call("20120515134254000").should == t
  end

  it "works with Z at the end" do
    t = Time.utc(2012, 5, 15, 13, 42, 54)
    converter.call("2012-05-15 13:42:54.000Z").should == t
    converter.call("2012-05-15T13:42:54.000Z").should == t
   converter.call("2012-05-15T13:42:54Z").should == t
    converter.call("20120515134254000Z").should == t
  end

  it "does not require time part" do
    converter.call("2012-05-15 13:42").should == Time.utc(2012, 5, 15, 13, 42)
    converter.call("2012-05-15 13").should == Time.utc(2012, 5, 15, 13)
    converter.call("2012-05-15").should == Time.utc(2012, 5, 15)
  end

  it "raises error if can format is wrong" do
    lambda { converter.call("2/10/2031 13:44:22") }.should raise_error(InputSanitizer::ConversionError)
  end

  it "raises error if date is wrong" do
    lambda { converter.call("2012-02-32") }.should raise_error(InputSanitizer::ConversionError)
  end

  it "allows the instance of Time" do
    t = Time.now
    converter.call(t).should == t.utc
  end

  it "raises error if value is of invalid type" do
    lambda { converter.call({}) }.should raise_error(InputSanitizer::ConversionError)
  end
end

describe InputSanitizer::V1::AllowNil do
  it "passes blanks" do
    lambda { |_| 1 }.extend(InputSanitizer::V1::AllowNil).call("").should be_nil
  end

  it "passes things the extended sanitizer passes" do
    lambda { |_| :something }.extend(InputSanitizer::V1::AllowNil).call(:stuff).
      should eq(:something)
  end

  it "raises error if the extended sanitizer raises error" do
    action = lambda do
      lambda { |_| raise "Some error" }.extend(InputSanitizer::V1::AllowNil).call(:stuff)
    end

    action.should raise_error
  end
end
