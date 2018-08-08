#ActiveSupport::JSON = Yajl
#ActiveSupport::JSON = JSON

require 'yajl'
require 'json'

ASJSON = Yajl
#ASJSON = JSON

# Rails
class Foo
  def to_json(context = nil)
    if context
      super
    else
      ASJSON.dump self
    end
  end
end

ary = [Foo.new]
p ASJSON.dump ary
