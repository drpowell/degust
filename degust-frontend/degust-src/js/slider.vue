<style scoped>
    .slider { display: inline-block; width: 50px; margin: 0 10px; font-size: 8pt}

</style>
<template>
    <div>
        <input type="text" :class="{error: isError, warning: isWarning}"
               :disabled='textDisable'
               :value="this.my_fmt(value)" v-on:input="value = $event.target.value" />
        <input type="range" v-model="sliderVal" v-bind:min="min" v-bind:max="max" value="sliderVal" class="slider" id="myRange">
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
            default: () -> [0 .. 10]

    data: () ->
        value: this.value_in
        isError: false
        isWarning: false
        stepValuesCur: this.stepValues
        slider:
            data: this.stepValuesCur
        min: 0
        max: this.stepValues.length - 1
        steps: 1
        sliderVal: this.value_in

    mounted: () ->
        Vue.nextTick( () =>
            console.log(this.value, this.min, this.max)
            if this.value >= this.min && this.value <= this.max
                elArr = this.stepValuesCur.map((el) => Math.abs((el - this.value)))
                this.sliderVal = elArr.indexOf(Math.min.apply(null, elArr))
                this.max = this.stepValuesCur.length - 1
        )

    watch:
        sliderVal: (v) -> this.value = this.stepValuesCur[v]
        warning: (v) -> this.isWarning = v
        value_in: (v) -> this.value = v
        value: () ->
            if this.validator?
                this.isError = !this.validator(this.value)
            if this.value >= this.min #Find the index of the array that is closest to the value (if it is inside it)
                elArr = this.stepValuesCur.map((el) => Math.abs((el - this.value)))
                this.sliderVal = elArr.indexOf(Math.min.apply(null, elArr))
            if !this.isError
                this.$emit('input', +this.value)

    methods:
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

        set_max: (val, min, max, log) ->
            if !log
                this.stepValuesCur = (x for x in [0 .. max] by 10)
                this.stepValuesCur[0] = min
            else
                #Generate scale
                newStepValues = [0,1,2,3,4,5,10,25,50,100,200]
                if !(newStepValues.every((val) => max > val))
                    newStepValues = newStepValues.filter((val) => val < max)
                else
                    fibMax = 300
                    while max > fibMax
                        newStepValues.push(fibMax)
                        len = newStepValues.length
                        fibMax = newStepValues.slice(len - 2, len).reduce((acc, val) -> acc + val)
                newStepValues.push(max)
                this.stepValuesCur = newStepValues
            this.max = this.stepValuesCur.length - 1
            if this.value >= this.min
                elArr = this.stepValuesCur.map((el) => Math.abs((el - this.value)))
                this.sliderVal = elArr.indexOf(Math.min.apply(null, elArr))
                this.max = this.stepValuesCur.length - 1

</script>
