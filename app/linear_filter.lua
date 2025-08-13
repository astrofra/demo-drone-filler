-- LinearFilter class
LinearFilter = {}
LinearFilter.__index = LinearFilter

-- Constructor
function LinearFilter:new(size)
    local obj = {
        filter_size = size,
        values = {}
    }
    setmetatable(obj, self)
    return obj
end

-- Method to add a new value
function LinearFilter:SetNewValue(val)
    table.insert(self.values, val)
    -- Keep the size within the limit
    if #self.values > self.filter_size then
        table.remove(self.values, 1)
    end
end

-- Method to get the filtered value (mean of the stored values)
function LinearFilter:GetMeanValue()
	if #self.values == 0 then
		return 0.0
	end

	local sum = 0.0

	for _, v in ipairs(self.values) do
        sum = sum + v
    end

    return sum / #self.values
end

-- Method to get the filtered value (median of the stored values)
function LinearFilter:GetMedianValue()
    if #self.values == 0 then
        return 0.0
    end

    -- Create a copy of the values table and sort it
    local sorted_values = {table.unpack(self.values)}
    table.sort(sorted_values)

    local mid = math.floor(#sorted_values / 2) + 1
    if #sorted_values % 2 == 0 then
        -- Even number of elements: return the average of the two middle values
        return (sorted_values[mid - 1] + sorted_values[mid]) / 2.0
    else
        -- Odd number of elements: return the middle value
        return sorted_values[mid]
    end
end
