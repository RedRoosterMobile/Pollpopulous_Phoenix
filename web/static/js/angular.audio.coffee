((window, angular) ->
  'use strict'
  angular.module('ngAudio', []).directive('ngAudio', [
    '$compile'
    '$q'
    'ngAudio'
    ($compile, $q, ngAudio) ->
      {
        restrict: 'AEC'
        scope:
          volume: '='
          start: '='
          currentTime: '='
          loop: '='
          clickPlay: '='
        controller: ($scope, $attrs, $element, $timeout) ->
          audio = ngAudio.load($attrs.ngAudio)
          $scope.$audio = audio
          # audio.unbind();
          $element.on 'click', ->
            if $scope.clickPlay == false
              return
            audio.audio.play()
            audio.volume = $scope.volume or audio.volume
            audio.loop = $scope.loop
            audio.currentTime = $scope.start or 0
            $timeout (->
              audio.play()
              return
            ), 5
            return
          return

      }
  ]).service('localAudioFindingService', [
    '$q'
    ($q) ->

      @find = (id) ->
        deferred = $q.defer()
        $sound = document.getElementById(id)
        if $sound
          deferred.resolve $sound
        else
          deferred.reject id
        deferred.promise

      return
  ]).service('remoteAudioFindingService', [
    '$q'
    ($q) ->

      @find = (url) ->
        deferred = $q.defer()
        audio = new Audio
        audio.addEventListener 'error', ->
          deferred.reject()
          return
        audio.addEventListener 'loadstart', ->
          deferred.resolve audio
          return
        # bugfix for chrome...
        setTimeout (->
          audio.src = url
          return
        ), 1
        deferred.promise

      return
  ]).service('cleverAudioFindingService', [
    '$q'
    'localAudioFindingService'
    'remoteAudioFindingService'
    ($q, localAudioFindingService, remoteAudioFindingService) ->

      @find = (id) ->
        deferred = $q.defer()
        id = id.replace('|', '/')
        localAudioFindingService.find(id).then(deferred.resolve, ->
          remoteAudioFindingService.find id
        ).then deferred.resolve, deferred.reject
        deferred.promise

      return
  ]).value('ngAudioGlobals',
    muting: false
    songmuting: false).factory('NgAudioObject', [
    'cleverAudioFindingService'
    '$rootScope'
    '$interval'
    '$timeout'
    'ngAudioGlobals'
    (cleverAudioFindingService, $rootScope, $interval, $timeout, ngAudioGlobals) ->
      (id) ->

        $setWatch = ->
          $audioWatch = $rootScope.$watch((->
            {
              volume: audioObject.volume
              currentTime: audioObject.currentTime
              progress: audioObject.progress
              muting: audioObject.muting
              loop: audioObject.loop
            }
          ), ((newValue, oldValue) ->
            if newValue.currentTime != oldValue.currentTime
              audioObject.setCurrentTime newValue.currentTime
            if newValue.progress != oldValue.progress
              audioObject.setProgress newValue.progress
            if newValue.volume != oldValue.volume
              audioObject.setVolume newValue.volume
            if newValue.volume != oldValue.volume
              audioObject.setVolume newValue.volume
            $looping = newValue.loop
            if newValue.muting != oldValue.muting
              audioObject.setMuting newValue.muting
            return
          ), true)
          return

        window.addEventListener 'click', ->
          audio.play()
          audio.pause()
          window.removeEventListener 'click', twiddle
          return
        $audioWatch = undefined
        $willPlay = false
        $willPause = false
        $willRestart = false
        $volumeToSet = undefined
        $looping = undefined
        $isMuting = false
        $observeProperties = true
        audio = undefined
        audioObject = this
        @id = id
        @safeId = id.replace('/', '|')
        @loop = 0

        @unbind = ->
          $observeProperties = false
          return

        @play = ->
          $willPlay = true
          return

        @pause = ->
          $willPause = true
          return

        @restart = ->
          $willRestart = true
          return

        @stop = ->
          @restart()
          return

        @setVolume = (volume) ->
          $volumeToSet = volume
          return

        @setMuting = (muting) ->
          $isMuting = muting
          return

        @setProgress = (progress) ->
          if audio and audio.duration
            audio.currentTime = audio.duration * progress
          return

        @setCurrentTime = (currentTime) ->
          if audio and audio.duration
            audio.currentTime = currentTime
          return

        cleverAudioFindingService.find(id).then ((nativeAudio) ->
          audio = nativeAudio
          audio.addEventListener 'canplay', ->
            audioObject.canPlay = true
            return
          return
        ), (error) ->
          audioObject.error = true
          console.warn error
          return
        $interval (->
          if $audioWatch
            $audioWatch()
          if audio
            if $isMuting or ngAudioGlobals.isMuting
              audio.volume = 0
            else
              audio.volume = if audioObject.volume != undefined then audioObject.volume else 1
            if $willPlay
              audio.play()
              $willPlay = false
            if $willRestart
              audio.pause()
              audio.currentTime = 0
              $willRestart = false
            if $willPause
              audio.pause()
              $willPause = false
            if $volumeToSet
              audio.volume = $volumeToSet
              $volumeToSet = undefined
            if $observeProperties
              audioObject.currentTime = audio.currentTime
              audioObject.duration = audio.duration
              audioObject.remaining = audio.duration - (audio.currentTime)
              audioObject.progress = audio.currentTime / audio.duration
              audioObject.paused = audio.paused
              audioObject.src = audio.src
              if $looping and audioObject.currentTime >= audioObject.duration
                if $looping != true
                  $looping--
                  audioObject.loop--
                  # if (!$looping) return;
                audioObject.setCurrentTime 0
                audioObject.play()
            if !$isMuting and !ngAudioGlobals.isMuting
              audioObject.volume = audio.volume
            audioObject.audio = audio
          $setWatch()
          return
        ), 25
        return
  ]).service 'ngAudio', [
    'NgAudioObject'
    'ngAudioGlobals'
    (NgAudioObject, ngAudioGlobals) ->

      @play = (id) ->
        audio = new NgAudioObject(id)
        audio.play()
        audio

      @load = (id) ->
        new NgAudioObject(id)

      @mute = ->
        ngAudioGlobals.muting = true
        return

      @unmute = ->
        ngAudioGlobals.muting = false
        return

      @toggleMute = ->
        ngAudioGlobals.muting = !ngAudioGlobals.muting
        return

      return
  ]
  return
) window, window.angular

# ---
# generated by js2coffee 2.2.0
