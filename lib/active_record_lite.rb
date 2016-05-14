require_relative 'db_connection'
require_relative 'searchable'
require_relative 'associatable'
require 'active_support/inflector'


class ActiveRecordLite
  extend Searchable
  extend Associatable

  def self.columns

    if @columns.nil?
      arr = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
      SQL
      
      @columns = arr.first.map{|el| el.to_sym}
    end

    @columns
  end

  def self.finalize!

    self.columns.each do |col|
      define_method("#{col}") do
        attributes[col]
      end

      define_method("#{col}=") do |val|
        attributes[col] = val
      end
    end

  end

  def self.table_name=(table_name)
    @table_name = "#{table_name}"
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all

    arr = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL

    arr.map { |el| self.new(el) }
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    found = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    found.empty? ? nil : found_object = self.new(found[0])
  end

  def initialize(params = {})

    params.each do |k,v|
      col = k.to_sym
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(col)
      set_col = "#{k}="
      send(set_col, v)
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    keys = attributes.keys
    vals = attribute_values
    k = '(' + keys.join(', ') + ')'
    v = "( '" + vals.join("', '") + "')"

    DBConnection.execute(<<-SQL)
      INSERT INTO
        #{self.class.table_name} #{k}
      VALUES
        #{v}
    SQL

    recent_id = DBConnection.execute(<<-SQL)
      SELECT
        MAX(id) AS most_recent_id
      FROM
        #{self.class.table_name}
    SQL

    self.id = recent_id.first['most_recent_id']
  end

  def update
    attr_without_id = attributes.dup
    attr_without_id.delete(:id)
    setting = attr_without_id.map{|k,v| "#{k} = '#{v}'"}.join(", ")

    DBConnection.execute(<<-SQL)
      UPDATE
        #{self.class.table_name}
      SET
        #{setting}
      WHERE
        id = #{id}
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end
end
