log_moderation = 10.0

normalized_key = "_normalized_"

class Normalize
	# Compute normalisation for the given count columns - unless already computed.
	# return the columns for normalised in the same order
	@normalize: (data, columns) ->
		columns.map((c) =>
			idx = normalized_key+c.idx
			col = data.column_by_idx(idx)
			if (!col)
				norm_factor = data.get_total(c) / 1000000.0
				col = {idx: idx, name: "#{c.name} (N)", type: 'norm', parent: c.parent}
				data.add_column(col, (r) => Math.log(log_moderation + r[c.idx]/norm_factor)/Math.log(2))
			col
		)

# Calculate min/max for each dimension passed
calc_extent = (data, dims) ->
    # Calculate min/max for all dimensions - Want common scale across dimensions
    extents = []
    dims.forEach (k) ->
        extents.push(d3.extent(data, (v) -> +v[k.idx]))
    extent = d3.extent(d3.merge(extents))
    # Just a bit larger than the extent (so can be brushed over)
    return extent.map((v) -> v*1.05)

module.exports =
	Normalize: Normalize
	calc_extent: calc_extent
