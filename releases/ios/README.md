# iOS Release

## ODC_Tracker.ipa

This folder is the destination for the signed iOS IPA file.

The IPA **cannot** be built on Windows. It requires macOS + Xcode.

### Build on macOS

```bash
# From the project root on a Mac
flutter build ipa --release

# The IPA will appear at:
#   build/ios/ipa/odc_tracker_ai.ipa
# Copy it here:
cp build/ios/ipa/odc_tracker_ai.ipa releases/ios/ODC_Tracker.ipa
```

Or run the convenience script:

```bash
./scripts/build_ios_release.sh
```

### Distribute to iPhone

An IPA file is **not** directly installable by tapping it in WhatsApp or Files.
iOS requires a signed distribution method. The options are:

| Method | Who can use it | Complexity |
|--------|---------------|------------|
| **TestFlight** (recommended) | Anyone with your Apple ID invited | Medium |
| Ad Hoc (direct install via Apple Configurator) | Up to 100 specific registered devices | High |
| Enterprise (in-house) | Large companies only | High |
| App Store | Public | High — full review process |

**Recommended for personal/team use: TestFlight.**
See `IOS_INSTALL_GUIDE.md` for step-by-step instructions.

---

> Files in this folder are placeholders.
> `ODC_Tracker.ipa` will be placed here after a successful macOS build.
