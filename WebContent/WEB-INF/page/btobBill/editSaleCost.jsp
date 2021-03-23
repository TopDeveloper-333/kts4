<?xml version="1.0" encoding="UTF-8""?>
<!DOCTYPE html PUBLIC "-//W3C//Dtd XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html:html>
<head>
<jsp:include page="/WEB-INF/page/define/define-meta.jsp" />
<title>売上原価一括編集</title>
<link rel="stylesheet" href="./css/saleCostListEdit.css" type="text/css" />
<link rel="stylesheet" href="./css/jquery-ui-1.10.4.custom.min.css"
	type="text/css" />
<link rel="stylesheet" href="./css/jquery-ui-1.10.4.custom.css"
	type="text/css" />
<!-- 	<script type="text/javascript" src="./js/prototype.js"></script> -->
<script src="./js/fw.js" type="text/javascript" type="text/javascript"></script>
<script src="./js/jquery-1.10.2.min.js" language="javascript"></script>
<script src="./js/jquery-ui-1.10.4.custom.min.js" language="javascript"></script>

<script src="./js/jquery.ui.core.min.js"></script>
<script src="./js/jquery.ui.datepicker.min.js"></script>
<script src="./js/jquery.ui.datepicker-ja.min.js"></script>
<script src="./js/validation.js" type="text/javascript"></script>

<!--
【売上原価一括編集画面】
ファイル名：editSaleCost.jsp
作成日：2015/12/28
作成者：大山智史

（画面概要）

助ネコ・新規売上登録で生成された売上商品データの検索/一覧画面。

・変更内容を保存：
・直近の原価を反映：
・一覧へ戻る：


（注意・補足）

-->


