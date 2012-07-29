#! /usr/bin/env ruby

require 'csv'
require 'csv-interpreter'
require 'date'

infile = $stdin
outfile = $stdout

csv = CSV.new($stdin)
records = CSVInterpreter.parse(infile) do |p|
  p.has_header = true   # causes the first row to be discarded
  p.column_id_method = :column_index  # columns are identified by index in the p.format block.  This is the only option at the moment.

  # each row of input will become a hash on output.
  p.format :hash do |h|
    # each hash will have a date and distance field
    # for distance we're parsing the row manually (and converting to float)
    # for date we're processing the first column to make a Date object
    h.field :distance { |row| row[3].to_f }
    h.field :date, 0 { |d| Date.strptime(d, '%Y-%m-%d') }

    # we have a subhash to contain the origin and destination.
    h.hash :journey do |journey|
      # origin and destination are set to the unchanged string from the CSV
      journey.field :origin, 1
      journey.field :destination, 2
    end
  end
end

# Now we want to calculate the total distance
puts  "0.02f" % (records.inject(0.0) { |r, total| r[:distance] + total })
