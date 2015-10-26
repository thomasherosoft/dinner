topics = {}
hop = topics.hasOwnProperty

top.pubsub =
  subscribe: (topic, listener) ->
    topics[topic] = [] unless hop.call(topics, topic)
    index = topics[topic].push(listener) - 1
    remove: -> topics[topic].splice(index, 1)


  publish: (topic, info) ->
    if hop.call(topics, topic)
      topics[topic].forEach (item) ->
        item.call(null, info) if item and item.apply
