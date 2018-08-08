require "benchmark/ips"
require "coverage"
Coverage.start

x = Time.now
require "active_support/all"
require "action_view/helpers/output_safety_helper"
p Time.now - x

include ActionView::Helpers::OutputSafetyHelper

arr = ["i", "am", "a", "sentence"]

Benchmark.ips do |x|
  x.report "to sentence" do
    to_sentence(arr)
  end
end
