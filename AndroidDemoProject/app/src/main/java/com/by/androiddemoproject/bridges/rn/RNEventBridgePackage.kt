package com.by.androiddemoproject.bridges.rn

// MARK: - ReactPackage placeholder
// In a real project:
// class RNEventBridgePackage : ReactPackage {
//     override fun createNativeModules(context: ReactApplicationContext): List<NativeModule> {
//         return listOf(RNEventBridgeModule(context), RNRouterModule(context))
//     }
//     override fun createViewManagers(context: ReactApplicationContext): List<ViewManager<*, *>> = emptyList()
// }

class RNEventBridgePackage {
    fun createNativeModules(): List<Any> {
        return listOf(RNEventBridgeModule(), RNRouterModule())
    }
}
