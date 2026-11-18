export 'pdf_loader_stub.dart'
    if (dart.library.io) 'pdf_loader_io.dart'
    if (dart.library.js_interop) 'pdf_loader_web.dart';
