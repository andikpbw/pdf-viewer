import 'dart:typed_data';

/// Pure-Dart RFC 1950 (zlib) and RFC 1951 (DEFLATE) decompressor for decoding
/// `/FlateDecode` PDF content streams across all platforms (including Web).
class ZlibDecoder {
  const ZlibDecoder._();

  /// Decompresses a zlib-wrapped or raw DEFLATE [input] byte buffer.
  ///
  /// If decompression fails due to malformed input, returns `null`.
  static Uint8List? tryDecode(Uint8List input) {
    if (input.isEmpty) {
      return Uint8List(0);
    }
    try {
      int offset = 0;
      // Check for standard 2-byte RFC 1950 zlib header.
      if (input.length >= 6) {
        final int cmf = input[0];
        final int flg = input[1];
        final int cm = cmf & 0x0F;
        final int cinfo = (cmf >> 4) & 0x0F;
        if (cm == 8 && cinfo <= 7 && ((cmf * 256 + flg) % 31 == 0)) {
          offset = 2;
          // Check FDICT bit.
          if ((flg & 0x20) != 0) {
            offset += 4;
          }
        }
      }
      return _inflate(input, offset);
    } catch (_) {
      // Fallback: attempt raw deflate from byte 0 if header heuristic skipped.
      try {
        return _inflate(input, 0);
      } catch (_) {
        return null;
      }
    }
  }

  /// Wraps raw [data] into a valid RFC 1950 zlib stream using uncompressed
  /// (BTYPE=00) DEFLATE blocks and an Adler-32 checksum.
  static Uint8List encodeZlibStored(Uint8List data) {
    final BytesBuilder out = BytesBuilder(copy: false);
    // Zlib header: CMF = 0x78 (deflate, 32K window), FLG = 0x01 (check bits)
    out.addByte(0x78);
    out.addByte(0x01);

    int offset = 0;
    final int total = data.length;
    while (offset < total || total == 0) {
      final int remaining = total - offset;
      final int chunkLen = remaining > 65535 ? 65535 : remaining;
      final bool isFinal = (offset + chunkLen) >= total;
      // BFINAL (bit 0) + BTYPE=00 (bits 1..2)
      out.addByte(isFinal ? 0x01 : 0x00);
      final int nlen = (~chunkLen) & 0xFFFF;
      out.addByte(chunkLen & 0xFF);
      out.addByte((chunkLen >> 8) & 0xFF);
      out.addByte(nlen & 0xFF);
      out.addByte((nlen >> 8) & 0xFF);
      if (chunkLen > 0) {
        out.add(Uint8List.sublistView(data, offset, offset + chunkLen));
      }
      offset += chunkLen;
      if (total == 0) {
        break;
      }
    }

    // Compute Adler-32 checksum.
    int s1 = 1;
    int s2 = 0;
    for (int i = 0; i < data.length; i++) {
      s1 = (s1 + data[i]) % 65521;
      s2 = (s2 + s1) % 65521;
    }
    final int adler = (s2 << 16) | s1;
    out.addByte((adler >> 24) & 0xFF);
    out.addByte((adler >> 16) & 0xFF);
    out.addByte((adler >> 8) & 0xFF);
    out.addByte(adler & 0xFF);
    return out.takeBytes();
  }

  static Uint8List _inflate(Uint8List data, int startByte) {
    final _BitReader reader = _BitReader(data, startByte);
    final List<int> out = <int>[];

    int bfinal = 0;
    while (bfinal == 0) {
      bfinal = reader.readBits(1);
      final int btype = reader.readBits(2);

      if (btype == 0) {
        // Uncompressed block.
        reader.alignToByte();
        final int len = reader.readUint16();
        final int nlen = reader.readUint16();
        if ((len ^ 0xFFFF) != nlen) {
          throw const FormatException('Invalid uncompressed block length');
        }
        for (int i = 0; i < len; i++) {
          out.add(reader.readByte());
        }
      } else if (btype == 1 || btype == 2) {
        _HuffmanTable litLenTable;
        _HuffmanTable distTable;
        if (btype == 1) {
          litLenTable = _HuffmanTable.fixedLitLen;
          distTable = _HuffmanTable.fixedDist;
        } else {
          final (_HuffmanTable ll, _HuffmanTable dist) =
              _readDynamicTrees(reader);
          litLenTable = ll;
          distTable = dist;
        }
        _decodeBlock(reader, litLenTable, distTable, out);
      } else {
        throw const FormatException('Invalid DEFLATE block type (3)');
      }
    }

    return Uint8List.fromList(out);
  }

