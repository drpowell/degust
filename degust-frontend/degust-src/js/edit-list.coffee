# Class to allow inline editing of checkboxes.
# It will show an "overlay" over the reset of the screen
# And add a "apply" and "cancel" buttton.  With callbacks for each
class EditList
    constructor: (@opts) ->
        @elem = $(@opts.elem)
        return if @elem.data('edit')

        @_enable()

    _enable: () ->
        @elem.data('edit', true)
        @elem.addClass('edit-elem')

        cancel_btn = $("<button class='btn btn-default btn-sm'>Cancel</button>")
        apply_btn  = $("<button class='btn btn-primary btn-sm'>Apply</button>")
        @buttons = $('<div class="edit-btns">')
        @buttons.append(cancel_btn)
        @buttons.append(apply_btn)
        @elem.append(@buttons)
        cancel_btn.click(() => @_cancel())
        apply_btn.click(() => @_apply())


        # now the overlay highlight
        @over = $('<div class="edit-overlay">')
        @elem_back = $('<div class="edit-backdrop">')

        offset = @elem.offset()
        offset.top = offset.top-4
        offset.left = offset.left-4
        @elem_back.width(@elem.innerWidth()+8).height(@elem.innerHeight()+8).offset(offset)

        $("body").append(@over)
        $("body").append(@elem_back)


    _cancel: () ->
        @_done()
        @opts.cancel()

    _apply: () ->
        @_done()
        @opts.apply()

    _done: () ->
        @elem.data('edit', false)
        @elem.removeClass('edit-elem')
        @buttons.remove()
        @over.remove()
        @elem_back.remove()

window.EditList = EditList