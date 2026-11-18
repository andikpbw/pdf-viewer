import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/painting.dart';

import '../models/pdf_bookmark.dart';
import '../models/pdf_document.dart';
import '../models/pdf_metadata.dart';
import '../models/pdf_page_data.dart';
import 'zlib_decoder.dart';

/// Exception thrown when a PDF payload is malformed or cannot be parsed.
class PdfFormatException implements Exception {
  /// Creates a [PdfFormatException] with a descriptive [message].
  const PdfFormatException(this.message);

  /// Description of the parsing error.
  final String message;

  @override
  String toString() => 'PdfFormatException: $message';
}

/// Pure-Dart PDF 1.0–1.7 parser and content-stream interpreter.
///
/// Parses PDF objects, `/Info` metadata, `/Page` trees, `/FlateDecode` streams,
/// vector graphics (`re`, `m`, `l`, `S`, `f`, `B`, `rg`, `RG`, `g`, `G`), and
/// text blocks (`BT`..`ET`, `Tf`, `Td`, `TD`, `Tm`, `T*`, `Tj`, `TJ`) into
/// structured [PdfDocument] instances that render at crisp vector resolution on
/// any Flutter platform.
class PdfParser {
  const PdfParser._();

  /// Parses raw PDF [bytes] into a [PdfDocument].
  ///
  /// Throws a [PdfFormatException] if [bytes] is empty or does not contain a
  /// valid `%PDF-` header.
  static PdfDocument parseBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const PdfFormatException('PDF byte buffer is empty.');
    }

    final String rawLatin1 = latin1.decode(bytes, allowInvalid: true);
    final int headerIndex = rawLatin1.indexOf('%PDF-');
    if (headerIndex == -1) {
      throw const PdfFormatException(
        'Invalid PDF file: missing "%PDF-" header signature.',
      );
    }

    String version = '1.7';
    if (rawLatin1.length >= headerIndex + 8) {
      final String candidate =
          rawLatin1.substring(headerIndex + 5, headerIndex + 8).trim();
      if (RegExp(r'^\d\.\d$').hasMatch(candidate)) {
        version = candidate;
      }
    }

    final bool isEncrypted = RegExp(r'/Encrypt\b').hasMatch(rawLatin1);

    final Map<int, _PdfRawObject> objects = _extractObjects(bytes, rawLatin1);
    final PdfMetadata metadata = _extractMetadata(
      rawLatin1: rawLatin1,
      objects: objects,
      version: version,
      isEncrypted: isEncrypted,
      fileSize: bytes.length,
    );

    final List<PdfPageData> pages = _extractPages(objects, rawLatin1);
    final List<PdfBookmark> bookmarks = _extractBookmarks(objects, pages);

    return PdfDocument(
      pages: pages,
      metadata: metadata,
      bookmarks: bookmarks,
      rawBytes: bytes,
    );
  }

  static Map<int, _PdfRawObject> _extractObjects(
    Uint8List bytes,
    String rawLatin1,
  ) {
    final Map<int, _PdfRawObject> map = <int, _PdfRawObject>{};
    final RegExp objHeaderRegex = RegExp(r'(\d+)\s+(\d+)\s+obj\b');

    for (final RegExpMatch match in objHeaderRegex.allMatches(rawLatin1)) {
      final int? objId = int.tryParse(match.group(1) ?? '');
      if (objId == null) {
        continue;
      }
      final int bodyStart = match.end;
      final int endObjIndex = rawLatin1.indexOf('endobj', bodyStart);
      if (endObjIndex == -1) {
        continue;
      }
      final String objContent = rawLatin1.substring(bodyStart, endObjIndex);
      Uint8List? streamBytes;

      final int streamKeywordIdx = objContent.indexOf('stream');
      if (streamKeywordIdx != -1) {
        final int absStreamKeyword = bodyStart + streamKeywordIdx;
        int dataStart = absStreamKeyword + 6;
        if (dataStart < bytes.length && bytes[dataStart] == 0x0D) {
          dataStart++;
        }
        if (dataStart < bytes.length && bytes[dataStart] == 0x0A) {
          dataStart++;
        }
        final int endStreamRel =
            objContent.indexOf('endstream', streamKeywordIdx + 6);
        if (endStreamRel != -1) {
          int dataEnd = bodyStart + endStreamRel;
          while (dataEnd > dataStart &&
              (bytes[dataEnd - 1] == 0x0A || bytes[dataEnd - 1] == 0x0D)) {
            dataEnd--;
          }
          if (dataEnd >= dataStart && dataEnd <= bytes.length) {
            final Uint8List rawSlice =
                Uint8List.sublistView(bytes, dataStart, dataEnd);
            final bool isFlate = objContent.contains('/FlateDecode') ||
                objContent.contains('/Fl');
            if (isFlate) {
              streamBytes = ZlibDecoder.tryDecode(rawSlice) ?? rawSlice;
            } else {
              streamBytes = rawSlice;
            }
          }
        }
      }

      map[objId] = _PdfRawObject(
        id: objId,
        body: objContent,
        stream: streamBytes,
      );
    }

    return map;
  }

  static PdfMetadata _extractMetadata({
    required String rawLatin1,
    required Map<int, _PdfRawObject> objects,
    required String version,
    required bool isEncrypted,
    required int fileSize,
  }) {
    String? title = _findStringKey(rawLatin1, 'Title');
    String? author = _findStringKey(rawLatin1, 'Author');
    String? subject = _findStringKey(rawLatin1, 'Subject');
    String? keywords = _findStringKey(rawLatin1, 'Keywords');
    String? creator = _findStringKey(rawLatin1, 'Creator');
    String? producer = _findStringKey(rawLatin1, 'Producer');
    final String? rawCreationDate = _findStringKey(rawLatin1, 'CreationDate');
    final String? rawModDate = _findStringKey(rawLatin1, 'ModDate');

    for (final _PdfRawObject obj in objects.values) {
      if (obj.body.contains('/Title') || obj.body.contains('/Author')) {
        title ??= _findStringKey(obj.body, 'Title');
        author ??= _findStringKey(obj.body, 'Author');
        subject ??= _findStringKey(obj.body, 'Subject');
        keywords ??= _findStringKey(obj.body, 'Keywords');
        creator ??= _findStringKey(obj.body, 'Creator');
        producer ??= _findStringKey(obj.body, 'Producer');
      }
    }

    return PdfMetadata(
      title: title,
      author: author,
      subject: subject,
      keywords: keywords,
      creator: creator,
      producer: producer,
      creationDate: _parsePdfDate(rawCreationDate),
      modificationDate: _parsePdfDate(rawModDate),
      version: version,
      isEncrypted: isEncrypted,
      fileSizeInBytes: fileSize,
    );
  }

  static String? _findStringKey(String source, String key) {
    final RegExp pattern = RegExp(
      '/$key\\s*(?:\\(([^\\)]*)\\)|<([0-9A-Fa-f\\s]+)>)',
    );
    final RegExpMatch? match = pattern.firstMatch(source);
    if (match == null) {
      return null;
    }
    if (match.group(1) != null) {
      return _decodePdfLiteralString(match.group(1)!);
    }
    if (match.group(2) != null) {
      return _decodePdfHexString(match.group(2)!);
    }
    return null;
  }

  static DateTime? _parsePdfDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    String cleaned = raw.trim();
    if (cleaned.startsWith('D:')) {
      cleaned = cleaned.substring(2);
    }
    final RegExp digits =
        RegExp(r'^(\d{4})(\d{2})?(\d{2})?(\d{2})?(\d{2})?(\d{2})?');
    final RegExpMatch? m = digits.firstMatch(cleaned);
    if (m == null) {
      return DateTime.tryParse(raw);
    }
    final int year = int.parse(m.group(1)!);
    final int month = int.tryParse(m.group(2) ?? '1') ?? 1;
    final int day = int.tryParse(m.group(3) ?? '1') ?? 1;
    final int hour = int.tryParse(m.group(4) ?? '0') ?? 0;
    final int minute = int.tryParse(m.group(5) ?? '0') ?? 0;
    final int second = int.tryParse(m.group(6) ?? '0') ?? 0;
    return DateTime.utc(year, month, day, hour, minute, second);
  }

  static List<PdfPageData> _extractPages(
    Map<int, _PdfRawObject> objects,
    String rawLatin1,
  ) {
    final List<_PdfRawObject> pageObjects = <_PdfRawObject>[];
    final RegExp pageTypeRegex = RegExp(r'/Type\s*/Page\b(?!s)');

    final List<int> sortedIds = objects.keys.toList()..sort();
    for (final int id in sortedIds) {
      final _PdfRawObject obj = objects[id]!;
      if (pageTypeRegex.hasMatch(obj.body)) {
        pageObjects.add(obj);
      }
    }

    // Inherit global MediaBox if specified on /Pages parent node.
    final (double defaultWidth, double defaultHeight) =
        _parseMediaBox(rawLatin1) ?? (595.28, 841.89);

    if (pageObjects.isEmpty) {
      // Fallback: interpret all content streams in the file as page 1.
      final StringBuffer combinedStream = StringBuffer();
      for (final int id in sortedIds) {
        final _PdfRawObject obj = objects[id]!;
        if (obj.stream != null) {
          combinedStream.writeln(
            latin1.decode(obj.stream!, allowInvalid: true),
          );
        }
      }
      final List<PdfGraphicElement> elements = _interpretContentStream(
        combinedStream.toString(),
        defaultWidth,
        defaultHeight,
      );
      return <PdfPageData>[
        PdfPageData(
          pageNumber: 1,
          width: defaultWidth,
          height: defaultHeight,
          elements: elements,
        ),
      ];
    }

    final List<PdfPageData> result = <PdfPageData>[];
    for (int i = 0; i < pageObjects.length; i++) {
      final _PdfRawObject pageObj = pageObjects[i];
      final (double pageWidth, double pageHeight) =
          _parseMediaBox(pageObj.body) ?? (defaultWidth, defaultHeight);
      final int rotation = _parseRotation(pageObj.body);

      final String contentStream = _resolvePageContentStream(pageObj, objects);
      final List<PdfGraphicElement> elements = _interpretContentStream(
        contentStream,
        pageWidth,
        pageHeight,
      );

      result.add(
        PdfPageData(
          pageNumber: i + 1,
          width: pageWidth,
          height: pageHeight,
          rotation: rotation,
          elements: elements,
        ),
      );
    }

    return result;
  }

  static (double, double)? _parseMediaBox(String dictText) {
    final RegExp mediaBoxRegex = RegExp(
      r'/MediaBox\s*\[\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s*\]',
    );
    final RegExpMatch? m = mediaBoxRegex.firstMatch(dictText);
    if (m == null) {
      return null;
    }
    final double x0 = double.tryParse(m.group(1)!) ?? 0.0;
    final double y0 = double.tryParse(m.group(2)!) ?? 0.0;
    final double x1 = double.tryParse(m.group(3)!) ?? 595.28;
    final double y1 = double.tryParse(m.group(4)!) ?? 841.89;
    final double w = (x1 - x0).abs();
    final double h = (y1 - y0).abs();
    if (w <= 0 || h <= 0) {
      return null;
    }
    return (w, h);
  }

  static int _parseRotation(String dictText) {
    final RegExp rotRegex = RegExp(r'/Rotate\s+(\d+)');
    final RegExpMatch? m = rotRegex.firstMatch(dictText);
    if (m == null) {
      return 0;
    }
    final int val = int.tryParse(m.group(1)!) ?? 0;
    return val % 360;
  }

  static String _resolvePageContentStream(
    _PdfRawObject pageObj,
    Map<int, _PdfRawObject> objects,
  ) {
    final StringBuffer buffer = StringBuffer();
    if (pageObj.stream != null) {
      buffer.writeln(latin1.decode(pageObj.stream!, allowInvalid: true));
    }

    // Check /Contents [ N 0 R ... ]
    final RegExp arrayRegex = RegExp(r'/Contents\s*\[([^\]]+)\]');
    final RegExpMatch? arrayMatch = arrayRegex.firstMatch(pageObj.body);
    if (arrayMatch != null) {
      final String refs = arrayMatch.group(1)!;
      final RegExp refItem = RegExp(r'(\d+)\s+\d+\s+R');
      for (final RegExpMatch rm in refItem.allMatches(refs)) {
        final int? refId = int.tryParse(rm.group(1)!);
        final _PdfRawObject? target = objects[refId];
        if (target?.stream != null) {
          buffer.writeln(latin1.decode(target!.stream!, allowInvalid: true));
        }
      }
      return buffer.toString();
    }

    // Check /Contents N 0 R
    final RegExp singleRefRegex = RegExp(r'/Contents\s+(\d+)\s+\d+\s+R');
    final RegExpMatch? singleMatch = singleRefRegex.firstMatch(pageObj.body);
    if (singleMatch != null) {
      final int? refId = int.tryParse(singleMatch.group(1)!);
      final _PdfRawObject? target = objects[refId];
      if (target?.stream != null) {
        buffer.writeln(latin1.decode(target!.stream!, allowInvalid: true));
      }
    }

    return buffer.toString();
  }

  static List<PdfGraphicElement> _interpretContentStream(
    String stream,
    double pageWidth,
    double pageHeight,
  ) {
    if (stream.trim().isEmpty) {
      return const <PdfGraphicElement>[];
    }

    final List<PdfGraphicElement> elements = <PdfGraphicElement>[];
    final List<_GraphicsState> stateStack = <_GraphicsState>[];
    _GraphicsState state = _GraphicsState();

    // Active path state
    final List<Offset> activePathPoints = <Offset>[];
    Rect? pendingRect;

    // Active text state
    double textX = 0.0;
    double textY = 0.0;
    double textLineX = 0.0;
    double textLineY = 0.0;
    double textLeading = 14.0;
    double fontSize = 12.0;
    String fontName = 'F1';
    bool isBold = false;
    bool isItalic = false;
    bool isMono = false;

    final List<String> tokens = _tokenizeContentStream(stream);
    final List<String> operands = <String>[];

    double toPageY(double pdfY) => pageHeight - pdfY;

    void flushPendingGeometry({required bool fill, required bool stroke}) {
      if (pendingRect != null) {
        elements.add(
          PdfRectElement(
            rect: pendingRect!,
            fillColor: fill ? state.fillColor : null,
            strokeColor: stroke ? state.strokeColor : null,
            strokeWidth: state.lineWidth,
          ),
        );
        pendingRect = null;
      }
      if (activePathPoints.length >= 2) {
        if (activePathPoints.length == 2 && !fill && stroke) {
          elements.add(
            PdfLineElement(
              start: activePathPoints[0],
              end: activePathPoints[1],
              color: state.strokeColor,
              strokeWidth: state.lineWidth,
            ),
          );
        } else {
          elements.add(
            PdfPathElement(
              points: List<Offset>.unmodifiable(activePathPoints),
              fillColor: fill ? state.fillColor : null,
              strokeColor: stroke ? state.strokeColor : null,
              strokeWidth: state.lineWidth,
              isClosed: fill,
            ),
          );
        }
        activePathPoints.clear();
      }
    }

    void emitText(String rawText) {
      final String cleaned = rawText.trim();
      if (cleaned.isEmpty) {
        return;
      }
      final double effectiveFontSize =
          (fontSize * state.scaleY).clamp(6.0, 96.0);
      final double charWidthFactor = isMono ? 0.60 : (isBold ? 0.56 : 0.52);
      final double estimatedWidth =
          math.max(8.0, cleaned.length * effectiveFontSize * charWidthFactor);
      final double estimatedHeight = effectiveFontSize * 1.25;

      final double left = (textX + state.translateX).clamp(0.0, pageWidth);
      final double top = (toPageY(textY + state.translateY) - effectiveFontSize)
          .clamp(0.0, pageHeight);

      elements.add(
        PdfTextElement(
          text: cleaned,
          bounds: Rect.fromLTWH(left, top, estimatedWidth, estimatedHeight),
          fontSize: effectiveFontSize,
          color: state.fillColor,
          fontFamily: fontName,
          isBold: isBold,
          isItalic: isItalic,
          isMonospace: isMono,
        ),
      );
      textX += estimatedWidth;
    }

    for (final String token in tokens) {
      switch (token) {
        case 'q':
          stateStack.add(state.clone());
          operands.clear();
        case 'Q':
          if (stateStack.isNotEmpty) {
            state = stateStack.removeLast();
          }
          operands.clear();
        case 'cm':
          if (operands.length >= 6) {
            final double a = _numAt(operands, operands.length - 6, 1.0);
            final double d = _numAt(operands, operands.length - 3, 1.0);
            final double e = _numAt(operands, operands.length - 2, 0.0);
            final double f = _numAt(operands, operands.length - 1, 0.0);
            if (a > 0) {
              state.scaleX = a;
            }
            if (d > 0) {
              state.scaleY = d;
            }
            state.translateX += e;
            state.translateY += f;
          }
          operands.clear();
        case 'w':
          if (operands.isNotEmpty) {
            state.lineWidth =
                _numAt(operands, operands.length - 1, 1.0).clamp(0.25, 24.0);
          }
          operands.clear();
        case 'rg':
          if (operands.length >= 3) {
            state.fillColor = _rgbFromOperands(operands);
          }
          operands.clear();
        case 'RG':
          if (operands.length >= 3) {
            state.strokeColor = _rgbFromOperands(operands);
          }
          operands.clear();
        case 'g':
          if (operands.isNotEmpty) {
            final double g =
                _numAt(operands, operands.length - 1, 0.0).clamp(0.0, 1.0);
            final int v = (g * 255).round();
            state.fillColor = Color.fromARGB(255, v, v, v);
          }
          operands.clear();
        case 'G':
          if (operands.isNotEmpty) {
            final double g =
                _numAt(operands, operands.length - 1, 0.0).clamp(0.0, 1.0);
            final int v = (g * 255).round();
            state.strokeColor = Color.fromARGB(255, v, v, v);
          }
          operands.clear();
        case 'k':
          if (operands.length >= 4) {
            state.fillColor = _cmykFromOperands(operands);
          }
          operands.clear();
        case 'K':
          if (operands.length >= 4) {
            state.strokeColor = _cmykFromOperands(operands);
          }
          operands.clear();
        case 're':
          if (operands.length >= 4) {
            final double x = _numAt(operands, operands.length - 4, 0.0);
            final double y = _numAt(operands, operands.length - 3, 0.0);
            final double w = _numAt(operands, operands.length - 2, 0.0);
            final double h = _numAt(operands, operands.length - 1, 0.0);
            final double top = toPageY(y + h);
            pendingRect = Rect.fromLTWH(x, top, w.abs(), h.abs());
          }
          operands.clear();
        case 'm':
          if (operands.length >= 2) {
            activePathPoints.clear();
            final double x = _numAt(operands, operands.length - 2, 0.0);
            final double y = _numAt(operands, operands.length - 1, 0.0);
            activePathPoints.add(Offset(x, toPageY(y)));
          }
          operands.clear();
        case 'l':
          if (operands.length >= 2) {
            final double x = _numAt(operands, operands.length - 2, 0.0);
            final double y = _numAt(operands, operands.length - 1, 0.0);
            activePathPoints.add(Offset(x, toPageY(y)));
          }
          operands.clear();
        case 'h':
          operands.clear();
        case 'S':
        case 's':
          flushPendingGeometry(fill: false, stroke: true);
          operands.clear();
        case 'f':
        case 'F':
        case 'f*':
          flushPendingGeometry(fill: true, stroke: false);
          operands.clear();
        case 'B':
        case 'B*':
        case 'b':
        case 'b*':
          flushPendingGeometry(fill: true, stroke: true);
          operands.clear();
        case 'n':
          pendingRect = null;
          activePathPoints.clear();
          operands.clear();
        case 'BT':
          textX = 0.0;
          textY = 0.0;
          textLineX = 0.0;
          textLineY = 0.0;
          operands.clear();
        case 'ET':
          operands.clear();
        case 'Tf':
          if (operands.length >= 2) {
            fontName = operands[operands.length - 2].replaceAll('/', '');
            fontSize = _numAt(operands, operands.length - 1, 12.0);
            final String lower = fontName.toLowerCase();
            isBold =
                lower.contains('bold') || lower == 'f2' || lower.endsWith('b');
            isItalic = lower.contains('italic') ||
                lower.contains('oblique') ||
                lower == 'f3';
            isMono = lower.contains('mono') ||
                lower.contains('courier') ||
                lower == 'f4';
          }
          operands.clear();
        case 'TL':
          if (operands.isNotEmpty) {
            textLeading = _numAt(operands, operands.length - 1, 14.0);
          }
          operands.clear();
        case 'Tm':
          if (operands.length >= 6) {
            final double a = _numAt(operands, operands.length - 6, 1.0);
            final double e = _numAt(operands, operands.length - 2, 0.0);
            final double f = _numAt(operands, operands.length - 1, 0.0);
            if (a > 1.5 && fontSize == 12.0) {
              fontSize = a;
            }
            textLineX = e;
            textLineY = f;
            textX = e;
            textY = f;
          }
          operands.clear();
        case 'Td':
          if (operands.length >= 2) {
            final double tx = _numAt(operands, operands.length - 2, 0.0);
            final double ty = _numAt(operands, operands.length - 1, 0.0);
            textLineX += tx;
            textLineY += ty;
            textX = textLineX;
            textY = textLineY;
          }
          operands.clear();
        case 'TD':
          if (operands.length >= 2) {
            final double tx = _numAt(operands, operands.length - 2, 0.0);
            final double ty = _numAt(operands, operands.length - 1, 0.0);
            textLeading = -ty;
            textLineX += tx;
            textLineY += ty;
            textX = textLineX;
            textY = textLineY;
          }
          operands.clear();
        case 'T*':
          textLineY -= textLeading;
          textX = textLineX;
          textY = textLineY;
          operands.clear();
        case 'Tj':
          if (operands.isNotEmpty) {
            emitText(_decodePdfTokenText(operands.last));
          }
          operands.clear();
        case 'TJ':
          if (operands.isNotEmpty) {
            final String combined = operands.map(_decodePdfTokenText).join();
            emitText(combined);
          }
          operands.clear();
        case "'":
          textLineY -= textLeading;
          textX = textLineX;
          textY = textLineY;
          if (operands.isNotEmpty) {
            emitText(_decodePdfTokenText(operands.last));
          }
          operands.clear();
        case '"':
          textLineY -= textLeading;
          textX = textLineX;
          textY = textLineY;
          if (operands.isNotEmpty) {
            emitText(_decodePdfTokenText(operands.last));
          }
          operands.clear();
        default:
          operands.add(token);
      }
    }

    return elements;
  }

  static List<String> _tokenizeContentStream(String stream) {
    final List<String> tokens = <String>[];
    final int len = stream.length;
    int i = 0;

    while (i < len) {
      final int cu = stream.codeUnitAt(i);
      // Skip whitespace
      if (cu <= 32) {
        i++;
        continue;
      }
      // Skip comments % ... \n
      if (cu == 0x25) {
        while (i < len &&
            stream.codeUnitAt(i) != 0x0A &&
            stream.codeUnitAt(i) != 0x0D) {
          i++;
        }
        continue;
      }
      // Literal string (...)
      if (cu == 0x28) {
        final StringBuffer sb = StringBuffer('(');
        i++;
        int depth = 1;
        while (i < len && depth > 0) {
          final int c = stream.codeUnitAt(i);
          if (c == 0x5C && i + 1 < len) {
            sb.writeCharCode(c);
            sb.writeCharCode(stream.codeUnitAt(i + 1));
            i += 2;
            continue;
          }
          if (c == 0x28) {
            depth++;
          } else if (c == 0x29) {
            depth--;
          }
          sb.writeCharCode(c);
          i++;
        }
        tokens.add(sb.toString());
        continue;
      }
      // Array [...]
      if (cu == 0x5B) {
        final StringBuffer sb = StringBuffer('[');
        i++;
        int depth = 1;
        while (i < len && depth > 0) {
          final int c = stream.codeUnitAt(i);
          if (c == 0x28) {
            // Keep nested string inside array intact
            sb.writeCharCode(c);
            i++;
            int pDepth = 1;
            while (i < len && pDepth > 0) {
              final int sc = stream.codeUnitAt(i);
              if (sc == 0x5C && i + 1 < len) {
                sb.writeCharCode(sc);
                sb.writeCharCode(stream.codeUnitAt(i + 1));
                i += 2;
                continue;
              }
              if (sc == 0x28) {
                pDepth++;
              } else if (sc == 0x29) {
                pDepth--;
              }
              sb.writeCharCode(sc);
              i++;
            }
            continue;
          }
          if (c == 0x5B) {
            depth++;
          } else if (c == 0x5D) {
            depth--;
          }
          sb.writeCharCode(c);
          i++;
        }
        tokens.add(sb.toString());
        continue;
      }
      // Hex string <...>
      if (cu == 0x3C) {
        final int end = stream.indexOf('>', i + 1);
        if (end != -1) {
          tokens.add(stream.substring(i, end + 1));
          i = end + 1;
          continue;
        }
      }
      // Regular token
      final int start = i;
      while (i < len) {
        final int c = stream.codeUnitAt(i);
        if (c <= 32 ||
            c == 0x28 ||
            c == 0x29 ||
            c == 0x5B ||
            c == 0x5D ||
            c == 0x3C) {
          break;
        }
        i++;
      }
      tokens.add(stream.substring(start, i));
    }

    return tokens;
  }

  static double _numAt(List<String> operands, int index, double fallback) {
    if (index < 0 || index >= operands.length) {
      return fallback;
    }
    return double.tryParse(operands[index]) ?? fallback;
  }

  static Color _rgbFromOperands(List<String> operands) {
    final double r = _numAt(operands, operands.length - 3, 0.0).clamp(0.0, 1.0);
    final double g = _numAt(operands, operands.length - 2, 0.0).clamp(0.0, 1.0);
    final double b = _numAt(operands, operands.length - 1, 0.0).clamp(0.0, 1.0);
    return Color.fromARGB(
      255,
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
    );
  }

  static Color _cmykFromOperands(List<String> operands) {
    final double c = _numAt(operands, operands.length - 4, 0.0).clamp(0.0, 1.0);
    final double m = _numAt(operands, operands.length - 3, 0.0).clamp(0.0, 1.0);
    final double y = _numAt(operands, operands.length - 2, 0.0).clamp(0.0, 1.0);
    final double k = _numAt(operands, operands.length - 1, 0.0).clamp(0.0, 1.0);
    final int r = ((1.0 - c) * (1.0 - k) * 255).round();
    final int g = ((1.0 - m) * (1.0 - k) * 255).round();
    final int b = ((1.0 - y) * (1.0 - k) * 255).round();
    return Color.fromARGB(255, r, g, b);
  }

  static String _decodePdfTokenText(String token) {
    if (token.startsWith('(') && token.endsWith(')')) {
      return _decodePdfLiteralString(token.substring(1, token.length - 1));
    }
    if (token.startsWith('<') && token.endsWith('>')) {
      return _decodePdfHexString(token.substring(1, token.length - 1));
    }
    if (token.startsWith('[') && token.endsWith(']')) {
      final String inner = token.substring(1, token.length - 1);
      final StringBuffer sb = StringBuffer();
      final RegExp partRegex =
          RegExp(r'\((?:\\.|[^\\\)])*\)|<[0-9A-Fa-f\s]+>|(-?\d+(?:\.\d+)?)');
      for (final RegExpMatch m in partRegex.allMatches(inner)) {
        final String piece = m.group(0)!;
        if (piece.startsWith('(')) {
          sb.write(
              _decodePdfLiteralString(piece.substring(1, piece.length - 1)));
        } else if (piece.startsWith('<')) {
          sb.write(_decodePdfHexString(piece.substring(1, piece.length - 1)));
        } else {
          final double? kern = double.tryParse(piece);
          if (kern != null && kern < -180) {
            sb.write(' ');
          }
        }
      }
      return sb.toString();
    }
    return '';
  }

  static String _decodePdfLiteralString(String raw) {
    final StringBuffer out = StringBuffer();
    int i = 0;
    while (i < raw.length) {
      final int cu = raw.codeUnitAt(i);
      if (cu == 0x5C && i + 1 < raw.length) {
        final int next = raw.codeUnitAt(i + 1);
        switch (next) {
          case 0x6E: // n
            out.write('\n');
            i += 2;
          case 0x72: // r
            out.write('\r');
            i += 2;
          case 0x74: // t
            out.write('\t');
            i += 2;
          case 0x62: // b
            i += 2;
          case 0x66: // f
            i += 2;
          case 0x28: // (
            out.write('(');
            i += 2;
          case 0x29: // )
            out.write(')');
            i += 2;
          case 0x5C: // \
            out.write(r'\');
            i += 2;
          default:
            // Check octal \ddd
            if (next >= 0x30 && next <= 0x37) {
              String oct = String.fromCharCode(next);
              int consumed = 2;
              if (i + 2 < raw.length &&
                  raw.codeUnitAt(i + 2) >= 0x30 &&
                  raw.codeUnitAt(i + 2) <= 0x37) {
                oct += String.fromCharCode(raw.codeUnitAt(i + 2));
                consumed++;
                if (i + 3 < raw.length &&
                    raw.codeUnitAt(i + 3) >= 0x30 &&
                    raw.codeUnitAt(i + 3) <= 0x37) {
                  oct += String.fromCharCode(raw.codeUnitAt(i + 3));
                  consumed++;
                }
              }
              final int? code = int.tryParse(oct, radix: 8);
              if (code != null) {
                out.writeCharCode(code);
              }
              i += consumed;
            } else {
              out.writeCharCode(next);
              i += 2;
            }
        }
      } else {
        out.writeCharCode(cu);
        i++;
      }
    }
    return out.toString();
  }

  static String _decodePdfHexString(String hex) {
    final String cleaned = hex.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) {
      return '';
    }
    final String padded = cleaned.length.isOdd ? '${cleaned}0' : cleaned;
    final List<int> bytes = <int>[];
    for (int i = 0; i < padded.length; i += 2) {
      final int? byte = int.tryParse(padded.substring(i, i + 2), radix: 16);
      if (byte != null) {
        bytes.add(byte);
      }
    }
    // Check UTF-16BE BOM (0xFE, 0xFF)
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      final StringBuffer sb = StringBuffer();
      for (int i = 2; i + 1 < bytes.length; i += 2) {
        sb.writeCharCode((bytes[i] << 8) | bytes[i + 1]);
      }
      return sb.toString();
    }
    return String.fromCharCodes(bytes);
  }

  static List<PdfBookmark> _extractBookmarks(
    Map<int, _PdfRawObject> objects,
    List<PdfPageData> pages,
  ) {
    final List<PdfBookmark> bookmarks = <PdfBookmark>[];

    // 1. Check explicit outline objects containing /Title and /PageNum or /Dest
    int bmCounter = 1;
    final List<int> sortedIds = objects.keys.toList()..sort();
    for (final int id in sortedIds) {
      final _PdfRawObject obj = objects[id]!;
      if (obj.body.contains('/Outlines') ||
          obj.body.contains('/Type /Catalog')) {
        continue;
      }
      if (obj.body.contains('/Title') &&
          (obj.body.contains('/Parent') || obj.body.contains('/PageNumber'))) {
        final String? title = _findStringKey(obj.body, 'Title');
        final RegExp pageNumMatch = RegExp(r'/PageNumber\s+(\d+)');
        final RegExpMatch? pm = pageNumMatch.firstMatch(obj.body);
        if (title != null && title.isNotEmpty) {
          final int pageNumber = pm != null
              ? (int.tryParse(pm.group(1)!) ?? 1).clamp(1, pages.length)
              : 1;
          bookmarks.add(
            PdfBookmark(
              id: 'outline_${bmCounter++}',
              title: title,
              pageNumber: pageNumber,
            ),
          );
        }
      }
    }

    if (bookmarks.isNotEmpty) {
      return bookmarks;
    }

    // 2. Fallback: automatically infer outline from top-level headings (fontSize >= 15).
    for (final PdfPageData page in pages) {
      for (final PdfTextElement textEl in page.textElements) {
        if (textEl.fontSize >= 15.0 && textEl.text.length >= 3) {
          bookmarks.add(
            PdfBookmark(
              id: 'heading_p${page.pageNumber}_$bmCounter',
              title: textEl.text,
              pageNumber: page.pageNumber,
            ),
          );
          bmCounter++;
          break;
        }
      }
    }

    return bookmarks;
  }
}

class _PdfRawObject {
  const _PdfRawObject({
    required this.id,
    required this.body,
    this.stream,
  });

  final int id;
  final String body;
  final Uint8List? stream;
}

class _GraphicsState {
  _GraphicsState({
    this.fillColor = const Color(0xFF111827),
    this.strokeColor = const Color(0xFF334155),
    this.lineWidth = 1.0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.translateX = 0.0,
    this.translateY = 0.0,
  });

  Color fillColor;
  Color strokeColor;
  double lineWidth;
  double scaleX;
  double scaleY;
  double translateX;
  double translateY;

  _GraphicsState clone() {
    return _GraphicsState(
      fillColor: fillColor,
      strokeColor: strokeColor,
      lineWidth: lineWidth,
      scaleX: scaleX,
      scaleY: scaleY,
      translateX: translateX,
      translateY: translateY,
    );
  }
}
