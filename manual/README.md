# DelCod release transition

Use DelCod-release-1.1.2-8.apk for the release-signed manual install.

The old DelCod-release-1.1.1-7.apk was built without SUPABASE_ANON_KEY and can open as a black screen. Do not use it.

This manual APK is signed with the fixed DelCod release key. It is not referenced by updates/version.json because debug-signed installs cannot update to a release-signed APK in place. Users moving from the debug-signed channel must uninstall the old app once, then install this APK.
