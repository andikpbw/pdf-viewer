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
/// Parses PDF objects, `/Info` metadata, `/Catalog` → `/Pages` → `/Kids` trees,
/// inherited `/MediaBox`/`/CropBox`/`/Rotate`/`/Resources`, `/FlateDecode`,
/// `/ASCIIHexDecode`, `/ASCII85Decode`, PNG predictor streams, `/ToUnicode`
/// CMaps, Form XObjects (`/Do`), standard `/Outlines` trees, cubic Bezier
/// vector graphics (`re`, `m`, `l`, `c`, `v`, `y`, `h`, `S`, `f`, `B`, `rg`,
/// `RG`, `g`, `G`, `k`, `K`, `sc`, `scn`), and text blocks (`BT`..`ET`, `Tf`,
/// `Td`, `TD`, `Tm`, `T*`, `Tj`, `TJ`) into structured [PdfDocument] instances.
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

    final _ExtractedPagesResult extractedPages =
        _extractPages(objects, rawLatin1);
    final List<PdfBookmark> bookmarks = _extractBookmarks(
      objects,
      extractedPages.pages,
      extractedPages.pageObjIdToNumber,
    );

    return PdfDocument(
      pages: extractedPages.pages,
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
    final RegExp objHeaderRegex =
        RegExp(r'(?:^|[\r\n\s])(\d+)\s+(\d+)\s+obj\b');

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

      final int streamKeywordIdx = _findStreamKeyword(objContent);
      if (streamKeywordIdx != -1) {
        final String dictHeader = objContent.substring(0, streamKeywordIdx);
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
            streamBytes = _decodeStreamWithFilters(rawSlice, dictHeader);
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

  static int _findStreamKeyword(String objContent) {
    final RegExp streamRx = RegExp(r'>>\s*stream(?:\r\n|\n|\r)');
    final RegExpMatch? m = streamRx.firstMatch(objContent);
    if (m != null) {
      return objContent.indexOf('stream', m.start);
    }
    return objContent.indexOf('stream');
  }

  static Uint8List _decodeStreamWithFilters(
    Uint8List rawSlice,
    String dictHeader,
  ) {
    final List<String> filters = _extractFilterNames(dictHeader);
    if (filters.isEmpty) {
      return rawSlice;
    }
    Uint8List current = rawSlice;
    for (final String filter in filters) {
      switch (filter) {
        case 'FlateDecode':
        case 'Fl':
          final Uint8List? inflated = ZlibDecoder.tryDecode(current);
          if (inflated != null) {
            current = _applyPredictorIfNeeded(inflated, dictHeader);
          }
        case 'ASCIIHexDecode':
        case 'AHx':
          current = _decodeAsciiHex(current);
        case 'ASCII85Decode':
        case 'A85':
          current = _decodeAscii85(current);
      }
    }
    return current;
  }

  static List<String> _extractFilterNames(String dictHeader) {
    // Check array form: /Filter [ /ASCII85Decode /FlateDecode ]
    final RegExp arrayRx = RegExp(r'/Filter\s*\[([^\]]+)\]');
    final RegExpMatch? arrayMatch = arrayRx.firstMatch(dictHeader);
    if (arrayMatch != null) {
      return RegExp(r'/([A-Za-z0-9]+)')
          .allMatches(arrayMatch.group(1)!)
          .map((RegExpMatch m) => m.group(1)!)
          .toList(growable: false);
    }
    // Check single filter form: /Filter /FlateDecode
    final RegExp singleRx = RegExp(r'/Filter\s*/([A-Za-z0-9]+)\b');
    final RegExpMatch? singleMatch = singleRx.firstMatch(dictHeader);
    if (singleMatch != null) {
      return <String>[singleMatch.group(1)!];
    }
    return const <String>[];
  }

  static Uint8List _decodeAsciiHex(Uint8List input) {
    final String raw = latin1.decode(input, allowInvalid: true);
    final int eod = raw.indexOf('>');
    final String body = (eod != -1 ? raw.substring(0, eod) : raw)
        .replaceAll(RegExp(r'\s+'), '');
    if (body.isEmpty) {
      return Uint8List(0);
    }
    final String padded = body.length.isOdd ? '${body}0' : body;
    final List<int> out = <int>[];
    for (int i = 0; i < padded.length; i += 2) {
      final int? b = int.tryParse(padded.substring(i, i + 2), radix: 16);
      if (b != null) {
        out.add(b);
      }
    }
    return Uint8List.fromList(out);
  }

  static Uint8List _decodeAscii85(Uint8List input) {
    final String raw = latin1.decode(input, allowInvalid: true);
    final List<int> out = <int>[];
    final List<int> group = <int>[];

    for (int i = 0; i < raw.length; i++) {
      final int c = raw.codeUnitAt(i);
      if (c <= 32) {
        continue;
      }
      // End marker '~>'
      if (c == 0x7E) {
        break;
      }
      // 'z' shorthand for four zero bytes
      if (c == 0x7A && group.isEmpty) {
        out.addAll(const <int>[0, 0, 0, 0]);
        continue;
      }
      if (c < 33 || c > 117) {
        continue;
      }
      group.add(c - 33);
      if (group.length == 5) {
        int val = 0;
        for (final int d in group) {
          val = val * 85 + d;
        }
        out.add((val >> 24) & 0xFF);
        out.add((val >> 16) & 0xFF);
        out.add((val >> 8) & 0xFF);
        out.add(val & 0xFF);
        group.clear();
      }
    }

    if (group.length >= 2) {
      final int count = group.length;
      while (group.length < 5) {
        group.add(84);
      }
      int val = 0;
      for (final int d in group) {
        val = val * 85 + d;
      }
      final List<int> tail = <int>[
        (val >> 24) & 0xFF,
        (val >> 16) & 0xFF,
        (val >> 8) & 0xFF,
        val & 0xFF,
      ];
      for (int i = 0; i < count - 1; i++) {
        out.add(tail[i]);
      }
    }

    return Uint8List.fromList(out);
  }

  static Uint8List _applyPredictorIfNeeded(Uint8List data, String dictHeader) {
    final RegExpMatch? predMatch =
        RegExp(r'/Predictor\s+(\d+)').firstMatch(dictHeader);
    if (predMatch == null) {
      return data;
    }
    final int predictor = int.tryParse(predMatch.group(1)!) ?? 1;
    if (predictor < 10) {
      return data;
    }
    final int columns = int.tryParse(
          RegExp(r'/Columns\s+(\d+)').firstMatch(dictHeader)?.group(1) ?? '1',
        ) ??
        1;
    final int colors = int.tryParse(
          RegExp(r'/Colors\s+(\d+)').firstMatch(dictHeader)?.group(1) ?? '1',
        ) ??
        1;
    final int bpc = int.tryParse(
          RegExp(r'/BitsPerComponent\s+(\d+)')
                  .firstMatch(dictHeader)
                  ?.group(1) ??
              '8',
        ) ??
        8;

    final int bytesPerPixel = math.max(1, (colors * bpc + 7) ~/ 8);
    final int rowBytes = math.max(1, (columns * colors * bpc + 7) ~/ 8);
    final int stride = rowBytes + 1;
    if (stride <= 1 || data.length < stride) {
      return data;
    }

    final List<int> out = <int>[];
    Uint8List prevRow = Uint8List(rowBytes);
    int offset = 0;
    while (offset + stride <= data.length) {
      final int filterType = data[offset++];
      final Uint8List curRow = Uint8List(rowBytes);
      for (int x = 0; x < rowBytes; x++) {
        final int raw = data[offset + x];
        final int left = x >= bytesPerPixel ? curRow[x - bytesPerPixel] : 0;
        final int up = prevRow[x];
        final int upLeft = x >= bytesPerPixel ? prevRow[x - bytesPerPixel] : 0;
        int decoded;
        switch (filterType) {
          case 1: // Sub
            decoded = (raw + left) & 0xFF;
          case 2: // Up
            decoded = (raw + up) & 0xFF;
          case 3: // Average
            decoded = (raw + ((left + up) >> 1)) & 0xFF;
          case 4: // Paeth
            decoded = (raw + _paeth(left, up, upLeft)) & 0xFF;
          default: // None
            decoded = raw;
        }
        curRow[x] = decoded;
      }
      out.addAll(curRow);
      prevRow = curRow;
      offset += rowBytes;
    }

    return out.isEmpty ? data : Uint8List.fromList(out);
  }

  static int _paeth(int a, int b, int c) {
    final int p = a + b - c;
    final int pa = (p - a).abs();
    final int pb = (p - b).abs();
    final int pc = (p - c).abs();
    if (pa <= pb && pa <= pc) {
      return a;
    }
    if (pb <= pc) {
      return b;
    }
    return c;
  }

  static PdfMetadata _extractMetadata({
    required String rawLatin1,
    required Map<int, _PdfRawObject> objects,
    required String version,
    required bool isEncrypted,
    required int fileSize,
  }) {
    // Prefer /Info object referenced by trailer if available.
    _PdfRawObject? infoObj;
    final RegExpMatch? infoRef =
        RegExp(r'/Info\s+(\d+)\s+\d+\s+R').firstMatch(rawLatin1);
    if (infoRef != null) {
      final int? id = int.tryParse(infoRef.group(1)!);
      if (id != null) {
        infoObj = objects[id];
      }
    }

    final String primary = infoObj?.body ?? rawLatin1;
    String? title = _findStringKey(primary, 'Title');
    String? author = _findStringKey(primary, 'Author');
    String? subject = _findStringKey(primary, 'Subject');
    String? keywords = _findStringKey(primary, 'Keywords');
    String? creator = _findStringKey(primary, 'Creator');
    String? producer = _findStringKey(primary, 'Producer');
    final String? rawCreationDate = _findStringKey(primary, 'CreationDate') ??
        _findStringKey(rawLatin1, 'CreationDate');
    final String? rawModDate = _findStringKey(primary, 'ModDate') ??
        _findStringKey(rawLatin1, 'ModDate');

    for (final _PdfRawObject obj in objects.values) {
      if (obj.body.contains('/Title') || obj.body.contains('/Author')) {
        if (obj.body.contains('/Parent') || obj.body.contains('/PageNumber')) {
          continue; // Skip outline items when looking for document /Info.
        }
        title ??= _findStringKey(obj.body, 'Title');
        author ??= _findStringKey(obj.body, 'Author');
        subject ??= _findStringKey(obj.body, 'Subject');
        keywords ??= _findStringKey(obj.body, 'Keywords');
        creator ??= _findStringKey(obj.body, 'Creator');
        producer ??= _findStringKey(obj.body, 'Producer');
      }
    }

    title ??= _findStringKey(rawLatin1, 'Title');
    author ??= _findStringKey(rawLatin1, 'Author');

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
      '/$key\\s*(?:\\(((?:\\\\.|[^\\\\\\)])*)\\)|<([0-9A-Fa-f\\s]+)>)',
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

  static _ExtractedPagesResult _extractPages(
    Map<int, _PdfRawObject> objects,
    String rawLatin1,
  ) {
    final (double globalWidth, double globalHeight) =
        _parseBox(rawLatin1, 'CropBox') ??
            _parseBox(rawLatin1, 'MediaBox') ??
            (595.28, 841.89);

    // 1. Walk the canonical /Catalog -> /Pages -> /Kids tree in exact page order.
    final List<_ResolvedPageNode> orderedNodes = <_ResolvedPageNode>[];
    final Set<int> visitedNodes = <int>{};
    int? pagesRootId;

    for (final _PdfRawObject obj in objects.values) {
      if (RegExp(r'/Type\s*/Catalog\b').hasMatch(obj.body)) {
        final RegExpMatch? pagesRef =
            RegExp(r'/Pages\s+(\d+)\s+\d+\s+R').firstMatch(obj.body);
        if (pagesRef != null) {
          pagesRootId = int.tryParse(pagesRef.group(1)!);
          break;
        }
      }
    }

    if (pagesRootId != null && objects.containsKey(pagesRootId)) {
      _collectPageTree(
        nodeId: pagesRootId,
        objects: objects,
        visited: visitedNodes,
        inheritedBox: (globalWidth, globalHeight),
        inheritedRotate: 0,
        inheritedResourcesBody: '',
        out: orderedNodes,
      );
    }

    // 2. Fallback: scan all /Type /Page objects sorted by object ID.
    if (orderedNodes.isEmpty) {
      final RegExp pageTypeRegex = RegExp(r'/Type\s*/Page\b(?!s)');
      final List<int> sortedIds = objects.keys.toList()..sort();
      for (final int id in sortedIds) {
        final _PdfRawObject obj = objects[id]!;
        if (pageTypeRegex.hasMatch(obj.body)) {
          final (double w, double h) = _parseBox(obj.body, 'CropBox') ??
              _parseBox(obj.body, 'MediaBox') ??
              (globalWidth, globalHeight);
          orderedNodes.add(
            _ResolvedPageNode(
              obj: obj,
              width: w,
              height: h,
              rotation: _parseRotation(obj.body) ?? 0,
              resourcesBody: _resolveResourcesBody(obj.body, objects),
            ),
          );
        }
      }
    }

    // 3. Last-resort fallback: interpret all streams as page 1.
    if (orderedNodes.isEmpty) {
      final List<int> sortedIds = objects.keys.toList()..sort();
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
        stream: combinedStream.toString(),
        pageWidth: globalWidth,
        pageHeight: globalHeight,
        fonts: const <String, _PdfFontInfo>{},
        xObjects: const <String, int>{},
        objects: objects,
      );
      return _ExtractedPagesResult(
        pages: <PdfPageData>[
          PdfPageData(
            pageNumber: 1,
            width: globalWidth,
            height: globalHeight,
            elements: elements,
          ),
        ],
        pageObjIdToNumber: const <int, int>{},
      );
    }

    final List<PdfPageData> result = <PdfPageData>[];
    final Map<int, int> objIdToPageNum = <int, int>{};

    for (int i = 0; i < orderedNodes.length; i++) {
      final _ResolvedPageNode node = orderedNodes[i];
      final int pageNum = i + 1;
      objIdToPageNum[node.obj.id] = pageNum;

      final Map<String, _PdfFontInfo> fonts =
          _extractPageFonts(node.resourcesBody, objects);
      final Map<String, int> xObjects =
          _extractPageXObjects(node.resourcesBody, objects);

      final String contentStream = _resolvePageContentStream(node.obj, objects);
      final List<PdfGraphicElement> elements = _interpretContentStream(
        stream: contentStream,
        pageWidth: node.width,
        pageHeight: node.height,
        fonts: fonts,
        xObjects: xObjects,
        objects: objects,
      );

      result.add(
        PdfPageData(
          pageNumber: pageNum,
          width: node.width,
          height: node.height,
          rotation: node.rotation,
          elements: elements,
        ),
      );
    }

    return _ExtractedPagesResult(
      pages: result,
      pageObjIdToNumber: objIdToPageNum,
    );
  }

  static void _collectPageTree({
    required int nodeId,
    required Map<int, _PdfRawObject> objects,
    required Set<int> visited,
    required (double, double) inheritedBox,
    required int inheritedRotate,
    required String inheritedResourcesBody,
    required List<_ResolvedPageNode> out,
  }) {
    if (!visited.add(nodeId)) {
      return;
    }
    final _PdfRawObject? obj = objects[nodeId];
    if (obj == null) {
      return;
    }

    final (double, double) currentBox = _parseBox(obj.body, 'CropBox') ??
        _parseBox(obj.body, 'MediaBox') ??
        inheritedBox;
    final int currentRotate = _parseRotation(obj.body) ?? inheritedRotate;
    final String localRes = _resolveResourcesBody(obj.body, objects);
    final String effectiveRes =
        localRes.isNotEmpty ? localRes : inheritedResourcesBody;

    final bool isPagesNode = RegExp(r'/Type\s*/Pages\b').hasMatch(obj.body) ||
        obj.body.contains('/Kids');

    if (isPagesNode && !RegExp(r'/Type\s*/Page\b(?!s)').hasMatch(obj.body)) {
      final RegExpMatch? kidsMatch =
          RegExp(r'/Kids\s*\[([^\]]+)\]').firstMatch(obj.body);
      if (kidsMatch != null) {
        for (final RegExpMatch rm
            in RegExp(r'(\d+)\s+\d+\s+R').allMatches(kidsMatch.group(1)!)) {
          final int? childId = int.tryParse(rm.group(1)!);
          if (childId != null) {
            _collectPageTree(
              nodeId: childId,
              objects: objects,
              visited: visited,
              inheritedBox: currentBox,
              inheritedRotate: currentRotate,
              inheritedResourcesBody: effectiveRes,
              out: out,
            );
          }
        }
      }
      return;
    }

    out.add(
      _ResolvedPageNode(
        obj: obj,
        width: currentBox.$1,
        height: currentBox.$2,
        rotation: currentRotate,
        resourcesBody: effectiveRes,
      ),
    );
  }

  static String _resolveResourcesBody(
    String dictBody,
    Map<int, _PdfRawObject> objects,
  ) {
    final RegExpMatch? refMatch =
        RegExp(r'/Resources\s+(\d+)\s+\d+\s+R').firstMatch(dictBody);
    if (refMatch != null) {
      final int? id = int.tryParse(refMatch.group(1)!);
      if (id != null && objects[id] != null) {
        return objects[id]!.body;
      }
    }
    final int resIdx = dictBody.indexOf('/Resources');
    if (resIdx != -1) {
      return _extractBalancedDict(dictBody, resIdx) ??
          dictBody.substring(resIdx);
    }
    return '';
  }

  static String? _extractBalancedDict(String source, int startFrom) {
    final int open = source.indexOf('<<', startFrom);
    if (open == -1) {
      return null;
    }
    int depth = 0;
    int i = open;
    while (i + 1 < source.length) {
      if (source.codeUnitAt(i) == 0x3C && source.codeUnitAt(i + 1) == 0x3C) {
        depth++;
        i += 2;
        continue;
      }
      if (source.codeUnitAt(i) == 0x3E && source.codeUnitAt(i + 1) == 0x3E) {
        depth--;
        i += 2;
        if (depth == 0) {
          return source.substring(open, i);
        }
        continue;
      }
      i++;
    }
    return null;
  }

  static Map<String, _PdfFontInfo> _extractPageFonts(
    String resourcesBody,
    Map<int, _PdfRawObject> objects,
  ) {
    final Map<String, _PdfFontInfo> fonts = <String, _PdfFontInfo>{};
    if (resourcesBody.isEmpty) {
      return fonts;
    }

    String? fontDictBody;
    final RegExpMatch? fontDictRef =
        RegExp(r'/Font\s+(\d+)\s+\d+\s+R').firstMatch(resourcesBody);
    if (fontDictRef != null) {
      final int? id = int.tryParse(fontDictRef.group(1)!);
      fontDictBody = id != null ? objects[id]?.body : null;
    } else {
      final int fontIdx = resourcesBody.indexOf('/Font');
      if (fontIdx != -1) {
        fontDictBody = _extractBalancedDict(resourcesBody, fontIdx);
      }
    }

    if (fontDictBody == null) {
      return fonts;
    }

    final RegExp entryRx = RegExp(r'/([A-Za-z0-9_.-]+)\s+(\d+)\s+\d+\s+R');
    for (final RegExpMatch m in entryRx.allMatches(fontDictBody)) {
      final String fontKey = m.group(1)!;
      final int? fontObjId = int.tryParse(m.group(2)!);
      final _PdfRawObject? fontObj =
          fontObjId != null ? objects[fontObjId] : null;
      if (fontObj == null) {
        continue;
      }
      final String baseFont = RegExp(r'/BaseFont\s*/([^\s/<>\[\]()]+)')
              .firstMatch(fontObj.body)
              ?.group(1) ??
          fontKey;
      final String lower = baseFont.toLowerCase();
      final bool isBold = lower.contains('bold') ||
          lower.contains('semibold') ||
          lower.contains('black') ||
          lower.contains('heavy') ||
          fontKey.toLowerCase() == 'f2';
      final bool isItalic = lower.contains('italic') ||
          lower.contains('oblique') ||
          fontKey.toLowerCase() == 'f3';
      final bool isMono = lower.contains('mono') ||
          lower.contains('courier') ||
          lower.contains('consolas') ||
          lower.contains('code') ||
          fontKey.toLowerCase() == 'f4';

      Map<int, String>? toUnicode;
      final RegExpMatch? cmapRef =
          RegExp(r'/ToUnicode\s+(\d+)\s+\d+\s+R').firstMatch(fontObj.body);
      if (cmapRef != null) {
        final int? cmapId = int.tryParse(cmapRef.group(1)!);
        final Uint8List? cmapBytes =
            cmapId != null ? objects[cmapId]?.stream : null;
        if (cmapBytes != null) {
          toUnicode = _parseToUnicodeCMap(
            latin1.decode(cmapBytes, allowInvalid: true),
          );
        }
      }

      fonts[fontKey] = _PdfFontInfo(
        name: baseFont,
        isBold: isBold,
        isItalic: isItalic,
        isMono: isMono,
        toUnicode: toUnicode,
      );
    }

    return fonts;
  }

  static Map<int, String> _parseToUnicodeCMap(String cmapText) {
    final Map<int, String> mapping = <int, String>{};

    // Parse beginbfchar ... endbfchar
    final RegExp bfCharSection =
        RegExp(r'beginbfchar([\s\S]*?)endbfchar', multiLine: true);
    final RegExp bfCharPair = RegExp(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>');
    for (final RegExpMatch sec in bfCharSection.allMatches(cmapText)) {
      for (final RegExpMatch pair in bfCharPair.allMatches(sec.group(1)!)) {
        final int? src = int.tryParse(pair.group(1)!, radix: 16);
        final String dst = _decodeCMapUnicodeHex(pair.group(2)!);
        if (src != null && dst.isNotEmpty) {
          mapping[src] = dst;
        }
      }
    }

    // Parse beginbfrange ... endbfrange
    final RegExp bfRangeSection =
        RegExp(r'beginbfrange([\s\S]*?)endbfrange', multiLine: true);
    final RegExp bfRangeLine = RegExp(
      r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*(?:<([0-9A-Fa-f]+)>|\[([^\]]+)\])',
    );
    for (final RegExpMatch sec in bfRangeSection.allMatches(cmapText)) {
      for (final RegExpMatch line in bfRangeLine.allMatches(sec.group(1)!)) {
        final int? start = int.tryParse(line.group(1)!, radix: 16);
        final int? end = int.tryParse(line.group(2)!, radix: 16);
        if (start == null ||
            end == null ||
            end < start ||
            (end - start) > 4096) {
          continue;
        }
        if (line.group(3) != null) {
          final int? parsedDst = int.tryParse(line.group(3)!, radix: 16);
          if (parsedDst != null) {
            int dstStart = parsedDst;
            for (int code = start; code <= end; code++) {
              mapping[code] = String.fromCharCode(dstStart++);
            }
          }
        } else if (line.group(4) != null) {
          final List<RegExpMatch> items =
              RegExp(r'<([0-9A-Fa-f]+)>').allMatches(line.group(4)!).toList();
          for (int i = 0; i < items.length && (start + i) <= end; i++) {
            final String dst = _decodeCMapUnicodeHex(items[i].group(1)!);
            if (dst.isNotEmpty) {
              mapping[start + i] = dst;
            }
          }
        }
      }
    }

    return mapping;
  }

  static String _decodeCMapUnicodeHex(String hex) {
    final String cleaned = hex.trim();
    if (cleaned.isEmpty) {
      return '';
    }
    if (cleaned.length <= 4) {
      final int? cp = int.tryParse(cleaned, radix: 16);
      return cp != null ? String.fromCharCode(cp) : '';
    }
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i + 3 < cleaned.length; i += 4) {
      final int? cp = int.tryParse(cleaned.substring(i, i + 4), radix: 16);
      if (cp != null) {
        sb.writeCharCode(cp);
      }
    }
    return sb.toString();
  }

  static Map<String, int> _extractPageXObjects(
    String resourcesBody,
    Map<int, _PdfRawObject> objects,
  ) {
    final Map<String, int> xObjects = <String, int>{};
    if (resourcesBody.isEmpty) {
      return xObjects;
    }

    String? xObjDictBody;
    final RegExpMatch? xObjRef =
        RegExp(r'/XObject\s+(\d+)\s+\d+\s+R').firstMatch(resourcesBody);
    if (xObjRef != null) {
      final int? id = int.tryParse(xObjRef.group(1)!);
      xObjDictBody = id != null ? objects[id]?.body : null;
    } else {
      final int idx = resourcesBody.indexOf('/XObject');
      if (idx != -1) {
        xObjDictBody = _extractBalancedDict(resourcesBody, idx);
      }
    }

    if (xObjDictBody == null) {
      return xObjects;
    }
    for (final RegExpMatch m in RegExp(r'/([A-Za-z0-9_.-]+)\s+(\d+)\s+\d+\s+R')
        .allMatches(xObjDictBody)) {
      final int? objId = int.tryParse(m.group(2)!);
      if (objId != null) {
        xObjects[m.group(1)!] = objId;
      }
    }
    return xObjects;
  }

  static (double, double)? _parseBox(String dictText, String boxName) {
    final RegExp boxRegex = RegExp(
      '/$boxName\\s*\\[\\s*([-\\d.]+)\\s+([-\\d.]+)\\s+([-\\d.]+)\\s+([-\\d.]+)\\s*\\]',
    );
    final RegExpMatch? m = boxRegex.firstMatch(dictText);
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

  static int? _parseRotation(String dictText) {
    final RegExp rotRegex = RegExp(r'/Rotate\s+(-?\d+)');
    final RegExpMatch? m = rotRegex.firstMatch(dictText);
    if (m == null) {
      return null;
    }
    final int val = int.tryParse(m.group(1)!) ?? 0;
    return ((val % 360) + 360) % 360;
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

  static List<PdfGraphicElement> _interpretContentStream({
    required String stream,
    required double pageWidth,
    required double pageHeight,
    required Map<String, _PdfFontInfo> fonts,
    required Map<String, int> xObjects,
    required Map<int, _PdfRawObject> objects,
    _GraphicsState? initialState,
    int depth = 0,
  }) {
    if (stream.trim().isEmpty || depth > 6) {
      return const <PdfGraphicElement>[];
    }

    final List<PdfGraphicElement> elements = <PdfGraphicElement>[];
    final List<_GraphicsState> stateStack = <_GraphicsState>[];
    _GraphicsState state = initialState?.clone() ?? _GraphicsState();

    // Active path state
    final List<PdfPathCommand> activeCommands = <PdfPathCommand>[];
    final List<Offset> activeSimplePoints = <Offset>[];
    bool hasCurves = false;
    Offset currentPathPoint = Offset.zero;
    Rect? pendingRect;

    // Active text state
    double tmA = 1.0;
    double tmB = 0.0;
    double tmC = 0.0;
    double tmD = 1.0;
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
    _PdfFontInfo? activeFontInfo;

    final List<String> tokens = _tokenizeContentStream(stream);
    final List<String> operands = <String>[];

    Offset toPagePoint(double pdfX, double pdfY) {
      final Offset transformed = state.matrix.transformPoint(pdfX, pdfY);
      return Offset(transformed.dx, pageHeight - transformed.dy);
    }

    void flushPendingGeometry({required bool fill, required bool stroke}) {
      if (pendingRect != null) {
        elements.add(
          PdfRectElement(
            rect: pendingRect!,
            fillColor: fill ? state.fillColor : null,
            strokeColor: stroke ? state.strokeColor : null,
            strokeWidth: state.lineWidth * state.matrix.scaleFactor,
          ),
        );
        pendingRect = null;
      }
      if (activeCommands.isNotEmpty) {
        if (!hasCurves && activeSimplePoints.length == 2 && !fill && stroke) {
          elements.add(
            PdfLineElement(
              start: activeSimplePoints[0],
              end: activeSimplePoints[1],
              color: state.strokeColor,
              strokeWidth: state.lineWidth * state.matrix.scaleFactor,
            ),
          );
        } else if (hasCurves) {
          elements.add(
            PdfPathElement(
              commands: List<PdfPathCommand>.unmodifiable(activeCommands),
              fillColor: fill ? state.fillColor : null,
              strokeColor: stroke ? state.strokeColor : null,
              strokeWidth: state.lineWidth * state.matrix.scaleFactor,
              isClosed: fill,
            ),
          );
        } else if (activeSimplePoints.length >= 2) {
          elements.add(
            PdfPathElement(
              points: List<Offset>.unmodifiable(activeSimplePoints),
              fillColor: fill ? state.fillColor : null,
              strokeColor: stroke ? state.strokeColor : null,
              strokeWidth: state.lineWidth * state.matrix.scaleFactor,
              isClosed: fill,
            ),
          );
        }
        activeCommands.clear();
        activeSimplePoints.clear();
        hasCurves = false;
      }
    }

    void emitText(String rawText) {
      final String cleaned = rawText.trim();
      if (cleaned.isEmpty) {
        return;
      }
      final double tmScaleY = math.sqrt(tmC * tmC + tmD * tmD);
      final double tmScaleX = math.sqrt(tmA * tmA + tmB * tmB);
      final double effectiveTmScale = tmScaleY > 0.01 ? tmScaleY : 1.0;
      final double effectiveFontSize =
          (fontSize * effectiveTmScale * state.matrix.scaleFactor)
              .clamp(5.0, 120.0);
      final double charWidthFactor = isMono ? 0.60 : (isBold ? 0.56 : 0.52);
      final double estimatedWidth =
          math.max(8.0, cleaned.length * effectiveFontSize * charWidthFactor);
      final double estimatedHeight = effectiveFontSize * 1.25;

      final Offset pos = toPagePoint(textX, textY);
      final double left = pos.dx.clamp(0.0, pageWidth);
      final double top = (pos.dy - effectiveFontSize).clamp(0.0, pageHeight);

      elements.add(
        PdfTextElement(
          text: cleaned,
          bounds: Rect.fromLTWH(left, top, estimatedWidth, estimatedHeight),
          fontSize: effectiveFontSize,
          color: state.fillColor,
          fontFamily: activeFontInfo?.name ?? fontName,
          isBold: isBold,
          isItalic: isItalic,
          isMonospace: isMono,
        ),
      );
      textX += (tmScaleX > 0.01 ? estimatedWidth / tmScaleX : estimatedWidth);
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
            final _Affine2D m = _Affine2D(
              a: _numAt(operands, operands.length - 6, 1.0),
              b: _numAt(operands, operands.length - 5, 0.0),
              c: _numAt(operands, operands.length - 4, 0.0),
              d: _numAt(operands, operands.length - 3, 1.0),
              e: _numAt(operands, operands.length - 2, 0.0),
              f: _numAt(operands, operands.length - 1, 0.0),
            );
            state.matrix = state.matrix.multiply(m);
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
        case 'sc':
        case 'scn':
          final Color? c = _colorFromDynamicOperands(operands);
          if (c != null) {
            state.fillColor = c;
          }
          operands.clear();
        case 'SC':
        case 'SCN':
          final Color? c = _colorFromDynamicOperands(operands);
          if (c != null) {
            state.strokeColor = c;
          }
          operands.clear();
        case 're':
          if (operands.length >= 4) {
            final double x = _numAt(operands, operands.length - 4, 0.0);
            final double y = _numAt(operands, operands.length - 3, 0.0);
            final double w = _numAt(operands, operands.length - 2, 0.0);
            final double h = _numAt(operands, operands.length - 1, 0.0);
            final Offset p1 = toPagePoint(x, y);
            final Offset p2 = toPagePoint(x + w, y + h);
            pendingRect = Rect.fromPoints(p1, p2);
          }
          operands.clear();
        case 'm':
          if (operands.length >= 2) {
            final double x = _numAt(operands, operands.length - 2, 0.0);
            final double y = _numAt(operands, operands.length - 1, 0.0);
            final Offset pt = toPagePoint(x, y);
            currentPathPoint = pt;
            activeCommands.add(PdfMoveToCommand(pt));
            activeSimplePoints.add(pt);
          }
          operands.clear();
        case 'l':
          if (operands.length >= 2) {
            final double x = _numAt(operands, operands.length - 2, 0.0);
            final double y = _numAt(operands, operands.length - 1, 0.0);
            final Offset pt = toPagePoint(x, y);
            currentPathPoint = pt;
            activeCommands.add(PdfLineToCommand(pt));
            activeSimplePoints.add(pt);
          }
          operands.clear();
        case 'c':
          if (operands.length >= 6) {
            final Offset cp1 = toPagePoint(
              _numAt(operands, operands.length - 6, 0.0),
              _numAt(operands, operands.length - 5, 0.0),
            );
            final Offset cp2 = toPagePoint(
              _numAt(operands, operands.length - 4, 0.0),
              _numAt(operands, operands.length - 3, 0.0),
            );
            final Offset end = toPagePoint(
              _numAt(operands, operands.length - 2, 0.0),
              _numAt(operands, operands.length - 1, 0.0),
            );
            currentPathPoint = end;
            hasCurves = true;
            activeCommands.add(PdfCubicToCommand(cp1, cp2, end));
          }
          operands.clear();
        case 'v':
          if (operands.length >= 4) {
            final Offset cp2 = toPagePoint(
              _numAt(operands, operands.length - 4, 0.0),
              _numAt(operands, operands.length - 3, 0.0),
            );
            final Offset end = toPagePoint(
              _numAt(operands, operands.length - 2, 0.0),
              _numAt(operands, operands.length - 1, 0.0),
            );
            final Offset cp1 = currentPathPoint;
            currentPathPoint = end;
            hasCurves = true;
            activeCommands.add(PdfCubicToCommand(cp1, cp2, end));
          }
          operands.clear();
        case 'y':
          if (operands.length >= 4) {
            final Offset cp1 = toPagePoint(
              _numAt(operands, operands.length - 4, 0.0),
              _numAt(operands, operands.length - 3, 0.0),
            );
            final Offset end = toPagePoint(
              _numAt(operands, operands.length - 2, 0.0),
              _numAt(operands, operands.length - 1, 0.0),
            );
            currentPathPoint = end;
            hasCurves = true;
            activeCommands.add(PdfCubicToCommand(cp1, end, end));
          }
          operands.clear();
        case 'h':
          activeCommands.add(const PdfClosePathCommand());
          operands.clear();
        case 'S':
        case 's':
          if (token == 's') {
            activeCommands.add(const PdfClosePathCommand());
          }
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
          if (token == 'b' || token == 'b*') {
            activeCommands.add(const PdfClosePathCommand());
          }
          flushPendingGeometry(fill: true, stroke: true);
          operands.clear();
        case 'n':
          pendingRect = null;
          activeCommands.clear();
          activeSimplePoints.clear();
          hasCurves = false;
          operands.clear();
        case 'Do':
          if (operands.isNotEmpty) {
            final String xName = operands.last.replaceAll('/', '');
            final int? xObjId = xObjects[xName];
            final _PdfRawObject? xObj = xObjId != null ? objects[xObjId] : null;
            if (xObj != null &&
                xObj.stream != null &&
                RegExp(r'/Subtype\s*/Form\b').hasMatch(xObj.body)) {
              final String formRes = _resolveResourcesBody(xObj.body, objects);
              final Map<String, _PdfFontInfo> mergedFonts =
                  <String, _PdfFontInfo>{
                ...fonts,
                ..._extractPageFonts(formRes, objects),
              };
              final Map<String, int> mergedXObjs = <String, int>{
                ...xObjects,
                ..._extractPageXObjects(formRes, objects),
              };
              elements.addAll(
                _interpretContentStream(
                  stream: latin1.decode(xObj.stream!, allowInvalid: true),
                  pageWidth: pageWidth,
                  pageHeight: pageHeight,
                  fonts: mergedFonts,
                  xObjects: mergedXObjs,
                  objects: objects,
                  initialState: state,
                  depth: depth + 1,
                ),
              );
            }
          }
          operands.clear();
        case 'BT':
          tmA = 1.0;
          tmB = 0.0;
          tmC = 0.0;
          tmD = 1.0;
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
            fontSize = _numAt(operands, operands.length - 1, 12.0).abs();
            activeFontInfo = fonts[fontName];
            if (activeFontInfo != null) {
              isBold = activeFontInfo.isBold;
              isItalic = activeFontInfo.isItalic;
              isMono = activeFontInfo.isMono;
            } else {
              final String lower = fontName.toLowerCase();
              isBold = lower.contains('bold') ||
                  lower == 'f2' ||
                  lower.endsWith('b');
              isItalic = lower.contains('italic') ||
                  lower.contains('oblique') ||
                  lower == 'f3';
              isMono = lower.contains('mono') ||
                  lower.contains('courier') ||
                  lower == 'f4';
            }
          }
          operands.clear();
        case 'TL':
          if (operands.isNotEmpty) {
            textLeading = _numAt(operands, operands.length - 1, 14.0);
          }
          operands.clear();
        case 'Tm':
          if (operands.length >= 6) {
            tmA = _numAt(operands, operands.length - 6, 1.0);
            tmB = _numAt(operands, operands.length - 5, 0.0);
            tmC = _numAt(operands, operands.length - 4, 0.0);
            tmD = _numAt(operands, operands.length - 3, 1.0);
            final double e = _numAt(operands, operands.length - 2, 0.0);
            final double f = _numAt(operands, operands.length - 1, 0.0);
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
            textLineX += tx * tmA + ty * tmC;
            textLineY += tx * tmB + ty * tmD;
            textX = textLineX;
            textY = textLineY;
          }
          operands.clear();
        case 'TD':
          if (operands.length >= 2) {
            final double tx = _numAt(operands, operands.length - 2, 0.0);
            final double ty = _numAt(operands, operands.length - 1, 0.0);
            textLeading = -ty;
            textLineX += tx * tmA + ty * tmC;
            textLineY += tx * tmB + ty * tmD;
            textX = textLineX;
            textY = textLineY;
          }
          operands.clear();
        case 'T*':
          textLineY -= textLeading * tmD;
          textX = textLineX;
          textY = textLineY;
          operands.clear();
        case 'Tj':
          if (operands.isNotEmpty) {
            emitText(
              _decodePdfTokenText(operands.last, activeFontInfo?.toUnicode),
            );
          }
          operands.clear();
        case 'TJ':
          if (operands.isNotEmpty) {
            final String combined = operands
                .map(
                  (String op) =>
                      _decodePdfTokenText(op, activeFontInfo?.toUnicode),
                )
                .join();
            emitText(combined);
          }
          operands.clear();
        case "'":
          textLineY -= textLeading * tmD;
          textX = textLineX;
          textY = textLineY;
          if (operands.isNotEmpty) {
            emitText(
              _decodePdfTokenText(operands.last, activeFontInfo?.toUnicode),
            );
          }
          operands.clear();
        case '"':
          textLineY -= textLeading * tmD;
          textX = textLineX;
          textY = textLineY;
          if (operands.isNotEmpty) {
            emitText(
              _decodePdfTokenText(operands.last, activeFontInfo?.toUnicode),
            );
          }
          operands.clear();
        default:
          operands.add(token);
      }
    }

    return elements;
  }

  static Color? _colorFromDynamicOperands(List<String> operands) {
    final List<String> nums = operands
        .where((String s) => double.tryParse(s) != null)
        .toList(growable: false);
    if (nums.length >= 4) {
      return _cmykFromOperands(nums);
    }
    if (nums.length == 3) {
      return _rgbFromOperands(nums);
    }
    if (nums.length == 1) {
      final double g = (double.tryParse(nums.first) ?? 0.0).clamp(0.0, 1.0);
      final int v = (g * 255).round();
      return Color.fromARGB(255, v, v, v);
    }
    return null;
  }

  static List<String> _tokenizeContentStream(String stream) {
    final List<String> tokens = <String>[];
    final int len = stream.length;
    int i = 0;

    while (i < len) {
      final int cu = stream.codeUnitAt(i);
      if (cu <= 32) {
        i++;
        continue;
      }
      if (cu == 0x25) {
        while (i < len &&
            stream.codeUnitAt(i) != 0x0A &&
            stream.codeUnitAt(i) != 0x0D) {
          i++;
        }
        continue;
      }
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
      if (cu == 0x5B) {
        final StringBuffer sb = StringBuffer('[');
        i++;
        int depth = 1;
        while (i < len && depth > 0) {
          final int c = stream.codeUnitAt(i);
          if (c == 0x28) {
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
      if (cu == 0x3C) {
        // Dictionary << ... >>
        if (i + 1 < len && stream.codeUnitAt(i + 1) == 0x3C) {
          final int end = stream.indexOf('>>', i + 2);
          if (end != -1) {
            tokens.add(stream.substring(i, end + 2));
            i = end + 2;
            continue;
          }
        }
        final int end = stream.indexOf('>', i + 1);
        if (end != -1) {
          tokens.add(stream.substring(i, end + 1));
          i = end + 1;
          continue;
        }
      }
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

  static String _decodePdfTokenText(
    String token, [
    Map<int, String>? toUnicode,
  ]) {
    if (token.startsWith('(') && token.endsWith(')')) {
      final String literal =
          _decodePdfLiteralString(token.substring(1, token.length - 1));
      if (toUnicode != null && toUnicode.isNotEmpty) {
        final StringBuffer mapped = StringBuffer();
        for (final int cu in literal.codeUnits) {
          mapped.write(toUnicode[cu] ?? String.fromCharCode(cu));
        }
        return mapped.toString();
      }
      return literal;
    }
    if (token.startsWith('<') &&
        token.endsWith('>') &&
        !token.startsWith('<<')) {
      return _decodePdfHexString(
        token.substring(1, token.length - 1),
        toUnicode: toUnicode,
      );
    }
    if (token.startsWith('[') && token.endsWith(']')) {
      final String inner = token.substring(1, token.length - 1);
      final StringBuffer sb = StringBuffer();
      final RegExp partRegex =
          RegExp(r'\((?:\\.|[^\\\)])*\)|<[0-9A-Fa-f\s]+>|(-?\d+(?:\.\d+)?)');
      for (final RegExpMatch m in partRegex.allMatches(inner)) {
        final String piece = m.group(0)!;
        if (piece.startsWith('(')) {
          sb.write(_decodePdfTokenText(piece, toUnicode));
        } else if (piece.startsWith('<')) {
          sb.write(
            _decodePdfHexString(
              piece.substring(1, piece.length - 1),
              toUnicode: toUnicode,
            ),
          );
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
          case 0x0A: // line continuation \LF
            i += 2;
          case 0x0D: // line continuation \CR or \CRLF
            i += (i + 2 < raw.length && raw.codeUnitAt(i + 2) == 0x0A) ? 3 : 2;
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

  static String _decodePdfHexString(
    String hex, {
    Map<int, String>? toUnicode,
  }) {
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

    // Apply ToUnicode CMap if available (try 2-byte CID keys first, then 1-byte).
    if (toUnicode != null && toUnicode.isNotEmpty) {
      final bool hasTwoByteKeys =
          toUnicode.keys.any((int k) => k > 0xFF) || bytes.length.isEven;
      if (hasTwoByteKeys && bytes.length >= 2 && bytes.length.isEven) {
        int matchedPairs = 0;
        final StringBuffer sb = StringBuffer();
        for (int i = 0; i + 1 < bytes.length; i += 2) {
          final int code = (bytes[i] << 8) | bytes[i + 1];
          final String? mapped = toUnicode[code];
          if (mapped != null) {
            matchedPairs++;
            sb.write(mapped);
          } else if (code >= 32 && code < 127) {
            sb.writeCharCode(code);
          }
        }
        if (matchedPairs > 0) {
          return sb.toString();
        }
      }
      final StringBuffer singleSb = StringBuffer();
      int matchedSingle = 0;
      for (final int b in bytes) {
        final String? mapped = toUnicode[b];
        if (mapped != null) {
          matchedSingle++;
          singleSb.write(mapped);
        } else {
          singleSb.writeCharCode(b);
        }
      }
      if (matchedSingle > 0) {
        return singleSb.toString();
      }
    }

    return String.fromCharCodes(bytes);
  }

  static List<PdfBookmark> _extractBookmarks(
    Map<int, _PdfRawObject> objects,
    List<PdfPageData> pages,
    Map<int, int> pageObjIdToNumber,
  ) {
    final int maxPage = math.max(1, pages.length);

    // 1. Parse canonical PDF /Outlines linked tree from /Catalog -> /Outlines -> /First.
    int? outlinesRootId;
    for (final _PdfRawObject obj in objects.values) {
      if (RegExp(r'/Type\s*/Catalog\b').hasMatch(obj.body)) {
        final RegExpMatch? m =
            RegExp(r'/Outlines\s+(\d+)\s+\d+\s+R').firstMatch(obj.body);
        if (m != null) {
          outlinesRootId = int.tryParse(m.group(1)!);
          break;
        }
      }
    }
    if (outlinesRootId != null && objects[outlinesRootId] != null) {
      final RegExpMatch? firstMatch = RegExp(r'/First\s+(\d+)\s+\d+\s+R')
          .firstMatch(objects[outlinesRootId]!.body);
      if (firstMatch != null) {
        final int? firstId = int.tryParse(firstMatch.group(1)!);
        if (firstId != null) {
          final List<PdfBookmark> tree = _walkOutlineSiblings(
            startObjId: firstId,
            objects: objects,
            pageObjIdToNumber: pageObjIdToNumber,
            maxPage: maxPage,
            visited: <int>{},
          );
          if (tree.isNotEmpty) {
            return tree;
          }
        }
      }
    }

    // 2. Fallback: explicit outline objects containing /Title and /PageNumber or /Dest.
    final List<PdfBookmark> bookmarks = <PdfBookmark>[];
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
        if (title != null && title.isNotEmpty) {
          final int pageNumber = _resolveOutlinePageNumber(
            obj.body,
            objects,
            pageObjIdToNumber,
            maxPage,
          );
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

    // 3. Fallback: automatically infer outline from top-level headings (fontSize >= 15).
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

  static List<PdfBookmark> _walkOutlineSiblings({
    required int startObjId,
    required Map<int, _PdfRawObject> objects,
    required Map<int, int> pageObjIdToNumber,
    required int maxPage,
    required Set<int> visited,
  }) {
    final List<PdfBookmark> result = <PdfBookmark>[];
    int? currentId = startObjId;

    while (currentId != null && visited.add(currentId)) {
      final _PdfRawObject? obj = objects[currentId];
      if (obj == null) {
        break;
      }
      final String? title = _findStringKey(obj.body, 'Title');
      List<PdfBookmark> children = const <PdfBookmark>[];
      final RegExpMatch? firstChild =
          RegExp(r'/First\s+(\d+)\s+\d+\s+R').firstMatch(obj.body);
      if (firstChild != null) {
        final int? childId = int.tryParse(firstChild.group(1)!);
        if (childId != null) {
          children = _walkOutlineSiblings(
            startObjId: childId,
            objects: objects,
            pageObjIdToNumber: pageObjIdToNumber,
            maxPage: maxPage,
            visited: visited,
          );
        }
      }

      if (title != null && title.isNotEmpty) {
        final int pageNumber = _resolveOutlinePageNumber(
          obj.body,
          objects,
          pageObjIdToNumber,
          maxPage,
        );
        result.add(
          PdfBookmark(
            id: 'outline_$currentId',
            title: title,
            pageNumber: pageNumber,
            children: children,
          ),
        );
      }

      final RegExpMatch? nextMatch =
          RegExp(r'/Next\s+(\d+)\s+\d+\s+R').firstMatch(obj.body);
      currentId = nextMatch != null ? int.tryParse(nextMatch.group(1)!) : null;
    }

    return result;
  }

  static int _resolveOutlinePageNumber(
    String body,
    Map<int, _PdfRawObject> objects,
    Map<int, int> pageObjIdToNumber,
    int maxPage,
  ) {
    final RegExpMatch? pageNumMatch =
        RegExp(r'/PageNumber\s+(\d+)').firstMatch(body);
    if (pageNumMatch != null) {
      return (int.tryParse(pageNumMatch.group(1)!) ?? 1).clamp(1, maxPage);
    }
    final RegExpMatch? destRef =
        RegExp(r'/(?:Dest|D)\s*\[\s*(\d+)\s+\d+\s+R').firstMatch(body);
    if (destRef != null) {
      final int? targetObjId = int.tryParse(destRef.group(1)!);
      if (targetObjId != null && pageObjIdToNumber.containsKey(targetObjId)) {
        return pageObjIdToNumber[targetObjId]!.clamp(1, maxPage);
      }
    }
    // Check indirect /A N 0 R GoTo action dictionary
    final RegExpMatch? actionRef =
        RegExp(r'/A\s+(\d+)\s+\d+\s+R').firstMatch(body);
    if (actionRef != null) {
      final int? actionId = int.tryParse(actionRef.group(1)!);
      final String? actionBody =
          actionId != null ? objects[actionId]?.body : null;
      if (actionBody != null) {
        final RegExpMatch? actionDest =
            RegExp(r'/D\s*\[\s*(\d+)\s+\d+\s+R').firstMatch(actionBody);
        if (actionDest != null) {
          final int? targetObjId = int.tryParse(actionDest.group(1)!);
          if (targetObjId != null &&
              pageObjIdToNumber.containsKey(targetObjId)) {
            return pageObjIdToNumber[targetObjId]!.clamp(1, maxPage);
          }
        }
      }
    }
    return 1;
  }
}

class _ExtractedPagesResult {
  const _ExtractedPagesResult({
    required this.pages,
    required this.pageObjIdToNumber,
  });

  final List<PdfPageData> pages;
  final Map<int, int> pageObjIdToNumber;
}

class _ResolvedPageNode {
  const _ResolvedPageNode({
    required this.obj,
    required this.width,
    required this.height,
    required this.rotation,
    required this.resourcesBody,
  });

  final _PdfRawObject obj;
  final double width;
  final double height;
  final int rotation;
  final String resourcesBody;
}

class _PdfFontInfo {
  const _PdfFontInfo({
    required this.name,
    required this.isBold,
    required this.isItalic,
    required this.isMono,
    this.toUnicode,
  });

  final String name;
  final bool isBold;
  final bool isItalic;
  final bool isMono;
  final Map<int, String>? toUnicode;
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

class _Affine2D {
  const _Affine2D({
    this.a = 1.0,
    this.b = 0.0,
    this.c = 0.0,
    this.d = 1.0,
    this.e = 0.0,
    this.f = 0.0,
  });

  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;

  double get scaleFactor {
    final double sx = math.sqrt(a * a + b * b);
    final double sy = math.sqrt(c * c + d * d);
    final double avg = (sx + sy) * 0.5;
    return avg > 0.001 ? avg : 1.0;
  }

  Offset transformPoint(double x, double y) {
    return Offset(a * x + c * y + e, b * x + d * y + f);
  }

  _Affine2D multiply(_Affine2D m) {
    return _Affine2D(
      a: a * m.a + c * m.b,
      b: b * m.a + d * m.b,
      c: a * m.c + c * m.d,
      d: b * m.c + d * m.d,
      e: a * m.e + c * m.f + e,
      f: b * m.e + d * m.f + f,
    );
  }
}

class _GraphicsState {
  _GraphicsState({
    this.fillColor = const Color(0xFF111827),
    this.strokeColor = const Color(0xFF334155),
    this.lineWidth = 1.0,
    this.matrix = const _Affine2D(),
  });

  Color fillColor;
  Color strokeColor;
  double lineWidth;
  _Affine2D matrix;

  _GraphicsState clone() {
    return _GraphicsState(
      fillColor: fillColor,
      strokeColor: strokeColor,
      lineWidth: lineWidth,
      matrix: matrix,
    );
  }
}
