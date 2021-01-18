<?xml version="1.0" encoding="UTF-8""?>
<!DOCTYPE html PUBLIC "-//W3C//Dtd XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html:html>
	<head>
	<jsp:include page="/WEB-INF/page/define/define-meta.jsp" />
		<title>売上原価入力</title>
	<link rel="stylesheet" href="./css/saleCostList.css" type="text/css" />
	<link rel="stylesheet" href="./css/jquery-ui-1.10.4.custom.min.css" type="text/css" />
	<link rel="stylesheet" href="./css/jquery-ui-1.10.4.custom.css" type="text/css" />
<!-- 	<script type="text/javascript" src="./js/prototype.js"></script> -->
	<script src="./js/jquery-1.10.2.min.js" language="javascript"></script>
	<script src="./js/jquery-ui-1.10.4.custom.min.js" language="javascript"></script>

	<script src="./js/jquery.ui.core.min.js"></script>
	<script src="./js/jquery.ui.datepicker.min.js"></script>
	<script src="./js/jquery.ui.datepicker-ja.min.js"></script>
	<script src="./js/validation.js" type="text/javascript"></script>

<!--
【売上原価一覧画面】
ファイル名：saleCostList.jsp
作成日：2015/12/21
作成者：大山智史

（画面概要）

助ネコ・新規売上登録で生成された売上商品データの検索/一覧画面。

・検索条件：伝票情報か商品情報で絞り込みが可能。検索結果一覧の表示件数も変更可能。
・検索結果：売上商品データ毎の表示。中央右に売上額/原価/粗利の集計。

・検索ボタン押下：設定された絞り込み項目をもとに検索処理を実行する。
・「一括編集する」ボタン押下：検索結果の売上原価一覧を編集可能な一括編集画面へ遷移する。
・行をダブルクリックまたは受注Noリンクをクリック：対象データの売上詳細画面に遷移する。

（注意・補足）

