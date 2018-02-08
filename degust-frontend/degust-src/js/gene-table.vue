<style scoped>
#grid { height: 300px; }

#grid >>> .slick-row { font-size: 9pt; }
#grid >>> .slick-row:hover {
  font-weight: bold;
  color: #069;
}

#grid >>> .slick-row .counts { margin-left: 10px; color: #999;}
#grid >>> .slick-row .counts span:nth-child(odd) { color: #bbb; }

#grid-info { font-size: 9pt; }
.tab-search { font-size: 9pt; float: right; margin-top: -10px; }
.tab-search .active { background-color: gold; }

div.csv-download-div { float: right; margin: -7px 30px 0 0; }
.csv-download-div a { font-size: 9pt; }

</style>

<template>
    <div>
        <div>
          <div class="tab-search">
            Search:
            <input type="text" v-model='searchStr' :class='{active: searchStr!=""}' @keyup.esc='searchStr=""'>
            <span class='glyphicon glyphicon-cog gene-table-settings'></span>
          </div>
          <div class='csv-download-div'>
            <a @click='do_download("csv")'>Download CSV</a>
            <span class="dropdown">
                <button class="btn-link dropdown-toggle" type="button" id="dropDownload" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
                  <span class="caret"></span>
                </button>
              <ul class="dropdown-menu download" aria-labelledby="dropDownload">
                <li><a @click='do_download("csv")'>Download as CSV</a></li>
                <li><a @click='do_download("tsv")'>Download as TSV</a></li>
                <li><a @click='do_download("odf")'>Download as ODF</a></li>
              </ul>
            </span>
          </div>
          <div id="grid-info">
              Showing {{table_info.top}}..{{table_info.btm}} of {{table_info.total}}
          </div>
        </div>

        <slick-table id="grid" ref='slickGrid'
                     :rows='tableRows'
                     :columns='gene_table_columns'
                     :sorter='sorter'
                     @info='set_table_info'
                     @dblclick='dblclick'
                     @mouseover='mouseover'
                     @mouseout='mouseout'
                     >
        </slick-table>
    </div>
</template>

<script lang='coffee'>

slickTable = require('./slick-table.vue').default

# TODO : restore page from link info

# Rules for guess best info link based on some ID
guess_link_info =
    [{re: /^ENS/, link: 'http://ensembl.org/Multi/Search/Results?q=%s;site=ensembl'},
     {re: /^CG/, link: 'http://flybase.org/cgi-bin/uniq.html?species=Dmel&cs=yes&db=fbgn&caller=genejump&context=%s'},
     {re: /^/, link: 'http://www.ncbi.nlm.nih.gov/gene/?&term=%s'},
    ]

guess_link_info_uniprot =
    {re: /^[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}/, link: 'https://www.uniprot.org/uniprot/%s'}
    

# Guess the link using the guess_link_info table
guess_link = (useUniprot, info) ->
    return if !info?
    if useUniprot
        return guess_link_info_maxquant.link if info.match(guess_link_info_maxquant.re)
    for o in link_info_use
        return o.link if info.match(o.re)
    return null


comparer_num = (x,y) -> (if x == y then 0 else (if x > y then 1 else -1))

# Format data as ODF as used by GenePattern
# http://software.broadinstitute.org/cancer/software/genepattern/file-formats-guide#ODF
odf_fmt = (cols,rows) ->
    hdr = ["ODF 1.0",
           "HeaderLines=4",
           "Model= Dataset",
           "DataLines="+rows.length,
           "COLUMN_TYPES: "+cols.map((c)->if c.type=='info' then "String" else "double").join("\t"),
           "COLUMN_NAMES: "+cols.map((c)->c.name).join("\t"),
    ].concat(rows.map((r) -> r.join("\t"))).join("\n")

do_download = (gene_data, gene_table, fmt) ->
    items = gene_table
    return if items.length==0
    cols = gene_data.columns_by_type(['info','fc_calc','count','fdr','avg','p'])
    count_cols = gene_data.columns_by_type('count')
    keys = cols.map((c) -> c.name).concat(count_cols.map((c) -> c.name+" CPM"))
    rows = items.map( (r) ->  #FIXME re-use Normalize
        cpms = count_cols.map((c) -> (r[c.idx]/(gene_data.get_total(c)/1000000.0)).toFixed(3))
        cols.map( (c) -> r[c.idx] ).concat(cpms)
    )
    mimetype = 'text/csv'
    switch fmt
        when 'csv' then filename='degust.csv'; result=d3.csv.format([keys].concat(rows))
        when 'tsv' then filename='degust.tsv'; result=d3.tsv.format([keys].concat(rows))
        when 'odf'
            mimetype = 'text/plain'
            filename='degust.odf'
            cols_all = cols.concat(count_cols.map((c) -> {type:'cpm', name: c.name+" CPM"}))
            result=odf_fmt(cols_all, rows)

    # In future, look at this library : https://github.com/eligrey/FileSaver.js
    link = document.createElement("a")
    link.setAttribute("href", window.URL.createObjectURL(new Blob([result], {type: mimetype})))
    link.setAttribute("download", filename)
    document.body.appendChild(link)
    link.click()
    link.remove()


