package jp.co.kts.service.fileExport;

import java.awt.Color;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang.StringUtils;

import com.itextpdf.awt.AsianFontMapper;
import com.itextpdf.awt.PdfGraphics2D;
import com.itextpdf.text.Document;
import com.itextpdf.text.Font;
import com.itextpdf.text.Image;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.Rectangle;
import com.itextpdf.text.pdf.Barcode;
import com.itextpdf.text.pdf.BaseFont;
import com.itextpdf.text.pdf.PdfContentByte;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;

import jp.co.keyaki.cleave.common.util.StringUtil;
import jp.co.kts.app.extendCommon.entity.ExtendSalesItemDTO;
import jp.co.kts.app.extendCommon.entity.ExtendSalesSlipDTO;
import jp.co.kts.app.output.entity.StoreDTO;
import jp.co.kts.service.sale.SaleDisplayService;
import net.arnx.jsonic.JSON;

public class ExportPickListService {

	static SimpleDateFormat fileNmTimeFormat = new SimpleDateFormat(
			"yyyyMMdd_HHmmss");
	static SimpleDateFormat displyTimeFormat = new SimpleDateFormat(
			"yyyy/MM/dd  HH:mm:ss");

	// static int testrow = 40;
	public void pickList(HttpServletResponse response,
			List<ExtendSalesSlipDTO> salesSlipList) throws Exception {

		SaleDisplayService saleDisplayService = new SaleDisplayService();
		List<ExtendSalesSlipDTO> pickList = new ArrayList<>();
		pickList = saleDisplayService.getPickItemList(salesSlipList);

		/*
		 *  出力しようとしている伝票が全て楽天倉庫の商品であった場合
		 *  ピッキングリスト・納品書を出力する処理はスキップする。
		 *  ※楽天倉庫の伝票はピッキングリスト・納品書を出力しない仕様のため。
		 */
		/*
		 *  ピッキングリスト・納品書の出力はajaxで処理しているので
		 *  楽天倉庫伝票のみを印刷しようとした場合はメッセージを出力する為に
		 *  判別する文字をjspへ渡す。
		 */
		int[] slipCountArray = new int[2];
		slipCountArray = countKtsStocks(pickList);

		//KTS伝票が０件の場合、ピッキングリスト・納品書は出力しない。
		if (slipCountArray[0] <= 0) {
			response.setCharacterEncoding("UTF-8");
			PrintWriter printWriter = response.getWriter();
			printWriter.print(JSON.encode(slipCountArray));
			return;
		}

		Date date = new Date();

		String fname = "ピッキング＆納品書リスト" + fileNmTimeFormat.format(date) + ".pdf";
		// ファイル名に日本語を使う場合、以下の方法でファイル名を設定.
		byte[] sJis = fname.getBytes("Shift_JIS");
		fname = new String(sJis, "ISO8859_1");

		Document document = new Document(PageSize.A4, 5, 5, 40, 5);

		PdfWriter writer = PdfWriter.getInstance(document,
				new FileOutputStream("pickList.pdf"));

//		BaseFont baseFont = BaseFont.createFont(
//				AsianFontMapper.JapaneseFont_Go,
//				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED);
//
//		Font font = new Font(BaseFont.createFont(
//				AsianFontMapper.JapaneseFont_Go,
//				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED), 9);

		BaseFont baseFont = BaseFont.createFont(
				AsianFontMapper.JapaneseFont_Min,
				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED);

		Font font = new Font(BaseFont.createFont(
				AsianFontMapper.JapaneseFont_Min,
				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED), 9);


		document.open();

		for (ExtendSalesSlipDTO slipDto : pickList) {

			// KTS倉庫から出庫予定の商品だけピッキングリストと納品書を出力する。
			if (slipDto.getRslLeaveFlag() == null || StringUtils.equals(slipDto.getRslLeaveFlag(), "0")) {
				/** ピッキングリスト */
				pickHeader(document, writer, baseFont, date);
				pickList(document, writer, font, baseFont, slipDto);
				document.newPage();

				/** 納品書 */
				float orderCurrentHeight = 0;
				orderCurrentHeight = fixedPhrases(document, writer, font, baseFont,
						slipDto);
				orderCurrentHeight = orderDetail(document, writer, font, baseFont,
						slipDto, orderCurrentHeight);
				orderItemDetail(document, writer, font, baseFont, slipDto,
						orderCurrentHeight);
				// 改ページ
				document.newPage();
			}
		}

		document.close();

		// ピッキングリスト・納品書を作成することができたら呼び出し元に目印を返してpdf出力する。
		response.setCharacterEncoding("UTF-8");
		PrintWriter printWriter = response.getWriter();
		printWriter.print(JSON.encode(slipCountArray));

	}

	private static void pickHeader(Document document, PdfWriter writer,
			BaseFont baseFont, Date date) throws Exception {

		PdfContentByte pdfContentByte = writer.getDirectContent();
		// テキストの開始
		pdfContentByte.beginText();

		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 12);
		// 表示位置の設定
		pdfContentByte.setTextMatrix(210, 820);

		// 表示する文字列の設定
		pdfContentByte.showText("★★ピッキングリスト★★");

		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 8);
		// 表示位置の設定
		pdfContentByte.setTextMatrix(465, 825);

		// 表示する文字列の設定
		pdfContentByte.showText(displyTimeFormat.format(date) + "　作成");

		// テキストの終了
		pdfContentByte.endText();

