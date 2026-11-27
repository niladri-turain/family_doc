# Text recognition (google_mlkit_text_recognition) uses only the Latin
# model; its plugin also references the Chinese/Devanagari/Japanese/Korean
# packs, which are not included.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