module.exports =
    name: 'gene-table'
    components:
        slickTable: slickTable
    props:
        linkUrl:
            default: null
        geneData:
            default: []
            required: true
        rows:
            default: []
            required: true
        showCounts:
            default: false
        showIntensity:
            default: false
        fcColumns:
            required: true
        useUniprot:
            default: false
    data: () ->
        searchStr: ""
        table_info:
            top: 0
            btm: 0
            total: 0
    watch:
        # Not detected automatically in the gene_table_columns cause only used in a callback
        showCounts: () ->
            this.$refs.slickGrid.invalidate()
        showIntensity: () ->
            this.$refs.slickGrid.invalidate()
    computed:
        gene_table_columns: () ->
            column_keys = this.geneData.columns_by_type(['info','fdr','p'])
            column_keys = column_keys.concat(this.fcColumns)
            me = this
            columns = column_keys.map((col) ->
                hsh =
                    id: col.idx
                    name: col.name
                    field: col.idx
                    sortable: true
                    formatter: (i,c,val,m,row) ->
                        if col.type in ['fc_calc']
                            me.fc_div(val, col, row)
                        else if col.type in ['fdr','p']
                            if val<0.01 then val.toExponential(2) else val.toFixed(2)
                        else
                            val
                if col.type in ['fdr','p']
                    hsh.width = 70
                    hsh.maxWidth = 70
                switch col.type
                    when 'fdr'     then hsh.toolTip = "False Discovery Rate"
                    when 'p'       then hsh.toolTip = "Raw P value"
                    when 'fc_calc' then hsh.toolTip = "Log<sub>2</sub> Fold-change"
                hsh
            )
            columns
        tableRows: () ->
            if this.searchStr==''
                this.rows
            else
                searchStr=this.searchStr
                cols=this.geneData.columns_by_type('info')
                this.rows.filter((item) ->
                    for col in cols
                        str = item[col.idx]
                        return true if str? && typeof str == 'string' &&
                                       str.toLowerCase().indexOf(searchStr)>=0
                    false
                )
    methods:
        do_download: (typ) ->
            do_download(this.geneData, this.tableRows, typ)

        set_table_info: (info) ->
            this.table_info = info

        # Used to format the fold-change divs in the table.
        fc_div: (n, column, row) ->
            colour = if n>0.1 then "pos" else if n<-0.1 then "neg" else ""
            countStr = ""
            if this.showCounts=='yes'
                count_columns = this.geneData.assoc_column_by_type('count',column.name)
                vals = count_columns.map((c,i) -> "<span>#{row[c.idx]}</span>")
                countStr = "<span class='counts'>(#{vals.join(" ")})</span>"
            else if this.showCounts=='cpm'
                count_columns = this.geneData.assoc_column_by_type('count',column.name)
                vals = count_columns.map((c) =>
                    tot = this.geneData.get_total(c)
                    val = (1000000 * row[c.idx]/tot).toFixed(1)
                    "<span>#{val}</span>"
                )
                countStr = "<span class='counts'>(#{vals.join(" ")})</span>"
            "<div class='#{colour}'>#{n.toFixed(2)}#{countStr}</div>"

            if this.showIntensity=='yes'
                count_columns = this.geneData.assoc_column_by_type('count',column.name)
                vals = count_columns.map((c,i) -> "<span>#{row[c.idx]}</span>")
                countStr = "<span class='counts'>(#{vals.join(" ")})</span>"
            else if this.showIntensity=='log2'
                count_columns = this.geneData.assoc_column_by_type('count',column.name)
                vals = count_columns.map((c) =>
                    tot = this.geneData.get_total(c)
                    val = ((Math.log(row[c.idx])) * Math.LOG2E).toFixed(1)
                    "<span>#{val}</span>"
                )
                countStr = "<span class='counts'>(#{vals.join(" ")})</span>"
            "<div class='#{colour}'>#{n.toFixed(2)}#{countStr}</div>"

        # Open a page for the given gene.  Use either the defined link or guess one.
        # The "ID" column can be specified as 'link' otherwise the first 'info' column is used
        dblclick: (item) ->
            cols = this.geneData.columns_by_type(['link'])
            if cols.length==0
                cols = this.geneData.columns_by_type(['info'])
            if cols.length>0
                info = item[cols[0].idx]
                link = if this.linkUrl? then this.linkUrl else guess_link(this.useUniprot, info)
                log_debug("Dbl click.  Using info/link",info,link)
                if link?
                    link = link.replace(/%s/, info)
                    window.open(link)
                    window.focus()
        mouseover: (item) ->
            this.$emit('mouseover',item)
        mouseout: () ->
            this.$emit('mouseout')

        # called for sorting columns from slickgrid
        sorter: (args) ->
            column = this.geneData.column_by_idx(args.sortCol.field)
            this.$refs.slickGrid.sort((r1,r2) ->
                r = 0
                x=r1[column.idx]; y=r2[column.idx]
                if column.type in ['fc_calc']
                    if false #sortAbsLogFC
                    then r = comparer_num(Math.abs(x), Math.abs(y))
                    else r = comparer_num(x, y)
                else if column.type in ['fdr']
                    r = comparer_num(x, y)
                else
                    r = comparer_num(x,y)
                r * (if args.sortAsc then 1 else -1)
            )

</script>
