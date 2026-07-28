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

subprojects {
    val configureNamespace: () -> Unit = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val methods = android.javaClass.methods
                // Dynamic reflection override for compileSdk / compileSdkVersion to API 34
                val compileSdkMethod = methods.firstOrNull { (it.name == "compileSdkVersion" || it.name == "compileSdk") && it.parameterCount == 1 }
                if (compileSdkMethod != null) {
                    try {
                        compileSdkMethod.invoke(android, 34)
                    } catch (e: Exception) {
                        try {
                            compileSdkMethod.invoke(android, "android-34")
                        } catch (ex: Exception) {}
                    }
                }
            } catch (e: Exception) {}

            try {
                val methods = android.javaClass.methods
                val getNamespace = methods.firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
                val setNamespace = methods.firstOrNull { it.name == "setNamespace" && it.parameterCount == 1 && it.parameterTypes[0] == String::class.java }
                if (getNamespace != null && setNamespace != null) {
                    val currentNamespace = getNamespace.invoke(android)
                    if (currentNamespace == null) {
                        setNamespace.invoke(android, "com.example." + project.name.replace("-", "_"))
                    }
                }
            } catch (e: Exception) {
                // Ignore fallback
            }

            // Strip package attribute from AndroidManifest.xml if it exists to avoid AGP 8+ validation failure
            try {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    var content = manifestFile.readText()
                    if (content.contains("package=")) {
                        val regex = """package="[^"]*"""".toRegex()
                        content = content.replace(regex, "")
                        manifestFile.writeText(content)
                    }
                }
            } catch (e: Exception) {
                // Ignore errors
            }
        }
    }

    if (project.state.executed) {
        configureNamespace()
    } else {
        project.afterEvaluate {
            configureNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
