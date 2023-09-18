// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs, depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:webview_flutter/webview_flutter.dart';
// #docregion platform_imports
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// #enddocregion platform_imports

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MaterialApp(
    home: const WebViewExample(),
    theme: ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 0, 135, 245),
        elevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Color.fromARGB(255, 0, 135, 245)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            elevation: 0,
            fixedSize: const Size(50, 50),
            foregroundColor: Colors.white,
            shape: const CircleBorder(eccentricity: 0),
            backgroundColor: const Color.fromARGB(255, 0, 135, 245),
            side: const BorderSide(
              color: Colors.black38,
            )),
      ),
    ),
  ));
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebViewController _controller;
  void initialization() async {
    await Future.delayed(const Duration(milliseconds: 400));
    FlutterNativeSplash.remove();
  }

  @override
  void initState() {
    super.initState();
    initialization();
    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://apps.admob.com/v2/home/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            debugPrint('url change to ${change.url}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse('https://apps.admob.com/v2/home'));

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context).pop(true);
                });
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 1,
                        color: Colors.black38,
                        child: const SpinKitFadingCircle(
                          color: Colors.white,
                          size: 60.0,
                        ),
                      ),
                    ),
                  ],
                );
              });
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Geride sayfa yok',
                  textAlign: TextAlign.center,
                ),
                behavior: SnackBarBehavior.floating,
                width: 170,
              ),
            );
          }
        }

        return false;
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatNav(webViewController: _controller),
        appBar: AppBar(
          title: const Text('Google Admob'),
        ),
        body: WebViewWidget(controller: _controller),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
              color: Color.fromARGB(255, 0, 135, 245),
              boxShadow: [
                BoxShadow(offset: Offset(-0.00, -0.10), blurRadius: 0.3)
              ]),
          child: NavigationControls(webViewController: _controller),
        ),
      ),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key, required this.webViewController});

  final WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return ButtonBar(
      alignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton(
          child: const Icon(
            Icons.arrow_back,
            size: 30,
          ),
          onPressed: () async {
            if (await webViewController.canGoBack()) {
              await webViewController.goBack();

              showCupertinoDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.of(context).pop(true);
                    });
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 1,
                            color: Colors.black38,
                            child: const SpinKitFadingCircle(
                              color: Colors.white,
                              size: 60.0,
                            ),
                          ),
                        ),
                      ],
                    );
                  });
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Geride sayfa yok',
                      textAlign: TextAlign.center,
                    ),
                    behavior: SnackBarBehavior.floating,
                    width: 170,
                  ),
                );
              }
            }
          },
        ),
        ElevatedButton(
          child: const Icon(
            Icons.refresh_outlined,
            size: 30,
          ),
          onPressed: () {
            webViewController.reload();
            showCupertinoDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.of(context).pop(true);
                  });
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 1,
                          color: Colors.black38,
                          child: const SpinKitFadingCircle(
                            color: Colors.white,
                            size: 60.0,
                          ),
                        ),
                      ),
                    ],
                  );
                });
          },
        ),
        ElevatedButton(
          child: const Icon(
            size: 30,
            Icons.arrow_forward,
          ),
          onPressed: () async {
            if (await webViewController.canGoForward()) {
              await webViewController.goForward();
              showCupertinoDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.of(context).pop(true);
                    });
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 1,
                            color: Colors.black38,
                            child: const SpinKitFadingCircle(
                              color: Colors.white,
                              size: 60.0,
                            ),
                          ),
                        ),
                      ],
                    );
                  });
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'İleride sayfa yok',
                      textAlign: TextAlign.center,
                    ),
                    behavior: SnackBarBehavior.floating,
                    width: 150,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }
}

class FloatNav extends StatelessWidget {
  const FloatNav({super.key, required this.webViewController});

  final WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
        elevation: 1,
        child: const Icon(
          Icons.home,
          size: 30,
        ),
        onPressed: () {
          webViewController
              .loadRequest(Uri.parse('https://apps.admob.com/v2/home'));
          showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context).pop(true);
                });
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 1,
                        color: Colors.black38,
                        child: const SpinKitFadingCircle(
                          color: Colors.white,
                          size: 60.0,
                        ),
                      ),
                    ),
                  ],
                );
              });
        });
  }
}
