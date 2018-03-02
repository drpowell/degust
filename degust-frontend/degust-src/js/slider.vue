<style scoped>
    .slider { display: inline-block; width: 50px; margin: 0 10px; font-size: 8pt}

</style>
<template>
    <div>
        <input type="text" :class="{error: isError, warning: isWarning}"
               :disabled='textDisable'
               :value="this.my_fmt(value)" v-on:input="value = $event.target.value" />
        <div class='slider' v-once></div>
        <span v-if='dropdowns' class="dropdown">
          <button class="btn-link dropdown-toggle" type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu">
            <li v-for='v in dropdowns'>
                <a href="#" @click='value = v.value'>{{v.label}}</a>
            </li>
          </ul>
        </span>
    </div>
</template>

<script lang='coffee'>

module.exports =
    model:
        prop: 'value_in'        # Change default name for v-model
    props:
        warning: false
        value_in: 0
        validator: null
        fmt: null
        textDisable: false
        dropdowns: null
        stepValues:
            default: () -> [0..10]

    data: () ->
        value: this.value_in
        isError: false
        isWarning: false
        stepValuesCur: this.stepValues
        slider:
            data: this.stepValuesCur

    mounted: () ->
        this.setup()

    watch:
        warning: (v) -> this.isWarning = v
        value_in: (v) -> this.value = v
        value: () ->
            this.set_slider(this.value)
            if this.validator?
                this.isError = !this.validator(this.value)
            if !this.isError
                this.$emit('input', +this.value)

    methods:
        setup: () ->
            this.slider = $(".slider",this.$el).slider({
              animate: true,
              min: 0,
              max: this.stepValuesCur.length-1,
              value: 1,
              slide: (event, ui) =>
                this.value = this.stepValuesCur[ui.value]
            })
            this.set_slider(this.value)

        my_fmt: (v) ->
            if this.fmt?
                return this.fmt(v)
            n=Number(v)
            if n==undefined
                v
            else if n>0 && n<0.001
                n.toExponential(0)
            else
                v
        # Set the slider to the nearest entry
        set_slider: (v) ->
          set_i=0
          $.each(this.stepValuesCur, (i,v2) ->
            if (v2<=v)
              set_i = i
          )
          this.slider.slider("value", set_i)

        set_max: (val, min, max, log) ->
            if !log
                @stepValuesCur = (x for x in [min..max] by 10)
            else
                # FIXME
                @stepValuesCur = [0,1,2,3,4,5,10,20,100,200,Math.floor(max/3),Math.floor(max/2),max]
                @stepValuesCur = @stepValuesCur.filter((v) -> v>=min && v<=max)
            @slider.slider("option", "max", @stepValuesCur.length-1)
            @set_slider(val)

</script>
