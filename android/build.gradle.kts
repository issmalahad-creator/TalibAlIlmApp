allprojects {
    repositories {
        google()
        mavenCentral()
        // Tesseract4Android (OCR لكتب "مكتبتي" المصوَّرة بلا طبقة نص) يُنشَر
        // عبر JitPack فقط — راجع native-crash-diagnosis/OCR notes في
        // TEXT_SOURCE_ADAPTERS.md §7.1 لسبب استبعاد حزم Flutter الجاهزة.
        maven { url = uri("https://jitpack.io") }
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
