* Don't show "counts", show "intensity" labels?
    * "show counts" options
* Check how MDS is calculated - should use log intensity?
    * Currently uses
* Don't show low "counts" filtering on config page
* QC plots - which ones makes sense?
    * Histogram of intensity
    * Heatmap of missing values

* Analysis script, and options.  eg, imputation.  Other filtering?
    * Imputation using method close to Perseus software (partly done, currently uses runif instead rnorm)
    * Find suitable variance stabilising transformation
    * Remove redundant column filtering? (Is it redundant?)

* Look into re-enabling error reports (Currently disabled)

* Usability
    * Use Escape button to close pop-overs
    * In Firefox: The condition selector clips group the sample is added to in half