<script type="text/javascript">
	$(document).ready(function() {
		$(".overlay").css("display", "none");
		
		function calcCost(value1, value2) {

			var listPrice = parseFloat(value1);
			var nrateOver = parseFloat((value2) * 0.01);
			// それぞれの小数点の位置を取得
			var dotPosition1 = getDotPosition(listPrice);
			var dotPosition2 = getDotPosition(nrateOver);

			// 位置の値が大きい方（小数点以下の位が多い方）の位置を取得
			var max = Math.max(dotPosition1, dotPosition2);

			// 大きい方に小数の桁を合わせて文字列化、
			// 小数点を除いて整数の値にする
			var intValue1 = parseFloat((listPrice.toFixed(max) + '').replace('.', ''));
			var intValue2 = parseFloat((nrateOver.toFixed(max) + '').replace('.', ''));

			// 10^N の値を計算
			if (max == 1) {
				max = max + 1;
			} else {
				max = max * 2;
			}
			var power = Math.pow(10, max);

			// 整数値で引き算した後に10^Nで割る
			return [ intValue1, intValue2, power ];

		}

		//小数点の位置を探るメソッド
		function getDotPosition(value) {

			// 数値のままだと操作できないので文字列化する
			var strVal = String(value);
			var dotPosition = 0;

			//小数点が存在するか確認
			// 小数点があったら位置を取得
			if (strVal.lastIndexOf('.') !== -1) {
				dotPosition = (strVal.length - 1) - strVal.lastIndexOf('.');
			}

			return dotPosition;
		}
		
		
		$(".domePostage").change(function() {
			  console.log("Input text changed!");
		});
		
		$('.profitId').each(function(profit){
			var val = removeComma($(this).text());
			val = parseInt(val);
	        
			var color = '';
			if(val < 0 ){
				color = "red";
			}else if(val > 800){
				color = "white";
			}else {
				color = "orange";
			}
			$(this).attr('style', 'background-color:'+color+';');
			
			
			var index = $('.profitId').index(this);

			var listPrice = removeComma($(".listPrice").eq(index).val());
			
			// 掛け率取得
			var rateOver = removeComma($(".itemRateOver").eq(index).val());

			// 送料取得
			var postage = removeComma($(".domePostage").eq(index).val());

			// 法人掛け率取得
			var cRateOver = $(".corporationRateOver").eq(index).val();
			if (cRateOver == "") {
				cRateOver = 0;
			}

			// カンマを除去
			listPrice = removeComma(listPrice);
			rateOver = removeComma(rateOver);
			postage = removeComma(postage);
			cRateOver = removeComma(cRateOver);

			if(parseInt(listPrice) == 0)	return;
			if(parseInt(rateOver) == 0)	return;

			// カインドコストの計算処理
			// 定価と掛率に0.01を掛けた数値でカインドコストを算出する。
			var kindCostArray = calcCost(parseInt(listPrice), parseFloat(rateOver)); /// return [intValue1, intValue2, power]
			var tempKindCost = (kindCostArray[0] * kindCostArray[1]) / kindCostArray[2];

			var kindDot = tempKindCost % 10;
			if(kindDot > 0)	tempKindCost = parseInt(tempKindCost) + parseInt(1);
			
			var kindCost = parseInt(tempKindCost);

			$('.kindCost').eq(index).val(kindCost);
			addComma($(".kindCost").eq(index).val());			
			// 原価の計算処理
			// 掛率と法人掛率で定価用の掛率を算出する。
			var rate = parseFloat(rateOver) + parseFloat(cRateOver);

			// 定価と定価用の掛け率から原価（メーカー）を算出
			var costArray = calcCost(listPrice, rate);
			
			var tempCost = (costArray[0] * costArray[1]) / costArray[2];
			
			var dot = tempCost % 10;
			if(dot > 0)	tempCost = parseInt(tempCost) + parseInt(1);
			
			var cost = parseInt(tempCost);

			$('.cost').eq(index).val(cost);
			addComma($(".cost").eq(index).val());			

			// 単価取得
			var pieceRate = $(".pieceRateHidden").eq(index).val();
			if (pieceRate == "") {
				pieceRate = 0;
			}
			
			pieceRate = parseInt(pieceRate);
			
			var storeFlag = $(".storeFlag").eq(index).val();
			
			var profit = parseInt(cost) - parseInt(kindCost);

			var color = '';
			if(profit < 0 ){
				color = "red";
			}else if(profit > 800){
				color = "white";
			}else {
				color = "orange";
			}
			profit = new String(profit).replace(/,/g, "");
			while (profit != (profit = profit.replace(/^(-?\d+)(\d{3})/, "$1,$2")));
			
			$(this).html(profit + "&nbsp;円");
			$(this).attr('style', 'background-color:'+color+';');
						
	    });		
	});

	$(function() {

		if ($("#sysSaleItemIDListSize").val() != 0) {
			var slipPageNum = Math.ceil($("#sysSaleItemIDListSize").val()
					/ $("#saleListPageMax").val());

			$(".slipPageNum").text(slipPageNum);
			$(".slipNowPage").text(Number($("#pageIdx").val()) + 1);

			var i;

			if (0 == $("#pageIdx").val()) {
				$(".pager > li:eq(3)").find("a").attr("class",
						"pageNum nowPage");
				$(".underPager > li:eq(3)").find("a").attr("class",
						"pageNum nowPage");
			}

			var startIdx;
			// maxDispは奇数で入力
			var maxDisp = 7;
			// slipPageNumがmaxDisp未満の場合maxDispの値をslipPageNumに変更
			if (slipPageNum < maxDisp) {

				maxDisp = slipPageNum;

			}

			var center = Math.ceil(Number(maxDisp) / 2);
			var pageIdx = new Number($("#pageIdx").val());

			// 現在のページが中央より左に表示される場合
			if (center >= pageIdx + 1) {
				startIdx = 1;
				$(".lastIdx").html(slipPageNum);
				$(".liFirstPage").hide();

				// 現在のページが中央より右に表示される場合
			} else if (slipPageNum - (center - 1) <= pageIdx + 1) {

				startIdx = slipPageNum - (maxDisp - 1);
				$(".liLastPage").hide();
				$(".3dotLineEnd").hide();

				// 現在のページが中央に表示される場合
			} else {

				startIdx = $("#pageIdx").val() - (center - 2);
				$(".lastIdx").html(slipPageNum);

			}

			$(".salesSlipLink").click(function () {

				var id = $(this).find(".sysSalesSlipId_Link").val();
				$("#sysSalesSlipId").val(id);
				
				FwGlobal.submitForm(document.forms[0],"/detailSale","detailSale" + $("#sysSalesSlipId").val(),"top=130,left=500,width=780px,height=520px;");

			});

			$(".itemCodeLink").click(function () {

				var value = $(this).find(".itemCode").val();
				
				$("#managementCode").val(value);

				goTransactionNew("searchDomesticExhibition.do");
			});

			$(".pageNum").html(startIdx);
			var endIdx = startIdx + (maxDisp - 1);

			if (startIdx <= 2) {

				$(".3dotLineTop").hide();

			}

			if ((slipPageNum <= 8) || ((slipPageNum - center) <= (pageIdx + 1))) {

				$(".3dotLineEnd").hide();

			}

			if (slipPageNum <= maxDisp) {

				$(".liLastPage").hide();
				$(".liFirstPage").hide();

			}

			for (i = startIdx; i < endIdx && i < slipPageNum; i++) {
				var clone = $(".pager > li:eq(3)").clone();
				clone.children(".pageNum").text(i + 1);

				if (i == $("#pageIdx").val()) {

					clone.find("a").attr("class", "pageNum nowPage");

				} else {
					clone.find("a").attr("class", "pageNum");
				}

				$(".pager > li.3dotLineEnd").before(clone);
			}
		}
		//******************************************************************************************************

		//商品掛け率
		$(".priceTextRateOver").blur(function() {

			if ($(this).val() == "") {
				$(this).val(0);
				return;
			}
			if (!numberFloatCheck(this)) {
				$(this).val(0);
				return;
			}
			var numList = $(this).val().split(".");
			if (numList[0].length > 2 || numList[1].length > 2) {
				alert("商品掛け率の桁数が多いです。");
				$(this).val(0);
				return;
			}
		});

		//アラート
		if (document.getElementById('alertType').value != ''
				&& document.getElementById('alertType').value != '0') {
			actAlert(document.getElementById('alertType').value);
			document.getElementById('alertType').value = '0';
		}

		// 変更内容を保存
		$(".saveSaleCost").click(function() {

			if (confirm("変更を反映させます。よろしいですか？")) {
				removeCommaGoTransaction("saveSaleCost.do");
			}
			return;
		});

		// 直近の原価を反映
		$(".reflectLatestSaleCostCost").click(function() {

			// 一覧のインデックスを設定
			$("#listIdx").val($(".reflectLatestSaleCostCost").index(this));

			goTransaction("reflectLatestSaleCostCost.do");

			return;
		});

		// 入力した原価で金額算出
		$(".calcSaleCost")
				.click(
						function() {

							// 一覧のインデックスを設定
							var index = $(".calcSaleCost").index(this);

							// 定価取得
							var listPrice = $(".listPrice").eq(index).val();
							
							if (listPrice == 0 || listPrice == "") {
								alert("定価が設定されていません。");
								return;
							}

							// 掛け率取得
							var rateOver = $(".itemRateOver").eq(index).val();
							if (rateOver == 0 || rateOver == "") {
								alert("掛け率が設定されていません。");
								return;
							}

							// 送料取得
							var postage = $(".domePostage").eq(index).val();
							$(".domePostageKind").eq(index).val(postage);

							// 法人掛け率取得
							var cRateOver = $(".corporationRateOver").eq(index)
									.val();
							if (cRateOver == "") {
								cRateOver = 0;
							}

							// カンマを除去
							listPrice = removeComma(listPrice);
							rateOver = removeComma(rateOver);
							postage = removeComma(postage);
							cRateOver = removeComma(cRateOver);

							// カインドコストの計算処理
							// 定価と掛率に0.01を掛けた数値でカインドコストを算出する。
							var kindCostArray = calcCost(listPrice, rateOver); /// return [intValue1, intValue2, power]
							var tempKindCost = (kindCostArray[0] * kindCostArray[1]) / kindCostArray[2];
							
							var kindDot = tempKindCost % 10;
							if(kindDot > 0)	tempKindCost = parseInt(tempKindCost) + parseInt(1);
							
							var kindCost = parseInt(tempKindCost);

							$(".kindCost").eq(index).val(kindCost);
							addComma($(".kindCost").eq(index).val());

							// 原価の計算処理
							// 掛率と法人掛率で定価用の掛率を算出する。
							var rate = parseFloat(rateOver) + parseFloat(cRateOver);

							// 定価と定価用の掛け率から原価（メーカー）を算出
							var costArray = calcCost(listPrice, rate);
							
							var tempCost = (costArray[0] * costArray[1]) / costArray[2];
							
							var dot = tempCost % 10;
							if(dot > 0)	tempCost = parseInt(tempCost) + parseInt(1);
							
							var cost = parseInt(tempCost);

							$(".cost").eq(index).val(cost);
							addComma($(".cost").eq(index).val());
							
							
							// 単価取得
							var pieceRate = $(".pieceRateHidden").eq(index).val();
							if (pieceRate == "") {
								pieceRate = 0;
							}
							var storeFlag = $(".storeFlag").eq(index).val();
							
							var profit = parseInt(cost) - parseInt(kindCost);

							var color = '';
							if(profit < 0 ){
								color = "red";
							}else if(profit > 800){
								color = "white";
							}else {
								color = "orange";
							}
							profit = new String(profit).replace(/,/g, "");
							while (profit != (profit = profit.replace(/^(-?\d+)(\d{3})/, "$1,$2")));
							
							$('.profitId').eq(index).html(profit + "&nbsp;円");
							$('.profitId').eq(index).attr('style', 'background-color:'+color+';');
							return;

						});

		//Kind原価の計算メソッド (引数：定価、掛率)
		function calcCost(value1, value2) {

			var listPrice = parseFloat(value1);
			var nrateOver = parseFloat((value2) * 0.01);
			// それぞれの小数点の位置を取得
			var dotPosition1 = getDotPosition(listPrice);
			var dotPosition2 = getDotPosition(nrateOver);

			// 位置の値が大きい方（小数点以下の位が多い方）の位置を取得
			var max = Math.max(dotPosition1, dotPosition2);

			// 大きい方に小数の桁を合わせて文字列化、
			// 小数点を除いて整数の値にする
			var intValue1 = parseFloat((listPrice.toFixed(max) + '').replace('.', ''));
			var intValue2 = parseFloat((nrateOver.toFixed(max) + '').replace('.', ''));

			// 10^N の値を計算
			if (max == 1) {
				max = max + 1;
			} else {
				max = max * 2;
			}
			var power = Math.pow(10, max);

			// 整数値で引き算した後に10^Nで割る
			return [ intValue1, intValue2, power ];

		}

		//小数点の位置を探るメソッド
		function getDotPosition(value) {

			// 数値のままだと操作できないので文字列化する
			var strVal = String(value);
			var dotPosition = 0;

			//小数点が存在するか確認
			// 小数点があったら位置を取得
			if (strVal.lastIndexOf('.') !== -1) {
				dotPosition = (strVal.length - 1) - strVal.lastIndexOf('.');
			}

			return dotPosition;
		}

		// 原価メーカのカーソルキー移動
		$(".cost").keyup(function(e) {
			// 一覧のインデックスを設定
			var index = $(".cost").index(this);
			switch (e.which) {
			case 39: // [→]
				$(".kindCost").eq(index).focus();
				$(".kindCost").eq(index).select();
				break;
			case 37: // [←]
				index--;
				$(".calcSaleCost").eq(index).focus();
				break;
			case 38: // [↑]
				index--;
				$(".cost").eq(index).focus();
				$(".cost").eq(index).select();
				break;
			case 40: // [↓]
				index++;
				$(".cost").eq(index).focus();
				$(".cost").eq(index).select();
				break;
			}
		});

		// Kind原価のカーソルキー移動
		$(".kindCost").keyup(function(e) {
			// 一覧のインデックスを設定
			var index = $(".kindCost").index(this);
			switch (e.which) {
			case 39: // [→]
				$(".listPrice").eq(index).focus();
				$(".listPrice").eq(index).select();
				break;
			case 37: // [←]
				$(".cost").eq(index).focus();
				$(".cost").eq(index).select();
				break;
			case 38: // [↑]
				index--;
				$(".kindCost").eq(index).focus();
				$(".kindCost").eq(index).select();
				break;
			case 40: // [↓]
				index++;
				$(".kindCost").eq(index).focus();
				$(".kindCost").eq(index).select();
				break;
			}
		});

		// 定価のカーソルキー移動
		$(".listPrice").keyup(function(e) {
			// 一覧のインデックスを設定
			var index = $(".listPrice").index(this);
			switch (e.which) {
			case 39: // [→]
				$(".itemRateOver").eq(index).focus();
				$(".itemRateOver").eq(index).select();
				break;
			case 37: // [←]
				$(".kindCost").eq(index).focus();
				$(".kindCost").eq(index).select();
				break;
			case 38: // [↑]
				index--;
				$(".listPrice").eq(index).focus();
				$(".listPrice").eq(index).select();
				break;
			case 40: // [↓]
				index++;
				$(".listPrice").eq(index).focus();
				$(".listPrice").eq(index).select();
				break;
			}
		});

		// 商品掛け率のカーソルキー移動
		$(".itemRateOver").keyup(function(e) {
			// 一覧のインデックスを設定
			var index = $(".itemRateOver").index(this);
			switch (e.which) {
			case 39: // [→]
				$(".calcSaleCost").eq(index).focus();
				break;
			case 37: // [←]
				$(".listPrice").eq(index).focus();
				$(".listPrice").eq(index).select();
				break;
			case 38: // [↑]
				index--;
				$(".itemRateOver").eq(index).focus();
				$(".itemRateOver").eq(index).select();
				break;
			case 40: // [↓]
				index++;
				$(".itemRateOver").eq(index).focus();
				$(".itemRateOver").eq(index).select();
				break;
			}
		});

		// 算出のカーソルキー移動
		$(".calcSaleCost").keyup(function(e) {
			// 一覧のインデックスを設定
			var index = $(".calcSaleCost").index(this);
			switch (e.which) {
			case 39: // [→]
				index++;
				$(".cost").eq(index).focus();
				$(".cost").eq(index).select();
				break;
			case 37: // [←]
				$(".itemRateOver").eq(index).focus();
				break;
			case 38: // [↑]
				index--;
				$(".calcSaleCost").eq(index).focus();
				break;
			case 40: // [↓]
				index++;
				$(".calcSaleCost").eq(index).focus();
				break;
			}
		});

	});