-->


	<script type="text/javascript">

	$(document).ready(function(){
		$(".overlay").css("display", "none");
	 });



	$(function() {

	     if($('.slipNoExist').prop('checked') || $('.slipNoHyphen').prop('checked')) {
	    	 $('.slipNoNone').attr('disabled','disabled');
	     }

		 if($('.slipNoNone').prop('checked')) {
		    	$('.slipNoExist').attr('disabled','disabled');
		    	$('.slipNoHyphen').attr('disabled','disabled');
		    }

		if ($("#sysSaleItemIDListSize").val() != 0) {
			var slipPageNum = Math.ceil($("#sysSaleItemIDListSize").val() / $("#saleListPageMax").val());

			$(".slipPageNum").text(slipPageNum);
			$(".slipNowPage").text(Number($("#pageIdx").val()) + 1);

			var i;

			if (0 == $("#pageIdx").val()) {
 				$(".pager > li:eq(3)").find("a").attr("class", "pageNum nowPage");
 				$(".underPager > li:eq(3)").find("a").attr("class", "pageNum nowPage");
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

		//アラート
		if (document.getElementById('alertType').value != '' && document.getElementById('alertType').value != '0') {
			actAlert(document.getElementById('alertType').value);
			document.getElementById('alertType').value = '0';
		}

	    $(".clear").click(function(){
	        $("#searchOptionArea input, #searchOptionArea select").each(function(){
	            if (this.type == "checkbox" || this.type == "radio") {
	                this.checked = false;
	            } else {
	                $(this).val("");
	            }
	        });
	    });

		$('.num').spinner( {
			max: 9999,
			min: 0,
			step: 1
		});

		$(".calender").datepicker();
		$(".calender").datepicker("option", "showOn", 'button');
		$(".calender").datepicker("option", "buttonImageOnly", true);
		$(".calender").datepicker("option", "buttonImage", './img/calender_icon.png');


		$('#searchOptionOpen').click(function () {

			if($('#searchOptionOpen').text() == "▼絞り込み") {
				$('#searchOptionOpen').text("▲隠す");
			} else {
				$('#searchOptionOpen').text("▼絞り込み");
			}

			$('#searchOptionArea').slideToggle("fast");
		});

		$('.td_editRemarks').dblclick(function() {
			var txt = $(this).text();
			$(this).html('<textarea rows="4" col="50" style="width: 150px;">'+ txt +'</textarea>');
			$('textarea').focus();
		});

		//売上詳細
		$(".salesSlipRow").dblclick(function () {

			$("#sysSalesSlipId").val($(this).find(".sysSalesSlipId").val());
			goTransaction("detailSale.do");
		});

		$(".salesSlipLink").click(function () {

			var id = $(this).find(".sysSalesSlipId_Link").val();
			$("#sysSalesSlipId").val(id);
			goTransaction("detailSale.do");
		});


		$(".pageNum").click (function () {

			if ($("#pageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#pageIdx").val($(this).text() - 1);
			goTransaction("saleCostListPageNo.do");
		});

		//次ページへ
		$("#nextPage").click (function () {

			var maxPage = new Number($(".slipPageNum").eq(0).text());
			if (Number($("#pageIdx").val()) + 1 >= maxPage) {
				alert("最終ページです");
				return;
			}
			$("#pageIdx").val(Number($("#pageIdx").val()) + 1);
			goTransaction("saleCostListPageNo.do");
		});

		//前ページへ
		$("#backPage").click (function () {

			if ($("#pageIdx").val() == 0) {
				alert("先頭ページです");
				return;
			}
			$("#pageIdx").val(Number($("#pageIdx").val()) - 1);
			goTransaction("saleCostListPageNo.do");
		});

//ページ送り（上側）
		//先頭ページへ
		$("#firstPage").click (function () {

			if ($("#pageIdx").val() == 0) {
				alert("先頭ページです");
				return;
			}

			if ($("#pageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#pageIdx").val(0);

			goTransaction("saleCostListPageNo.do");
		});

		//最終ページへ
		$("#lastPage").click (function () {

			var maxPage = new Number($(".slipPageNum").eq(0).text());
			if (Number($("#pageIdx").val()) + 1 >= maxPage) {
				alert("最終ページです");
				return;
			}

			if ($("#pageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#pageIdx").val(maxPage - 1);

			goTransaction("saleCostListPageNo.do");
		});

// ページ送り（下側）
		//次ページへ
		$("#underNextPage").click (function () {

			var maxPage = new Number($(".slipPageNum").eq(0).text());
			if (Number($("#pageIdx").val()) + 1 >= maxPage) {
				alert("最終ページです");
				return;
			}

			if ($("#pageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#pageIdx").val(Number($("#pageIdx").val()) + 1);

			goTransaction("saleCostListPageNo.do");
		});

		//前ページへ
		$("#underBackPage").click (function () {

			if ($("#pageIdx").val() == 0) {
				alert("先頭ページです");
				return;
			}
			$("#pageIdx").val(Number($("#pageIdx").val()) - 1);
			goTransaction("saleCostListPageNo.do");
		});

		//20140403 安藤　ここから
		//先頭ページへ
		$("#underFirstPage").click (function () {

			if ($("#pageIdx").val() == 0) {
				alert("先頭ページです");
				return;
			}

			if ($("#pageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#pageIdx").val(0);
			goTransaction("saleCostListPageNo.do");
		});

		//最終ページへ
		$("#underLastPage").click (function () {

			var maxPage = new Number($(".slipPageNum").eq(0).text());
			if (Number($("#pageIdx").val()) + 1 >= maxPage) {
				alert("最終ページです");
				return;
			}

			if ($("#pageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#pageIdx").val(maxPage - 1);
			goTransaction("saleCostListPageNo.do");
		});

		// 一括編集ボタン
		$(".editCostlist").click (function (){


			goTransaction("editsaleCost.do");

			return;
		});

//******************************************************************************************************
		$(".search").click (function () {

			if ($("#orderDateFrom").val() && $("#orderDateTo").val()){
				fromAry = $("#orderDateFrom").val().split("/");
				toAry = $("#orderDateTo").val().split("/");
				fromDt = new Date(fromAry[0], fromAry[1], fromAry[2]);
				toDt = new Date(toAry[0], toAry[1], toAry[2]);
				if (fromDt > toDt) {
					alert("注文日 の検索開始日付が、検索終了日付より後の日付になっています。");
					return false;
				}
			}

			if ($("#sumClaimPriceFrom").val() && $("#sumClaimPriceTo").val()) {
				if ($("#sumClaimPriceFrom").val() > $("#sumClaimPriceTo").val()) {
					alert("請求額 の検索開始金額が、検索終了金額より大きい額になっています。");
					return false;
				}
			}

			if ($("#destinationAppointDateFrom").val() && $("#destinationAppointDateTo").val()){
				fromAry = $("#destinationAppointDateFrom").val().split("/");
				toAry = $("#destinationAppointDateTo").val().split("/");
				fromDt = new Date(fromAry[0], fromAry[1], fromAry[2]);
				toDt = new Date(toAry[0], toAry[1], toAry[2]);
				if (fromDt > toDt) {
					alert("配送指定日 の検索開始日付が、検索終了日付より後の日付になっています。");
					return false;
				}
			}

			if ($("#shipmentPlanDateFrom").val() && $("#shipmentPlanDateTo").val()){
				fromAry = $("#shipmentPlanDateFrom").val().split("/");
				toAry = $("#shipmentPlanDateTo").val().split("/");
				fromDt = new Date(fromAry[0], fromAry[1], fromAry[2]);
				toDt = new Date(toAry[0], toAry[1], toAry[2]);
				if (fromDt > toDt) {
					alert("出荷予定日 の検索開始日付が、検索終了日付より後の日付になっています。");
					return false;
				}
			}

			if ($("#itemCodeFrom").val() && $("#itemCodeTo").val()) {
				if ($("#itemCodeFrom").val() > $("#itemCodeTo").val()) {
					alert("品番 の出力開始番号が、出力終了番号より大きい値になっています。");
					return false;
				}
			}

			$(".overlay").css("display", "block");
			$(".message").text("検索中");
			removeCommaList($(".priceTextMinus"));
			removeCommaGoTransaction('saleCostList.do');

		});


	});

	var count;
	function boxChecked(check) {
	  	for(count= 0; count < document.saleForm.pickingFinBox.length; count++) {
	  		document.saleForm.pickingFinBox[count].checked = check;
	  	}
	  }


	</script>
	</head>
	<jsp:include page="/WEB-INF/page/common/menu.jsp" />
	<html:form action="/initSaleCostList" enctype="multipart/form-data">
	<html:hidden property="alertType" styleId="alertType"></html:hidden>

	<h4 class="headingKind">売上原価入力</h4>

	<fieldset id="searchOptionField">
	<legend id="searchOptionOpen">▲隠す</legend>
	<div id="searchOptionArea">
	<nested:nest property="saleCostSearchDTO" >
		<table id="checkBoxTable" style="border-collapse: collapse;">
			<tr>
				<td colspan="2" class="flgCheck"><label><nested:checkbox property="pickingListFlg"/>ピッキングリスト出力済</label></td>
				<td class="arrow">→</td>
				<td class="flgCheck"><label><nested:checkbox property="leavingFlg"/>出庫済</label></td>
				<td class="pdg_left_30px"><label><nested:checkbox property="returnFlg"/>返品伝票</label></td>
			</tr>
			<tr>
				<td><label><nested:checkbox property="searchAllFlg" />全件表示</label></td>
				<td class="td_right slipNoLabel">伝票番号</td>
				<td class="slipNoCheckBoxTd"><label><nested:checkbox property="slipNoExist" styleClass="slipNoCheckBox slipNoExist" />有</label></td>
				<td class="slipNoCheckBoxTd"><label><nested:checkbox property="slipNoHyphen" styleClass="slipNoCheckBox slipNoHyphen" />ハイフン</label></td>
				<td class="slipNoNoneCheckBoxTd"><label><nested:checkbox property="slipNoNone" styleClass="slipNoCheckBox slipNoNone" />無</label></td>
			</tr>
		</table>

		<table id="rootTable">
			<tr>
				<td>法人</td>
				<td><nested:select property="sysCorporationId">
						<html:option value="0">　</html:option>
						<html:optionsCollection property="corporationList" label="corporationNm" value="sysCorporationId" />
					</nested:select>
				</td>
				<td class="td_center">処理ルート</td>
				<td colspan="3"><nested:select property="disposalRoute">
						<html:optionsCollection property="disposalRouteMap" label="value" value="key"/>
					</nested:select>
				</td>
			</tr>
			<tr>
				<td>販売チャネル</td>
				<td><nested:select property="sysChannelId" >
						<html:option value="0">　</html:option>
						<html:optionsCollection property="channelList" label="channelNm" value="sysChannelId" />
					</nested:select>
				</td>
			</tr>
		</table>

		<table id="costTable">
			<tr>
				<td>原価</td>
				<td><label><nested:checkbox property="costMakerItemFlg"/>メーカー品</label></td>
				<td><label><nested:checkbox property="costNoRegistry"/>原価未入力</label></td>
				<td><label><nested:checkbox property="costZeroRegistry"/>原価が0円</label></td>
			</tr>
			<tr>
				<td>原価確認</td>
				<td><label><nested:checkbox property="costNoCheckFlg"/>未確認</label></td>
				<td><label><nested:checkbox property="costCheckedFlg"/>確認済</label></td>
			</tr>
		</table>

		<table id="orderTable">
			<tr>
				<td>注文日</td>
				<td><nested:text property="orderDateFrom" styleId="orderDateFrom" styleClass="calender" maxlength="10" /> ～ <nested:text property="orderDateTo" styleId="orderDateTo" styleClass="calender" maxlength="10" /></td>
			</tr>
			<tr>
				<td>受注番号</td>
				<td><nested:text property="orderNo" styleClass="text_w250" maxlength="30" /></td>
			</tr>
			<tr>
				<td>注文者名</td>
				<td><nested:text property="orderNm" styleClass="text_w150" maxlength="30" /></td>
			</tr>
			<tr>
				<td>注文者TEL</td>
				<td><nested:text property="orderTel" styleClass="text_w150" maxlength="13" /></td>
			</tr>
			<tr>
				<td>注文者MAIL</td>
				<td><nested:text property="orderMailAddress" styleClass="text_w250" maxlength="256" /></td>
			</tr>
			<tr>
				<td>決済方法</td>
				<td><nested:select property="accountMethod">
					<html:optionsCollection property="accountMethodMap" label="value" value="key" />
				</nested:select></td>
			</tr>
			<tr>
				<td>請求額</td>
				<td><nested:text property="sumClaimPriceFrom" styleId="sumClaimPriceFrom" styleClass="text_w100 priceTextMinusSearch" maxlength="9" />&nbsp;円&nbsp;～&nbsp;<nested:text property="sumClaimPriceTo" styleId="sumClaimPriceTo" styleClass="text_w100 priceTextMinusSearch" maxlength="9" />&nbsp;円</td>
			</tr>
			<tr>
				<td>一言メモ</td>
				<td><nested:text property="memo" styleClass="text_w250" /><br/><span class="explain">※BO情報やYahooID等</span></td>
			</tr>
		</table>

		<div id="centerArea">

		<table id="deliveryTable">
			<tr>
				<td>運送会社</td>
				<td><nested:select property="transportCorporationSystem">
							<html:optionsCollection property="transportCorporationSystemMap" label="value" value="key"/>
					</nested:select>
				</td>
			</tr>
			<tr>
				<td>送り状番号</td>
				<td><nested:text property="slipNo" styleClass="text_w200" maxlength="30" /></td>
			</tr>
			<tr>
				<td>送り状種別</td>
				<td>
				<nested:select property="invoiceClassification">
				<html:optionsCollection property="invoiceClassificationMap" label="key" value="key"/>
				</nested:select></td>
			</tr>
			<tr>
				<td>配送指定日</td>
				<td><nested:text property="destinationAppointDateFrom" styleId="destinationAppointDateFrom" styleClass="calender" /> ～ <nested:text property="destinationAppointDateTo" styleId="destinationAppointDateTo" styleClass="calender" maxlength="10" />
			</tr>
			<tr>
				<td>出荷予定日</td>
				<td><nested:text property="shipmentPlanDateFrom" styleId="shipmentPlanDateFrom" styleClass="calender" maxlength="10" /> ～ <nested:text property="shipmentPlanDateTo" styleId="shipmentPlanDateTo" styleClass="calender" maxlength="10" /></td>
			</tr>
		</table>

		<table id="destinationTable">
			<tr>
				<td>届け先名</td>
				<td><nested:text property="destinationNm" styleClass="text_w150" maxlength="30" /></td>
			</tr>
			<tr>
				<td>届け先TEL</td>
				<td><nested:text property="destinationTel" styleClass="text_w150" maxlength="13" /></td>
			</tr>
		</table>

		</div>

		<table id="itemTable">
			<tr>
				<td>品番（前方一致）</td>
				<td><nested:text property="itemCode" styleClass="text_w120 numText" maxlength="11" /></td>
			</tr>
			<tr>
				<td>品番</td>
				<td><nested:text property="itemCodeFrom" styleId="itemCodeFrom" styleClass="text_w120 numText" maxlength="11" /> ～ <nested:text property="itemCodeTo" styleId="itemCodeTo" styleClass="text_w120 numText" maxlength="11" /></td>
			</tr>
			<tr>
				<td>他社品番（前方一致）</td>
				<td><nested:text property="salesItemCode" styleClass="text_w120" maxlength="30" /></td>
			</tr>
			<tr>
				<td>商品名</td>
				<td><nested:text property="itemNm" styleClass="text_w200" /></td>
			</tr>
			<tr>
				<td>他社商品名</td>
				<td><nested:text property="salesItemNm" styleClass="text_w200" /></td>
			</tr>
		</table>

		<table id="buttonTable">
			<tr>
				<td>並び順</td>
				<td>
					<nested:select property="sortFirst">
						<html:optionsCollection property="saleSearchMap" value="key" label="value" />
					</nested:select>
					<nested:select property="sortFirstSub">
						<html:optionsCollection property="saleSearchSortOrder" value="key" label="value" />
					</nested:select>
				</td>
			</tr>
			<tr>
				<td>表示件数</td>
				<td>
					<nested:select property="listPageMax">
						<html:optionsCollection property="salelistPageMaxMap" value="key" label="value" />
					</nested:select>&nbsp;件
				</td>
			</tr>
			<tr>
				<td colspan="2" style="padding: 10px 0 0 60px;"><a class="button_main search" href="javascript:void(0);" >検索</a></td>
				<td colspan="2" style="padding-top: 14px;"><a class="button_white clear" href="javascript:void(0);">リセット</a></td>
			</tr>
		</table>

	</nested:nest>
	</div>
	</fieldset>
	<nested:nest property="errorDTO">
	<nested:notEmpty property="errorMessage">
		<div id="errorArea">
			<p class="errorMessage"><nested:write property="errorMessage"/></p>
		</div>
	</nested:notEmpty>
	</nested:nest>

	<nested:notEmpty property="salesCostList">
	<div class="middleArea">
		<table class="editButtonTable">
			<tr>
				<td><a class="button_main editCostlist" href="Javascript:void(0);">一括編集する</a></td>
			</tr>
		</table>
	</div>



<!-- ページ(上側) -->

	<div class="paging_area">
		<div class="paging_total_top">
			<h3>全&nbsp;<nested:write property="sysSaleItemIDListSize" />&nbsp;件&nbsp;（&nbsp;<span class="slipNowPage" ></span>&nbsp;/&nbsp;<span class="slipPageNum"></span>&nbsp;ページ&nbsp;）</h3>
		</div>
		<div class="paging_num_top">
			<ul class="pager fr mb10">
			    <li class="backButton"><a href="javascript:void(0);" id="backPage" >&laquo;</a></li>
			    <li class="liFirstPage" ><a href="javascript:void(0);" id="firstPage" >1</a></li>
			    <li class="3dotLineTop"><span>...</span></li>
				<li><a href="javascript:void(0);" class="pageNum" ></a></li>
			  	<li class="3dotLineEnd"><span>...</span></li>
			    <li class="liLastPage" ><a href="javascript:void(0);" id="lastPage"  class="lastIdx" ></a></li>
			    <li class="nextButton"><a href="javascript:void(0);" id="nextPage" >&raquo;</a></li>
			</ul>
		</div>


<!-- ページ(上側)ここまで -->
	</div>

	<div id="list_area" >
	<input type="hidden" name="sysSalesSlipId" id="sysSalesSlipId" />
	<nested:hidden property="sysSaleItemIDListSize" styleId="sysSaleItemIDListSize" />
	<nested:hidden property="saleCostPageIdx" styleId="pageIdx" />
	<nested:hidden property="saleListPageMax" styleId="saleListPageMax" />
		<table class="list_table">
			<tr>
				<th class="saleSlipNo">伝票番号</th>
				<th class="corporationNm">取引先法人</th>
				<th class="shipmentPlanDate">出庫予定日</th>
				<th class="itemCode">品番</th>
				<th class="itemNm">商品名</th>
				<th class="orderNm">注文数</th>
				<th class="pieceRate">単価</th>
				<th class="corporationRateOverHd">法人掛け率</th>
				<th class="cost">原価(メーカー)</th>
				<th class="kindCost">Kind原価</th>
				<th class="listPrice">定価</th>
				<th class="itemRateOver">商品掛け率</th>
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

			<tbody style="background:${backgroundColor};" class="salesSlipRow change_color">
			<nested:hidden property="sysSalesSlipId" styleClass="sysSalesSlipId"></nested:hidden>
			<nested:hidden property="sysSalesItemId" styleClass="sysSalesItemId" />
			<tr>
				<td>
					<a href="Javascript:(void);" class="salesSlipLink" >
						<nested:write property="saleSlipNo" />
						<nested:hidden property="sysSalesSlipId" styleClass="sysSalesSlipId_Link"></nested:hidden>
					</a>
				</td>
				<td><nested:write property="corporationNm" /></td>
				<td><nested:write property="shipmentPlanDate" /></td>
				<td><nested:write property="itemCode" /></td>
				<td><nested:write property="itemNm" /></td>
				<td><nested:write property="orderNum" /></td>
				<td><nested:write property="pieceRate" format="###,###,###" />&nbsp;円</td>
				<td><nested:write property="corporationRateOver" />&nbsp;％</td>
				<td><nested:write property="cost" format="###,###,###" />&nbsp;円</td>
				<td><nested:write property="kindCost" format="###,###,###" />&nbsp;円</td>
				<td><nested:write property="listPrice" format="###,###,###" />&nbsp;円</td>
				<td><nested:write property="itemRateOver" />&nbsp;％</td>
				<td><nested:checkbox property="costCheckFlag" disabled="true" /></td>
			</tr>
			</tbody>
			</nested:iterate>
			</table>
		</div>

<!-- ページ(下側) 20140407 安藤 -->
		<div class="under_paging_area">
			<div class="paging_total_top">
				<h3>全&nbsp;<nested:write property="sysSaleItemIDListSize" />&nbsp;件&nbsp;（&nbsp;<span class="slipNowPage" ></span>&nbsp;/&nbsp;<span class="slipPageNum"></span>&nbsp;ページ&nbsp;）</h3>
			</div>
			<div class="paging_num_top">
				<ul class="pager fr mb10 underPager">
				    <li class="backButton"><a href="javascript:void(0);" id="underBackPage" >&laquo;</a></li>
				    <li class="liFirstPage" ><a href="javascript:void(0);" id="underFirstPage" >1</a></li>
				    <li class="3dotLineTop"><span>...</span></li>
					<li><a href="javascript:void(0);" class="pageNum" ></a></li>
				  	<li class="3dotLineEnd"><span>...</span></li>
				    <li class="liLastPage" ><a href="javascript:void(0);" id="underLastPage"  class="lastIdx" ></a></li>
				    <li class="nextButton"><a href="javascript:void(0);" id="underNextPage" >&raquo;</a></li>
				</ul>
			</div>
		</div>
<!-- ページ(下側)　ここまで -->

		</nested:notEmpty>


	</html:form>
	<div class="overlay">
		<div class="messeage_box">
			<h1 class="message">ファイル作成中</h1>
			<BR />
			<p>Now Loading...</p>
			<img  src="./img/load.gif" alt="loading" ></img>
				<BR />
				<BR />
				<BR />
		</div>
	</div>
</html:html>
