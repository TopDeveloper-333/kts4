<?xml version="1.0" encoding="UTF-8""?>
<!DOCTYPE html PUBLIC "-//W3C//Dtd XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html:html>
	<head>
	<title>業販原価入力</title>
	<jsp:include page="/WEB-INF/page/define/define-meta.jsp" />
	<link rel="stylesheet" href="./css/corporateSaleCostList.css" type="text/css" />
	<link rel="stylesheet" href="./css/jquery-ui-1.10.4.custom.min.css" type="text/css" />
	<link rel="stylesheet" href="./css/jquery-ui-1.10.4.custom.css" type="text/css" />
	<link rel="stylesheet" href="./css/font-awesome.min.css"/>
<!-- 	<script type="text/javascript" src="./js/prototype.js"></script> -->
	<script src="./js/jquery-1.10.2.min.js" language="javascript"></script>
	<script src="./js/jquery-ui-1.10.4.custom.min.js" language="javascript"></script>

	<script src="./js/jquery.ui.core.min.js"></script>
	<script src="./js/jquery.ui.datepicker.min.js"></script>
	<script src="./js/jquery.ui.datepicker-ja.min.js"></script>
	<script src="./js/validation.js" type="text/javascript"></script>
	<script src="./js/shortcut.js"></script>

<!--
【業販原価一覧画面】
ファイル名：corporateSaleCostList.jsp
作成日：2016/01/04
作成者：髙桑

（画面概要）


業販原価データの検索/一覧画面。
・行ダブルクリック：詳細画面に遷移する。
・商品毎のピッキングリスト出力済みフラグは、画面から操作、更新が可能。




（注意・補足）

