module DSVAreas
  SJAELLAND = ("0".."4999")
  FYN = ("5000".."5999")
  NORDJYLLAND = ["9000"]
  MIDTJYLLAND = ("6000".."9999").to_a - ["9000"]
end
