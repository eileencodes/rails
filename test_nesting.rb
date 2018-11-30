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
p a: ActiveSupport::JSON.encode(Foo.new(Bar.new), neat: [:lolol])
p b: ActiveSupport::JSON.encode(Bar.new, neat: [:lolol]) # should be passed to bar
p c: ActiveSupport::JSON.encode([Bar.new], neat: [:lolol]) # should be passed to bar
p d: ActiveSupport::JSON.encode({ "x" => Bar.new}, neat: [:lolol]) # should be passed to bar

