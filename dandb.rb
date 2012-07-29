# This is the program I roughed out as a design spec for the library.
#
# I said "how do I want to be able to process CSV files in my app"
# and wrote the library to accommodate that.

require 'csv-interpreter'

inputfile = $stdin

csv = CSV.new(inputfile)
hashes = CSVInterpreter.parse(csv) do |p|
  p.has_header = true
  p.column_id_method = :column_index    # could also identfy columns by their headings
  # Get rid of any rows that start with a formfeed character.
  p.reject_if { |row| row[0] == "\f" }
  p.format :hash do |h|
    h.hash :vendor do |vendor|
      vendor.field :duns_number, 0
      vendor.field :contact_urn, 10
      vendor.field :sic_code_collected_1_5_digit, 18
    end
    h.field :company_name, 1
    h.field :street_address do |row|
      row[2..5].compact.reject(&:empty?).join("\n")
    end
    h.field :town, 6
    h.field :county, 7
    h.field :postcode, 8
    h.field :phone, 9
    h.field :title, 11
    h.field :forename, 12
    h.field :other_names, 13
    h.field :surname, 14
    h.field :gender, 15
    h.field :job_title, 16
    h.field :is_senior_decision_maker, 17 do |isdm|
      case isdm.upcase
        when "YES" then true
        when "NO" then false
        else nil
      end
    end
  end
end

hashes.each do |hash|
  puts hash
end
