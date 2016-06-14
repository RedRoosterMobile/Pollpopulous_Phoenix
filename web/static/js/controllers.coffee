((window, angular) ->

  controllers = angular.module('Pollpopulous.controllers', [
    'nvd3ChartDirectives'
    #'ngAudio'
    'ngAnimate'
  ])
  controllers.controller 'mainController', [
    '$scope'
    '$http'
    '$timeout'
    #'ngAudio'
    'mmModernizr'
    ($scope, $http, $timeout, modernizr) ->
      # https://gist.github.com/danielgtaylor/0b60c2ed1f069f118562

      # fnord: on ios, only last loaded sound will play
      $scope.sfxOverAndOut = $ngAudio.load('/overandout_long.wav') if modernizr.audio
      $scope.sfxBlip = $ngAudio.load('/blip.wav') if modernizr.audio
      $scope.sfxCoin = $ngAudio.load('/coin.wav') if modernizr.audio

      $scope.descriptionFunction = ->
        (d) ->
          d.name

      $scope.voteCount = ->
        (d) ->
          d.votes.length

      $scope.getIndexOfCandidate = (candidate) ->
        $scope.data.candidates.indexOf candidate

      $scope.alerts = [ {
        type: 'success'
        msg: 'Welcome to Lunch Poll'
        timestamp: Date.now()
      } ]

      $scope.closeAlert = (index) ->
        $scope.alerts.splice index, 1
        $scope.sfxOverAndOut.play() if modernizr.audio
        return

      colors = [
        'url(#gradientForegroundPurple)'
        'url(#gradientForegroundRed)'
        'rgba(120,230,122,0.3)'
        'gold'
        'purple'
        'darkBlue'
        'lightBrown'
        'lightRed'
        'darkOrange'
      ]

      $scope.color = ->
        (d) ->
          colors[$scope.getIndexOfCandidate(d.data)]

      $scope.data = {}
      url = location.pathname.split('/').splice(-1)
      console.log('Socket');
      socket = new Socket("/socket")
      console.log socket
      socket.connect()
      socket.onClose( (e) -> console.log("Closed") )
      console.log socket

      # dispatcher = new WebSocketRails(location.host + '/websocket')
      channel = socket.channel("rooms:#{url[0]}", {})
      channel.join()
        .receive "error", -> console.log("Failed to connect")
        .receive "ok", -> console.log("Connected!")
      #channel = dispatcher.subscribe(url[0])

      $scope.init = (msg, poll_id) ->
        console.log 'init called'
        $scope.data.keywords = [
          'food'
          'meat'
        ]
        console.log msg
        $scope.data.nickname = ''

        $scope.data.knownSender = false
        $scope.data.optionName = ''
        $scope.data.candidates = msg
        $scope.data.poll_id = poll_id
        storedNickname = localStorage.getItem('nickname')
        if storedNickname and storedNickname.length > 0
          $scope.data.nickname = storedNickname
          $scope.data.knownSender = true
        # catch broadcasts on channel
        channel.on 'new_candidate', (data) ->
          $scope.$apply ->
            $scope.data.candidates.push data
            return
          return
        channel.on 'revoked_vote', (data) ->
          console.log 'revoked vote-----------------'
          console.log "data #{data}"
          console.log data

          # kick out corresponding vote
          #candidate = $.grep $scope.data.candidates, (where) -> where.id == data.candidate_id
          #if candidate.length > 0
          #  vote = $.grep candidate[0].votes , (where) -> where.id == data.vote.id
          #  if vote.length > 0
          #    $scope.data.candidates[$scope.data.candidates.indexOf(candidate[0])].votes.pop(vote[0])

          # madness, but works!!

          smash = false
          i = 0
          while i < $scope.data.candidates.length
            if $scope.data.candidates[i].id == data.candidate_id
              j = 0
              while j < $scope.data.candidates[i].votes.length
                isSameName = $scope.data.candidates[i].votes[j].nickname == data.vote.nickname
                isSameId = $scope.data.candidates[i].votes[j].id == data.vote.id
                if isSameName and isSameId
                  $scope.$apply ->
                    # kick it out
                    console.log $scope.data.candidates[i].votes.splice j, 1
                    smash = true
                    return
                if smash
                  break
                j++
            if smash
              break
            i++

          return
        channel.on 'new_vote', (data) ->
          console.log 'new_vote'
          console.log data
          for candidate in $scope.data.candidates
            console.log candidate
            console.log data.candidate_id
            console.log candidate.id

            if candidate.id == data.candidate_id
              console.log candidate.votes
              $scope.$apply ->
                # update goes here
                candidate.votes.push data.vote
                return
          return

        wsSuccess = (data) ->
          console.log 'ws: successful'
          console.log data
          $scope.data.knownSender = true
          localStorage.setItem 'nickname', $scope.data.nickname
          $scope.sfxCoin.play() if modernizr.audio
          return

        wsFailure = (data) ->
          console.log 'ws: failed'
          console.log data
          $scope.$apply ->
            $scope.alerts.push
              msg: data.message
              type: 'warning'
              timestamp: Date.now()
            return
          $scope.sfxBlip.play() if modernizr.audio
          popAlert()
          return

        popAlert = ->
          # trigger leave animation after certain time
          $timeout (->
            numAlerts = $scope.alerts.length
            if numAlerts
              $scope.closeAlert $scope.alerts[numAlerts - 1]
            return
          ), 3000
          # fiqure out a way to eliminate this timer

        # pop welcome alert once
        popAlert()

        $scope.vote = (option_id) ->
          console.log 'clicked vote'
          if $scope.data.nickname and $scope.data.nickname != ''
            message =
              nickname: $scope.data.nickname
              candidate_id: option_id
              url: url[0]
              poll_id: $scope.data.poll_id
            #dispatcher.trigger 'poll.vote_on', message, wsSuccess, wsFailure
            channel.push "pp:vote_for_candidate", message
          else
            $timeout ->
              wsFailure message: 'define your nickname first'
              return
          return

        $scope.revokeVote = (option) ->
          console.log 'clicked revoke'
          vote = $.grep option.votes, (where) -> where.nickname == $scope.data.nickname
          if vote.length > 0
            message =
              nickname: $scope.data.nickname
              vote_id: vote[0].id
              poll_id: $scope.data.poll_id
              candidate_id: option.id
              url: url[0]
            dispatcher.trigger 'poll.revoke_vote', message, wsSuccess, wsFailure
            return
          else if option.votes.length > 0
            $timeout ->
              wsFailure message: 'Not your vote'
              return
          else if option.votes.length == 0
            $timeout ->
              wsFailure message: 'Ever heard of negative votes?'
              return
          return

        $scope.addOption = ->
          # todo: min nickname length
          title = $scope.data.optionName.trim()
          nickname = $scope.data.nickname.trim()
          if title? and nickname? and nickname != '' and title != ''
            message =
              url: url
              poll_id: $scope.data.poll_id
              name: title
            dispatcher.trigger 'poll.add_option', message, wsSuccess, wsFailure
          else if title? or title == ''
            console.log 'define option title first '
            $timeout ->
              wsFailure message: 'define option title first'
              return
          else if nickname? or nickname == ''
            console.log 'define your nickname first'
            $timeout ->
              wsFailure message: 'define your nickname first'
              return
          return

        return

      return
  ]
  return
) window, window.angular
