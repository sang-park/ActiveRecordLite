require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end

end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    foreign_id = name.to_s.underscore.singularize + "_id"
    @foreign_key = options[:foreign_key] || foreign_id.to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.camelcase.singularize
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    name_underscore = name.to_s.underscore.singularize + "_id"
    self_class_name_underscore = self_class_name.to_s.underscore.singularize + "_id"
    @foreign_key = options[:foreign_key] || self_class_name_underscore.to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.camelcase.singularize
  end
end

module Associatable
  def belongs_to(name, options = {})

    assoc_options[name] = BelongsToOptions.new(name, options)
    options = assoc_options[name]

    define_method("#{name}") do
      return nil if self.send(options.foreign_key) == nil

      found = DBConnection.execute(<<-SQL)
        SELECT *
        FROM #{options.model_class.table_name}
        WHERE #{options.primary_key} = #{self.send(options.foreign_key)}
        LIMIT 1
      SQL

      options.model_class.find(found[0]['id'])
    end
  end

  def has_many(name, options = {})

    assoc_options[name] = HasManyOptions.new(name, self.to_s, options)
    options = assoc_options[name]

    define_method("#{name}") do
      return nil if self.send(options.primary_key) == nil

      found = DBConnection.execute(<<-SQL)
        SELECT *
        FROM #{options.model_class.table_name}
        WHERE #{options.foreign_key} = #{self.send(options.primary_key)}
      SQL

      found.map {|each| options.model_class.find(each['id'])}
    end

  end

  def has_one_through(name, through_name, source_name)
    define_method("#{name}") do
      through = self.send(through_name)
      through.send(source_name)
    end
  end

  def assoc_options
    @options ||= {}
  end
end
