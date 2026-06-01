package com.by.androiddemoproject.eventbus

import org.json.JSONObject
import java.util.UUID

enum class MessageType {
    request, response, notification, broadcast;

    companion object {
        fun fromString(value: String): MessageType = entries.first { it.name == value }
    }
}

enum class StackId {
    native, rn, flutter, webview, all;

    companion object {
        fun fromString(value: String): StackId = when (value) {
            "*" -> all
            else -> entries.first { it.name == value }
        }
    }

    fun toJsonValue(): String = when (this) {
        all -> "*"
        else -> name
    }
}

data class EventMessage(
    val id: String = UUID.randomUUID().toString(),
    val type: MessageType,
    val channel: String,
    val source: StackId,
    val target: StackId,
    val payload: JSONObject = JSONObject(),
    val callbackId: String? = null,
    val timestamp: Long = System.currentTimeMillis()
) {
    fun toJSONString(): String {
        val json = JSONObject().apply {
            put("id", id)
            put("type", type.name)
            put("channel", channel)
            put("source", source.toJsonValue())
            put("target", target.toJsonValue())
            put("payload", payload)
            put("callbackId", callbackId ?: JSONObject.NULL)
            put("timestamp", timestamp)
        }
        return json.toString()
    }

    companion object {
        fun fromJSONString(jsonString: String): EventMessage? {
            return try {
                val json = JSONObject(jsonString)
                EventMessage(
                    id = json.getString("id"),
                    type = MessageType.fromString(json.getString("type")),
                    channel = json.getString("channel"),
                    source = StackId.fromString(json.getString("source")),
                    target = StackId.fromString(json.getString("target")),
                    payload = json.optJSONObject("payload") ?: JSONObject(),
                    callbackId = if (json.isNull("callbackId")) null else json.optString("callbackId"),
                    timestamp = json.getLong("timestamp")
                )
            } catch (e: Exception) {
                null
            }
        }
    }
}
