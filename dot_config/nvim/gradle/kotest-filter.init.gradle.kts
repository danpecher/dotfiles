import org.gradle.api.tasks.testing.Test
import org.gradle.api.tasks.JavaExec
import org.gradle.api.tasks.SourceSetContainer

gradle.allprojects {
    tasks.withType<Test>().configureEach {
        val kotestFilter =
            gradle.startParameter.projectProperties["kotest.filter.tests"]
                ?: System.getenv("KOTEST_FILTER_TESTS")

        if (!kotestFilter.isNullOrBlank()) {
            systemProperty("kotest.filter.tests", kotestFilter)
        }
    }

    plugins.withId("org.jetbrains.kotlin.jvm") {
        val sourceSets = extensions.getByType(SourceSetContainer::class.java)

        tasks.register("kotestDirect", JavaExec::class.java) {
            group = "verification"
            description = "Runs a single Kotest spec or test via Kotest's direct launcher"

            val spec = gradle.startParameter.projectProperties["kotest.direct.spec"]
            val include = gradle.startParameter.projectProperties["kotest.direct.include"]

            dependsOn("testClasses")
            classpath = sourceSets.getByName("test").runtimeClasspath
            mainClass.set("io.kotest.engine.launcher.MainKt")
            workingDir = project.projectDir

            args("--specs", spec ?: "")
            if (!include.isNullOrBlank()) {
                args("--include", include)
            }
            args("--listener", "console")
        }
    }
}
