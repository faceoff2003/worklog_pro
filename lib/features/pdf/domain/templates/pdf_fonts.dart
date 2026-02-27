import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shared fonts for all PDF templates.
/// Using Roboto which supports full Latin characters including accents and €.
class PdfFonts {
  static late pw.Font regular;
  static late pw.Font bold;
  static late pw.Font italic;
  static bool _loaded = false;

  /// Call once before building any PDF document.
  static Future<void> load() async {
    if (_loaded) return;
    regular = await PdfGoogleFonts.robotoRegular();
    bold = await PdfGoogleFonts.robotoBold();
    italic = await PdfGoogleFonts.robotoItalic();
    _loaded = true;
  }

  static pw.TextStyle style({
    double fontSize = 11,
    bool isBold = false,
    bool isItalic = false,
  }) {
    return pw.TextStyle(
      font: isBold ? bold : (isItalic ? italic : regular),
      fontSize: fontSize,
    );
  }
}
