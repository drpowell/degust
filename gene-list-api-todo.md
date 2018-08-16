Geneset/Genetable API

API functions

- Both Public/User Defined
	* Get List of All Tables/Sets
	* Get specified Table/Set

- User Defined
	* Input a new Table/Set
	* Update existing Table/Set
	* Delete Table/Set

Geneset/Table Structure
* title: `str` `"Sample Title"`
* desc: `str` `"Group of genes associated with cancer outcome"`
* id_type: `str` `"EnsemblGenome"`
* collection_type - `"KEGG/Reactome/Allergome"` (Maybe `[]` for more than one type?)
* data - (Might not always be genes, sometimes proteins)
	* Each ID is - `[]`
        * name: `""`
        * col1:
        * col2:`...`
* columns:
    * id: `col1`
    * name: `"FDR"`
    * type (of contents): `str`, `int`, `float`
    * id-type: `"Ensembl"/"Gene Description"/"Gene Symbol"`


User needs to be able to: (JS)
* Filter/search by Title, Properties ("ID Type" & "Collection Type (KEGG, REACTOME etc."), Description, (Members?)
* Search endpoint needs to be able to search for this

User defined geneLists won't be required to add: Organism, Description
- Properties will be defined as "User List"/"User Provided")

API Specifics:
* GET:
    * Get all gene lists
        * `/degust/:id/gene_lists/`
        * If no gene list exists return `[]`
        * Can assume that each dataset has list of gene lists initialised to []
        * Returns JSON associated with each of the gene lists
    * Get a specific gene list
        * `/degust/:id/gene_lists/{:gene-list-id}`
        * If missing, push back to user with an error like "Gene list cannot be loaded because we cant find one with that name"

    * Get predefined gene lists for a given organism
        * `/degust/{:organism}/gene_lists/`
        * This does mean that Degust does need to know what kind of organism it is analysing.
    * Get specific predefined gene lists for a given organism
        * `/degust/{:organism}/gene_lists/{:gene-list-id}`
        * This does mean that Degust does need to know what kind of organism it is analysing.

* POST:
    * Make a new gene list
        * `/degust/:id/gene_lists/{:gene-list-id}`
        * If gene-list-id collision, push back to user with error "Gene list cannot be added, because one with that name already exists"
        * Assume list name is url encoded. (Remember to check for xss on render too)

<!-- For future
    * Update an existing gene list's genes
        * `/degust/:id/gene_lists/{:gene-list-id}/genes`
        * Post directly to a given gene list to replace the existing array of genes
    * Update an existing gene list's properties
        * `/degust/:id/gene_lists/{:gene-list-id}/properties`
        * Post directly to a given gene list to replace the existing properties
-->
* DEL:
    * Delete/Remove a gene list
    * `/degust/:id/gene_lists/{:gene-list-id}`
    * If missing, push back to user with error "Gene list cannot be deleted because we cant find one with that name"

How does the server perform merge/match operations?
It would then need to have an idea of which organism, and what kind of gene id it is currently looking at.

It might be overkill, but it'd be nice if a user was possibly able to export gene lists from one experiment to another from the dropdown as an "Export Gene Lists" button or something. Or maybe even an input form under 'advanced' and the user enters the secure-code?