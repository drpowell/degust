
# JQuery
window.jQuery = window.$ = require('./lib/jquery-1.10.2.js')
require('./lib/jquery-ui.js')

# Bootstrap
require('./lib/bootstrap-3.0.0.js')

# Ours
require('./version.coffee')
require('./util.coffee')

# Google Analytics
# Please keep, we just this for user numbers for funding degust development
require('./analytics.js')


# Display a popup warning, or fill in a warning box if using IE
add_browser_warning = () ->
	if window.navigator.userAgent.indexOf("MSIE ")>=0
		html = require("./browser-warning.html")
		outer = document.getElementsByTagName('body')
		outer[0].insertAdjacentHTML('afterbegin', html)

window.onload = () ->
	add_browser_warning()