//		Font font = new Font(BaseFont.createFont(
//				AsianFontMapper.JapaneseFont_Go,
//				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED), 8);

		Font font = new Font(BaseFont.createFont(
				AsianFontMapper.JapaneseFont_Min,
				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED), 8);

		PdfPTable pdfPTable = new PdfPTable(2);

		PdfPCell cell1_1 = new PdfPCell(new Paragraph("開始", font));
		PdfPCell cell1_2 = new PdfPCell(new Paragraph("：", font));

		PdfPCell cell2_1 = new PdfPCell(new Paragraph("終了", font));
		PdfPCell cell2_2 = new PdfPCell(new Paragraph("：", font));

		PdfPCell cell3_1 = new PdfPCell(new Paragraph("担当", font));
		PdfPCell cell3_2 = new PdfPCell(new Paragraph("", font));

		/**
		 * ALIGN_LEFT 左詰め 0 ALIGN_CENTER 中央（左右） 1 ALIGN_RIGHT 右詰め 2
		 * ALIGN_JUSTIFIED 両端揃え 3 ALIGN_TOP 上詰め 4 ALIGN_MIDDLE 中央（上下） 5
		 * ALIGN_BOTTOM 下詰め 6 ALIGN_BASELINE ベースライン 7
		 */
		cell1_1.setHorizontalAlignment(1);
		cell1_2.setHorizontalAlignment(1);

		cell2_1.setHorizontalAlignment(1);
		cell2_2.setHorizontalAlignment(1);

		cell3_1.setHorizontalAlignment(1);
		cell3_2.setHorizontalAlignment(1);

		// 線消すメモ
		// cell1_1.setBorder(Rectangle.NO_BORDER);
		pdfPTable.addCell(cell1_1);

		pdfPTable.addCell(cell1_2);

		pdfPTable.addCell(cell2_1);
		pdfPTable.addCell(cell2_2);

		pdfPTable.addCell(cell3_1);
		pdfPTable.addCell(cell3_2);

		pdfPTable.setTotalWidth(80);
		int width[] = { 25, 55 };
		pdfPTable.setWidths(width);
		pdfPTable.writeSelectedRows(0, 3, 485, 820, writer.getDirectContent());

	}

	private static void pickList(Document document, PdfWriter writer,
			Font font, BaseFont baseFont, ExtendSalesSlipDTO slipDto)
			throws Exception {
		PdfContentByte pdfContentByte = writer.getDirectContent();

		/**
		 * ---------------------------------------------------注文者情報START--------
		 * ---------------------------------------------------------
		 */
		// テキストの開始
		pdfContentByte.beginText();

		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 8);

		// 表示位置の設定
		pdfContentByte.setTextMatrix(30, 800);

		// 表示する文字列の設定
		pdfContentByte.showText("■注文者");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(100, 800);

		// 表示する文字列の設定
		pdfContentByte.showText("受注ルート");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, 800);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getCorporationNm() + "　"
				+ slipDto.getChannelNm());

		// 表示位置の設定
		pdfContentByte.setTextMatrix(100, 785);

		// 表示する文字列の設定
		pdfContentByte.showText("受注番号");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, 785);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getOrderNo());

		// 表示位置の設定
		pdfContentByte.setTextMatrix(100, 770);

		// 表示する文字列の設定
		pdfContentByte.showText("注文日時");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, 770);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getOrderDate() + " "
				+ slipDto.getOrderTime());

		// 表示位置の設定
		pdfContentByte.setTextMatrix(420, 770);

		// 表示する文字列の設定
		pdfContentByte.showText("支払方法");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(470, 770);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getAccountMethod());

		// 表示位置の設定
		pdfContentByte.setTextMatrix(100, 755);

		// 表示する文字列の設定
		pdfContentByte.showText("注文者名");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, 755);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getOrderFullNm() + "("
				+ slipDto.getOrderFullNmKana() + ")" + "様");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(420, 755);

		// 表示する文字列の設定
		pdfContentByte.showText("電話番号");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(470, 755);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getOrderTel());

		// 表示位置の設定
		pdfContentByte.setTextMatrix(100, 740);

		// 表示する文字列の設定
		pdfContentByte.showText("注文者住所");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, 740);

		// 表示する文字列の設定
		pdfContentByte.showText("〒" + slipDto.getOrderZip() + " "
				+ slipDto.getOrderPrefectures()
				+ slipDto.getOrderMunicipality() + slipDto.getOrderAddress()
				+ slipDto.getOrderBuildingNm());

		pdfContentByte.setTextMatrix(100, 725);

		// 表示する文字列の設定
		pdfContentByte.showText("メール");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, 725);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getOrderMailAddress());

		// 表示位置の設定
		pdfContentByte.setTextMatrix(30, 710);

		// 表示する文字列の設定
		pdfContentByte.showText("一言メモ/備考欄：");

		String orderRemarksMemo = slipDto.getOrderRemarksMemo();

		orderRemarksMemo = replaceNewline(orderRemarksMemo);
		int yPos = 710;
		int newlineCount = 58;
		/**
		 * 暫定。継続条件に＝が入っているから58文字くらいの時、無駄に空行作られるかも。＝
		 * 外すと備考が空のときypos加算しないから同じとこに書かれるのかな。
		 */
		for (int strNum = 0; strNum <= orderRemarksMemo.length();) {
			pdfContentByte.setTextMatrix(100, yPos);
			pdfContentByte.showText(StringUtils.substring(orderRemarksMemo, strNum,
					strNum + newlineCount));

			strNum += newlineCount;
			yPos -= 10;
		}
		/**
		 * この辺暫定。とりあえず、２バイト文字と１バイト文字によって改行の桁数変わるから判断する。時間あるときAPI読んで全体的に作りかえる
		 */

		yPos -= 5;

		// テキストの終了
		pdfContentByte.endText();
		yPos += 5;

		int pageHeight = (int) document.getPageSize().getHeight();

		// PdfGraphics2D のインスタンス化
		PdfGraphics2D pdfGraphics2D = new PdfGraphics2D(pdfContentByte,
				document.getPageSize().getWidth(), document.getPageSize()
						.getHeight());
		pdfGraphics2D.setColor(new Color(0, 0, 0));
		pdfGraphics2D.drawLine(30, pageHeight - yPos, 565, pageHeight - yPos);
		pdfGraphics2D.dispose();
		/**
		 * ---------------------------------------------------お届け先START--------
		 * ---------------------------------------------------------
		 */
		// テキストの開始
		pdfContentByte.beginText();

		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 8);
		// 表示位置の設定
		yPos -= 15;
		pdfContentByte.setTextMatrix(30, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("■お届け先");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(100, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("お届け先名");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getDestinationFullNm() + "("
				+ slipDto.getDestinationFullNmKana() + ")" + "様");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(420, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("電話番号");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(470, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getDestinationTel());

		// 表示位置の設定
		yPos -= 15;
		pdfContentByte.setTextMatrix(100, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("お届け先住所");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("〒" + slipDto.getDestinationZip() + " "
				+ slipDto.getDestinationPrefectures()
				+ slipDto.getDestinationMunicipality()
				+ slipDto.getDestinationAddress()
				+ slipDto.getDestinationBuildingNm());

		// 表示位置の設定
		yPos -= 15;
		pdfContentByte.setTextMatrix(30, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("備考欄：");

		String deliveryRemarks = slipDto.getSenderRemarks();
		deliveryRemarks = replaceNewline(deliveryRemarks);
		for (int strNum = 0; strNum <= deliveryRemarks.length();) {
			pdfContentByte.setTextMatrix(100, yPos);
			pdfContentByte.showText(StringUtils.substring(deliveryRemarks,
					strNum, strNum + newlineCount));

			strNum += newlineCount;
			yPos -= 10;
		}

		yPos -= 5;

		// 表示位置の設定
		pdfContentByte.setTextMatrix(30, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("一言メモ：");

		String senderMemo = slipDto.getSenderMemo();

		senderMemo = replaceNewline(senderMemo);

		for (int strNum = 0; strNum <= senderMemo.length();) {
			pdfContentByte.setTextMatrix(100, yPos);
			pdfContentByte.showText(StringUtils.substring(senderMemo, strNum,
					strNum + newlineCount));

			strNum += newlineCount;
			yPos -= 10;
		}

		// テキストの終了
		pdfContentByte.endText();

		yPos += 5;
		pdfGraphics2D.setColor(new Color(0, 0, 0));
		pdfGraphics2D.drawLine(30, pageHeight - yPos, 565, pageHeight - yPos);
		pdfGraphics2D.dispose();

		/**
		 * ---------------------------------------------------伝票情報START--------
		 * ---------------------------------------------------------
		 */
		// テキストの開始
		pdfContentByte.beginText();

		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 8);
		// 表示位置の設定
		yPos -= 15;
		pdfContentByte.setTextMatrix(30, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("■伝票情報");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(100, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("運送会社");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getTransportCorporationSystem());

		// 表示位置の設定
		pdfContentByte.setTextMatrix(420, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("出荷予定日");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(470, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getShipmentPlanDate());

		// 表示位置の設定
		yPos -= 15;
		// 表示位置の設定
		pdfContentByte.setTextMatrix(100, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("送り状種別");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(170, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getInvoiceClassification());

		// 表示位置の設定
		pdfContentByte.setTextMatrix(420, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("配送指定日");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(470, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getDestinationAppointDate());

		// 表示位置の設定
		yPos -= 15;
		// 表示位置の設定
		pdfContentByte.setTextMatrix(420, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("時間帯指定");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(470, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getDestinationAppointTime());

		yPos -= 15;
		pdfContentByte.setTextMatrix(30, yPos);

		// 表示する文字列の設定
		pdfContentByte.showText("一言メモ：");

		String slipMemo = slipDto.getSlipMemo();
		slipMemo = replaceNewline(slipMemo);
		for (int strNum = 0; strNum <= slipMemo.length();) {
			pdfContentByte.setTextMatrix(100, yPos);
			pdfContentByte.showText(StringUtils.substring(slipMemo, strNum,
					strNum + newlineCount));

			strNum += newlineCount;
			yPos -= 10;
		}

		// テキストの終了
		pdfContentByte.endText();

		yPos += 5;
		pdfGraphics2D.setColor(new Color(0, 0, 0));
		pdfGraphics2D.drawLine(30, pageHeight - yPos, 565, pageHeight - yPos);
		pdfGraphics2D.dispose();

		PdfPTable pdfPTable = new PdfPTable(6);

		// 表の要素(列タイトル)を作成
		PdfPCell cell1_1 = new PdfPCell(new Paragraph("品番", font));
		cell1_1.setRowspan(2); // セルを2行分結合
		cell1_1.setGrayFill(0.8f); // セルを灰色に設定

		PdfPCell cell1_2 = new PdfPCell(new Paragraph("倉庫場所", font));
		cell1_2.setGrayFill(0.8f); // セルを灰色に設定

		PdfPCell cell1_3 = new PdfPCell(new Paragraph("ロケーションNo", font));
		cell1_3.setGrayFill(0.8f); // セルを灰色に設定

		// 表の要素(列タイトル)を作成
		PdfPCell cell1_4 = new PdfPCell(new Paragraph("個数", font));
		cell1_4.setRowspan(2); // セルを2行分結合
		cell1_4.setGrayFill(0.8f); // セルを灰色に設定

		PdfPCell cell1_5 = new PdfPCell(new Paragraph("バーコード", font));
		cell1_5.setRowspan(2); // セルを2行分結合
		cell1_5.setGrayFill(0.8f); // セルを灰色に設定

		// 表の要素(列タイトル)を作成
		PdfPCell cell1_6 = new PdfPCell(new Paragraph("チェック", font));
		cell1_6.setRowspan(2); // セルを2行分結合
		cell1_6.setGrayFill(0.8f); // セルを灰色に設定

		// 表の要素(列タイトル)を作成
		PdfPCell cell2_1 = new PdfPCell(new Paragraph("商品名", font));
		cell2_1.setColspan(2); // セルを2列分結合
		cell2_1.setGrayFill(0.8f); // セルを灰色に設定

		cell1_1.setHorizontalAlignment(1);
		cell1_2.setHorizontalAlignment(1);
		cell1_3.setHorizontalAlignment(1);
		cell1_4.setHorizontalAlignment(1);
		cell1_5.setHorizontalAlignment(1);
		cell1_6.setHorizontalAlignment(1);
		cell2_1.setHorizontalAlignment(1);

		// 表の要素を表に追加する
		pdfPTable.addCell(cell1_1);
		pdfPTable.addCell(cell1_2);
		pdfPTable.addCell(cell1_3);
		pdfPTable.addCell(cell1_4);
		pdfPTable.addCell(cell1_5);
		pdfPTable.addCell(cell1_6);
		pdfPTable.addCell(cell2_1);

		yPos -= 15;
		pdfPTable.setTotalWidth(535);
		int width[] = { 70, 145, 100, 25, 150, 45 };
		pdfPTable.setWidths(width);

		int repaginationRow = 0;
		float pageHight = 0;
		int rowNum = 0;
		//総描画行数
		int totalRowNum = 0;
		int itemNum = 0;

		// 書き込みと改ページの判定のために、一行分の高さを保持する変数
		float oneHeight = 0;

		// 商品毎のループ
		for (rowNum = 0; rowNum < slipDto.getPickItemList().size(); rowNum++) {

			// 複数個の商品も1個につき1バーコードを出力するよう修正
			// 商品の数量毎のループ
			for (itemNum = 0; itemNum < slipDto.getPickItemList().get(rowNum).getOrderNum(); itemNum++) {

				// 一行分の高さを算出するために、PDFへ設定前の高さを保持する。
				float beforHeigt = pdfPTable.calculateHeights();


				// 表の要素を作成
				PdfPCell cell3_1 = new PdfPCell(new Paragraph(slipDto
						.getPickItemList().get(rowNum).getItemCode(), font));
				cell3_1.setRowspan(2); // セルを2行分結合

				// cell3_2, cell3_3がnullの場合,当該セルが表示されなくなる現象を修正
				if (slipDto.getPickItemList().get(rowNum).getWarehouseNm() == null) {
					slipDto.getPickItemList().get(rowNum).setWarehouseNm("　");
				}
				if (slipDto.getPickItemList().get(rowNum).getLocationNo() == null){
					slipDto.getPickItemList().get(rowNum).setLocationNo("　");
				}

				// 表の要素を作成
				PdfPCell cell3_2 = new PdfPCell(new Paragraph(slipDto
						.getPickItemList().get(rowNum).getWarehouseNm(), font));

				PdfPCell cell3_3 = new PdfPCell(new Paragraph(slipDto
						.getPickItemList().get(rowNum).getLocationNo(), font));

				PdfPCell cell3_4 = new PdfPCell(new Paragraph(
						String.valueOf(1), font));
				cell3_4.setRowspan(2); // セルを2行分結合
				// 4996740500084
				// 表の要素を作成

				com.itextpdf.text.Image image = null;
				image = makeBarcode(writer, slipDto.getPickItemList().get(rowNum)
						.getItemCode());

				PdfPCell cell3_5;
				if (image != null) {
					cell3_5 = new PdfPCell(image);
				} else {
					cell3_5 = new PdfPCell(new Paragraph("", font));
				}

				cell3_5.setRowspan(2); // セルを2行分結合

				PdfPCell cell3_6 = new PdfPCell(new Paragraph("", font));
				cell3_6.setRowspan(2); // セルを2行分結合

				PdfPCell cell4_1 = new PdfPCell(new Paragraph(slipDto
						.getPickItemList().get(rowNum).getItemNm(), font));
				cell4_1.setColspan(2); // セルを2列分結合

				cell3_1.setHorizontalAlignment(1);
				cell3_2.setHorizontalAlignment(1);
				cell3_3.setHorizontalAlignment(1);
				cell3_4.setHorizontalAlignment(1);
				cell3_5.setHorizontalAlignment(1);
				cell3_6.setHorizontalAlignment(1);
				cell4_1.setHorizontalAlignment(1);

				if (image != null) {
					cell3_1.setPaddingTop(10f);
					cell3_1.setPaddingBottom(5f);
					cell3_2.setPaddingTop(10f);
					cell3_2.setPaddingBottom(5f);
					cell3_3.setPaddingTop(10f);
					cell3_3.setPaddingBottom(5f);
					cell3_4.setPaddingTop(10f);
					cell3_4.setPaddingBottom(5f);
					cell3_5.setPaddingTop(10f);
					cell3_5.setPaddingBottom(5f);
					cell3_6.setPaddingTop(10f);
					cell3_6.setPaddingBottom(5f);
					cell4_1.setPaddingTop(10f);
					cell4_1.setPaddingBottom(5f);
				}

				pdfPTable.addCell(cell3_1);
				pdfPTable.addCell(cell3_2);
				pdfPTable.addCell(cell3_3);
				pdfPTable.addCell(cell3_4);
				pdfPTable.addCell(cell3_5);
				pdfPTable.addCell(cell3_6);
				pdfPTable.addCell(cell4_1);

				// 2ページ目以降書き込みや改ページが必要か判定するために、
				// PDFへ設定前の高さと設定後の高さから、一商品分の高さを算出する。
				oneHeight = pdfPTable.calculateHeights() - beforHeigt;

				// ２ページ以降で書き込みや改ページが必要な場合の判定、650を超える場合は書き込みと改ページを実行する。
				if (repaginationRow > 0 && pdfPTable.calculateHeights() - pageHight + oneHeight > 650) {
					pageHight = pdfPTable.calculateHeights();
					/** 大枠の線から10px上を越えていたらその行削除し次ページに表示 */
					pdfPTable.writeSelectedRows(0, 6, repaginationRow - 1,
							totalRowNum - 1, 30, 800, writer.getDirectContent());
					repaginationRow = totalRowNum;

					// この分岐に入った場合は改ページ後も商品が存在するので改ページする。
					document.newPage();

				// １ページ目で改ページ後も出力する商品が存在し改ページが必要な場合
				// XXX バーコードなしの行が混在すると1頁分の印刷範囲を超えてしまうので、一頁目が全てバーコード無商品の場合の高さを判断基準とした。
				} else if (pdfPTable.calculateHeights() > 516 && repaginationRow == 0) {
					/** 大枠の線から10px上を越えていたらその行削除し次ページに表示 */
					pageHight = pdfPTable.calculateHeights();
					totalRowNum -= 1;
					pdfPTable.writeSelectedRows(0, 6, 0, totalRowNum - 1, 30, yPos,
							writer.getDirectContent());
					repaginationRow = totalRowNum;

					// この分岐に入った場合は改ページ後も商品が存在するので改ページする。
					document.newPage();

				}

				totalRowNum += 2;
			}
		}
		if (totalRowNum > repaginationRow && repaginationRow == 0) {
			pdfPTable.writeSelectedRows(0, 6, 0, -1, 30, yPos,
					writer.getDirectContent());
		} else if (totalRowNum > repaginationRow) {
			pdfPTable.writeSelectedRows(0, 6, repaginationRow - 1, -1, 30, 800,
					writer.getDirectContent());

		}

	}

	private static String replaceNewline(String text) {

		if (text == null) {
			return StringUtils.EMPTY;
		}
		String LINE_SEPARATOR_PATTERN1 = "\r\n";
		text = StringUtils.replace(text, LINE_SEPARATOR_PATTERN1, " ");
		String LINE_SEPARATOR_PATTERN2 = "\n";
		text = StringUtils.replace(text, LINE_SEPARATOR_PATTERN2, " ");
		return text;

	}

	/**
	 *
	 * @param document
	 * @param writer
	 */
	private static void newPage(Document document, PdfWriter writer) {

		document.newPage();

		PdfContentByte pdfContentByte = writer.getDirectContent();
		// PdfGraphics2D のインスタンス化
		PdfGraphics2D pdfGraphics2D = new PdfGraphics2D(pdfContentByte,
				document.getPageSize().getWidth(), document.getPageSize()
						.getHeight());
		pdfGraphics2D.setColor(new Color(0, 0, 0));
		pdfGraphics2D.drawRect(30, 30, 535, 782);
		pdfGraphics2D.dispose();

	}

	private static Image makeBarcode(PdfWriter writer, String value) {

		// バーコードイメージの作成
		com.itextpdf.text.Image image = null;
		try {
			Barcode barcode39 = new com.itextpdf.text.pdf.Barcode39();
			barcode39.setCode(value);
			PdfContentByte cb = writer.getDirectContent();

			image = barcode39.createImageWithBarcode(cb, null, null);
		} catch (Exception e) {
			return null;
		}
		return image;
	}

	private static float fixedPhrases(Document document, PdfWriter writer,
			Font font, BaseFont baseFont, ExtendSalesSlipDTO slipDto)
			throws Exception {
//TODO
		PdfContentByte pdfContentByte = writer.getDirectContent();

		// PdfGraphics2D のインスタンス化
		PdfGraphics2D pdfGraphics2D = new PdfGraphics2D(pdfContentByte,
				document.getPageSize().getWidth(), document.getPageSize()
						.getHeight());
		pdfGraphics2D.setColor(new Color(0, 0, 0));
		pdfGraphics2D.drawRect(30, 30, 535, 782);
		pdfGraphics2D.drawLine(30, 60, 565, 60);
		pdfGraphics2D.dispose();

		// テキストの開始
		pdfContentByte.beginText();

		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 18);
		// 表示位置の設定
		pdfContentByte.setTextMatrix(230, 790);

		// 表示する文字列の設定
		pdfContentByte.showText("お買い上げ明細書");

		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 9);
		// 表示位置の設定
		pdfContentByte.setTextMatrix(50, 760);

		// 表示する文字列の設定
		pdfContentByte.showText(slipDto.getOrderFullNm() + " 様");
		// 表示位置の設定
		pdfContentByte.setTextMatrix(50, 730);
		// 表示する文字列の設定
		pdfContentByte.showText("この度は当店のご利用、誠にありがとうございました。");
		pdfContentByte.setTextMatrix(50, 719);
		pdfContentByte.showText("下記のとおり商品をご納品いたします。");
		pdfContentByte.setTextMatrix(50, 708);
		pdfContentByte.showText("ご確認いただきますよう、お願い申し上げます。");

		// 表示位置の設定
		pdfContentByte.setTextMatrix(350, 760);

		// 表示する文字列の設定
		pdfContentByte.showText("受注番号：" + slipDto.getOrderNo());
		// テキストの終了
		pdfContentByte.endText();

		SaleDisplayService saleDisplayService = new SaleDisplayService();

		StoreDTO storeDTO = new StoreDTO();
		storeDTO = saleDisplayService.selectShopInfo(
				slipDto.getSysCorporationId(), slipDto.getSysChannelId());

		if (storeDTO == null) {
			storeDTO = new StoreDTO();
		}

		PdfPTable CorporationTable = new PdfPTable(1);

		PdfPCell cell = null;

		if (StringUtils.equals(storeDTO.getStoreNmDispFlg(), "1")) {
			cell = new PdfPCell(new Paragraph(storeDTO.getStoreNm(), font));
			cell.setBorder(Rectangle.NO_BORDER);
			CorporationTable.addCell(cell);
		}

		if (StringUtils.equals(storeDTO.getCorporationNmDispFlg(), "1")) {
			String corporationNm = storeDTO.getCorporationNm();
			if (StringUtils.equals(storeDTO.getNameHeaderDispFlg(), "1")) {
				corporationNm = "株式会社 " + corporationNm;
			}
			cell = new PdfPCell(new Paragraph(corporationNm, font));
			cell.setBorder(Rectangle.NO_BORDER);
			CorporationTable.addCell(cell);
		}

		if (StringUtils.equals(storeDTO.getZipDispFlg(), "1")) {
			cell = new PdfPCell(new Paragraph("〒" + storeDTO.getZip(), font));
			cell.setBorder(Rectangle.NO_BORDER);
			CorporationTable.addCell(cell);
		}
		if (StringUtils.equals(storeDTO.getAddressDispFlg(), "1")) {
			cell = new PdfPCell(new Paragraph(storeDTO.getAddress(), font));
			cell.setBorder(Rectangle.NO_BORDER);
			CorporationTable.addCell(cell);
		}

		if (StringUtils.equals(storeDTO.getTelNoDispFlg(), "1")) {
			cell = new PdfPCell(new Paragraph("TEL:" + storeDTO.getTelNo(),
					font));
			cell.setBorder(Rectangle.NO_BORDER);
			CorporationTable.addCell(cell);
		}

		if (StringUtils.equals(storeDTO.getFaxNoDispFlg(), "1")) {
			cell = new PdfPCell(new Paragraph("FAX:" + storeDTO.getFaxNo(),
					font));
			cell.setBorder(Rectangle.NO_BORDER);
			CorporationTable.addCell(cell);
		}
		if (StringUtils.equals(storeDTO.getMailDispFlg(), "1")) {
			cell = new PdfPCell(new Paragraph("Email:"
					+ storeDTO.getStoreMailAddress(), font));
			cell.setBorder(Rectangle.NO_BORDER);
			CorporationTable.addCell(cell);
		}

		cell = new PdfPCell(new Paragraph("　", font));
		cell.setBorder(Rectangle.NO_BORDER);
		CorporationTable.addCell(cell);

		cell = new PdfPCell(new Paragraph("ご注文日：" + slipDto.getOrderDate(),
				font));
		cell.setHorizontalAlignment(2);
		cell.setBorder(Rectangle.NO_BORDER);
		CorporationTable.addCell(cell);

		CorporationTable.setTotalWidth(195);

		float CorporationTableYPos = 745;
//TODO
		CorporationTable.writeSelectedRows(0, -1, 350, CorporationTableYPos,
				writer.getDirectContent());

		float CorporationTableHight = CorporationTable.calculateHeights();

		return CorporationTableYPos - CorporationTableHight;

	}

	private static float orderDetail(Document document, PdfWriter writer,
			Font font, BaseFont baseFont, ExtendSalesSlipDTO slipDto,
			float orderCurrentHeight) throws Exception {

		PdfPTable orderDetailTable = new PdfPTable(1);
		PdfPCell cell = null;
		// 表の要素(列タイトル)を作成
		cell = new PdfPCell(new Paragraph("お買い上げ明細", font));
		cell.setGrayFill(0.8f); // セルを灰色に設定
		// 表の要素を表に追加する
		orderDetailTable.addCell(cell);

		cell = new PdfPCell(new Paragraph("〒" + slipDto.getDestinationZip()
				+ " " + slipDto.getDestinationPrefectures()
				+ slipDto.getDestinationMunicipality()
				+ slipDto.getDestinationAddress()
				+ slipDto.getDestinationBuildingNm(), font));
		cell.setBorder(Rectangle.NO_BORDER);
		orderDetailTable.addCell(cell);

		cell = new PdfPCell(new Paragraph(
				slipDto.getDestinationFullNm() + " 様", font));
		cell.setBorder(Rectangle.NO_BORDER);
		orderDetailTable.addCell(cell);

		cell = new PdfPCell(new Paragraph("配送方法： "
				+ slipDto.getInvoiceClassification(), font));
		cell.setBorder(Rectangle.NO_BORDER);
		orderDetailTable.addCell(cell);

		orderDetailTable.setTotalWidth(495);
		// pdfPTable.setWidths(width);
		orderDetailTable.writeSelectedRows(0, -1, 50, orderCurrentHeight,
				writer.getDirectContent());

		float orderDetailTableHight = orderDetailTable.calculateHeights();

		return orderCurrentHeight - orderDetailTableHight;

	}

	private static void orderItemDetail(Document document, PdfWriter writer,
			Font font, BaseFont baseFont, ExtendSalesSlipDTO slipDto,
			float orderCurrentHeight) throws Exception {
		PdfPTable pdfPTable = new PdfPTable(4);
		pdfPTable.setTotalWidth(495);
		int width[] = { 297, 74, 50, 74 };
		pdfPTable.setWidths(width);

		// 表の要素(列タイトル)を作成
		PdfPCell cellItemNmHeader = new PdfPCell(new Paragraph("商品名", font));
		cellItemNmHeader.setGrayFill(0.8f); // セルを灰色に設定
		PdfPCell cellUnitPriceHeader = new PdfPCell(new Paragraph("単価", font));
		cellUnitPriceHeader.setGrayFill(0.8f); // セルを灰色に設定
		PdfPCell cellQuantityHeader = new PdfPCell(new Paragraph("数量", font));
		cellQuantityHeader.setGrayFill(0.8f); // セルを灰色に設定
		// 表の要素(列タイトル)を作成
		PdfPCell cellPriceHeader = new PdfPCell(new Paragraph("価格", font));
		cellPriceHeader.setGrayFill(0.8f); // セルを灰色に設定

		cellUnitPriceHeader.setHorizontalAlignment(1);
		cellQuantityHeader.setHorizontalAlignment(1);
		cellPriceHeader.setHorizontalAlignment(1);

		// 表の要素を表に追加する
		pdfPTable.addCell(cellItemNmHeader);
		pdfPTable.addCell(cellUnitPriceHeader);
		pdfPTable.addCell(cellQuantityHeader);
		pdfPTable.addCell(cellPriceHeader);

		/**
		 * ループ(商品LISTのDTOをループさせる予定)
		 */
		int repaginationRow = 0;
		float pageHight = 0;
		int rowNum = 0;
		long totalPrice = 0;
		for (rowNum = 0; rowNum < slipDto.getPickItemList().size(); rowNum++) {
			// 商品名
			PdfPCell cellItemNm = new PdfPCell(new Paragraph(slipDto
					.getPickItemList().get(rowNum).getItemNm(), font));
			// 単価
			PdfPCell cellUnitPrice = new PdfPCell(new Paragraph(
					StringUtil.formatCalc(BigDecimal.valueOf(slipDto
							.getPickItemList().get(rowNum).getPieceRate()))
							+ "円", font));
			PdfPCell cellQuantity = new PdfPCell(new Paragraph(
					String.valueOf(slipDto.getPickItemList().get(rowNum)
							.getOrderNum()), font));
			PdfPCell cellPrice = new PdfPCell(new Paragraph(
					StringUtil.formatCalc(BigDecimal.valueOf(slipDto
							.getPickItemList().get(rowNum).getPieceRate()
							* slipDto.getPickItemList().get(rowNum)
									.getOrderNum()))
							+ "円", font));

			totalPrice += slipDto.getPickItemList().get(rowNum).getPieceRate()
					* slipDto.getPickItemList().get(rowNum).getOrderNum();

			cellUnitPrice.setHorizontalAlignment(2);
			cellQuantity.setHorizontalAlignment(2);
			cellPrice.setHorizontalAlignment(2);

			pdfPTable.addCell(cellItemNm);
			pdfPTable.addCell(cellUnitPrice);
			pdfPTable.addCell(cellQuantity);
			pdfPTable.addCell(cellPrice);

			if (pdfPTable.calculateHeights() > orderCurrentHeight
					&& repaginationRow == 0) {
				pageHight = pdfPTable.calculateHeights();
				/** 大枠の線を越えていたらその行削除し次ページに表示 */
				// pdfPTable.deleteRow(rowNum);
				// rowNum--;
				pageHight = pdfPTable.calculateHeights();
				pdfPTable.writeSelectedRows(0, 4, 0, rowNum - 1, 50,
						orderCurrentHeight, writer.getDirectContent());
				repaginationRow = rowNum;

			} else if (pdfPTable.calculateHeights() - pageHight > 750) {
				/** 行の高さがページ超えてくると無限ループ発生するはずなのであとで対処 */
				newPage(document, writer);
				pageHight = pdfPTable.calculateHeights();
				/** 大枠の線から10px上を越えていたらその行削除し次ページに表示 */
				// pdfPTable.deleteRow(rowNum);
				// rowNum--;
				pdfPTable.writeSelectedRows(0, 4, repaginationRow - 1,
						rowNum - 1, 50, 800, writer.getDirectContent());
				repaginationRow = rowNum;
			}
		}
		if (rowNum > repaginationRow && repaginationRow == 0) {
			pdfPTable.writeSelectedRows(0, 4, 0, -1, 50, orderCurrentHeight,
					writer.getDirectContent());
		} else if (rowNum > repaginationRow) {
			newPage(document, writer);
			pdfPTable.writeSelectedRows(0, 4, repaginationRow - 1, rowNum - 1,
					50, 800, writer.getDirectContent());
		}
		/** 多分、計算式違う、下の計算から、テーブルを記述始めているyposから以下の値を引かないと欲しい値が算出されない。 */
		float height = pdfPTable.calculateHeights() - pageHight;

		PdfPTable itemTotalPriceTable;
		float yPos = 0.0f;

		// 代金引換または代金引換(カード)の場合、納品書に手数料の出力を行う
		if (slipDto.getCodCommission() > 0) {
			itemTotalPriceTable = new PdfPTable(3);

			// 表の要素(列タイトル)を作成
			PdfPCell cellSumItemPriceHeader = new PdfPCell(new Paragraph(
					"商品合計(税込)", font));
			cellSumItemPriceHeader.setGrayFill(0.8f); // セルを灰色に設定
			PdfPCell cellpostageHeader = new PdfPCell(new Paragraph("送料", font));
			cellpostageHeader.setGrayFill(0.8f); // セルを灰色に設定
			PdfPCell cellCommissionHeader = new PdfPCell(new Paragraph("代引き手数料", font));
			cellCommissionHeader.setGrayFill(0.8f); // セルを灰色に設定

			cellSumItemPriceHeader.setHorizontalAlignment(1);
			cellpostageHeader.setHorizontalAlignment(1);
			cellCommissionHeader.setHorizontalAlignment(1);

			// 表の要素を表に追加する
			itemTotalPriceTable.addCell(cellSumItemPriceHeader);
			itemTotalPriceTable.addCell(cellpostageHeader);
			itemTotalPriceTable.addCell(cellCommissionHeader);

			// 外税の場合、税追加
			if (StringUtils.equals(slipDto.getTaxClass(), "2")) {
				totalPrice += slipDto.getTax();
			}

			PdfPCell cellSumItemPrice = new PdfPCell(new Paragraph(
					StringUtil.formatCalc(BigDecimal.valueOf(totalPrice)) + "円",
					font));
			PdfPCell cellpostage = new PdfPCell(new Paragraph(
					StringUtil.formatCalc(BigDecimal.valueOf(slipDto.getPostage()))
							+ "円", font));
			PdfPCell cellCommission = new PdfPCell(new Paragraph(
					StringUtil.formatCalc(BigDecimal.valueOf(slipDto.getCodCommission()))
							+ "円", font));

			cellSumItemPrice.setHorizontalAlignment(2);
			cellpostage.setHorizontalAlignment(2);
			cellCommission.setHorizontalAlignment(2);

			itemTotalPriceTable.addCell(cellSumItemPrice);
			itemTotalPriceTable.addCell(cellpostage);
			itemTotalPriceTable.addCell(cellCommission);

			itemTotalPriceTable.setTotalWidth(170);
			int itemTotalPriceTableWidth[] = { 70, 40, 60 };
			itemTotalPriceTable.setWidths(itemTotalPriceTableWidth);

			yPos = 580 - (height + 10);
			//cellSumItemPriceHeaderを次ページに表示するか判定
			if (height > 400) {
				newPage(document, writer);
				yPos = 800;
			}


			itemTotalPriceTable.writeSelectedRows(0, -1, 375, yPos,
					writer.getDirectContent());

			//代引きの場合、合計金額に代引き手数料を加算
			totalPrice = totalPrice + slipDto.getCodCommission();

			// 代金引換以外の場合
		} else {
			itemTotalPriceTable = new PdfPTable(2);

			// 表の要素(列タイトル)を作成
			PdfPCell cellSumItemPriceHeader = new PdfPCell(new Paragraph(
					"商品合計(税込)", font));
			cellSumItemPriceHeader.setGrayFill(0.8f); // セルを灰色に設定
			PdfPCell cellpostageHeader = new PdfPCell(new Paragraph("送料", font));
			cellpostageHeader.setGrayFill(0.8f); // セルを灰色に設定

			cellSumItemPriceHeader.setHorizontalAlignment(1);
			cellpostageHeader.setHorizontalAlignment(1);

			// 表の要素を表に追加する
			itemTotalPriceTable.addCell(cellSumItemPriceHeader);
			itemTotalPriceTable.addCell(cellpostageHeader);

			// 外税の場合、税追加
			if (StringUtils.equals(slipDto.getTaxClass(), "2")) {
				totalPrice += slipDto.getTax();
			}

			PdfPCell cellSumItemPrice = new PdfPCell(new Paragraph(
					StringUtil.formatCalc(BigDecimal.valueOf(totalPrice)) + "円",
					font));
			PdfPCell cellpostage = new PdfPCell(new Paragraph(
					StringUtil.formatCalc(BigDecimal.valueOf(slipDto.getPostage()))
							+ "円", font));

			cellSumItemPrice.setHorizontalAlignment(2);
			cellpostage.setHorizontalAlignment(2);

			itemTotalPriceTable.addCell(cellSumItemPrice);
			itemTotalPriceTable.addCell(cellpostage);

			itemTotalPriceTable.setTotalWidth(110);
			int itemTotalPriceTableWidth[] = { 70, 40 };
			itemTotalPriceTable.setWidths(itemTotalPriceTableWidth);


			yPos = 580 - (height + 10);
			//cellSumItemPriceHeaderを次ページに表示するか判定
			if (height > 400) {
				newPage(document, writer);
				yPos = 800;
			}


			itemTotalPriceTable.writeSelectedRows(0, -1, 435, yPos,
					writer.getDirectContent());
		}


		PdfContentByte pdfContentByte = writer.getDirectContent();
		// テキストの開始
		pdfContentByte.beginText();
		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 9);
		// 表示位置の設定
		pdfContentByte.setTextMatrix(50, yPos - 40);
		// 表示する文字列の設定
		pdfContentByte.showText("お買い上げ総合計");
		// 表示位置の設定
		pdfContentByte.setTextMatrix(520, yPos - 105);
		// 表示する文字列の設定
		pdfContentByte.showText("以上");
		// テキストの終了
		pdfContentByte.endText();

		PdfPTable finalItemTotalPriceTable = new PdfPTable(3);

		// 表の要素(列タイトル)を作成
		PdfPCell cellTotalPriceHeader = new PdfPCell(new Paragraph("合計", font));
		cellTotalPriceHeader.setGrayFill(0.8f); // セルを灰色に設定
		PdfPCell cellUsedPointHeader = new PdfPCell(new Paragraph("利用ポイント",
				font));
		cellUsedPointHeader.setGrayFill(0.8f); // セルを灰色に設定
		PdfPCell cellTotalSumPriceHeader = new PdfPCell(new Paragraph("総合計",
				font));
		cellTotalSumPriceHeader.setGrayFill(0.8f); // セルを灰色に設定

		cellTotalPriceHeader.setHorizontalAlignment(1);
		cellUsedPointHeader.setHorizontalAlignment(1);
		cellTotalSumPriceHeader.setHorizontalAlignment(1);

		// 表の要素を表に追加する
		finalItemTotalPriceTable.addCell(cellTotalPriceHeader);
		finalItemTotalPriceTable.addCell(cellUsedPointHeader);
		finalItemTotalPriceTable.addCell(cellTotalSumPriceHeader);

		PdfPCell cellTotalPrice = new PdfPCell(new Paragraph(
				StringUtil.formatCalc(BigDecimal.valueOf(totalPrice
						+ slipDto.getPostage()))
						+ "円", font));
		PdfPCell cellUsedPoint = new PdfPCell(new Paragraph(
				slipDto.getUsedPoint() + "円", font));
		PdfPCell cellTotalSumPrice = new PdfPCell(new Paragraph(
				StringUtil.formatCalc(BigDecimal.valueOf(totalPrice
						+ slipDto.getPostage() - slipDto.getUsedPoint()))
						+ "円", font));

		cellTotalPrice.setHorizontalAlignment(2);
		cellUsedPoint.setHorizontalAlignment(2);
		cellTotalSumPrice.setHorizontalAlignment(2);

		finalItemTotalPriceTable.addCell(cellTotalPrice);
		finalItemTotalPriceTable.addCell(cellUsedPoint);
		finalItemTotalPriceTable.addCell(cellTotalSumPrice);

		finalItemTotalPriceTable.setTotalWidth(160);
		int finalItemTotalPriceTableWidth[] = { 50, 60, 50 };
		finalItemTotalPriceTable.setWidths(finalItemTotalPriceTableWidth);
		finalItemTotalPriceTable.writeSelectedRows(0, -1, 385, yPos - 60,
				writer.getDirectContent());

		PdfPTable pdfRemarksTable = new PdfPTable(1);
		pdfRemarksTable.setTotalWidth(495);

		// int remarksTablewidth[] = {495};
		// pdfPTable.setWidths(remarksTablewidth);
		if (StringUtils.isEmpty(slipDto.getDeliveryRemarks())) {
			slipDto.setDeliveryRemarks(StringUtils.EMPTY);
		}
		PdfPCell cellIRemaks = new PdfPCell(new Paragraph("備考："
				+ slipDto.getDeliveryRemarks(), font));
		cellIRemaks.setBorder(Rectangle.NO_BORDER);
		pdfRemarksTable.addCell(cellIRemaks);
		pdfRemarksTable.writeSelectedRows(0, -1, 50, yPos - 125,
				writer.getDirectContent());
	}

	public void totalPickList(HttpServletResponse response,
			List<ExtendSalesSlipDTO> salesSlipList) throws Exception {

		Date date = new Date();

		Document document = new Document(PageSize.A4, 0, 0, 30, 5);

		PdfWriter writer = PdfWriter.getInstance(document,
				new FileOutputStream("totalPickList.pdf"));

//		BaseFont baseFont = BaseFont.createFont(
//				AsianFontMapper.JapaneseFont_Go,
//				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED);
//
//		Font font = new Font(BaseFont.createFont(
//				AsianFontMapper.JapaneseFont_Go,
//				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED), 9);

		BaseFont baseFont = BaseFont.createFont(
				AsianFontMapper.JapaneseFont_Min,
				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED);

		Font font = new Font(BaseFont.createFont(
				AsianFontMapper.JapaneseFont_Min,
				AsianFontMapper.JapaneseEncoding_H, BaseFont.NOT_EMBEDDED), 9);

		document.open();

		PdfContentByte pdfContentByte = writer.getDirectContent();
		// テキストの開始
		pdfContentByte.beginText();

		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 12);
		// 表示位置の設定
		pdfContentByte.setTextMatrix(210, 820);

		// 表示する文字列の設定
		pdfContentByte.showText("トータルピッキングリスト");

		// フォントとサイズの設定
		pdfContentByte.setFontAndSize(baseFont, 8);
		// 表示位置の設定
		pdfContentByte.setTextMatrix(430, 820);

		// 表示する文字列の設定
		pdfContentByte.showText("作成日時:" + displyTimeFormat.format(date));

		// テキストの終了
		pdfContentByte.endText();

		PdfPTable pdfPTable = new PdfPTable(4);
		pdfPTable.setTotalWidth(535);
		int width[] = { 30, 70, 405, 30 };
		pdfPTable.setWidths(width);

		// 表の要素(列タイトル)を作成
		PdfPCell cellIdHeader = new PdfPCell(new Paragraph("", font));
		cellIdHeader.setGrayFill(0.8f); // セルを灰色に設定
		PdfPCell cellItemCdHeader = new PdfPCell(new Paragraph("商品コード", font));
		cellItemCdHeader.setGrayFill(0.8f); // セルを灰色に設定
		PdfPCell cellItemNmHeader = new PdfPCell(new Paragraph("商品名", font));
		cellItemNmHeader.setGrayFill(0.8f); // セルを灰色に設定
		// 表の要素(列タイトル)を作成
		PdfPCell cellItemNumHeader = new PdfPCell(new Paragraph("数量", font));
		cellItemNumHeader.setGrayFill(0.8f); // セルを灰色に設定

		cellItemCdHeader.setHorizontalAlignment(1);
		cellItemNmHeader.setHorizontalAlignment(1);
		cellItemNumHeader.setHorizontalAlignment(1);

		// 表の要素を表に追加する
		pdfPTable.addCell(cellIdHeader);
		pdfPTable.addCell(cellItemCdHeader);
		pdfPTable.addCell(cellItemNmHeader);
		pdfPTable.addCell(cellItemNumHeader);

		SaleDisplayService saleDisplayService = new SaleDisplayService();
		List<ExtendSalesItemDTO> pickList = new ArrayList<>();
		pickList = saleDisplayService.getTotalPickItemList(salesSlipList);

		// 全て楽天倉庫から出庫する商品だった場合は表を出力しない。
		if (!pickList.isEmpty()) {

			int itemRowCount = 1;
			int totalItemNum = 0;
			for (ExtendSalesItemDTO itemDto : pickList) {
				PdfPCell cellId = new PdfPCell(new Paragraph(
						String.valueOf(itemRowCount), font));

				PdfPCell cellItemCd = new PdfPCell(new Paragraph(
						itemDto.getItemCode(), font));

				PdfPCell cellItemNm = new PdfPCell(new Paragraph(
						itemDto.getItemNm(), font));

				PdfPCell cellItemNum = new PdfPCell(new Paragraph(
						String.valueOf(itemDto.getOrderNum()), font));

				totalItemNum += itemDto.getOrderNum();

				cellId.setHorizontalAlignment(2);
				cellItemCd.setHorizontalAlignment(1);
				cellItemNm.setHorizontalAlignment(0);
				cellItemNum.setHorizontalAlignment(2);

				// 表の要素を表に追加する
				pdfPTable.addCell(cellId);
				pdfPTable.addCell(cellItemCd);
				pdfPTable.addCell(cellItemNm);
				pdfPTable.addCell(cellItemNum);

				itemRowCount++;
			}

			PdfPCell cellTotalItem = new PdfPCell(new Paragraph("合計", font));

			PdfPCell cellTotalItemNum = new PdfPCell(new Paragraph(
					String.valueOf(totalItemNum), font));
			cellTotalItem.setColspan(3); // セルを2列分結合

			cellTotalItem.setHorizontalAlignment(2);
			cellTotalItemNum.setHorizontalAlignment(2);

			// 表の要素を表に追加する
			pdfPTable.addCell(cellTotalItem);
			pdfPTable.addCell(cellTotalItemNum);

		}

		document.add(pdfPTable);
		document.close();

	}

	public void outPut(HttpServletResponse response, String filePath,
			String fname) throws Exception {

		OutputStream os = response.getOutputStream();

		try {

			// ファイル名に日本語を使う場合、以下の方法でファイル名を設定.
			byte[] sJis = fname.getBytes("Shift_JIS");
			fname = new String(sJis, "ISO8859_1");
			File fileOut = new File(fname);
			FileInputStream hFile = new FileInputStream(filePath);
			BufferedInputStream bis = new BufferedInputStream(hFile);

			// レスポンス設定
			response.setContentType("application/pdf");
			response.setHeader("Content-Disposition", "inline; filename=\""
					+ fileOut.getName() + "\"");

			int len = 0;
			byte[] buffer = new byte[1024];
			while ((len = bis.read(buffer)) >= 0) {
				os.write(buffer, 0, len);
			}

			bis.close();
		} catch (IOException e) {
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			return;
		} finally {

			if (os != null) {
				try {
					os.close();
				} catch (IOException e) {
					response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
					return;
				} finally {
					os = null;
				}
			}
		}
	}

	public int[] countKtsStocks(List<ExtendSalesSlipDTO> pickList) {

		int ktsStockCount = 0;

		int totalCount = 0;
		if (pickList != null) {
			totalCount = pickList.size();

			for (ExtendSalesSlipDTO slipDto : pickList) {

				// KTS倉庫から出庫予定の商品だけピッキングリストと納品書を出力する。
				if (slipDto.getRslLeaveFlag() == null || StringUtils.equals(slipDto.getRslLeaveFlag(), "0")) {
					ktsStockCount++;
				}
			}
		}

		//先頭要素：KTS伝票数、後要素：RSL伝票数
		int[] slipCountArray = new int[2];

		slipCountArray[0] = ktsStockCount;
		slipCountArray[1] = totalCount - ktsStockCount;
		return slipCountArray;
	}
}