</script>
</head>
<jsp:include page="/WEB-INF/page/common/menu.jsp" />
<html:form action="/initSaleCostList" enctype="multipart/form-data">
	<html:hidden property="alertType" styleId="alertType"></html:hidden>

	<h4 class="headingKind">売上原価一括編集</h4>
	<nested:nest property="errorDTO">
		<nested:notEmpty property="errorMessage">
			<div id="errorArea">
				<p class="errorMessage">
					<nested:write property="errorMessage" />
				</p>
			</div>
		</nested:notEmpty>
	</nested:nest>

	<div class="middleArea">
		<table class="editButtonTable">
			<tr>
				<td><a class="button_main saveSaleCost"
					href="Javascript:void(0);" tabindex="-1">変更内容を保存</a></td>
				<td><a class="button_white" href="javascript: void(0);"
					onclick="goTransaction('saleCostListPageNo.do');" tabindex="-1">一覧へ戻る</a></td>
			</tr>
		</table>
	</div>




	<div id="list_area">
		<input type="hidden" name="sysSalesSlipId" id="sysSalesSlipId" />
		<nested:hidden property="sysSaleItemIDListSize"
			styleId="sysSaleItemIDListSize" />
		<nested:hidden property="saleCostPageIdx" styleId="pageIdx" />
		<nested:hidden property="saleListPageMax" styleId="saleListPageMax" />
		<nested:hidden property="saleCostListIdx" styleId="listIdx" />
		<table class="list_table">
			<tr>
				<th class="saleSlipNo">伝票番号</th>
				<th class="corporationNm">取引先法人</th>
				<th class="shipmentPlanDate">出庫予定日</th>
				<th class="itemCode">品番</th>
				<th class="itemNm" style="width:250px; max-width:250px">商品名</th>
				<th class="orderNm">注文数</th>
				<th class="pieceRate">単価</th>
				<th class="corporationRateOverHd">法人掛け率</th>
				<th class="costHd">原価(メーカー)</th>
				<th class="domePostageHd">送料</th>
				<th class="kindCostHd">Kind原価</th>
				<th class="listPriceHd">定価</th>
				<th class="domePostageHd">送料</th>
				<th class="itemRateOverHd">商品掛け率</th>
				<th class="calcHd">入力した定価で<br />金額算出
				</th>
				<th class="reflectHd">直近の原価を<br />反映
				</th>
				<th class="profitHd">利益判定</th>
				<th class="check">確認</th>
			</tr>

			<nested:iterate property="salesCostList" indexId="idx">

				<!-- 		マスタにない商品 -->
				<nested:notEqual property="sysItemId" value="0">
					<bean:define id="backgroundColor" value="" />
				</nested:notEqual>
				<nested:equal property="sysItemId" value="0">
					<bean:define id="backgroundColor" value="#FFFFC0" />
				</nested:equal>

				<tbody style="background:${backgroundColor};"
					class="salesSlipRow change_color_only">
			<nested:hidden property="sysSalesSlipId" styleClass="sysSalesSlipId"></nested:hidden>
					<nested:hidden property="sysSalesItemId"
						styleClass="sysSalesItemId" />
					<nested:hidden property="storeFlag"
						styleClass="storeFlag" />
					<nested:hidden property="pieceRate"
						styleClass="pieceRateHidden" />
					<tr>
						<td>
							<a href="Javascript:(void);" class="salesSlipLink" >
								<nested:write property="saleSlipNo" />
								<nested:hidden property="sysSalesSlipId" styleClass="sysSalesSlipId_Link"></nested:hidden>
							</a>
						</td>
						<td><nested:write property="corporationNm" /></td>
						<td><nested:write property="shipmentPlanDate" /></td>
						<td>
							<a href="Javascript:(void);" class="itemCodeLink" >
								<nested:write property="itemCode" />
								<input type="hidden" name="managementCode" id="managementCode">
								<nested:hidden property="itemCode" styleClass="itemCode"></nested:hidden>
							</a>
						
						</td>
						<td><nested:write property="itemNm" /></td>
						<td><nested:write property="orderNum" /></td>
						<td><nested:write property="pieceRate" format="###,###,###" />&nbsp;円</td>
						<td><nested:write property="corporationRateOver" />&nbsp;％ <nested:hidden
								property="corporationRateOver" styleClass="corporationRateOver" />
						</td>
						<td><nested:text property="cost" styleClass="priceText cost"
								style="width: 80px; text-align: right;" maxlength="9" />&nbsp;円</td>
						<td><nested:text property="domePostage"
								styleClass="priceText domePostage"
								style="width: 80px; text-align: right;" maxlength="9" />&nbsp;円</td>
						<td><nested:text property="kindCost"
								styleClass="priceText kindCost"
								style="width: 80px; text-align: right;" maxlength="9" />&nbsp;円</td>
						<td><nested:text property="listPrice"
								styleClass="priceText listPrice"
								style="width: 80px; text-align: right;" maxlength="9" />&nbsp;円</td>
						<td><nested:text property="domePostage"
								styleClass="priceText domePostageKind"
								style="width: 80px; text-align: right;" maxlength="9" />&nbsp;円</td>
						<td><nested:text property="itemRateOver"
								styleClass="priceTextRateOver itemRateOver"
								style="width: 80px; text-align: right;" maxlength="9" />&nbsp;％</td>
						<td class="tdButton"><a href="Javascript:void(0);"
							class="button_small_main calcSaleCost">算出</a></td>
						<td class="tdButton"><a href="Javascript:void(0);"
							class="button_small_main reflectLatestSaleCostCost" tabindex="-1">反映</a></td>
						<td class="profitId"><nested:write property="profit" format="###,###,###" />&nbsp;円</td>
						<td><nested:checkbox property="costCheckFlag"
								styleClass="costCheckFlag" /></td>
						<nested:hidden property="costCheckFlag" value="off" />
					</tr>
				</tbody>
			</nested:iterate>
		</table>
	</div>

	<footer class="footer buttonArea">
	<ul style="position: relative;">
		<li class="footer_button"><a class="button_main saveSaleCost"
			href="Javascript:void(0);" tabindex="-1">変更内容を保存</a></li>
		<li class="footer_button"><a class="button_white"
			href="javascript: void(0);"
			onclick="goTransaction('saleCostListPageNo.do');" tabindex="-1">一覧へ戻る</a>
		</li>
	</ul>
	</footer>


</html:form>
</html:html>
