package com.by.androiddemoproject.pagedata

import org.json.JSONObject
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

data class PageData(
    val dataId: String = UUID.randomUUID().toString(),
    val source: String,
    val target: String,
    val route: String? = null,
    val data: JSONObject,
    val timestamp: Long = System.currentTimeMillis(),
    val ttl: Long = 300_000L
) {
    val isExpired: Boolean
        get() = System.currentTimeMillis() - timestamp > ttl

    fun toJSON(): JSONObject {
        return JSONObject().apply {
            put("dataId", dataId)
            put("source", source)
            put("target", target)
            put("route", route)
            put("data", data)
            put("timestamp", timestamp)
            put("ttl", ttl)
        }
    }

    fun toJSONString(): String = toJSON().toString()

    companion object {
        fun from(json: JSONObject): PageData? {
            return try {
                PageData(
                    dataId = json.getString("dataId"),
                    source = json.getString("source"),
                    target = json.getString("target"),
                    route = json.optString("route", null),
                    data = json.getJSONObject("data"),
                    timestamp = json.optLong("timestamp", System.currentTimeMillis()),
                    ttl = json.optLong("ttl", 300_000L)
                )
            } catch (e: Exception) {
                null
            }
        }

        fun from(jsonString: String): PageData? {
            return try {
                from(JSONObject(jsonString))
            } catch (e: Exception) {
                null
            }
        }
    }
}

object PageDataStore {
    private val store = ConcurrentHashMap<String, PageData>()
    private val routeDataMap = ConcurrentHashMap<String, String>()

    fun put(source: String, target: String, route: String? = null, data: JSONObject, ttl: Long = 300_000L): String {
        val pageData = PageData(source = source, target = target, route = route, data = data, ttl = ttl)
        store[pageData.dataId] = pageData
        if (route != null) {
            routeDataMap[route] = pageData.dataId
        }
        return pageData.dataId
    }

    fun get(dataId: String): PageData? {
        val pageData = store[dataId] ?: return null
        if (pageData.isExpired) {
            remove(dataId)
            return null
        }
        return pageData
    }

    fun getByRoute(route: String): PageData? {
        val dataId = routeDataMap[route] ?: return null
        return get(dataId)
    }

    fun consume(dataId: String): PageData? {
        val data = get(dataId)
        if (data != null) remove(dataId)
        return data
    }

    fun consumeByRoute(route: String): PageData? {
        val dataId = routeDataMap[route] ?: return null
        val data = get(dataId)
        if (data != null) remove(dataId)
        return data
    }

    fun remove(dataId: String) {
        store.remove(dataId)?.let { pageData ->
            pageData.route?.let { routeDataMap.remove(it) }
        }
    }

    fun cleanup() {
        store.entries.filter { it.value.isExpired }.forEach { entry ->
            entry.value.route?.let { routeDataMap.remove(it) }
            store.remove(entry.key)
        }
    }
}
