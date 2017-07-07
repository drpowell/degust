# FAQ

### How can a gene have zero counts for all samples but has a non-zero fold-change?

This can happen when using the backend of Degust.  Degust uses voom (or edgeR) to perform the expression analysis.  Voom adds a small constant (0.5), to each count, normalizes for library size, then takes the log.  This means when you have a count of 0 across all samples, but different library sizes, it is possible to compute a non-zero fold-change.

We recommend setting **Min read count** on the configuration page to a small value, say 10.

### What is the **Min read count** setting?

This is the minimum number of reads required in at least one sample to keep the gene in the analysis.  That is, a given gene is omitted if the number of reads across all samples is below this setting.


### I don't see an option to display an MDS plot

The MDS plot is only available when you have included "count" columns

### How is the MDS plot calculated

  * First genes that don't pass the "FDR cut-off" or "abs log FC" filters are ignored.  Using these filters is "cheating" when doing an MDS plot to look at replicate clustering
  * The remaining genes have the counts for each replicate log-transformed.
  * The genes are then ranked by decreasing variance.  That is, the most variable genes are "at the top"
  * Then the top "Skip genes" are ignored.
  * And the next "Num genes" are selected.
  * These selected genes are used to compute an MDS (or PCA) plot

### Configuring a Degust session programmatically

First upload your count matrix, and note the special code created in the url.  eg. `73fb85e4625f5bdd08cfeb3b9fc7a7f2`

You may download the settings in a json format.  Note here the use of the [https://stedolan.github.io/jq/](jq) tool, this isn't necessary but it does make for nicer formatting of the json.

    curl 'http://degust.erc.monash.edu/degust/73fb85e4625f5bdd08cfeb3b9fc7a7f2/settings' | jq '.settings' > foo.json

You can now edit the file `foo.json` to change any settings.  To save you changes you POST it back to the server:

    curl 'http://degust.erc.monash.edu/degust/73fb85e4625f5bdd08cfeb3b9fc7a7f2/settings' -F 'settings=<foo.json'


Example json settings below.   Important parts:
  * `csv_format` specifies the format of your uploaded file, true for csv, or false for tsv
  * `info_columns` are the names of columns from your csv file
  * `name` the name of the degust session
  * `replicates` An array of conditions.  Each condition is an array with the first entry as your chosen name for a condition, and the second entry is an array of the column names of the replicates from your file.
  * `init_select` the condition names from the `replicates` array that specify the conditions to select on page log
  * `hidden_factor` the condition names from the `replicates` array that specifies linear model terms for batch effects
  * `analyze_server_side` use true if you upload counts, false if you upload analysis results for visualisation in degust

```json
{
  "min_cpm_samples": 5,
  "min_cpm": 1,
  "hidden_factor": [],
  "init_select": [
    "cdhR",
    "GppX",
    "luxS",
    "wt"
  ],
  "name": "Public Example",
  "analyze_server_side": true,
  "info_columns": [
    "Feature",
    "gene",
    "product"
  ],
  "replicates": [
    [
      "cdhR",
      [
        "cdhR-rep1",
        "cdhR-rep2"
      ]
    ],
    [
      "GppX",
      [
        "GppX-rep1",
        "GppX-rep2"
      ]
    ],
    [
      "luxS",
      [
        "luxS-rep1",
        "luxS-rep2",
        "luxS-rep3"
      ]
    ],
    [
      "wt",
      [
        "wt-rep1",
        "wt-rep2",
        "wt-rep3"
      ]
    ]
  ],
  "csv_format": true,
}
```
