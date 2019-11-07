class String
  def to_hash_object
    JSON.parse(self.gsub(/:([a-zA-z]+)/,'"\\1"').gsub('=>', ': ')).symbolize_keys
  end
end