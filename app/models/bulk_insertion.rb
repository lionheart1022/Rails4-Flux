class BulkInsertion
  attr_reader :inserted_ids

  def initialize(rows, column_names:, model_class:, returning: true)
    @rows = rows
    @column_names = column_names
    @model_class = model_class
    @returning = returning
  end

  def perform!
    if rows.count == 0
      return @inserted_ids = []
    end

    sql = "INSERT INTO #{model_class.quoted_table_name} (#{quoted_column_names.join(', ')}) VALUES #{quoted_inserts.join(', ')}#{returning ? " RETURNING #{quoted_primary_key_column_name}" : ''}"
    result = model_class.connection.execute(sql, "Bulk insertion of #{model_class.model_name.human.downcase.pluralize}")

    @inserted_ids = result.map { |row| row[primary_key] }
  end

  private

  attr_reader :rows
  attr_reader :column_names
  attr_reader :model_class
  attr_reader :returning

  def quoted_inserts
    rows.map do |row|
      quoted_values = column_mapping.map do |column_name, column|
        model_class.connection.quote(row[column_name], column)
      end

      "(#{quoted_values.join(', ')})"
    end
  end

  def quoted_column_names
    column_names.map do |column_name|
      model_class.connection.quote_column_name(column_name)
    end
  end

  def quoted_primary_key_column_name
    model_class.connection.quote_column_name(primary_key)
  end

  def column_mapping
    @column_mapping ||= begin
      Hash[
        column_names.map do |column_name|
          [column_name, model_class.column_for_attribute(column_name)]
        end
      ]
    end
  end

  def primary_key
    @primary_key ||= model_class.primary_key
  end
end
