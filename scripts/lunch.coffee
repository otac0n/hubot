# Description:
#   Vote on where to go for lunch.
#
# Commands:
#   hubot lunch time
#   hubot lunch vote +<option>|-<option>|<option1><option2><option3>...
#   hubot lunch call
#   hubot lunch add option <option>
#   hubot lunch remove option <option>
#   hubot lunch options
#
# Author:
#   John Gietzen

module.exports = (robot) ->

  robot.brain.data.lunch = {options:[],votes:{}} if !robot.brain.data.lunch?

  shuffle = (arr) ->
      i = arr.length
      if i < 2 then return arr
      while --i
          j = ~~(Math.random() * (i+1))
          [arr[i], arr[j]] = [arr[j], arr[i]]
      return arr

  robot.respond /lunch( time)?$/i, (msg) ->
    lunch = robot.brain.data.lunch
    lunch.votes = {}
    if lunch.options.length == 0
      msg.send "No lunch options available.  Use '#{robot.name} add lunch option' to add some."
    else
      shuffle lunch.options
      options = lunch.options.map((o, i) -> String.fromCharCode(65 + i) + ": " + o).join('\n')
      msg.send 'Votes reset; options randomized:\n' + options

  robot.respond /(lunch add|add lunch)( option)? (.+)$/i, (msg) ->
    lunch = robot.brain.data.lunch
    option = msg.match[3]
    index = lunch.options.indexOf option
    if index == -1
      if lunch.options.length >= 26
        msg.send "Too many lunch options (ran out of alphabet)."
      else
        lunch.options.push option
        msg.send "Lunch option #{option} added."
    else
      msg.send "Lunch option #{option} already exists."

  robot.respond /(lunch remove|remove lunch)( option)? (.+)$/i, (msg) ->
    lunch = robot.brain.data.lunch
    option = msg.match[3]
    index = lunch.options.indexOf option
    if index != -1
      for id, vote of lunch.votes
        i = 0
        while i < vote.length
          v = vote[i]
          if v == index
            vote.splice i, 1
          else
            if v > index then vote[i] = v - 1
            i++
      lunch.options.splice index, 1
      msg.send "Lunch option #{option} removed."
    else
      msg.send "Lunch option #{option} does not exist."

  robot.respond /lunch options$/i, (msg) ->
    msg.send robot.brain.data.lunch.options.join('\n')

  robot.respond /(lunch vote|vote lunch) ([-+]?)(.+)$/i, (msg) ->
    lunch = robot.brain.data.lunch
    user = msg.message.user
    action = msg.match[2]
    selection = msg.match[3].toUpperCase()
    options = selection.split("").map((c) -> c.charCodeAt(0) - 65)
    if not options.every ((o) -> o >= 0 and o < lunch.options.length)
      msg.send "#{user.name}: Invalid vote."
    else
      vote = lunch.votes[user.id] || (lunch.votes[user.id] = [])
      switch action
        when ''
          vote.splice 0, vote.length
          (vote.push i) for i in options
        when '+'
          for i in options
            index = vote.indexOf i
            if index == -1
              vote.push i
        when '-'
          for i in options
            index = vote.indexOf i
            if index != -1
              vote.splice index, 1
      msg.send "#{user.name}: Your choices are " + vote.map((i) -> lunch.options[i]).join(', ')

  robot.respond /(lunch call|call lunch)$/i, (msg) ->
    lunch = robot.brain.data.lunch
    tally = []
    (tally.push 0) for i in [0...lunch.options.length] by 1
    for id, vote of lunch.votes
      (tally[i]++) for i in vote
    results = (votes: v, option: lunch.options[i] for v, i in tally when v > 0)
    if results.length == 0
      msg.send "No votes."
    else
      results.sort (a, b) -> b.votes - a.votes
      msg.send results.map((r) -> r.option + ": " + r.votes).join('\n')
