require_relative 'db_connection'

module Searchable
  def where(params)
    in_sql = params.to_a.map { |k,v| "#{k} = '#{v}'"}
    args = in_sql.join(" AND ")

    a = DBConnection.execute(<<-SQL)
      SELECT
        id
      FROM
        #{table_name}
      WHERE
        #{args}
    SQL

    a.map { |id| self.find(id['id'])}
 end
end