  static (_HuffmanTable, _HuffmanTable) _readDynamicTrees(_BitReader reader) {
    final int hlit = reader.readBits(5) + 257;
    final int hdist = reader.readBits(5) + 1;
    final int hclen = reader.readBits(4) + 4;

    const List<int> clOrder = <int>[
      16,
      17,
      18,
      0,
      8,
      7,
      9,
      6,
      10,
      5,
      11,
      4,
      12,
      3,
      13,
      2,
      14,
      1,
      15,
    ];
    final List<int> codeLengthLengths = List<int>.filled(19, 0);
    for (int i = 0; i < hclen; i++) {
      codeLengthLengths[clOrder[i]] = reader.readBits(3);
    }
    final _HuffmanTable codeLenTable = _HuffmanTable(codeLengthLengths);

    final List<int> allLengths = List<int>.filled(hlit + hdist, 0);
    int idx = 0;
    while (idx < hlit + hdist) {
      final int sym = codeLenTable.decodeSymbol(reader);
      if (sym < 16) {
        allLengths[idx++] = sym;
      } else if (sym == 16) {
        final int prev = idx > 0 ? allLengths[idx - 1] : 0;
        final int repeat = reader.readBits(2) + 3;
        for (int r = 0; r < repeat && idx < allLengths.length; r++) {
          allLengths[idx++] = prev;
        }
      } else if (sym == 17) {
        final int repeat = reader.readBits(3) + 3;
        for (int r = 0; r < repeat && idx < allLengths.length; r++) {
          allLengths[idx++] = 0;
        }
      } else if (sym == 18) {
        final int repeat = reader.readBits(7) + 11;
        for (int r = 0; r < repeat && idx < allLengths.length; r++) {
          allLengths[idx++] = 0;
        }
      } else {
        throw const FormatException('Invalid code length symbol');
      }
    }

    final List<int> litLenLengths = allLengths.sublist(0, hlit);
    final List<int> distLengths = allLengths.sublist(hlit);
    return (_HuffmanTable(litLenLengths), _HuffmanTable(distLengths));
  }

  static void _decodeBlock(
    _BitReader reader,
    _HuffmanTable litLenTable,
    _HuffmanTable distTable,
    List<int> out,
  ) {
    const List<int> lengthBase = <int>[
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      13,
      15,
      17,
      19,
      23,
      27,
      31,
      35,
      43,
      51,
      59,
      67,
      83,
      99,
      115,
      131,
      163,
      195,
      227,
      258,
    ];
    const List<int> lengthExtra = <int>[
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      1,
      1,
      1,
      2,
      2,
      2,
      2,
      3,
      3,
      3,
      3,
      4,
      4,
      4,
      4,
      5,
      5,
      5,
      5,
      0,
    ];
    const List<int> distBase = <int>[
      1,
      2,
      3,
      4,
      5,
      7,
      9,
      13,
      17,
      25,
      33,
      49,
      65,
      97,
      129,
      193,
      257,
      385,
      513,
      769,
      1025,
      1537,
      2049,
      3073,
      4097,
      6145,
      8193,
      12289,
      16385,
      24577,
    ];
    const List<int> distExtra = <int>[
      0,
      0,
      0,
      0,
      1,
      1,
      2,
      2,
      3,
      3,
      4,
      4,
      5,
      5,
      6,
      6,
      7,
      7,
      8,
      8,
      9,
      9,
      10,
      10,
      11,
      11,
      12,
      12,
      13,
      13,
    ];

    while (true) {
      final int sym = litLenTable.decodeSymbol(reader);
      if (sym < 256) {
        out.add(sym);
      } else if (sym == 256) {
        break;
      } else {
        final int lenIdx = sym - 257;
        if (lenIdx < 0 || lenIdx >= lengthBase.length) {
          throw const FormatException('Invalid length code');
        }
        final int length =
            lengthBase[lenIdx] + reader.readBits(lengthExtra[lenIdx]);
        final int distSym = distTable.decodeSymbol(reader);
        if (distSym < 0 || distSym >= distBase.length) {
          throw const FormatException('Invalid distance code');
        }
        final int distance =
            distBase[distSym] + reader.readBits(distExtra[distSym]);
        final int start = out.length - distance;
        if (start < 0) {
          throw const FormatException('Distance back-reference out of bounds');
        }
        for (int i = 0; i < length; i++) {
          out.add(out[start + i]);
        }
      }
    }
  }
}

