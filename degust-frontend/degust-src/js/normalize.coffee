
normalized_key = "_normalized_"

class Normalize
	# Compute normalisation for the given count columns - unless already computed.
	# return the columns for normalised in the same order
	@normalize_cpm: (data,columns,log_moderation) ->
		columns.map((c) =>
			idx = normalized_key+c.idx
			col = data.column_by_idx(idx)
			if (!col || col.log_moderation != log_moderation)
				norm_factor = data.get_total(c) / 1000000.0
				col = {idx: idx, name: "#{c.name}", type: 'norm', parent: c.parent, log_moderation: log_moderation, nice_name: data.nice_name(c.name)}
				data.add_column(col, (r) => Math.log(log_moderation + r[c.idx]/norm_factor) * Math.LOG2E)
			col
		)

	# Handle normalization that needs to be handled on the backend.
	# Takes the type (used to put in the table, and for caching)
	# and a promise, that will issue the http request
	@normalize_from_backend: (data,columns,type, req_promise) ->
		# First check if we have the data already
		new_cols = columns.map((col) ->
			idx = normalized_key+type+"_"+col.idx
			data.column_by_idx(idx)
		).filter((col) -> col!=null)
		if (new_cols.length == columns.length)
			return new Promise((resolve) -> resolve(new_cols))

		# Nope, need to request it
		#this.ev_backend.$emit('start_loading')
		startTime = Date.now()
		new Promise((resolve) ->
			req_promise.then((d) =>
				console.log("Normalized data request took #{Date.now() - startTime }ms")
				#this.ev_backend.$emit('done_loading')
				new_cols = []
				columns.forEach((col) =>
					idx = normalized_key+type+"_"+col.idx
					new_col = {idx: idx, name: "#{col.name}", type: 'norm', parent: col.parent, nice_name: data.nice_name(col.name)}
					i = d.extra.normalized.columns.indexOf(col.name)
					data.add_column(new_col, (r,rid) => d.extra.normalized.values[rid][i])
					new_cols.push(new_col)
				)
				resolve(new_cols)
			)
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
