import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gado_gado_app/data/models/order_model.dart';

/// Generates a branded sales report PDF for the Owner role.
class PdfReportGenerator {
  // Brand colours (matching AppColors.primary = #2E7D32 green)
  static const PdfColor _primaryGreen = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _bgLight = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF212121);
  static const PdfColor _textGrey = PdfColor.fromInt(0xFF757575);
  static const PdfColor _white = PdfColors.white;
  static const PdfColor _whiteSubtle = PdfColor(1, 1, 1, 0.75);   // white @ 75% opacity
  static const PdfColor _whiteFaint  = PdfColor(1, 1, 1, 0.60);   // white @ 60% opacity
  static const PdfColor _divider = PdfColor.fromInt(0xFFE0E0E0);

  /// Maps an [OrderStatus] to an Indonesian label string.
  static String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:    return 'Menunggu';
      case OrderStatus.preparing:  return 'Diproses';
      case OrderStatus.ready:      return 'Siap';
      case OrderStatus.completed:  return 'Selesai';
      case OrderStatus.finished:   return 'Selesai ✓';
      case OrderStatus.cancelled:  return 'Dibatalkan';
    }
  }

  /// Maps a [ServiceType] to an Indonesian short label.
  static String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.dineIn:   return 'Makan di Tempat';
      case ServiceType.takeAway: return 'Bawa Pulang';
      case ServiceType.rsvp:     return 'Reservasi';
      case ServiceType.delivery: return 'Pengiriman';
    }
  }

  static String _periodLabel(String period) {
    switch (period) {
      case 'day':   return 'Harian';
      case 'week':  return 'Mingguan';
      default:      return 'Bulanan';
    }
  }

  /// Builds and returns the [pw.Document] with the full sales report.
  static Future<pw.Document> generateSalesReport({
    required List<OrderModel> filteredOrders,
    required List<Map<String, dynamic>> topItems,
    required String period,           // 'day' | 'week' | 'month'
    required DateTime? startDate,
    required DateTime? endDate,
    required double totalRevenue,
    required int totalOrders,
    required double avgCheck,
    required double avgRating,
  }) async {
    final doc = pw.Document();
    final idr = NumberFormat('#,###', 'id_ID');
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final now = DateTime.now();

    final String periodStr = _periodLabel(period);
    final String dateRangeStr = (startDate != null && endDate != null)
        ? '${dateFormat.format(startDate)} – ${dateFormat.format(endDate)}'
        : dateFormat.format(now);
    final String printedAt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now);

    // ── Separate finished vs cancelled for cleaner summary ──
    final finishedOrders = filteredOrders
        .where((o) => o.status == OrderStatus.finished || o.status == OrderStatus.completed)
        .toList();
    final cancelledOrders = filteredOrders
        .where((o) => o.status == OrderStatus.cancelled)
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        header: (ctx) => _buildHeader(periodStr, dateRangeStr, printedAt),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 24),

          // ── Summary Cards ──
          _buildSummarySection(
            totalRevenue: totalRevenue,
            totalOrders: totalOrders,
            avgCheck: avgCheck,
            avgRating: avgRating,
            finishedCount: finishedOrders.length,
            cancelledCount: cancelledOrders.length,
            idr: idr,
          ),

          pw.SizedBox(height: 20),

          // ── Top Products ──
          if (topItems.isNotEmpty) ...[
            _sectionTitle('🏆  Produk Terlaris'),
            pw.SizedBox(height: 8),
            _buildTopProductsTable(topItems),
            pw.SizedBox(height: 20),
          ],

          // ── Transaction Table ──
          _sectionTitle('📋  Daftar Transaksi'),
          pw.SizedBox(height: 8),
          if (filteredOrders.isEmpty)
            _emptyState('Tidak ada transaksi pada periode ini.')
          else
            _buildTransactionTable(filteredOrders, idr, dateFormat),
        ],
      ),
    );

    return doc;
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
  static pw.Widget _buildHeader(String period, String dateRange, String printedAt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: pw.BoxDecoration(
            color: _primaryGreen,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'WARUNG GADO-GADO',
                    style: pw.TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Warung Mpo Lemez',
                    style: pw.TextStyle(color: _whiteSubtle, fontSize: 9),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'LAPORAN PENJUALAN $period'.toUpperCase(),
                    style: pw.TextStyle(
                      color: _white,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    dateRange,
                    style: pw.TextStyle(color: _whiteSubtle, fontSize: 9),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Dicetak: $printedAt',
                    style: pw.TextStyle(color: _whiteFaint, fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _divider, thickness: 0.5),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(color: _divider, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'GadoGado POS System — Dokumen ini dicetak secara otomatis.',
              style: const pw.TextStyle(color: _textGrey, fontSize: 7),
            ),
            pw.Text(
              'Halaman ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(color: _textGrey, fontSize: 7),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SUMMARY SECTION
  // ─────────────────────────────────────────────
  static pw.Widget _buildSummarySection({
    required double totalRevenue,
    required int totalOrders,
    required double avgCheck,
    required double avgRating,
    required int finishedCount,
    required int cancelledCount,
    required NumberFormat idr,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _divider, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RINGKASAN KINERJA',
            style: pw.TextStyle(
              color: _textGrey,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 12),
          // Big revenue number
          pw.Text(
            'Rp ${idr.format(totalRevenue)}',
            style: pw.TextStyle(
              color: _primaryGreen,
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Total Pendapatan Periode Ini',
            style: const pw.TextStyle(color: _textGrey, fontSize: 9),
          ),
          pw.SizedBox(height: 14),
          // Stats row
          pw.Row(
            children: [
              _statBox('Total Pesanan', '$totalOrders pesanan'),
              pw.SizedBox(width: 8),
              _statBox('Rata-rata Transaksi', 'Rp ${idr.format(avgCheck)}'),
              pw.SizedBox(width: 8),
              _statBox('Pesanan Selesai', '$finishedCount pesanan'),
              pw.SizedBox(width: 8),
              _statBox('Dibatalkan', '$cancelledCount pesanan',
                  valueColor: cancelledCount > 0 ? const PdfColor.fromInt(0xFFBF360C) : _primaryGreen),
            ],
          ),
          if (avgRating > 0) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _statBox('Rating Rata-rata', '⭐ ${avgRating.toStringAsFixed(1)} / 5.0'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _statBox(String label, String value, {PdfColor? valueColor}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _divider, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(color: _textGrey, fontSize: 7)),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: valueColor ?? _textDark,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP PRODUCTS TABLE
  // ─────────────────────────────────────────────
  static pw.Widget _buildTopProductsTable(List<Map<String, dynamic>> topItems) {
    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(50),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primaryGreen),
          children: [
            _tableHeader('#'),
            _tableHeader('Nama Menu'),
            _tableHeader('Jumlah Terjual'),
            _tableHeader('Status'),
          ],
        ),
        // Rows
        ...topItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final qty = item['subtitle']?.toString().split(' ').first ?? '-';
          final tag = item['tag']?.toString() ?? '';
          final isEven = i.isEven;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? _white : _bgLight),
            children: [
              _tableCell('${i + 1}', align: pw.TextAlign.center),
              _tableCell(item['title']?.toString() ?? '-'),
              _tableCell(qty, align: pw.TextAlign.center),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: tag == 'POPULER'
                        ? const PdfColor.fromInt(0xFFFFF3E0)
                        : const PdfColor.fromInt(0xFFE3F2FD),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    tag,
                    style: pw.TextStyle(
                      color: tag == 'POPULER'
                          ? const PdfColor.fromInt(0xFFE65100)
                          : const PdfColor.fromInt(0xFF1565C0),
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // TRANSACTION TABLE
  // ─────────────────────────────────────────────
  static pw.Widget _buildTransactionTable(
    List<OrderModel> orders,
    NumberFormat idr,
    DateFormat dateFmt,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),   // ID Order (short)
        1: const pw.FlexColumnWidth(1.8),   // Tanggal
        2: const pw.FlexColumnWidth(1.5),   // Tipe Layanan
        3: const pw.FlexColumnWidth(1.4),   // Pembayaran
        4: const pw.FlexColumnWidth(1.6),   // Total
        5: const pw.FlexColumnWidth(1.2),   // Status
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primaryGreen),
          children: [
            _tableHeader('ID Order'),
            _tableHeader('Tanggal'),
            _tableHeader('Tipe Layanan'),
            _tableHeader('Pembayaran'),
            _tableHeader('Total'),
            _tableHeader('Status'),
          ],
        ),
        // Data rows
        ...orders.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          final isEven = i.isEven;
          final isCancelled = o.status == OrderStatus.cancelled;

          // Short ID: take last 12 chars
          final shortId = o.id.length > 16 ? '...${o.id.substring(o.id.length - 14)}' : o.id;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isCancelled
                  ? const PdfColor.fromInt(0xFFFFF8F8)
                  : (isEven ? _white : _bgLight),
            ),
            children: [
              _tableCell(shortId, fontSize: 7),
              _tableCell(dateFmt.format(o.timestamp), fontSize: 8),
              _tableCell(_serviceLabel(o.serviceType), fontSize: 8),
              _tableCell(_paymentLabel(o.paymentMethod), fontSize: 8),
              _tableCell(
                'Rp ${idr.format(o.totalAmount)}',
                fontSize: 8,
                bold: true,
                color: _primaryGreen,
              ),
              _tableCellStatus(o.status),
            ],
          );
        }),

        // Total row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFE8F5E9)),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'TOTAL (${orders.length} transaksi)',
                style: pw.TextStyle(
                  color: _primaryGreen,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            _tableCell(''),
            _tableCell(''),
            _tableCell(''),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Rp ${NumberFormat('#,###', 'id_ID').format(orders.fold(0.0, (s, o) => s + o.totalAmount))}',
                style: pw.TextStyle(
                  color: _primaryGreen,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            _tableCell(''),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _textDark,
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _emptyState(String msg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      alignment: pw.Alignment.center,
      child: pw.Text(msg, style: const pw.TextStyle(color: _textGrey, fontSize: 10)),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8,
    bool bold = false,
    PdfColor color = _textDark,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _tableCellStatus(OrderStatus status) {
    PdfColor bgColor;
    PdfColor textColor;

    switch (status) {
      case OrderStatus.finished:
      case OrderStatus.completed:
        bgColor = const PdfColor.fromInt(0xFFE8F5E9);
        textColor = const PdfColor.fromInt(0xFF1B5E20);
        break;
      case OrderStatus.cancelled:
        bgColor = const PdfColor.fromInt(0xFFFFEBEE);
        textColor = const PdfColor.fromInt(0xFFC62828);
        break;
      case OrderStatus.ready:
        bgColor = const PdfColor.fromInt(0xFFE3F2FD);
        textColor = const PdfColor.fromInt(0xFF1565C0);
        break;
      default:
        bgColor = const PdfColor.fromInt(0xFFFFF9C4);
        textColor = const PdfColor.fromInt(0xFFE65100);
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          _statusLabel(status),
          style: pw.TextStyle(color: textColor, fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:         return 'Tunai';
      case PaymentMethod.qris:         return 'QRIS';
      case PaymentMethod.bankTransfer: return 'Trf Bank';
      case PaymentMethod.eWallet:      return 'E-Wallet';
    }
  }
}
