<template>
    <modal v-if='show' :showModal='show' :closeAction='close'>
        <h3 slot='header'>About Degust</h3>
        <div slot='body'>
            <p>Degust : Visualize, explore and appreciate RNA-seq differential gene-expression data.</p>
            <p>Version : {{version}}  (See <a target='_blank' href='https://raw.github.com/drpowell/degust/master/Changelog.txt'>Changelog</a>)</p>
            <p>Visit the <a href='http://degust.org/'>Degust project page</a>,
                or the <a href='https://github.com/drpowell/degust'>source code on GitHub</a>
            </p>
            <div>Written by <a href='http://thunking.drp.id.au/'>David R. Powell</a> (<a href='http://twitter.com/d_r_powell'>@d_r_powell</a>)</div>
            <a href='https://doi.org/10.5281/zenodo.3258932'>
              <img src='https://zenodo.org/badge/DOI/10.5281/zenodo.3258932.svg' style="margin: 1em 0"/>
            </a>
            <hr/>
            <div class='supported-by'>
                Supported by:
                <div>
                    <a href='https://platforms.monash.edu/bioinformatics/'>Monash Bioinformatics Platform, Monash University</a>
                </div>

                <div style='margin-top: 10px;'>
                    Past Support:
                    <a href='http://vicbioinformatics.com/'>Victorian Bioinformatics Consortium, Monash University</a>
                    VLSCI's Life Sciences Computation Centre
                </div>
            </div>
        </div>
        <div slot='footer'>
            <button class='btn btn-primary' @click='close'>Close</button>
        </div>
    </modal>
</template>

<script lang='coffee'>


module.exports =
    name: 'about'
    props:
        show: false
        version:
            default: degust_version
    methods:
        close: () -> this.$emit('close')

</script>
