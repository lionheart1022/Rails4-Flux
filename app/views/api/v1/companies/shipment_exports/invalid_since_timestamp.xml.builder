xml.instruct!
xml.Error do
  xml.Identifier "invalid_since_timestamp"
  xml.Message "The provided `since` timestamp (#{params[:since].inspect}) could not be recognized as a supported timestamp"
end
