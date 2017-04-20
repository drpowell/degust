
window.our_log = (o) ->
    if window.console && console.log
        console.log.apply(console, if !!arguments.length then arguments else [this])
    else opera && opera.postError && opera.postError(o || this)

window.log_info = (o) -> log_msg("INFO", arguments)
window.log_warn = (o) -> log_msg("WARN", arguments)
window.log_error = (o) -> log_msg("ERROR", arguments)
window.log_debug = (o) ->
    log_msg("DEBUG", arguments) if window.debug?

# Our internal log allowing a log type
log_msg = (msg,rest) ->
    args = Array.prototype.slice.call(rest)
    r = [msg].concat(args)
    window.our_log.apply(window, r)

    return if msg=='DEBUG'

    $('.log-list').append("<pre class='#{msg.toLowerCase()}'>#{msg}: #{args}")
    if msg=='ERROR'
        $('.log-link').removeClass('btn-link')
        $('.log-link').addClass('btn-danger')
    if msg=='ERROR' || msg=='WARN'
        $('.log-link').css('opacity','1')


# ------------------------------------------------------------
# This "scheduler" is designed to be used for tasks that may take some time, and
# will be called often.  For example, updating the heatmap, or datatable.
# It will schedule a given task after a set timeout, if the same task is re-scheduled before
# it is run, its schedule time will be reset
# Use: "schedule" for tasks that may be overwritten by later tasks
#      "schedule_now" for tasks that must not be skipped (these will run *now*)
class ScheduleTasks
    constructor: () ->
        @tasks = {}
        @interval = 100

    schedule: (lbl, func, interval=@interval) ->
        if @tasks[lbl]
            # Already a pending update.  Cancel it and re-schedule
            #msg_debug("clearing",lbl,@tasks[lbl].id)
            clearTimeout(@tasks[lbl].id)

        # No task pending.  add it, and schedule an update
        @tasks[lbl] =
            func: func
            id: setTimeout((() => @_runNow(lbl)), interval)
        #msg_debug("set",lbl,@tasks[lbl].id)

    # Used when an important task must run and not be overridden by later tasks
    schedule_now: (lbl, func) ->
        @tasks[lbl] =
            func: func
        @_runNow(lbl)

    _runNow: (lbl) ->
        task = @tasks[lbl]
        if task
            # Ensure there is still a task, may have been run by schedule_now()
            delete @tasks[lbl]
            #msg_debug("running",lbl,task.id)
            task.func()


window.scheduler = new ScheduleTasks()
# ------------------------------------------------------------

# Convert any parameters in the pages url into a hash
split_params = (loc) ->
    vars = {}
    hash = null
    idx = loc.indexOf('?')
    return vars if idx<0

    hashes = loc.slice(idx + 1).split('&')
    for i in [0..hashes.length-1]
        hash = hashes[i].split('=')
        if hash[0].length>0
            vars[hash[0]] = decodeURIComponent(hash[1].replace(/\#$/,''))
    vars

window.get_url_vars = () ->
    split_params(window.location.search)

window.get_hash_vars = () ->
    split_params(window.location.hash)

window.set_hash_var = (set) ->
    p = get_hash_vars()
    for k,v of set
        if v?
            p[k] = v
        else
            delete p[k]

    loc = (for k,v of p
               k + "=" + encodeURIComponent(v)).join("&")
    if loc.length>0
        window.location.hash = '?'+loc
    else
        window.location.hash = ''

window.setup_nav_bar = () ->
    about = $(require("../templates/about.hbs")(version: degust_version))
    $('#about-modal').replaceWith(about)
    $("a.log-link").click(() -> $('.log-list').toggle())

    window.debug ?= get_url_vars()["debug"]

# ------------------------------------------------------------
# WorkerWrapper : Take a javascript function, and wrap it in a web-worker.
# NOTE: The passed function can have no external dependencies!
# This handles creating a new blob for the function, and releases that blob
# on each new start() call
class WorkerWrapper
    constructor: (worker_fn, @callback) ->
        @blob = new Blob(["onmessage ="+worker_fn.toString()], { type: "text/javascript" })

    stop: () ->
        if @blobURL?
            #console.log "Terminating existing worker"
            @worker.terminate()
            window.URL.revokeObjectURL(@blobURL)
            @blobURL = null

    start: (data) ->
        @stop()
        @blobURL = window.URL.createObjectURL(@blob)
        @worker = new Worker(@blobURL)
        @worker.onmessage = (e) => @callback(e.data)
        @worker.postMessage(data)

window.WorkerWrapper = WorkerWrapper

# ------------------------------------------------------------
# SVG Downloading
#
class SVG
    # Recursively call copyStyle
    @copyStyleDeep = (src,dest) ->
        SVG.copyStyle(src, dest)

        sChildren = src.node().childNodes
        dChildren = dest.node().childNodes
        console.log "Mismatch number of children!" if sChildren.length != dChildren.length
        for i in [0...sChildren.length]
            if sChildren[i].nodeType == Node.ELEMENT_NODE
                SVG.copyStyleDeep(d3.select(sChildren[i]), d3.select(dChildren[i]))

   # Copy the style of the src nodes.  Just the styles that are important
    @copyStyle = (src, dest) ->
            # Hide any "visibilty" hidden nodes.  Necessary for InkScape
            if (src.style('visibility') == 'hidden')
               dest.style('display','none')
            else if src.node().tagName == 'text'
                ['font-size','font-family'].forEach((a) ->
                    dest.style(a, src.style(a))
                )
                # convert dx/dy from 'em' to 'px'.
                ['dx','dy'].forEach((a) ->
                    if (m = /(.*)em/.exec(dest.attr(a)))
                        dest.attr(a, m[1] * 10)       # Assume 10px font-size.  HACK
                )
            else  if src.node().tagName in ['rect','line','path']
                ['fill','stroke','fill-opacity'].forEach((a) ->
                    dest.style(a, src.style(a))
                )

    # Download an SVG element.  Expects the passed element selector to have an
    # attribute 'data-for' that is a selector for the SVG to download
    @download_svg = (e) ->
        svg_elem = d3.select(d3.select(e).attr('data-for'))
        node = svg_elem.node().cloneNode(true)
        SVG.copyStyleDeep(svg_elem, d3.select(node))

        d3.select(node)
          .attr("version", 1.1)
          .attr("xmlns", "http://www.w3.org/2000/svg")

        wrapper = document.createElement('div')
        wrapper.appendChild(node)
        html = wrapper.innerHTML
        d3.select(e)
          .attr("href-lang", "image/svg+xml")
          .attr("href", "data:image/svg+xml;base64,\n" + btoa(html))

@download_svg = SVG.download_svg
# ------------------------------------------------------------
# Dynamic JS loading
#
class DynamicJS
    @LOADED = {}
    @LOADING = {}

    @load = (src, cb) ->
        if src of @LOADED
            cb()
            return
        if src of @LOADING
            @LOADING[src] = cb
            return
        head = document.getElementsByTagName('head')[0]
        script = document.createElement('script')
        script.type = 'text/javascript'
        script.src = src
        #   script.onreadystatechange= () ->
        #       if (this.readyState == 'complete')
        #           cb()
        @LOADING[src] = cb
        script.onerror = () =>
            log_error("Unable to load : ",src)
        script.onload = () =>
            @LOADED[src] = true
            @LOADING[src]()      # Call the latest callback that has been registered

        head.appendChild(script);
window.DynamicJS = DynamicJS
