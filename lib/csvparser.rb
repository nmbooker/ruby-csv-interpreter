# A DSL for defining how a CSV file is to be parsed into an Array of Hashes

require 'csv'

class CSVParser
  def initialize(&block)
    @has_header = true     # default
    @column_id_method = :column_index    # default.  Could also be :heading
    @reject_if = lambda { |x| false }
    if block
      block.call(self)
    end
  end
  
  def self.parse(csv_reader, &block)
    new(&block).parse(csv_reader)
  end

  attr_accessor :has_header
  attr_accessor :column_id_method

  def reject_if(&block)
    @reject_if = block
  end

  def output_format_name
    @formatter_klass.formatter_name
  end

  def format(formatter_klass, &block)
    if formatter_klass.is_a?(Symbol) then
      @formatter_klass = Formatter[formatter_klass]
    else
      @formatter_klass = formatter_klass
    end
    @formatter = @formatter_klass.new(@column_id_method, &block)
  end

  def parse(csv_reader)
    if @has_header
      @header = csv_reader.shift
    end
    result = csv_reader.reject{ |row| @reject_if.call(row) }.map { |row| @formatter.parse_row(row) }
    return result
  end

  class Field
    def initialize(column_id_method, key=nil, &block)
      @column_id_method = column_id_method
      @in_key = key
      @block = block
    end

    def parse_row(row)
      if @block
        if @in_key
          @block.call(row[@in_key])
        else
          @block.call(row)
        end
      elsif @in_key
        row[@in_key]
      end
    end
  end

  class Formatter
    def self.[](type)
      case type
        when :hash then HashFormatter
        else raise IndexError.new("invalid formatter name: #{type.inspect}")
      end
    end

    def initialize(column_id_method, &block)
      #$stderr.puts "#{self.class}"
      @fields = {}
      @column_id_method = column_id_method
      if block
        block.call(self)
      end
    end

    # Declare a subhash, grouping fields.
    #
    # The subhash will be saved at the given key, but otherwise processed
    # in exactly the same way.
    #
    # e.g.
    #  CsvParser.parse(inputfile) do |p|
    #    p.format CsvParser::Formatter[:hash] do |h|
    #      h.field :name, 1
    #      h.hash :address do |addr|
    #        addr.field :street, 2
    #        addr.field :town, 3
    #      end
    #    end
    #  end
    #
    # Example above will result in a hash that looks like this for each row:
    #  {:address => {:street => "10 A Road", :town => "Anytown"}, :name => "Fred"}
    def hash(key, &block)
      #$stderr.puts "hash for #{key.inspect}"
      @fields[key] = Formatter[:hash].new(@column_id_method, &block)
    end

    # Declare a field with the given key.
    # column_id, if provided, is the column to extract this field from.
    # 
    # If column_id is provided without a block, then the value corresponding
    # to key in the output hash will be the string read in from the CSV file.
    #
    # If a block is provided, then the result of the block is what ends up
    # in the resulting hash for each row.
    #
    # If column_id is provided with a block, then the data in that column
    # is retrieved and sent to the block as its first argument.
    #
    # If a block is provided, but without a column_id, then the block is
    # passed the whole Row.  You must then extract what you need with row[index] as per the Ruby CSV module.
    #
    # You must provide AT LEAST ONE of column_id or a block
    #
    # Here are some examples:
    #
    #  h.field :name, 1
    #  # :name => whatever's in the second column
    #
    #  h.field :is_family, 2 { |family| if family == "yes" ? true : false }
    #  # :is_family => true if 'yes' is in the third column, otherwise false
    #
    #  h.field :address { |row| row[3..6].join("\n") }
    #  # :address => the 4th to 7th column in one string, separated by newline characters
    def field(key, column_id=nil, &block)
      @fields[key] = Field.new(@column_id_method, column_id, &block)
    end
  end

  class HashFormatter < Formatter
    def self.formatter_name
      :hash
    end

    def parse_row(row)
      #$stderr.puts "parse_row"
      result = {}
      for key, row_parser in @fields
        result[key] = row_parser.parse_row(row)
      end
      return result
    end
  end
end
