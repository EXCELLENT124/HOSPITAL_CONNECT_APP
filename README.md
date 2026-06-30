# Health Connect

Health Connect is a responsive Flutter application for coordinating South African RAF matters between hospitals and legal practices.

## Implemented

- Hospital and legal-practice registration
- Role-based hospital/lawyer sign-in
- Encrypted on-device demo persistence
- RAF case intake, status tracking, and document selection
- Location, availability, experience and outcome-based lawyer ranking
- Lawyer assignment, case messaging, and an in-app notification centre
- Adaptive Android/Windows navigation and colour-changing themes
- Automated launch and matching tests

## Run after this update

Stop the old run with `q`, then:

```powershell
flutter pub get
flutter test
flutter run -d windows
```

For Android, start an emulator in Android Studio and run:

```powershell
flutter devices
flutter run -d <device-id>
```

## Demo safety

Data is encrypted locally using platform secure storage, but this remains a prototype. Do not enter real patient information. Production requires a managed backend, independently reviewed POPIA controls, consent and retention workflows, server-side access control, audit logging, malware scanning for documents, backups, breach response, and professional review of lawyer-ranking rules.
