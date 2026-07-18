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

// Keep evaluationDependsOn in its own block (Flutter 3.44+).
// Combining it with other subproject config can drop libapp.so from the AAB.
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (project.plugins.hasPlugin("com.android.application") || project.plugins.hasPlugin("com.android.library")) {
        project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
            compileSdkVersion(36)
            defaultConfig {
                minSdkVersion(21)
                targetSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
