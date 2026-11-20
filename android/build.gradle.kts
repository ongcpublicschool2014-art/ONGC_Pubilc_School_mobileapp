allprojects {
    repositories {
        google()
        mavenCentral()
        // Paytm native SDK (com.paytm.appinvokesdk) for paytm_allinonesdk.
        maven { url = uri("https://artifactory.paytm.in/libs-release-local") }
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
