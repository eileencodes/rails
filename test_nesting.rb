require "active_support/all"
require "json"

class Bar
  def as_json(options = nil)
    if options
      options
    else
      "omg"
    end
  end
end

class Foo
  def initialize bar
    @bar = bar
  end
end

# Options isn't passed to bar
p ActiveSupport::JSON.encode(Foo.new(Bar.new), neat: [:lolol])

