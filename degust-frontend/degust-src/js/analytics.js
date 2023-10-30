// Google Analytics
// Please keep, we need this for user numbers for funding degust development

window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', 'G-SBXH4BS1QV');
gtag('set', 'allow_google_signals', false);
gtag('set', 'user_properties', {
  'degust-version': degust_version
});

(function() {
  var ga = document.createElement('script');
  ga.type = 'text/javascript';
  ga.async = true;
  ga.src = "https://www.googletagmanager.com/gtag/js?id=G-SBXH4BS1QV"
  var s = document.getElementsByTagName('script')[0];
  s.parentNode.insertBefore(ga, s);
})();

window.onerror = function(message, file, line) {
  var sFormattedMessage = '[' + file + ' (' + line + ')] ' + message;
  gtag('event', 'exception', {
    'description': sFormattedMessage,
    'fatal': false   // set to true if the error is fatal
  });
}
