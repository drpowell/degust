
# JQuery
window.jQuery = window.$ = require('./lib/jquery-1.10.2.js')
require('./lib/jquery-ui.js')

# Bootstrap
require('./lib/bootstrap-3.0.0.js')

# Ours
require('./version.coffee')
require('./util.coffee')
require('./gene_data.coffee')

# Display a popup warning, or fill in a warning box if using IE
add_browser_warning = () ->
	if window.navigator.userAgent.indexOf("MSIE ")>=0
		html = require("../templates/browser-warning.hbs")()
		outer = $('.browser-warning-outer')
		if outer.length==0
			# No container found, let's create a popup one
			$('body').prepend('<div class="warning-popover browser-warning-outer"></div>')
			outer = $('.browser-warning-outer')
		outer.append(html)

$(document).ready(() ->
	add_browser_warning()
)
