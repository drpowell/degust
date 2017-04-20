# ------------------------------------------------------------
# Slider routines
class Slider
    # Set the slider to the nearest entry
    set_slider: (v) ->
      set_i=0
      $.each(@stepValues, (i,v2) ->
        if (v2<=v)
          set_i = i
      )
      @slider.slider("value", set_i)

    fmt: (v) ->
      if @opts.fmt?
        return @opts.fmt(v)

      n=Number(v)
      if n==undefined
          v
      else if n>0 && n<0.001
          n.toExponential(0)
      else
          v

    set_max: (val, min, max, log) ->
        if !log
            @stepValues = (x for x in [min..max] by 10)
        else
            # FIXME
            @stepValues = [0,1,2,3,4,5,10,20,100,200,Math.floor(max/3),Math.floor(max/2),max]
            @stepValues = @stepValues.filter((v) -> v>=min && v<=max)
        @slider.slider("option", "max", @stepValues.length-1)
        @set_slider(val)
        $(@opts.input_id).val(@fmt(val))
        @opts.on_change(val)

    set_val: (val, fire_change) ->
        $(@opts.input_id).val(@fmt(val))
        @set_slider(val)
        if fire_change?
            @opts.on_change(val)

    constructor: (@opts) ->
        @stepValues = @opts.step_values || [0..10]
        @slider = $(@opts.id).slider({
          animate: true,
          min: 0,
          max: @stepValues.length-1,
          value: 1,
          slide: (event, ui) =>
            v = @stepValues[ui.value]
            $(@opts.input_id).val(@fmt(v))
            @opts.on_change(v)
        })

        @set_val(@opts.val) if @opts.val?

        self = this
        $(@opts.input_id).keyup(() ->
          v = $(this).val()
          if self.opts.validator(v)
            $(this).removeClass('error')
            self.set_slider(v)
            self.opts.on_change(v)
          else
            $(this).addClass('error')
        )

window.Slider = Slider
