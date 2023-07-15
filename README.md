
# Introduction
This is just a personal project for learning about how flutter build process
works and learn how whole flutter app is put together. Current version is using
a **debug** build of flutter because that is what my current interest is. Later
I will add **release** build as well.

This respository is just for quick replication and if you want to copy-paste
all the steps in the article.

You can read details about how this project works and what are the steps
involved: https://hereket.github.io/posts/flutter_without_gradle/

# Building

``` console
git clone https://github.com/hereket/handmade_flutter
cd handmade_flutter
```

If you have your own key you can just copy it in to handmade_flutter folder. If
you don't have or don't want to bother copying just generate a debug one.

```
keytool -genkeypair -keystore keystore.jks -alias androidkey \
      -validity 10000 -keyalg RSA -keysize 2048 \
      -storepass android -keypass android
```

After key generation just run build script.

```
./build.sh
```

This will create __build/handmade_flutter.apk which you can copy into your
device or emulator. 

If you want automatically push new apk to your connected device you should
uncomment last two lines in the **build.sh**. Adb will push the apk to the
device and launch it automatically.
