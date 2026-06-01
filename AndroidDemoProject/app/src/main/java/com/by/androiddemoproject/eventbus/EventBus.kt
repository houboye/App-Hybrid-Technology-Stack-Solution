package com.by.androiddemoproject.eventbus

import android.os.Handler
import android.os.Looper
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

object EventBus {
    private val adapters = ConcurrentHashMap<StackId, EventBridgeAdapter>()
    private val channelListeners = ConcurrentHashMap<String, MutableList<(EventMessage) -> Unit>>()
    private val pendingCallbacks = ConcurrentHashMap<String, (EventMessage) -> Unit>()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(adapter: EventBridgeAdapter) {
        adapters[adapter.stackId] = adapter
    }

    fun unregister(stackId: StackId) {
        adapters.remove(stackId)
    }

    fun dispatch(message: EventMessage) {
        when {
            message.type == MessageType.response && message.callbackId != null -> {
                pendingCallbacks.remove(message.callbackId)?.let { callback ->
                    mainHandler.post { callback(message) }
                }
            }
            message.type == MessageType.broadcast || message.target == StackId.all -> {
                adapters.filter { it.key != message.source }.forEach { (_, adapter) ->
                    mainHandler.post { adapter.send(message) }
                }
                notifyListeners(message.channel, message)
            }
            else -> {
                if (message.target == StackId.native) {
                    notifyListeners(message.channel, message)
                } else {
                    adapters[message.target]?.let { adapter ->
                        mainHandler.post { adapter.send(message) }
                    }
                }
            }
        }
    }

    fun sendRequest(
        target: StackId,
        channel: String,
        payload: org.json.JSONObject = org.json.JSONObject(),
        callback: (EventMessage) -> Unit
    ) {
        val callbackId = UUID.randomUUID().toString()
        val message = EventMessage(
            type = MessageType.request,
            channel = channel,
            source = StackId.native,
            target = target,
            payload = payload,
            callbackId = callbackId
        )
        pendingCallbacks[callbackId] = callback
        dispatch(message)
    }

    fun sendNotification(target: StackId, channel: String, payload: org.json.JSONObject = org.json.JSONObject()) {
        val message = EventMessage(
            type = MessageType.notification,
            channel = channel,
            source = StackId.native,
            target = target,
            payload = payload
        )
        dispatch(message)
    }

    fun broadcast(channel: String, payload: org.json.JSONObject = org.json.JSONObject()) {
        val message = EventMessage(
            type = MessageType.broadcast,
            channel = channel,
            source = StackId.native,
            target = StackId.all,
            payload = payload
        )
        dispatch(message)
    }

    fun subscribe(channel: String, handler: (EventMessage) -> Unit) {
        channelListeners.getOrPut(channel) { mutableListOf() }.add(handler)
    }

    private fun notifyListeners(channel: String, message: EventMessage) {
        channelListeners[channel]?.let { listeners ->
            mainHandler.post {
                listeners.forEach { it(message) }
            }
        }
    }
}
