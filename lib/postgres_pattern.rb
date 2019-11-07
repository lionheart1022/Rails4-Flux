module PostgresPattern
  def escape(unescaped)
    unescaped
      .gsub("\\", "\\\\")
      .gsub("%", "\\%")
      .gsub("_", "\\_")
  end

  module_function :escape
end
