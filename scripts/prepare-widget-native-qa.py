"""Build an isolated Android host containing the production widget code and resources."""
from pathlib import Path
import shutil,sys,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]; dest=Path(sys.argv[1]);dest.mkdir(parents=True,exist_ok=True)
(dest/'settings.gradle.kts').write_text('''pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral() } }
rootProject.name="NidoWidgetReview"
include(":app")
''')
(dest/'build.gradle.kts').write_text('''plugins {
 id("com.android.application") version "8.11.1" apply false
 id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}
''')
(dest/'gradle.properties').write_text('android.useAndroidX=true\norg.gradle.jvmargs=-Xmx3g\n')
app=dest/'app';main=app/'src/main';native=main/'java/com/example/twohearts';native.mkdir(parents=True,exist_ok=True)
for f in (root/'android/app/src/main/kotlin/com/example/twohearts').glob('Nido*Widget*.kt'):shutil.copy2(f,native/f.name)
(native/'MainActivity.kt').write_text('''package com.example.twohearts
class MainActivity:android.app.Activity()
object NidoReminders { fun mood(c:android.content.Context,j:org.json.JSONObject?) {} ; fun clear(c:android.content.Context) {} }
''')
for folder in ['drawable-nodpi','xml','xml-v31']:
 for f in (root/'android/app/src/main/res'/folder).glob('*widget*'):
  d=main/'res'/folder;d.mkdir(parents=True,exist_ok=True);shutil.copy2(f,d/f.name)
layout=main/'res/layout';layout.mkdir(parents=True,exist_ok=True);shutil.copy2(root/'android/app/src/main/res/layout/nido_personal_widget.xml',layout/'nido_personal_widget.xml')
shutil.copytree(root/'android/app/src/main/assets',main/'assets',dirs_exist_ok=True)
shutil.copy2(root/'data/quotes/widget-quote-vectors.json',main/'assets/widget-quote-vectors.json')
ns='{http://schemas.android.com/apk/res/android}'
source=ET.parse(root/'android/app/src/main/AndroidManifest.xml').getroot();manifest=ET.Element('manifest');application=ET.SubElement(manifest,'application',{ns+'theme':'@android:style/Theme.Material.Light.NoActionBar',ns+'label':'NIDO widget QA'})
for item in source.find('application'):
 if 'Widget' in item.get(ns+'name',''):
  item.set(ns+'name','com.example.twohearts.'+item.get(ns+'name').lstrip('.'));application.append(item)
ET.SubElement(application,'activity',{ns+'name':'com.example.twohearts.MainActivity',ns+'exported':'true'})
ET.register_namespace('android',ns[1:-1]);ET.ElementTree(manifest).write(main/'AndroidManifest.xml',encoding='utf-8',xml_declaration=True)
(app/'build.gradle.kts').write_text('''plugins { id("com.android.application"); id("org.jetbrains.kotlin.android") }
android {
 namespace="com.example.twohearts"; compileSdk=36
 defaultConfig { applicationId="com.example.twohearts.widgetqa"; minSdk=24; targetSdk=36; testInstrumentationRunner="androidx.test.runner.AndroidJUnitRunner" }
 compileOptions { isCoreLibraryDesugaringEnabled=true; sourceCompatibility=JavaVersion.VERSION_17; targetCompatibility=JavaVersion.VERSION_17 }
 kotlinOptions { jvmTarget="17" }
}
dependencies {
 coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
 testImplementation("junit:junit:4.13.2")
 androidTestImplementation("androidx.test:runner:1.6.2")
 androidTestImplementation("androidx.test.ext:junit:1.2.1")
}
''')
for folder in ['test','androidTest']:
 shutil.copytree(root/'android/app/src'/folder,app/'src'/folder,dirs_exist_ok=True)
print(dest)
