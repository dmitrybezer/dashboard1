class Dashing.WorldClock extends Dashing.Widget
  # configuration
  locations: [
    { zone: "Australia/Brisbane", display_location: "BNE"},
    { zone: "Europe/Budapest", display_location: "BUD" },
    { zone: "Asia/Calcutta", display_location: "DEH" },
    { zone: "America/New_York", display_location: "BOS"},
    { zone: "America/Vancouver", display_location: "POR" }
  ]


  startClock: ->
    for location in @locations
      date = moment().tz(location.zone)
      location.time = [date.hours(), date.minutes(), date.seconds()].map (n)->
        ('0' + n).slice(-2)
      .join(':')
      minutes = 60 * date.hours() + date.minutes()
      totalWidth = document.querySelector('.hours').clientWidth - 1
      offset = (minutes / (24.0 * 60)) * totalWidth

      clock = document.querySelector("." + location.display_location)
      if(clock)
        ['-webkit-transform', '-moz-transform', '-o-transform', '-ms-transform', 'transform'].forEach (vendor) ->
          clock.style[vendor] = "translateX(" + offset + "px)"

          if(location.primary)
            @set('time', location.time)
        , @

    setTimeout @startClock.bind(@), 1000

  setupHours: ->
    hours = []
    for h in [0..23]
      do (h) ->
        hours[h] = {}
        hours[h].dark = h< 8 || h>= 19
        hours[h].name = if h == 12 then h else h%12
    @set('hours', hours)

  ready: ->
    @setupHours()
    @startClock()
