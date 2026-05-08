allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.get().dir("../../build")
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}