class _BitReader {
  _BitReader(this.bytes, this.bytePos);

  final Uint8List bytes;
  int bytePos;
  int bitBuf = 0;
  int bitCount = 0;

  int readBits(int count) {
    if (count == 0) {
      return 0;
    }
    while (bitCount < count) {
      if (bytePos >= bytes.length) {
        throw const FormatException('Unexpected end of DEFLATE stream');
      }
      bitBuf |= bytes[bytePos++] << bitCount;
      bitCount += 8;
    }
    final int val = bitBuf & ((1 << count) - 1);
    bitBuf >>= count;
    bitCount -= count;
    return val;
  }

  void alignToByte() {
    bitBuf = 0;
    bitCount = 0;
  }

  int readByte() {
    alignToByte();
    if (bytePos >= bytes.length) {
      throw const FormatException('Unexpected end of byte stream');
    }
    return bytes[bytePos++];
  }

  int readUint16() {
    final int lo = readByte();
    final int hi = readByte();
    return lo | (hi << 8);
  }
}

class _HuffmanTable {
  _HuffmanTable(List<int> codeLengths) {
    int maxBits = 0;
    for (final int len in codeLengths) {
      if (len > maxBits) {
        maxBits = len;
      }
    }
    _maxBits = maxBits == 0 ? 1 : maxBits;
    final List<int> blCount = List<int>.filled(_maxBits + 1, 0);
    for (final int len in codeLengths) {
      if (len > 0) {
        blCount[len]++;
      }
    }
    final List<int> nextCode = List<int>.filled(_maxBits + 1, 0);
    int code = 0;
    for (int bits = 1; bits <= _maxBits; bits++) {
      code = (code + blCount[bits - 1]) << 1;
      nextCode[bits] = code;
    }
    for (int sym = 0; sym < codeLengths.length; sym++) {
      final int len = codeLengths[sym];
      if (len > 0) {
        final int c = nextCode[len]++;
        _lookup[(len << 16) | c] = sym;
      }
    }
  }

  static final _HuffmanTable fixedLitLen = _HuffmanTable(_buildFixedLitLen());
  static final _HuffmanTable fixedDist = _HuffmanTable(List<int>.filled(32, 5));

  static List<int> _buildFixedLitLen() {
    final List<int> lengths = List<int>.filled(288, 0);
    for (int i = 0; i <= 143; i++) {
      lengths[i] = 8;
    }
    for (int i = 144; i <= 255; i++) {
      lengths[i] = 9;
    }
    for (int i = 256; i <= 279; i++) {
      lengths[i] = 7;
    }
    for (int i = 280; i <= 287; i++) {
      lengths[i] = 8;
    }
    return lengths;
  }

  final Map<int, int> _lookup = <int, int>{};
  int _maxBits = 15;

  int decodeSymbol(_BitReader reader) {
    int code = 0;
    for (int len = 1; len <= _maxBits; len++) {
      code = (code << 1) | reader.readBits(1);
      final int? sym = _lookup[(len << 16) | code];
      if (sym != null) {
        return sym;
      }
    }
    throw const FormatException('Invalid Huffman code');
  }
}
