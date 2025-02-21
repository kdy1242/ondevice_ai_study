import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? image;
  List<Face> faces = [];

  Future<File?> selectImage() async {
    FilePickerResult? selectedImage = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowCompression: false,
      compressionQuality: 0,
    );

    if (selectedImage?.files.single.path != null) {
      return File(selectedImage!.files.single.path!);
    }
    return null;
  }

  Future<void> setImage() async {
    File? selectedImage = await selectImage();

    if (selectedImage != null) {
      setState(() {
        faces = [];
        image = selectedImage;
      });
    }
  }

  Future<List<Face>> getFaces() async {
    if (image != null) {
      InputImage inputImage = InputImage.fromFilePath(image!.path);
      FaceDetector faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableTracking: true,
        ),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);

      return faces;
    }
    return [];
  }

  Future<void> setFaces() async {
    final result = await getFaces();
    setState(() {
      faces = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Finder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: setImage,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (image != null)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Image.file(
                            image!,
                            fit: BoxFit.contain,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                          FutureBuilder<Size>(
                            future: _getImageSize(image!),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return Container();

                              final imageSize = snapshot.data!;
                              final widthRatio =
                                  constraints.maxWidth / imageSize.width;
                              final heightRatio =
                                  constraints.maxHeight / imageSize.height;
                              final ratio = min(widthRatio, heightRatio);

                              final renderWidth = imageSize.width * ratio;
                              final renderHeight = imageSize.height * ratio;

                              final offsetX =
                                  (constraints.maxWidth - renderWidth) / 2;
                              final offsetY =
                                  (constraints.maxHeight - renderHeight) / 2;

                              return Stack(
                                children: faces.map((face) {
                                  return Positioned(
                                    left:
                                        face.boundingBox.left * ratio + offsetX,
                                    top: face.boundingBox.top * ratio + offsetY,
                                    width: face.boundingBox.width * ratio,
                                    height: face.boundingBox.height * ratio,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                )
              else
                const Text('No image selected'),
              const SizedBox(height: 20),
              TextButton(
                onPressed: setFaces,
                child: const Text('find'),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 이미지 크기를 가져오는 헬퍼 함수
  Future<Size> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer();
    final Image image = Image.file(imageFile);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          completer.complete(Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          ));
        },
      ),
    );
    return completer.future;
  }
}
