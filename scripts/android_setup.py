"""Generate Android runner from the installed Flutter stable SDK on any OS."""
import pathlib, shutil, subprocess, tempfile
from xml.etree import ElementTree as ET
root = pathlib.Path(__file__).resolve().parents[1]
flutter = shutil.which("flutter")
if not flutter:
    raise SystemExit("Install Flutter stable and add flutter to PATH.")
if not (root / 'android').exists():
    with tempfile.TemporaryDirectory() as tmp:
        generated = pathlib.Path(tmp) / 'servora'
        subprocess.run([flutter,'create','--no-pub','--platforms=android','--org','lk.group50',str(generated)],check=True)
        shutil.copytree(generated / 'android',root / 'android')
manifest = root / 'android/app/src/main/AndroidManifest.xml'
ns = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android',ns)
tree = ET.parse(manifest)
element = tree.getroot()
permissions = {x.get('{%s}name'%ns) for x in element.findall('uses-permission')}
for suffix in ['INTERNET','ACCESS_COARSE_LOCATION','ACCESS_FINE_LOCATION','POST_NOTIFICATIONS']:
    name = 'android.permission.' + suffix
    if name not in permissions:
        element.insert(0,ET.Element('uses-permission',{'{%s}name'%ns:name}))
tree.write(manifest,encoding='utf-8',xml_declaration=True)
subprocess.run([flutter,'pub','get'],cwd=root,check=True)
print('Android runner ready. Next run flutterfire configure as described in README.md.')
