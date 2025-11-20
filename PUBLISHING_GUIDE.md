# Publishing Flutter Quran Tajweed to pub.dev

## Prerequisites

1. **Google Account**: You need a Google account to publish to pub.dev
2. **GitHub Repository**: Your code should be on GitHub (already done ✓)
3. **License File**: You have MIT License (already done ✓)
4. **CHANGELOG.md**: You have a changelog (already done ✓)
5. **README.md**: You have documentation (already done ✓)

## Step 1: Verify Package Structure

Your package structure is correct:
```
flutter_quran_tajwid/
├── lib/                    # Package code
├── example/                # Example app (required)
├── LICENSE                 # MIT License
├── README.md              # Package documentation
├── CHANGELOG.md           # Version history
├── pubspec.yaml           # Package metadata
└── API_REFERENCE.md       # API docs
```

## Step 2: Update pubspec.yaml

I've already updated it with:
- ✅ Description (< 180 characters, explains what the package does)
- ✅ Repository URL
- ✅ Homepage URL
- ✅ Issue tracker URL
- ✅ Version: 1.0.0 (follows semantic versioning)

## Step 3: Run Dry-Run Check

Before publishing, test your package:

```bash
cd /Users/applemachome/StudioProjects/flutter_quran_tajwid
flutter pub publish --dry-run
```

This will check for:
- Package structure issues
- Missing required files
- pubspec.yaml validation
- Asset declarations
- Platform compatibility

**Fix any warnings or errors reported!**

## Step 4: Run Flutter Analyze

Ensure no code issues:

```bash
flutter analyze
```

Fix any errors or warnings (lints are okay).

## Step 5: Test the Example App

Make sure the example app works:

```bash
cd example
flutter run
```

Test on at least one platform (Android/iOS/Web).

## Step 6: Publish to pub.dev

Once dry-run passes with no errors:

```bash
cd /Users/applemachome/StudioProjects/flutter_quran_tajwid
flutter pub publish
```

### What Happens:

1. **Authentication Prompt**: 
   ```
   Pub needs your authorization to upload packages on your behalf.
   In a web browser, go to https://accounts.google.com/o/oauth2/auth?...
   Then click the link above and paste the authorization code.
   ```

2. **Browser Opens**: You'll be redirected to Google sign-in
3. **Grant Permission**: Allow pub.dev to access your account
4. **Copy Code**: You'll get an authorization code
5. **Paste Code**: Return to terminal and paste the code
6. **Confirmation**: 
   ```
   Package has 0 warnings.
   Publishing flutter_quran_tajwid 1.0.0 to https://pub.dev:
   |-- ...
   
   Do you want to publish flutter_quran_tajwid 1.0.0 to https://pub.dev (y/N)?
   ```

7. **Type `y`**: Confirm publication

8. **Processing**: Pub.dev will:
   - Upload your package
   - Run analysis
   - Generate documentation
   - Make it available

## Step 7: Verify Publication

After ~10 minutes:
1. Visit: https://pub.dev/packages/flutter_quran_tajwid
2. Check package score (aims for 130+ points)
3. Review generated documentation
4. Test installation in a new project

## Common Issues & Solutions

### Issue: "Published packages must have an sdk constraint"
**Solution**: Already fixed - SDK constraint is `>=3.0.0 <4.0.0`

### Issue: "Package has too many warnings"
**Solution**: Run `flutter analyze` and fix issues

### Issue: "Missing required files"
**Solution**: Ensure you have:
- README.md
- CHANGELOG.md
- LICENSE
- pubspec.yaml with proper description

### Issue: "Description too long"
**Solution**: Keep description under 180 characters (already done ✓)

### Issue: "Assets not found"
**Solution**: Verify assets exist and are listed in pubspec.yaml

### Issue: "Example folder issues"
**Solution**: Ensure example app runs: `cd example && flutter run`

## Post-Publication

### Update README Badge

Add this to the top of your README.md:

```markdown
[![pub package](https://img.shields.io/pub/v/flutter_quran_tajwid.svg)](https://pub.dev/packages/flutter_quran_tajwid)
```

### Monitor Package Health

Check your package dashboard:
- **Pub Points**: Aim for 130/130
- **Popularity**: Grows with downloads
- **Likes**: Encourage users to like
- **Pub Points Issues**: Fix any reported issues

### Respond to Issues

Monitor GitHub issues and respond to:
- Bug reports
- Feature requests
- Questions

## Publishing Updates

When you make changes:

1. **Update CHANGELOG.md**:
   ```markdown
   ## 1.0.1
   
   * Fixed bug in audio recording
   * Improved performance
   ```

2. **Bump Version** in pubspec.yaml:
   - Patch: 1.0.0 → 1.0.1 (bug fixes)
   - Minor: 1.0.0 → 1.1.0 (new features, backward compatible)
   - Major: 1.0.0 → 2.0.0 (breaking changes)

3. **Publish Again**:
   ```bash
   flutter pub publish --dry-run  # Test first
   flutter pub publish            # Publish
   ```

## Package Score Checklist

To get 130/130 points:

- ✅ **Follow Dart file conventions** (20 points)
- ✅ **Provide documentation** (10 points) - README, API docs
- ✅ **Support multiple platforms** (20 points) - Android, iOS, Web
- ✅ **Pass static analysis** (30 points) - No errors/warnings
- ✅ **Support up-to-date dependencies** (20 points)
- ✅ **Support latest SDK** (20 points) - SDK >=3.0.0
- ✅ **Provide example** (10 points) - Example app included

## Versioning Best Practices

Follow [Semantic Versioning](https://semver.org/):

- **1.0.0** - Initial stable release
- **1.0.1** - Bug fixes
- **1.1.0** - New features (backward compatible)
- **2.0.0** - Breaking changes

## Before Version 2.0.0

When you're ready for breaking changes:
1. Update CHANGELOG with migration guide
2. Mark deprecated APIs with `@deprecated`
3. Give users time to migrate (publish 1.x with deprecation warnings)
4. Then release 2.0.0

## Quick Command Reference

```bash
# From package root directory
cd /Users/applemachome/StudioProjects/flutter_quran_tajwid

# Check for issues (dry-run)
flutter pub publish --dry-run

# Run analysis
flutter analyze

# Format code
dart format .

# Publish
flutter pub publish

# Test example
cd example && flutter run
```

## Resources

- **Pub.dev Publishing Guide**: https://dart.dev/tools/pub/publishing
- **Package Layout**: https://dart.dev/guides/libraries/create-packages
- **Package Scoring**: https://pub.dev/help/scoring
- **Semantic Versioning**: https://semver.org/

## Support

After publishing:
- Monitor: https://pub.dev/packages/flutter_quran_tajwid
- GitHub Issues: https://github.com/ha-ar/flutter_quran_tajwid/issues
- Pub.dev Admin: https://pub.dev/packages/flutter_quran_tajwid/admin
