// Google Analytics
// Please keep, we just this for user numbers for funding degust development

window._gaq = window._gaq || [];
window._gaq.push(['drp._setAccount', 'UA-45207067-1']);
window._gaq.push(['drp._setCustomVar',1,'widget','degust']);
window._gaq.push(['drp._setCustomVar',2,'degust-version',degust_version]);
window._gaq.push(['drp._trackPageview']);

(function() {
  var ga = document.createElement('script');
  ga.type = 'text/javascript';
  ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0];
  s.parentNode.insertBefore(ga, s);
})();

window.onerror = function(message, file, line) {
  var sFormattedMessage = '[' + file + ' (' + line + ')] ' + message;
  _gaq.push(['drp._trackEvent', 'Exceptions', 'Application', sFormattedMessage, null, true]);
}
