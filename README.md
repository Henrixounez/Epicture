# Epicture

![](./assets/launcher/small_icon.png)

Made with <3 by [Skaas](https://github.com/Skaas) and [Henrixounez](https://github.com/Henrixounez)

Epicture is a mobile interface for Imgur.
It was made with Flutter and uses Imgur official API.

This documentation covers UX / UI, Imgur interaction and will explain some of the choices we have made during development.

## Usage

### How to build
```
export PATH="$PATH":"/.../flutter/bin/"
flutter build apk
flutter build ios
```

### How to generate docs
```
flutter pub global activate dartdoc
export PATH="$PATH":"/.../flutter/bin/cache/dart-sdk/bin/"
export PATH="$PATH":"/.../flutter/.pub-cache/bin"
dartdoc
```


----

## Why Flutter ?

Flutter is a multiplatform framework made by Google which allow us to write one application for both IOS and Android. It was released only two years ago but is very reliable nonetheless.

Flutter is all about widgets. Your application is a combination of Widgets that works together in order to create a responsive UI without thinking much of the hardware.
Widgets are built and refreshed everytime they have to. For example, when some widget data which is displayed is changed, the widget is rebuilt and the UI is automatically updated.

Flutter is very documented, very easy to use but difficult to master. It comes with a very powerful environment, Android Studio, that makes environment management very trivial.

The focus was on UI/UX, not backend, hence the choice of a multiplatform framework over more complex tools such as Kotlin or C#.

### Why not React Native ?

React Native is a very powerful framework to develop cross-platform application. We already knew how to use React so it would have been a perfect choice.

The main reasons is because React Native environment is a pain to set up compared to Flutter. Expo often doesn't work as intended and Flutter is well known for it's hot reloading, which makes development easier.

There is other reasons such as syntax and architecture. React Native would have been good nonetheless but developing Flutter application feel's way better.

---
## Imgur API
Imgur API is a relatively simple API.

The OAUTH2 connection was set up using deep linking. This allows us to open Imgur authentication in a webview (we uses Chrome for design reasons) and to get back on our application with the user's credentials thanks to a callback.

All of Imgur API interactions were handled by Dart's http module combined with Dart's powerful Future module.

---

## UX and functionalities

Epicture is composed of three main panels :

- Home
- Search
- Camera

### Home

![](https://i.imgur.com/AXBg1MI.png "Home before / after connection")

The Home panel ask for connection if you aren't already logged with OAUTH2.

To log-in, simply press the 'Log-in' button.

After logging, you can scroll down and explore Imgur's trending posts.

#### Image and videos

![](https://i.imgur.com/RqQya73.png "An image and a video")

An image and a video are almost identical.

At the top, you can see the profile picture of the OP (original poster), the image title, OP's name, time since posting and the type of post (image or album) but most of the time, images are albums with one element. You can press the heart to put the image in your favorites. If the image is already in it, you can press the heart again to remove it.

In the middle, the content is displayed. If this is a video, you can press buttons to interact with it :

- Sound on / off
- Play / Stop the video

If you press the content, it will be displayed fullscreen in order to have a better view.

Finally, at the bottom, you can see how many views / upvotes / downvotes the content has. You can press **up** or **down** in order to upvote / downvote the content.

#### Profile
![](https://i.imgur.com/JP6Jo8F.png "The profile menu")

You can access the profile menu by pressing your avatar (which is displayed in the home's appbar).

Here, you can see every content your uploaded and favorited.

You can also change the **mature setting** which filters the content you find on Epicture.

Finally, you can disconnect from Epicture.
### Search

![](https://i.imgur.com/CydFbSZ.png "The search menu")

The search menu is accessible whether or not you are connected.

You may search content by pressing the Appbar and writing what you want. If you put a **#** before your keyword, Epicture will search by tag.

Then is displayed the trending tags. By pressing one of them, Epicture will automatically search for it.

Finally, you can sort the content found by three setting :
- Top (score of the content) then by date (top of the week / year / all )
- Time (from the most recent to the oldest)
- Viral (images chosen by Imgur)

---

### Camera and Upload

#### Camera
![](https://i.imgur.com/6WieG1M.png "The camera and the editor")

Epicture's camera was made using *camera*, an official Flutter plugin which gives us acess to the smartphone cameras. We chose not to use the official plugin which calls for the default smartphone camera because this one allow us to display the camera as much as we want, giving a *snapchat like* felling.

By pressing the bottom-right button, you will switch between the smartphone cameras.

##### Editor
The bottom-center button takes a picture. The picture is then displayed in a editor where you can press three different buttons :
- The top-left ditch the picture and let you take a new one.
- The bottom-left saves the picture on your phone. You are then free to upload it or to take another one.
- The bottom-right let you upload it.

Finally, the camera's bottom-left button let you take a pictures from your gallery, and then upload it.

#### Uploader

![](https://i.imgur.com/drBMrOu.png "The uploader in action")

The uploader menu allows you to upload your image with some parameters.

You may chose a name for your image/ album and choose it's privacy ('public', 'hidden', 'secret').

Then is displayed your images. Each image has it's own description.
By pressing 'Add more images', you will be able to add as many images as you want from your gallery.

When you are ready, you can press the bottom-right button to upload your content. A fancy animation will take place and, when the upload is over, you will be redirected into the camera menu.

![](https://i.imgur.com/zSu3KHL.png "The fancy upload animation")


## Technical informations

You can build the doc thanks to [dartdoc](https://pub.dev/packages/dartdoc)
