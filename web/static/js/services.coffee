services = angular.module('Pollpopulous.services', [])

# phantomjs does't support video and audio
services.service 'mmModernizr', [ ->
  return window.Modernizr or {}
  #return {
  #  video: true
  #}
]
