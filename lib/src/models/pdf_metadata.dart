import 'package:flutter/foundation.dart';

/// Metadata extracted from a PDF document's `/Info` dictionary and header.
@immutable
class PdfMetadata {
  /// Creates a [PdfMetadata] instance.
  const PdfMetadata({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
    this.producer,
    this.creationDate,
    this.modificationDate,
    this.version = '1.7',
    this.isEncrypted = false,
    this.fileSizeInBytes = 0,
  });

  /// Creates a [PdfMetadata] instance from a key-value map.
  factory PdfMetadata.fromMap(Map<String, dynamic> map) {
    return PdfMetadata(
      title: map['title'] as String?,
      author: map['author'] as String?,
      subject: map['subject'] as String?,
      keywords: map['keywords'] as String?,
      creator: map['creator'] as String?,
      producer: map['producer'] as String?,
      creationDate: map['creationDate'] != null
          ? DateTime.tryParse(map['creationDate'].toString())
          : null,
      modificationDate: map['modificationDate'] != null
          ? DateTime.tryParse(map['modificationDate'].toString())
          : null,
      version: (map['version'] as String?) ?? '1.7',
      isEncrypted: (map['isEncrypted'] as bool?) ?? false,
      fileSizeInBytes: (map['fileSizeInBytes'] as int?) ?? 0,
    );
  }

  /// The document's title.
  final String? title;

  /// The name of the person or organization that created the document.
  final String? author;

  /// The subject of the document.
  final String? subject;

  /// Keywords associated with the document.
  final String? keywords;

  /// The application that originally created the document.
  final String? creator;

  /// The application or library that converted/produced the PDF.
  final String? producer;

  /// The date and time the document was created.
  final DateTime? creationDate;

  /// The date and time the document was last modified.
  final DateTime? modificationDate;

  /// The PDF specification version (for example, `'1.4'` or `'1.7'`).
  final String version;

  /// Whether the PDF document has an `/Encrypt` dictionary entry.
  final bool isEncrypted;

  /// The size of the source PDF payload in bytes.
  final int fileSizeInBytes;

  /// Returns a human-readable file size string (for example, `'24.5 KB'`).
  String get formattedFileSize {
    if (fileSizeInBytes <= 0) {
      return '0 B';
    }
    if (fileSizeInBytes < 1024) {
      return '$fileSizeInBytes B';
    }
    final double kb = fileSizeInBytes / 1024.0;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final double mb = kb / 1024.0;
    return '${mb.toStringAsFixed(2)} MB';
  }

  /// Creates a copy of this [PdfMetadata] with the given fields replaced.
  PdfMetadata copyWith({
    String? title,
    String? author,
    String? subject,
    String? keywords,
    String? creator,
    String? producer,
    DateTime? creationDate,
    DateTime? modificationDate,
    String? version,
    bool? isEncrypted,
    int? fileSizeInBytes,
  }) {
    return PdfMetadata(
      title: title ?? this.title,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      keywords: keywords ?? this.keywords,
      creator: creator ?? this.creator,
      producer: producer ?? this.producer,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      version: version ?? this.version,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      fileSizeInBytes: fileSizeInBytes ?? this.fileSizeInBytes,
    );
  }

  /// Converts this [PdfMetadata] instance into a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'author': author,
      'subject': subject,
      'keywords': keywords,
      'creator': creator,
      'producer': producer,
      'creationDate': creationDate?.toIso8601String(),
      'modificationDate': modificationDate?.toIso8601String(),
      'version': version,
      'isEncrypted': isEncrypted,
      'fileSizeInBytes': fileSizeInBytes,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PdfMetadata &&
        other.title == title &&
        other.author == author &&
        other.subject == subject &&
        other.keywords == keywords &&
        other.creator == creator &&
        other.producer == producer &&
        other.creationDate == creationDate &&
        other.modificationDate == modificationDate &&
        other.version == version &&
        other.isEncrypted == isEncrypted &&
        other.fileSizeInBytes == fileSizeInBytes;
  }

  @override
  int get hashCode => Object.hash(
        title,
        author,
        subject,
        keywords,
        creator,
        producer,
        creationDate,
        modificationDate,
        version,
        isEncrypted,
        fileSizeInBytes,
      );

  @override
  String toString() =>
      'PdfMetadata(title: $title, author: $author, version: $version, '
      'size: $formattedFileSize)';
}
