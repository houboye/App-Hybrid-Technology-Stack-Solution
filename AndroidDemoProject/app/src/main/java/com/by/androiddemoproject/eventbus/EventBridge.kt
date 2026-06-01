package com.by.androiddemoproject.eventbus

interface EventBridgeAdapter {
    val stackId: StackId
    fun send(message: EventMessage)
}
