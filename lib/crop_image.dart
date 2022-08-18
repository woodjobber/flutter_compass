import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'dart:io';

Future<File> cropAndResizeFile({
  required File file,
  required double aspectRatio,
  required int width,
  required String destPath,
  int quality = 100,
}) async {
  return compute<_CropResizeArgs, File>(
      _cropAndResizeFile,
      _CropResizeArgs(
        sourcePath: file.path,
        destPath: destPath,
        aspectRatio: aspectRatio,
        width: width,
        quality: quality,
      ));
}

class _CropResizeArgs {
  final String sourcePath;
  final String destPath;
  final double aspectRatio;
  final int width;
  final int quality;
  _CropResizeArgs({
    required this.sourcePath,
    required this.destPath,
    required this.aspectRatio,
    required this.width,
    required this.quality,
  });
}

Future<File> _cropAndResizeFile(_CropResizeArgs args) async {
  final image =
      await img.decodeImage(await File(args.sourcePath).readAsBytes());

  if (image == null) throw Exception('Unable to decode image from file');

  final croppedResized = cropAndResize(image, args.aspectRatio, args.width);
  final jpegBytes = img.encodeJpg(croppedResized, quality: args.quality);

  final croppedImageFile = await File(args.destPath).writeAsBytes(jpegBytes);
  return croppedImageFile;
}

img.Image cropAndResize(img.Image src, double aspectRatio, int width) {
  final cropped = centerCrop(src, aspectRatio);
  final croppedResized = img.copyResize(
    cropped,
    width: width,
    interpolation: img.Interpolation.average,
  );
  if (cropped.width < width) {
    return cropped;
  }
  return croppedResized;
}

img.Image centerCrop(img.Image source, double aspectRatio) {
  final rect = getCropRect(
      sourceWidth: source.width,
      sourceHeight: source.height,
      aspectRatio: aspectRatio);

  return img.copyCrop(source, rect.left, rect.top, rect.width, rect.height);
}

math.Rectangle<int> getCropRect({
  required int sourceWidth,
  required int sourceHeight,
  required double aspectRatio,
}) {
  var left = 0;
  var top = 0;
  var width = sourceWidth;
  var height = sourceHeight;

  if (aspectRatio < sourceWidth / sourceHeight) {
    width = (sourceHeight * aspectRatio).floor();
    left = (sourceWidth - width) ~/ 2;
  } else if (aspectRatio > sourceWidth / sourceHeight) {
    height = sourceWidth ~/ aspectRatio;
    top = (sourceHeight - height) ~/ 2;
  }
  return math.Rectangle<int>(left, top, width, height);
}
