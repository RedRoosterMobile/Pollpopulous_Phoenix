// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

//import socket from "./socket"

// import $ from "jquery"
//import * as bootstrap from './bootstrap.min';
import angular from "angular"
import "angular-animate"
import "d3"
import "nvd3"

import * as ngAudio from "./angular.audio"
//import "angular-ui-bootstrap"
import * as ui from "./angular.ui.bootstrap"
import "angular-nvd3"

import * as controllers from './controllers'
import * as directives from './directives'
import * as services from './services'


import {Socket} from "phoenix"
// coffescript
// http://www.phoenixframework.org/docs/static-assets
class App {
  static init() {

    // import madness es6 to coffee
    window.Socket = Socket;
    window.$ = $;


    var $body = $('body');
    var ratioHandler =  () => {
        var ratio = this.calculateAspectRatio($body);
        if (ratio > 2.125) {
            console.log('bad ratio!');
            $body.removeClass('rolling');
        } else {
            $body.addClass('rolling');
            console.log('good ratio!');
        }
    };

    // fuck this, go back to static fullscreen bg
    /*
    $( window ).scroll(function(event) {
      console.log(event);
      console.log($('body').last().offset());
      console.log($(".list-group-item-text").last().offset());
    });
    */


    $(window).resize(ratioHandler);
    ratioHandler();

    let p=$('.pollpopulous');
    if (p.length>0) {
      let coverEditor = angular.module('Pollpopulous', [
        //'templates',
        'ui.bootstrap',
        'Pollpopulous.controllers',
        'Pollpopulous.directives',
        'Pollpopulous.services',
        'ngAnimate',
      ])
      console.log(p);
      angular.bootstrap ($('.pollpopulous')[0], [ 'Pollpopulous' ]);
      console.log(p);
    }
    return
    // todo: just manually bootstrap an app, depending on page
    let $message  = $("#message")
    let $username = $("#username")
    let $messages = $("#messages")
    let $candidateButton = $("#addCandidate")
    let $candidate = $("#candidate")
    let $voteButton = $("#vote")

    let socket = new Socket("/socket")
    socket.connect()
    socket.onClose( e => console.log("Closed") )
    console.log(socket);

    let pathname = window.location.pathname;
    let room = 'lobby';
    let splitPath = pathname.split('/');
    pathname = splitPath[splitPath.length-1]
    if (pathname.length > 1 ){
      pathname = pathname.replace('/','');
      room = pathname;
    }
    console.log(pathname);
    let channel = socket.channel("rooms:"+pathname, {})
    channel.join()
      .receive("error", () => console.log("Failed to connect"))
      .receive("ok", () => console.log("Connected!"))

    channel.on("new:message", msg => this.appendMessage(msg))
    channel.on("new:candidate", msg => this.appendCandidate(msg))

    if ($candidateButton) {
      $candidateButton.on('click', e => {
        console.log('addCandidate'+ $candidate.val());
        channel.push("pp:add_candidate", {
          nickname: $username.val(),
          candidate: $candidate.val(),
          poll: room
        })
        console.log('addedCandidate');
      })
    }
    if ($voteButton) {
      $voteButton.on('click', e => {
        console.log('voting for candidate'+ $candidate.val() + ' on room ' + room);
        channel.push("pp:vote_for_candidate", {
          nickname: $username.val(),
          candidate: $candidate.val(),
          poll: room
        })
        console.log('addedCandidate');
      })
    }


    $message
      .off("keypress")
      .on("keypress", e => {
        if(e.keyCode == 13) {
          channel.push("new:message", {
            user: $username.val(),
            body: $message.val()
          })
          $message.val("")
        }
      })
  }

  static sanitize(msg) { return $("<div />").text(msg).html() }

  static calculateAspectRatio($element) {
    return $element.width() / $element.height();
  }

  static appendMessage(message) {
    let $messages = $("#messages")
    let username = this.sanitize(message.user || "New User")
    let messageBody  = this.sanitize(message.body)

    $messages.append(`<p><b>[${username}]</b>: ${messageBody}</p>`)
  }

  static vote(candidate_id) {
    console.log(candidate_id);
  }

  static appendCandidate(message) {
    console.log('new:candidate');
    console.log(message);
  }

}

$( () => App.init() )

export default App