-->
	<script>
	$(document).ready(function(){
		$(".overlay").css("display", "none");

		// 法人リンクの選択文字
		$("#corpLink<bean:write name="btobBillForm" property="corpSaleCostSearchDTO.sysCorporationId" />").removeAttr("href");
		$("#corpLink<bean:write name="btobBillForm" property="corpSaleCostSearchDTO.sysCorporationId" />").parents("li").attr("class", "corp");
		$("#corpLink<bean:write name="btobBillForm" property="corpSaleCostSearchDTO.sysCorporationId" />").attr("class", "selected");
	});

	$(function() {
		//アラート
		if (document.getElementById('alertType').value != '' && document.getElementById('alertType').value != '0') {
			actAlert(document.getElementById('alertType').value);
			document.getElementById('alertType').value = '0';
		}

		for (var i = 1; i <= 9; i++) {
			shortcut.add("Alt+" + i, function(e){
				$("#sysCorporationId").val(Number(e.keyCode) - 48);
				goTransaction("initRegistryCorporateSales.do");
			});
		}

		pickingListFlgChange = 0;

	    $(".clear").click(function(){
	        $("#searchOptionArea input, #searchOptionArea select").each(function(){
	            if (this.type == "checkbox" || this.type == "radio") {
	                this.checked = false;
	            } else {
	                $(this).val("");
	            }
	        });
	        $(".slipStatus").eq(0).prop("checked", true);
	        $(".pickingListFlg").eq(0).prop("checked", true);
	        $(".leavingFlg").eq(0).prop("checked", true);
	    });
		$('#searchOptionOpen').click(function () {

			if($('#searchOptionOpen').text() == "▼検索") {
				$('#searchOptionOpen').text("▲隠す");
			} else {
				$('#searchOptionOpen').text("▼検索");
			}

			$('#searchOptionArea').slideToggle("fast");
		});

		$(".calender").datepicker();
		$(".calender").datepicker("option", "showOn", 'button');
		$(".calender").datepicker("option", "buttonImageOnly", true);
		$(".calender").datepicker("option", "buttonImage", './img/calender_icon.png');

		$(".nyukin").children("a").click(function(){
			$(this).hide();
			$(this).parent().append("<input type='text' class='nyukingaku' />");
		});

		//法人メニュー開閉
		$(".corptgl").click(function(){
			$(this).parent(".corp").find(".corpmenu").toggle();
		});



//******************************************************************************************************
	     if($('.slipNoExist').prop('checked') || $('.slipNoHyphen').prop('checked')) {
	    	 $('.slipNoNone').attr('disabled','disabled');
	     }

		 if($('.slipNoNone').prop('checked')) {
		    	$('.slipNoExist').attr('disabled','disabled');
		    	$('.slipNoHyphen').attr('disabled','disabled');
		    }

//******************************************************************************************************
		if ($("#sysCorprateSaleItemIDListSize").val() != 0) {
			var slipPageNum = Math.ceil($("#sysCorprateSaleItemIDListSize").val() / $("#corpSaleListPageMax").val());

			$(".slipPageNum").text(slipPageNum);
			$(".slipNowPage").text(Number($("#corpSaleCostPageIdx").val()) + 1);

			var i;

			if (0 == $("#corpSaleCostPageIdx").val()) {
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
			var corpSaleCostPageIdx = new Number($("#corpSaleCostPageIdx").val());

			// 現在のページが中央より左に表示される場合
			if (center >= corpSaleCostPageIdx + 1) {
				startIdx = 1;
				$(".lastIdx").html(slipPageNum);
				$(".liFirstPage").hide();

			// 現在のページが中央より右に表示される場合
			} else if (slipPageNum - (center - 1) <= corpSaleCostPageIdx + 1) {

				startIdx = slipPageNum - (maxDisp - 1);
				$(".liLastPage").hide();
				$(".3dotLineEnd").hide();

			// 現在のページが中央に表示される場合
			} else {

				startIdx = $("#corpSaleCostPageIdx").val() - (center - 2);
				$(".lastIdx").html(slipPageNum);

			}

			$(".pageNum").html(startIdx);
			var endIdx = startIdx + (maxDisp - 1);

			if (startIdx <= 2) {

 				$(".3dotLineTop").hide();

 			}

			if ((slipPageNum <= 8) || ((slipPageNum - center) <= (corpSaleCostPageIdx + 1))) {

				$(".3dotLineEnd").hide();

			}

			if (slipPageNum <= maxDisp) {

				$(".liLastPage").hide();
				$(".liFirstPage").hide();

			}


			for (i = startIdx; i < endIdx && i < slipPageNum; i++) {
				var clone = $(".pager > li:eq(3)").clone();
				clone.children(".pageNum").text(i + 1);

				if (i == $("#corpSaleCostPageIdx").val()) {

					clone.find("a").attr("class", "pageNum nowPage");

				} else {
					clone.find("a").attr("class", "pageNum");
				}

 				$(".pager > li.3dotLineEnd").before(clone);
			}
		}
//******************************************************************************************************
		$(".pageNum").click (function () {

			if ($("#corpSaleCostPageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#corpSaleCostPageIdx").val($(this).text() - 1);
			goTransaction("corporateSaleCostListPageNo.do");
		});

		//次ページへ
		$("#nextPage").click (function () {

			var maxPage = new Number($(".slipPageNum").eq(0).text());
			if (Number($("#corpSaleCostPageIdx").val()) + 1 >= maxPage) {
				alert("最終ページです");
				return;
			}
			$("#corpSaleCostPageIdx").val(Number($("#corpSaleCostPageIdx").val()) + 1);
			goTransaction("corporateSaleCostListPageNo.do");
		});

		//前ページへ
		$("#backPage").click (function () {

			if ($("#corpSaleCostPageIdx").val() == 0) {
				alert("先頭ページです");
				return;
			}
			$("#corpSaleCostPageIdx").val(Number($("#corpSaleCostPageIdx").val()) - 1);
			goTransaction("corporateSaleCostListPageNo.do");
		});

//ページ送り（上側）
		//先頭ページへ
		$("#firstPage").click (function () {

			if ($("#corpSaleCostPageIdx").val() == 0) {
				alert("先頭ページです");
				return;
			}

			if ($("#corpSaleCostPageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#corpSaleCostPageIdx").val(0);

			goTransaction("corporateSaleCostListPageNo.do");
		});

		//最終ページへ
		$("#lastPage").click (function () {

			var maxPage = new Number($(".slipPageNum").eq(0).text());
			if (Number($("#corpSaleCostPageIdx").val()) + 1 >= maxPage) {
				alert("最終ページです");
				return;
			}

			if ($("#corpSaleCostPageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#corpSaleCostPageIdx").val(maxPage - 1);

			goTransaction("corporateSaleCostListPageNo.do");
		});

// ページ送り（下側）
		//次ページへ
		$("#underNextPage").click (function () {

			var maxPage = new Number($(".slipPageNum").eq(0).text());
			if (Number($("#corpSaleCostPageIdx").val()) + 1 >= maxPage) {
				alert("最終ページです");
				return;
			}

			if ($("#corpSaleCostPageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#corpSaleCostPageIdx").val(Number($("#corpSaleCostPageIdx").val()) + 1);

			goTransaction("corporateSaleCostListPageNo.do");
		});

		//前ページへ
		$("#underBackPage").click (function () {

			if ($("#corpSaleCostPageIdx").val() == 0) {
				alert("先頭ページです");
				return;
			}
			$("#corpSaleCostPageIdx").val(Number($("#corpSaleCostPageIdx").val()) - 1);
			goTransaction("corporateSaleCostListPageNo.do");
		});

		//20140403 安藤　ここから
		//先頭ページへ
		$("#underFirstPage").click (function () {

			if ($("#corpSaleCostPageIdx").val() == 0) {
				alert("先頭ページです");
				return;
			}

			if ($("#corpSaleCostPageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#corpSaleCostPageIdx").val(0);
			goTransaction("corporateSaleCostListPageNo.do");
		});

		//最終ページへ
		$("#underLastPage").click (function () {

			var maxPage = new Number($(".slipPageNum").eq(0).text());
			if (Number($("#corpSaleCostPageIdx").val()) + 1 >= maxPage) {
				alert("最終ページです");
				return;
			}

			if ($("#corpSaleCostPageIdx").val() == ($(this).text() - 1)) {

				return;

			}

			$("#corpSaleCostPageIdx").val(maxPage - 1);
			goTransaction("corporateSaleCostListPageNo.do");
		});

//******************************************************************************************************


		$(".search").click (function () {

			$("#searchPreset").val(0);
			$(".overlay").css("display", "block");
			$(".message").text("検索中");
			removeCommaList($(".priceTextMinus"));
			removeCommaGoTransaction('corporateSaleCostList.do');
		});

		//売上詳細
		$(".corporateSalesSlipRow").dblclick(function () {

			$("#sysCorporateSalesSlipId").val($(this).find(".sysCorporateSalesSlipId").val());
			goTransaction("initCorporateSaleDetail.do");
		});

		// 法人リンク
		$(".salesSlipLink").click(function () {

			$("#sysCorporateSalesSlipId").val($(this).find(".sysCorporateSalesSlipId_link").val());
			goTransaction("initCorporateSaleDetail.do");

		});


		// 法人リンク
		$(".corpLink").click(function(){
			var corporationId = $(this).find(".sysCorporationId").val();
			$("#sysCorporationId").val(corporationId);
			$("#corpSaleCostPageIdx").val(0);
			$("#searchPreset").val(0);
			removeCommaList($(".priceTextMinus"));
			removeCommaGoTransaction('corporateSaleCostList.do');
		});

		$(".editCorporateSaleCost").click (function (){

			goTransaction("editCorporateSaleCost.do");
		});


		$(".pickingListFlg").change(function () {
			pickingListFlgChange = 1;
		});

	});



</script>
	</head>
	<jsp:include page="/WEB-INF/page/common/menu.jsp" />
	<html:form action="/initCorporateSaleCostList"  enctype="multipart/form-data">
	<html:hidden property="alertType" styleId="alertType"></html:hidden>

	<h4 class="headingKind">業販原価入力</h4>
	<nested:hidden property="sysCorporateSalesSlipId" styleId="sysCorporateSalesSlipId"/>


	<ul class="hmenu mb10">
		<nested:iterate property="corporationList" id="corporation">
			<li class="corp corpLink">
				<a href="javascript:void(0);" id="corpLink<nested:write property="sysCorporationId" />"><nested:write property="abbreviation" /></a>
				<nested:hidden property="sysCorporationId" styleClass="sysCorporationId" />
			</li>
		</nested:iterate>
		<li class="corp corpLink"><a href="javascript:void(0);"  id="corpLink0">ALL</a><input type="hidden" class="sysCorporationId" value="0" /></li>
	</ul>
	<fieldset class="searchOptionField">
		<legend id="searchOptionOpen">▲隠す</legend>
		<nested:nest property="corpSaleCostSearchDTO">
			<nested:hidden property="searchPreset" styleId="searchPreset" />
			<div id="searchOptionArea">
				<table id="search_option">
					<tr>
						<td colspan="8">
							<div class="flgCheck fl">
								<ul>
									<li>ピッキングリスト</li>
									<li><label><nested:radio property="pickingListFlg" value="0" styleClass="pickingListFlg" />ピッキング前の商品を含む伝票を検索する</label></li>
									<li><label><nested:radio property="pickingListFlg" value="1" styleClass="pickingListFlg" />全てピッキング済みの伝票を検索する</label></li>
									<li><label><nested:radio property="pickingListFlg" value="2" styleClass="pickingListFlg" />全てピッキング前の伝票を検索する</label></li>
								</ul>
							</div>
							<div class="arrow fl mt30">→</div>
							<div class="flgCheck fl">
								<ul>
									<li>出庫</li>
									<li><label><nested:radio property="leavingFlg" value="0" styleClass="leavingFlg" />未出庫の商品を含む伝票を検索する</label></li>
									<li><label><nested:radio property="leavingFlg" value="1" styleClass="leavingFlg" />全て出庫済みの伝票を検索する</label></li>
									<li><label><nested:radio property="leavingFlg" value="2" styleClass="leavingFlg" />全て未出庫の伝票を検索する</label></li>
								</ul>
							</div>
							<div class="fl mt30">
								<span class="pdg_left_30px"><label><nested:checkbox property="returnFlg" />返品伝票</label></span>
								<span class="flgCheck"><label><nested:checkbox property="invalidFlag" />無効伝票</label></span>
								<span class="pdg_left_30px"><label><nested:checkbox property="searchAllFlg" />全件表示</label></span>
							</div>
							<div class="fl" style="margin-top:14px;">
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
							</div>
						</td>
					</tr>
					<tr>
						<td>見積日</td>
						<td style="white-space: nowrap;"><nested:text property="estimateDateFrom" styleClass="calender"  maxlength="10" />&nbsp;～&nbsp;<nested:text property="estimateDateTo" styleClass="calender"  maxlength="10" /></td>
						<td>ステータス</td>
						<td colspan="3">
<%-- 							<span><label><nested:checkbox property="slipStatusEstimate" />見積</label></span> --%>
<%-- 							<span><label><nested:checkbox property="slipStatusOrder" />受注</label></span> --%>
<%-- 							<span><label><nested:checkbox property="slipStatusSales" />売上</label></span> --%>
								<label><nested:radio property="slipStatus" value="1" styleClass="slipStatus" />見積</label>
								<label><nested:radio property="slipStatus" value="2" styleClass="slipStatus" />受注</label>
								<label><nested:radio property="slipStatus" value="3" styleClass="slipStatus" />売上</label>
						</td>
						<td>品番（前方一致）</td>
						<td><nested:text property="itemCode" styleClass="text_w120 numText" maxlength="11" /></td>
					</tr>
					<tr>
						<td>受注日</td>
						<td style="white-space: nowrap;"><nested:text property="orderDateFrom" styleClass="calender"  maxlength="10" />&nbsp;～&nbsp;<nested:text property="orderDateTo" styleClass="calender"  maxlength="10" /></td>
						<td>伝票番号</td>
						<td><nested:text property="orderNo" /></td>
						<td>運送会社</td>
						<td><nested:select property="transportCorporationSystem">
								<html:optionsCollection property="transportCorporationSystemMap" label="value" value="key"/>
						</nested:select></td>
						<td>品番</td>
						<td style="white-space: nowrap;"><nested:text property="itemCodeFrom" styleId="itemCodeFrom" styleClass="text_w120 numText" maxlength="11" /> ～ <nested:text property="itemCodeTo" styleId="itemCodeTo" styleClass="text_w120 numText" maxlength="11" /></td>
					</tr>
					<tr>
						<td>
							出庫予定日
							<nested:define id="dateFrom" property="scheduledLeavingDateFrom" />
							<input type="hidden" value="${dateFrom}" id="scheduledLeavingDateFrom" />
							<nested:define id="dateTo" property="scheduledLeavingDateTo" />
							<input type="hidden" value="${dateTo}" id="scheduledLeavingDateTo" />
						</td>
						<td style="white-space: nowrap;"><nested:text property="scheduledLeavingDateFrom" styleClass="calender"  maxlength="10" />&nbsp;～&nbsp;<nested:text property="scheduledLeavingDateTo" styleClass="calender"  maxlength="10" /></td>

						<td>法人</td>
						<td>
							<nested:select property="sysCorporationId" styleId="sysCorporationId">
								<option value="0">　</option>
								<html:optionsCollection property="corporationList" label="corporationNm" value="sysCorporationId" />
							</nested:select>
						</td>
						<td>売掛残</td>
						<td><nested:select property="receivableBalance">
							<html:option value="0">　</html:option>
							<html:option value="1">有</html:option>
							<html:option value="2">無</html:option>
						</nested:select></td>
						<td>他社品番（前方一致）</td>
						<td><nested:text property="salesItemCode" styleClass="text_w120" maxlength="30" /></td>
					</tr>
					<tr>
						<td>出庫日</td>
						<td style="white-space: nowrap;"><nested:text property="leavingDateFrom" styleClass="calender"  maxlength="10" />&nbsp;～&nbsp;<nested:text property="leavingDateTo" styleClass="calender"  maxlength="10" /></td>
						<td>得意先番号</td>
						<td><nested:text property="clientNo" /></td>
						<td>並び替え</td>
						<td>
							<nested:select property="sortFirst">
								<html:optionsCollection property="saleSearchMap" value="key" label="value" />
							</nested:select>
							<nested:select property="sortFirstSub">
								<html:optionsCollection property="saleSearchSortOrder" value="key" label="value" />
							</nested:select>
						</td>
						<td>商品名</td>
						<td><nested:text property="itemNm" styleClass="text_w200" /></td>
					</tr>
					<tr>
						<td>売上日</td>
						<td style="white-space: nowrap;"><nested:text property="salesDateFrom" styleClass="calender"  maxlength="10" />&nbsp;～&nbsp;<nested:text property="salesDateTo" styleClass="calender"  maxlength="10" /></td>
						<td>得意先名</td>
						<td><nested:text property="clientNm" /></td>
						<td>表示件数</td>
						<td>
							<nested:select property="listPageMax">
								<html:optionsCollection property="listPageMaxMap" value="key" label="value" />
							</nested:select>&nbsp;件
						</td>
						<td>他社商品名</td>
						<td><nested:text property="salesItemNm" styleClass="text_w200" /></td>
					</tr>
					<tr>
						<td>請求日</td>
						<td style="white-space: nowrap;"><nested:text property="billingDateFrom" styleClass="calender"  maxlength="10" />&nbsp;～&nbsp;<nested:text property="billingDateTo" styleClass="calender"  maxlength="10" /></td>
						<td>担当者名</td>
						<td><nested:text property="personInCharge" /></td>
						<td>支払方法</td>
						<td><nested:select property="paymentMethod">
							<html:option value="0">　</html:option>
							<html:optionsCollection property="paymentMethodMap" label="value" value="key" />
						</nested:select></td>
					</tr>
					<tr>
						<td colspan="2" class="td_center" style="padding-left: 20px;"><a class="button_main search" href="javascript:void(0);">検索</a></td>
						<td colspan="2"><a class="button_white clear" href="javascript:void(0);">リセット</a></td>
					</tr>
				</table>
			</div>
		</nested:nest>
	</fieldset>

	<nested:nest property="errorDTO">
	<nested:notEmpty property="errorMessage">
		<div id="errorArea">
			<p class="errorMessage"><nested:write property="errorMessage"/></p>
		</div>
	</nested:notEmpty>
	</nested:nest>

<nested:notEmpty property="corpSalesCostList">
	<div class="middleArea">
		<table class="editButtonTable">
			<tr>
				<td><a class="button_main editCorporateSaleCost" href="Javascript:void(0);">一括編集する</a></td>
			</tr>
		</table>
	</div>
	<div class="paging_area">
		<div class="paging_total_top">
			<h3>全&nbsp;<nested:write property="sysCorprateSaleItemIDListSize" />&nbsp;件&nbsp;（&nbsp;<span class="slipNowPage" ></span>&nbsp;/&nbsp;<span class="slipPageNum"></span>&nbsp;ページ&nbsp;）</h3>
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
	</div>

	<div id="list_area">
		<nested:hidden property="sysCorprateSaleItemIDListSize" styleId="sysCorprateSaleItemIDListSize" />
		<nested:hidden property="corpSaleCostPageIdx" styleId="corpSaleCostPageIdx" />
		<nested:hidden property="corpSaleListPageMax" styleId="corpSaleListPageMax" />
		<table id="mstTable" class="list_table">
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


			<nested:iterate property="corpSalesCostList" indexId="listIdx">

<!-- 		マスタにない商品 -->
			<nested:notEqual property="sysItemId" value="0">
				<bean:define id="backgroundColor" value="" />
			</nested:notEqual>
			<nested:equal property="sysItemId" value="0">
				<bean:define id="backgroundColor" value="#FFFFC0" />
			</nested:equal>

				<tbody style="background:${backgroundColor};" class="corporateSalesSlipRow change_color">
				<nested:hidden property="sysCorporateSalesSlipId" styleClass="sysCorporateSalesSlipId"></nested:hidden>
				<tr>
					<td>
						<a href="Javascript:(void);" class="salesSlipLink">
							<nested:write property="saleSlipNo" />
							<nested:hidden property="sysCorporateSalesSlipId" styleClass="sysCorporateSalesSlipId_link"></nested:hidden>
						</a>
					</td>
					<td><nested:write property="corporationNm" /></td>
					<td><nested:write property="scheduledLeavingDate" /></td>
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
<!-- ページ(下側) -->
		<div class="under_paging_area">
			<div class="paging_total_top">
				<h3>全&nbsp;<nested:write property="sysCorprateSaleItemIDListSize" />&nbsp;件&nbsp;（&nbsp;<span class="slipNowPage" ></span>&nbsp;/&nbsp;<span class="slipPageNum"></span>&nbsp;ページ&nbsp;）</h3>
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