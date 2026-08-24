allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Restrict native ABIs: NDK 28 fails linking armeabi-v7a at API 21 (pthread_atfork).
// App abiFilters do not propagate to plugin modules like :jni.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            defaultConfig {
                ndk {
                    abiFilters.clear()
                    abiFilters.addAll(listOf("arm64-v8a", "x86_64"))
                }
            }
        }
    }
}
