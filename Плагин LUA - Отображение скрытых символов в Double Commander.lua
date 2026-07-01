local fields = {
  "Visible space",
}

function ContentGetSupportedField(FieldIndex)
  if fields[FieldIndex + 1] ~= nil then
    return fields[FieldIndex + 1], "", 8
  end
  return "", "", 0
end

function ContentGetValue(FileName, FieldIndex, UnitIndex, flags)
  if FieldIndex == 0 then
    local originalFileName = SysUtils.ExtractFileName(FileName)
    -- Replace non-breaking space with degree symbol
    local modifiedFileName = string.gsub(originalFileName, "\194\160", "°")
    -- Replace ordinary space with dot
    modifiedFileName = string.gsub(modifiedFileName, " ", "␣")
    return modifiedFileName
  else
    return nil
  end
end
