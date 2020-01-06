#!/usr/bin/ruby
require 'yaml'

index_file = ARGV.shift || usage
File.readable?(index_file) || abort("#{index_file} not found!")

index = YAML.load(File.read(index_file))

covered = []
uncovered = []

index.each_pair do |name, props|
    if props["tests"] && props["tests"] > 0
        covered << name
    else
        uncovered << name
    end
end

cov_percent = covered.count * 100 / (covered.count+uncovered.count)

puts "Total words: #{covered.count+uncovered.count}"
puts "Covered words: #{covered.count}"
puts "Uncovered words: #{uncovered.count}"
uncovered.each_slice(5) do |sl|
    puts "\t#{sl.join(' ')}"
end
puts "Coverage: #{cov_percent}%"