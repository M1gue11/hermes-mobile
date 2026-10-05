install:
	flutter pub get
	flutter analyze
	flutter test
	flutter build apk --release