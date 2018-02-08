<style scoped>
</style>

<template>
    <div class='scatter-outer' ref='outer'>
    </div>
</template>

<script lang='coffee'>


class Scatter3d
    constructor: (@opts) ->
        @el = el = @opts.elem

        @colour = @opts.colour || d3.scale.category10()

        renderer = @renderer = new THREE.WebGLRenderer({ antialias: true })

        w = @w = @opts.tot_width || el.clientWidth
        h = @h = @opts.tot_height || w #el.clientHeight
        @renderer.setSize(w, h)
        @animating = true

        @_make_menu(renderer.domElement)

        el.appendChild(renderer.domElement)
        renderer.setClearColor(new THREE.Color(0xFFFFFF))

        @camera = new THREE.PerspectiveCamera(45, w / h, 1, 10000)
        @camera.position.z = 215
        @camera.position.x = 0
        @camera.position.y = 0

        @scene = new THREE.Scene()

        @scatterPlot = new THREE.Object3D()
        @scene.add(@scatterPlot)
        @axis_group = new THREE.Object3D()
        @scene.add(@axis_group)

        @raycaster = new THREE.Raycaster()
        @mouse = new THREE.Vector2()

        # Add light to scene
        @scene.add(new THREE.HemisphereLight( new THREE.Color("#888888") ,new THREE.Color("#111111")))
        dl  = new THREE.DirectionalLight( 0xffffff , 0.7)
        dl.position.set(0,1,1)
        @scene.add(dl)

        @xScale = d3.scale.linear()
        @yScale = d3.scale.linear()
        @zScale = d3.scale.linear()

        @onResize(el,  () =>
          w = @w = el.clientWidth
          h = @h = w #el.clientHeight
          @renderer.setSize(w,h)
          @renderer.setViewport(0, 0, w, h)
          @camera.aspect = w / h
          @camera.updateProjectionMatrix()
        )

        @columns = {x: {}, y: {}, z: {}}
        @axis_type=1
        @setup_axis()

        @setup_events()

        @animate()

    update_data: (data, dims) ->
        [dim1,dim2,dim3] = dims
        # if (data instanceof DataFrame)
        #     data = data.get_data()

        @columns = {x: {name: dim1.name}, y: {name: dim2.name}, z: {name: dim3.name}}

        xExtent = d3.extent(data.map((d) -> dim1.get(d)))
        yExtent = d3.extent(data.map((d) -> dim2.get(d)))
        zExtent = d3.extent(data.map((d) -> dim3.get(d)))

        # Force equal extent on all dimensions.  Possibly make this an option in future
        xExtent = yExtent = zExtent = d3.extent(xExtent.concat(yExtent,zExtent))

        @xScale.domain(xExtent).nice()
                   .range([-50,50])
        @yScale.domain(yExtent).nice()
                   .range([-50,50])
        @zScale.domain(zExtent).nice()
                   .range([-50,50])

        # Delete any existing points
        for i in [@scatterPlot.children.length - 1 .. 0]
            @scatterPlot.remove(@scatterPlot.children[i])

        sphereGeo = new THREE.SphereGeometry( 2, 16, 16 )
        for i in [0...data.length]
            sphereMat = new THREE.MeshLambertMaterial( {color : @colour(data[i].sample.parent) })
            sphere = new THREE.Mesh(sphereGeo, sphereMat)
            sphere.position.x = @xScale(dim1.get(data[i]))
            sphere.position.y = @yScale(dim2.get(data[i]))
            sphere.position.z = @zScale(dim3.get(data[i]))
            sphere.userData = {datapoint: data[i]}

            @scatterPlot.add( sphere )

        @setup_axis()

    # Create a loop that monitors size of an element and fires occasional events for it
    onResize: (element, callback) ->
      height = element.clientHeight
      width  = element.clientWidth

      setInterval((() ->
          if (element.clientHeight != height || element.clientWidth != width)
            height = element.clientHeight
            width  = element.clientWidth
            callback()
      ), 500)


    _make_menu: (el) ->
        print_menu = (new Print(@svg, "scatter3d")).menu()
        menu = [ {  divider: true },
                {
                    title: 'Reset view',
                    action: (elm, d, i) =>
                        @scatterPlot.rotation.x = @scatterPlot.rotation.y = @scatterPlot.rotation.z = 0
                        @axis_group.rotation.x = @axis_group.rotation.y = @axis_group.rotation.z = 0
                        @camera.fov = 45
                        @camera.projectionMatrix = new THREE.Matrix4().makePerspective(@camera.fov,  @renderer.domElement.width/@renderer.domElement.height, @camera.near, @camera.far)
                },
                {
                    title: 'Toggle animation',
                    action: (elm, d, i) => @animating =! @animating
                },
                {
                    title: 'Toggle axis',
                    action: (elm, d, i) =>
                        @axis_type = (@axis_type+1)%4
                        @setup_axis()
                }
        ]
        d3.select(el).on('contextmenu', d3.contextMenu(print_menu.concat(menu))) # attach menu to element

    # helper function to add text to object
    addText: (object, string, scale, x, y, z, color) ->
        canvas = document.createElement('canvas')
        size = 256
        canvas.width = size
        canvas.height = size
        context = canvas.getContext('2d')
        context.fillStyle = "#" + color.getHexString()
        context.textAlign = 'center'
        context.font = '24px Arial'
        context.fillText(string, size / 2, size / 2)
        amap = new THREE.Texture(canvas)
        amap.needsUpdate = true
        mat = new THREE.SpriteMaterial({
          map: amap,
          transparent: true,
          color: 0xffffff })
        sp = new THREE.Sprite(mat)
        sp.scale.set( scale, scale, scale )
        sp.position.x = x
        sp.position.y = y
        sp.position.z = z
        object.add(sp)

    setup_axis: () ->
        # First remove all old axes
        for i in [@axis_group.children.length - 1 .. 0]
            @axis_group.remove(@axis_group.children[i])

        switch @axis_type
            when 0 then '' # Do nothing
            when 1 then @setup_axis_box()
            when 2 then @setup_axis0()
            when 3
                @setup_axis_box()
                @setup_axis0()


    setup_axis_box: () ->
        group = @axis_group   # Might need a different group so doesn't overlap on hover?
        axisColor = new THREE.Color("#000000")
        v = (x,y,z) -> new THREE.Vector3(x,y,z)
        mkaxis = (x1,y1,z1,x2,y2,z2) ->
            axisGeo = new THREE.Geometry()
            axisGeo.vertices.push(v(x1,y1,z1), v(x2,y2,z2))
            axis = new THREE.Line(axisGeo, new THREE.LineBasicMaterial({color: axisColor, linewidth: 1}))
            axis.type = THREE.Lines
            return axis

        [x1,x2] = @xScale.range()
        [y1,y2] = @yScale.range()
        [z1,z2] = @zScale.range()
        group.add(mkaxis(x1,y1,z1,x2,y1,z1))
        group.add(mkaxis(x1,y2,z1,x2,y2,z1))
        group.add(mkaxis(x1,y1,z2,x2,y1,z2))
        group.add(mkaxis(x1,y2,z2,x2,y2,z2))

        group.add(mkaxis(x1,y1,z1,x1,y2,z1))
        group.add(mkaxis(x2,y1,z1,x2,y2,z1))
        group.add(mkaxis(x1,y1,z2,x1,y2,z2))
        group.add(mkaxis(x2,y1,z2,x2,y2,z2))

        group.add(mkaxis(x1,y1,z1,x1,y1,z2))
        group.add(mkaxis(x2,y1,z1,x2,y1,z2))
        group.add(mkaxis(x1,y2,z1,x1,y2,z2))
        group.add(mkaxis(x2,y2,z1,x2,y2,z2))

        xTicks = @xScale.ticks(5)
        for j in [0...xTicks.length]
            t = @xScale(xTicks[j])
            group.add(mkaxis(t,y1,z1,t,y1,z2))
        zTicks = @zScale.ticks(5)
        for j in [0...zTicks.length]
            t = @zScale(zTicks[j])
            group.add(mkaxis(x1,y1,t,x2,y1,t))

        if (@columns.x)
            @addText(group, @columns.x.name, 50, x2+5, y1, z1, axisColor)
        if (@columns.y)
            @addText(group, @columns.y.name, 50, x1, y2+5, z1, axisColor)
        if (@columns.z)
            @addText(group, @columns.z.name, 50, x1, y1, z2+5, axisColor)

        tickColor = axisColor
        tickColor.r = Math.min(tickColor.r + 0.2, 1)
        tickColor.g = Math.min(tickColor.g + 0.2, 1)
        tickColor.b = Math.min(tickColor.b + 0.2, 1)
        tick = (length, thickness, axis, scale) =>
            ticks = scale.ticks(5)
            fmt = scale.tickFormat()
            for j in [0 ... ticks.length]
                t = new THREE.Geometry()
                switch (axis)
                    when 'x'
                        a1 = a2 = a3 = @xScale(ticks[j])
                        b1 = y1+length; b2 = y1-length; b3=y1-1.5*length
                        c1 = z1+length; c2 = z1-length; c3=z1-1.5*length
                    when 'y'
                        a1 = x1+length; a2 = x1-length; a3=x1-1.5*length
                        b1 = b2=b3=@yScale(ticks[j])
                        c1 = z1+length; c2=z1-length; c3=z1-1.5*length
                    when 'z'
                        a1 = x1+length; a2 = x1-length; a3=x1-1.5*length
                        b1 = y1+length; b2 = y1-length; b3=y1-1.5*length
                        c1 = c2=c3=@zScale(ticks[j])
                t.vertices.push(v(a1,b1,c1),v(a2,b2,c2))
                if (ticks[j] != 0)
                    @addText(group, fmt(ticks[j]), 40, a3, b3, c3, tickColor)
                    tl = new THREE.Line(t, new THREE.LineBasicMaterial({color: tickColor, linewidth: thickness}))
                    tl.type=THREE.Lines
                    group.add(tl)
        tick(2, 1, 'x', @xScale)
        tick(2, 1, 'y', @yScale)
        tick(2, 1, 'z', @zScale)

    setup_axis0: () ->
        group = @axis_group   # Might need a different group so doesn't overlap on hover?
        axisColor = new THREE.Color("#000000")
        v = (x,y,z) -> new THREE.Vector3(x,y,z)
        mkaxis = (x,y,z) ->
            xAxisGeo = new THREE.Geometry()
            xAxisGeo.vertices.push(v(0, 0, 0), v(x,y,z))
            xAxis = new THREE.Line(xAxisGeo, new THREE.LineBasicMaterial({color: axisColor, linewidth: 1}))
            xAxis.type = THREE.Lines
            return xAxis
        group.add(mkaxis(@xScale.range()[0],0,0))
        group.add(mkaxis(@xScale.range()[1],0,0))
        group.add(mkaxis(0, @yScale.range()[0],0))
        group.add(mkaxis(0, @yScale.range()[1],0))
        group.add(mkaxis(0, 0, @zScale.range()[0]))
        group.add(mkaxis(0, 0, @zScale.range()[1]))
        if (@columns.x)
            @addText(group, @columns.x.name, 50, 55, 0, 0, axisColor)
        if (@columns.y)
            @addText(group, @columns.y.name, 50, 0, 55, 0, axisColor)
        if (@columns.z)
            @addText(group, @columns.z.name, 50, 0, 0, 55, axisColor)

        # Ticks
        tickColor = axisColor
        tickColor.r = Math.min(tickColor.r + 0.2, 1)
        tickColor.g = Math.min(tickColor.g + 0.2, 1)
        tickColor.b = Math.min(tickColor.b + 0.2, 1)
        tick = (length, thickness, axis, scale) =>
            ticks = scale.ticks(5)
            fmt = scale.tickFormat()
            for j in [0 ... ticks.length]
                t = new THREE.Geometry()
                switch (axis)
                    when 'x'
                        a1 = a2 = a3 = @xScale(ticks[j])
                        b1 = length; b2 = -length; b3=1.5*length
                        c1 = 0; c2 = 0; c3=0
                    when 'y'
                        a1=length; a2 = -length; a3=1.5*length
                        b1=b2=b3=@yScale(ticks[j])
                        c1=0; c2=0; c3=0
                    when 'z'
                        a1=0; a2=0; a3=0
                        b1=length; b2=-length; b3=1.5*length
                        c1=c2=c3=@zScale(ticks[j])
                t.vertices.push(v(a1,b1,c1),v(a2,b2,c2))
                if (ticks[j] != 0)
                    @addText(group, fmt(ticks[j]), 40, a3, b3, c3, tickColor)
                    tl = new THREE.Line(t, new THREE.LineBasicMaterial({color: tickColor, linewidth: thickness}))
                    tl.type=THREE.Lines
                    group.add(tl)
        tick(2, 1, 'x', @xScale)
        tick(2, 1, 'y', @yScale)
        tick(2, 1, 'z', @zScale)


    setup_events: () ->
        @mousedown = false
        sx = 0
        sy = 0
        @el.onmousedown = (ev) =>
            if (ev.button==0 && !ev.ctrlKey)
                @mousedown = true
                sx = ev.clientX
                sy = ev.clientY
        @el.onmouseup = (ev) =>
            @mousedown = false
        @el.onmousemove = (ev) =>
            if (@mousedown)
                dx = ev.clientX - sx
                dy = ev.clientY - sy
                @scatterPlot.rotation.y += dx * 0.01
                @scatterPlot.rotation.x += dy * 0.01
                @axis_group.rotation.x = @scatterPlot.rotation.x
                @axis_group.rotation.y = @scatterPlot.rotation.y
                sx += dx
                sy += dy
            else
                canvasRect = ev.target.getBoundingClientRect()
                @mouse.x = 2 * ( ev.clientX - canvasRect.left ) / canvasRect.width - 1
                @mouse.y = -2 * ( ev.clientY - canvasRect.top ) / canvasRect.height + 1
                @on_mouse_hover()

        @el.onmousewheel = (ev) => ev.preventDefault()
        @el.addEventListener('DOMMouseScroll', ((ev) => @on_mouse_wheel(ev)), true)
        @el.addEventListener('mousewheel', ((ev) => @on_mouse_wheel(ev)), true)

    on_mouse_hover: () ->
        @raycaster.setFromCamera( @mouse, @camera )
        intersects = @raycaster.intersectObject( @scatterPlot, true )
        for o in intersects
            if (o.object.userData.datapoint)
                console.log("HOVER : ",o.object.userData )
                #o.object.material.emissive.setHex( 0xffff0 )

    on_mouse_wheel: (event) ->
        fovMAX = 180
        fovMIN = 1
        deltaY = event.wheelDeltaY || -10*event.detail || event.wheelDelta
        @camera.fov -= deltaY * 0.02
        @camera.fov = Math.max( Math.min( @camera.fov, fovMAX ), fovMIN )
        @camera.projectionMatrix = new THREE.Matrix4().makePerspective(@camera.fov,  @renderer.domElement.width/@renderer.domElement.height, @camera.near, @camera.far)

    animate: () ->
        if (!@mousedown && @animating)
            @scatterPlot.rotation.z += 0.0005
            @scatterPlot.rotation.y += 0.003
            @axis_group.rotation.x = @scatterPlot.rotation.x
            @axis_group.rotation.y = @scatterPlot.rotation.y
            @axis_group.rotation.z = @scatterPlot.rotation.z

        requestAnimationFrame( () => @animate() )
        @renderer.render(@scene, @camera)
        #stats.update()

module.exports =
    name: "scatter3d"
    props:
        data:
            type: Array
            required: true
        xColumn: null
        yColumn: null
        zColumn: null

    computed:
        needsUpdate: () ->
            # As per https://github.com/vuejs/vue/issues/844#issuecomment-265315349
            this.data
            this.xColumn
            this.yColumn
            this.colour
            Date.now()
    watch:
        needsUpdate: () ->
            this.update()

    methods:
        update: () ->
            console.log "scatter3d redraw()",this
            if this.data? && this.xColumn? && this.yColumn? && this.zColumn?
                this.me.update_data(this.data, [this.xColumn,this.yColumn,this.zColumn])
    mounted: () ->
        DynamicJS.load("./three.js", () =>
            this.me = new Scatter3d(
                elem: this.$refs.outer
                tot_height: 400
            )
            this.update()
        )

</script>
