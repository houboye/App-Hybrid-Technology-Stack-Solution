package com.by.androiddemoproject.pagedata

import org.json.JSONObject

object PageDataBridge {

    fun handleMethodCall(method: String, arguments: String?): String? {
        val args = arguments ?: return null

        return when (method) {
            "put" -> handlePut(args)
            "get" -> handleGet(args)
            "consume" -> handleConsume(args)
            "getByRoute" -> handleGetByRoute(args)
            "consumeByRoute" -> handleConsumeByRoute(args)
            else -> null
        }
    }

    private fun handlePut(jsonString: String): String? {
        return try {
            val json = JSONObject(jsonString)
            val source = json.getString("source")
            val target = json.getString("target")
            val route = if (json.isNull("route")) null else json.optString("route")
            val data = json.getJSONObject("data")
            val ttl = json.optLong("ttl", 300_000L)

            PageDataStore.put(
                source = source,
                target = target,
                route = route,
                data = data,
                ttl = ttl
            )
        } catch (e: Exception) {
            null
        }
    }

    private fun handleGet(dataId: String): String? {
        return PageDataStore.get(dataId)?.toJSONString()
    }

    private fun handleConsume(dataId: String): String? {
        return PageDataStore.consume(dataId)?.toJSONString()
    }

    private fun handleGetByRoute(route: String): String? {
        return PageDataStore.getByRoute(route)?.toJSONString()
    }

    private fun handleConsumeByRoute(route: String): String? {
        return PageDataStore.consumeByRoute(route)?.toJSONString()
    }
}
