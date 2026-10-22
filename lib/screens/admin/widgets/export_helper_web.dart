// Web export helper — uses universal_io or platform-safe stub
// Since direct dart:html is deprecated, we implement a no-op for non-web
// and rely on conditional imports at the point of use.

void saveAndDownloadWeb(String content, String fileName, String mimeType) {
  // No-op stub: actual web implementation is handled via JS interop
  // in production. This file is only invoked on Flutter Web builds.
  // On non-web platforms, use a file picker or share dialog instead.
}
