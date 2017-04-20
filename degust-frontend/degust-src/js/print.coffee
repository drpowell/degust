
class Print
    # Construct a print for SVG.  The specified "svg" can be :
    #   - d3 selection
    #   - an html node
    #   - or function that returns an html node
    constructor: (@svg, @name) ->

    menu: () ->
        [{  title: 'Save as SVG', action: () => @_to_svg() },
         {  title: 'Save as PNG', action: () => @_to_png() },
        ]

    _get_svg: () ->
        if (typeof @svg == "function")
            r=@svg()
        else if (@svg instanceof d3.selection)
            r=@svg.node()
        else
            r=@svg
        if ('svg' of r)
            [r.svg, r.width, r.height]
        else
            [r, r.clientWidth, r.clientHeight]

    _to_svg: () ->
        doctype = '<?xml version="1.0" standalone="no"?>' +
                  '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'

        # serialize our SVG XML to a string.
        source = (new XMLSerializer()).serializeToString(@_get_svg()[0])

        # create a file blob of our SVG.
        blob = new Blob([ doctype + source], { type: 'image/svg+xml;charset=utf-8' })

        url = window.URL.createObjectURL(blob)

        downloadLink = document.createElement("a")
        downloadLink.href = url
        downloadLink.download = @name + ".svg"
        document.body.appendChild(downloadLink)
        downloadLink.click()
        document.body.removeChild(downloadLink)

    _to_png: () ->
        # create the div element that will hold the context menu
        back = d3.selectAll('.print-backdrop').data([1])
                 .enter().append('div').attr('class','print-backdrop')
        div = d3.selectAll('.print-popup').data([1])
            .enter()
            .append('div')
            .attr('class', 'print-popup')
            .style('left', (d3.event.pageX - 2) + 'px')
            .style('top', (d3.event.pageY - 2) + 'px')
            .style('display', 'block')

        [svg,w,h] = @_get_svg()
        w||=300
        h||=300

        div.html("<form>
                   <div><label>File name</label><input class='pr-name' value='#{@name}'/></div>
                   <div><label>Width</label><input class='pr-width' value='#{w}'/></div>
                   <div><label>Height</label><input class='pr-height' value='#{h}'/></div>
                   <div><button class='submit' type='submit'>Save</button><button class='cancel' type='submit'>Cancel</button></div>
                 </form>")

        done = () =>
            div.remove()
            back.remove()

        back.on('click', () =>
            d3.event.preventDefault()
            done()
        )

        div.select('.submit').on('click', () =>
            d3.event.preventDefault()
            name = div.select(".pr-name").node().value
            w = div.select(".pr-width").node().value
            h = div.select(".pr-height").node().value
            done()
            @._to_png_finish(name,w,h)
        )
        div.select('.cancel').on('click', () =>
            d3.event.preventDefault()
            done()
        )

    _to_png_finish: (name,width,height) ->
        source = (new XMLSerializer()).serializeToString(@_get_svg()[0])

        canvas = document.createElement( "canvas" )
        ctx = canvas.getContext( "2d" )
        img = document.createElement( "img" )
        img.width  = canvas.width  = width
        img.height = canvas.height = height

        img.setAttribute( "src", "data:image/svg+xml;base64," + btoa( source ) )
        img.onload = () =>
            ctx.drawImage( img, 0, 0, img.width, img.height )
            imgsrc = canvas.toDataURL("image/png")

            downloadLink = document.createElement("a")
            downloadLink.download = name + ".png"
            downloadLink.href = imgsrc
            document.body.appendChild(downloadLink)
            downloadLink.click()
            document.body.removeChild(downloadLink)

    # Recursively call copyStyle
    @copy_svg_style_deep: (src,dest) ->
        Print.copy_svg_style(src, dest)

        sChildren = src.node().childNodes
        dChildren = dest.node().childNodes
        if (sChildren.length != dChildren.length)
            console.log("Mismatch number of children!")

        for i in [0...sChildren.length]
            if (sChildren[i].nodeType == Node.ELEMENT_NODE)
                Print.copy_svg_style_deep(d3.select(sChildren[i]), d3.select(dChildren[i]))

    # Copy the style of the src nodes.  Just the styles that are important
    @copy_svg_style: (src, dest) ->
        # Hide any "visibilty" hidden nodes.  Necessary for InkScape
        if (src.style('visibility') == 'hidden')
           dest.style('display','none')
        else if (src.node().tagName == 'text')
            ['font-size','font-family'].forEach((a) => dest.style(a, src.style(a)))
            # convert dx/dy from 'em' to 'px'.
            ['dx','dy'].forEach((a) =>
                m = /(.*)em/.exec(dest.attr(a))
                if (m)
                    dest.attr(a, m[1] * 10)       # Assume 10px font-size.  HACK
            )
        else if (['rect','line','path'].indexOf(src.node().tagName)>=0)
            ['fill','stroke','fill-opacity','display'].forEach((a) => dest.style(a, src.style(a)))

window.Print = Print
