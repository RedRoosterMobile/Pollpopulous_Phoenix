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


import {Socket} from "phoenix"

class App {
  static init() {
    let $message  = $("#message")
    let $username = $("#username")
    let $messages = $("#messages")

    let socket = new Socket("/socket")
    socket.connect()
    socket.onClose( e => console.log("Closed") )
    console.log(socket);

    let pathname = window.location.pathname;
    let room = 'lobby';
    if (pathname != '/') {
      pathname = pathname.replace('/','');
      room = pathname;
    }
    console.log(pathname);
    let channel = socket.channel("rooms:"+pathname, {})
    channel.join()
      .receive("error", () => console.log("Failed to connect"))
      .receive("ok", () => console.log("Connected!"))

    channel.on("new:message", msg => this.appendMessage(msg))

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

  static appendMessage(message) {
    let $messages = $("#messages")
    let username = this.sanitize(message.user || "New User")
    let messageBody  = this.sanitize(message.body)

    $messages.append(`<p><b>[${username}]</b>: ${messageBody}</p>`)
  }
}

$( () => App.init() )

export default App
