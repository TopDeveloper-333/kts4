package jp.co.kts.service.fileImport;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.validator.GenericValidator;
import org.apache.struts.upload.FormFile;

import jp.co.keyaki.cleave.fw.core.ActionContext;
import jp.co.keyaki.cleave.fw.dao.DaoException;
import jp.co.kts.app.common.entity.SalesSlipDTO;
import jp.co.kts.app.common.entity.ItemCostDTO;
import jp.co.kts.app.common.entity.ItemPriceDTO;
import jp.co.kts.app.common.entity.MstItemDTO;
import jp.co.kts.app.common.entity.MstUserDTO;
import jp.co.kts.app.common.entity.WarehouseStockDTO;
import jp.co.kts.app.extendCommon.entity.ExtendWarehouseStockDTO;
import jp.co.kts.app.extendCommon.entity.ItemCostPriceDTO;
import jp.co.kts.app.output.entity.SaleSlipErrorExcelImportDTO;
import jp.co.kts.dao.common.SequenceDAO;
import jp.co.kts.dao.fileImport.ExcelImportDAO;
import jp.co.kts.dao.mst.ChannelDAO;
import jp.co.kts.dao.mst.CorporationDAO;
import jp.co.kts.dao.mst.SupplierDAO;
import jp.co.kts.service.common.Result;
import jp.co.kts.service.common.ServiceConst;
import jp.co.kts.service.common.ServiceValidator;
import jp.co.kts.service.item.ItemService;
import jp.co.kts.service.mst.UserService;
import jp.co.kts.ui.web.struts.WebConst;
import jp.co.kts.app.extendCommon.entity.ExtendSalesItemDTO;
import jp.co.kts.app.extendCommon.entity.ExtendSalesSlipDTO;
import jp.co.kts.dao.sale.SaleDAO;

/**
 * エクセル取り込みで売上データの更新を行うクラスです
 * 2021/06/07　作成　金城
 *
 * @author 金城
 *
 */
public class SaleSlipUpdateService extends SaleSlipImportService {

	/**
	 * シート名　売上表
	 */
	private static final String SHEET_NAME_SALELIST = "売上表";

	/**
	 * シート無しの返却判定値
	 */
	private static final int SHEET_NAME_NO_EXIST = -1;

	@Override
	public SaleSlipErrorExcelImportDTO validate(FormFile excelImportForm) throws Exception {

		SaleSlipErrorExcelImportDTO dto = super.validate(excelImportForm);

		int mstItemSheetNum = 0;

		//ユーザー情報取得
		long userId = ActionContext.getLoginUserInfo().getUserId();
		UserService userService = new UserService();
		MstUserDTO mstUserDTO = new MstUserDTO();
		mstUserDTO = userService.getUserName(userId);
		String auth = mstUserDTO.getOverseasInfoAuth();


		//終了
		if (!dto.getResult().isSuccess()) {
			return dto;
		}

		/************************************************新規Excelシート取込START************************************************/
		//シートの存在を確認
		boolean authInfo = true;
		//シート名が存在することを判定し、そのシート番号を控えます
		int itemInfoNum = 0;
		String itemSheetNm = SHEET_NAME_SALELIST;
		itemInfoNum = checkSheetNameResult(dto.getResult(), wb, SHEET_NAME_SALELIST);

		//権限が違うExcelの場合Exception。
		if (auth.equals("0")) {
			throw new Exception();
		}
		authInfo = true;

		int sheetCheckResult = 0;
		sheetCheckResult = itemInfoNum;
		//終了
		if (!dto.getResult().isSuccess()) {
			return dto;
		}

		//新規Excelシートのいずれかが存在していた場合
		if (sheetCheckResult > -3) {
			//商品情報シートが存在していた場合
			if (itemInfoNum > SHEET_NAME_NO_EXIST) {

				//終了
				if (!dto.getResult().isSuccess()) {
					return dto;
				}

				List<List<String>> strMstItemList =
						uploadExcelFile(wb, wb.getSheetAt(mstItemSheetNum), ServiceConst.UPLOAD_EXCEL_SALE_SLIP_COLUMN);
				//取得したデータをDTOにつめる(varidateチェック含む)
				dto = setItemDetailInfo(dto, strMstItemList, authInfo);

				//varidateチェックにかかっていれば、ここで終了
				if (!dto.getResult().isSuccess()) {
					return dto;
				}
			}
			/************************************************新Excelシート取込END************************************************/
		}

		int sumSheetCheckResult = sheetCheckResult;

		if (sumSheetCheckResult == -3) {
			dto.getResult().addErrorMessage("LED00152");
			//終了
			if (!dto.getResult().isSuccess()) {
				return dto;
			}
		}

		return dto;
	}


	/**
	 * [概要] Excelから取得したデータをdtoに格納するメソッド（バリデート処理も含む）：商品情報
	 * @param dto
	 * @param warehouseStockList
	 * @return dto
	 * @throws Exception
	 */
	private SaleSlipErrorExcelImportDTO setItemDetailInfo(
			SaleSlipErrorExcelImportDTO dto, List<List<String>> saleSlipInfoList, boolean authInfo) throws Exception {

		Result<SalesSlipDTO> result = dto.getResult();
//		List<MstItemDTO> mstItem = new ArrayList<MstItemDTO>();
		SalesSlipDTO excelImportDTO = dto.getExcelImportDTO();
		ItemService itemService = new ItemService();
		errorIndex = ServiceConst.UPLOAD_EXCEL_INIT_ROWS + 1;
		if (authInfo) {
//			sheetNm = "商品情報_権限有";
		} else {
//			sheetNm = "商品情報";
		}
		for (int i = 0; i < saleSlipInfoList.size(); i++) {

			String orderNo = saleSlipInfoList.get(i).get(4);
			//受注番号が存在しない場合
			if (StringUtils.isEmpty(orderNo)) {
				result.addErrorMessage("LED00116", SHEET_NAME_SALELIST
						, String.valueOf(i + errorIndex), saleSlipInfoList.get(i).get(4));
				continue;
			}

			ExtendSalesSlipDTO salesSlipDTO = getExtendSalesSlip(orderNo);
			if (salesSlipDTO != null) {
				salesSlipDTO.setDisposalRoute(saleSlipInfoList.get(i).get(0));
				salesSlipDTO.setOrderNo(orderNo);
				String orderDate = saleSlipInfoList.get(i).get(5);
				if (orderDate.length() <= 10)
					salesSlipDTO.setOrderDate(orderDate);
				String orderTime = saleSlipInfoList.get(i).get(6);
				if (orderTime.length() <= 8)
					salesSlipDTO.setOrderTime(orderTime);
				salesSlipDTO.setOrderFamilyNm(saleSlipInfoList.get(i).get(9));
				salesSlipDTO.setOrderFirstNm(saleSlipInfoList.get(i).get(10));
				salesSlipDTO.setOrderFamilyNmKana(saleSlipInfoList.get(i).get(11));
				salesSlipDTO.setOrderFirstNmKana(saleSlipInfoList.get(i).get(12));
				salesSlipDTO.setOrderTel(saleSlipInfoList.get(i).get(13));
				salesSlipDTO.setOrderMailAddress(saleSlipInfoList.get(i).get(14));
				salesSlipDTO.setOrderZip(saleSlipInfoList.get(i).get(15));
				salesSlipDTO.setOrderPrefectures(saleSlipInfoList.get(i).get(16));
				salesSlipDTO.setOrderMunicipality(saleSlipInfoList.get(i).get(17));
				salesSlipDTO.setOrderAddress(saleSlipInfoList.get(i).get(18));
				salesSlipDTO.setOrderBuildingNm(saleSlipInfoList.get(i).get(19));
				salesSlipDTO.setOrderCompanyNm(saleSlipInfoList.get(i).get(20));
				salesSlipDTO.setOrderQuarter(saleSlipInfoList.get(i).get(21));
				salesSlipDTO.setAccountMethod(saleSlipInfoList.get(i).get(22));
				salesSlipDTO.setAccountCommission(Integer.valueOf(saleSlipInfoList.get(i).get(23)));
				String depositDate = saleSlipInfoList.get(i).get(24);
				if (depositDate.length() <= 10)
					salesSlipDTO.setDepositDate(depositDate);
				salesSlipDTO.setUsedPoint(Integer.valueOf(saleSlipInfoList.get(i).get(25)));
				salesSlipDTO.setGetPoint(Integer.valueOf(saleSlipInfoList.get(i).get(26)));
				salesSlipDTO.setMenberNo(saleSlipInfoList.get(i).get(27));
				salesSlipDTO.setOrderRemarksMemo(saleSlipInfoList.get(i).get(28));
				salesSlipDTO.setDestinationFamilyNm(saleSlipInfoList.get(i).get(29));
				salesSlipDTO.setDestinationFirstNm(saleSlipInfoList.get(i).get(30));
				salesSlipDTO.setDestinationFamilyNmKana(saleSlipInfoList.get(i).get(31));
				salesSlipDTO.setDestinationFirstNmKana(saleSlipInfoList.get(i).get(32));
				salesSlipDTO.setDestinationTel(saleSlipInfoList.get(i).get(33));
				salesSlipDTO.setDestinationZip(saleSlipInfoList.get(i).get(34));
				salesSlipDTO.setDestinationPrefectures(saleSlipInfoList.get(i).get(35));
				salesSlipDTO.setDestinationMunicipality(saleSlipInfoList.get(i).get(36));
				salesSlipDTO.setDestinationAddress(saleSlipInfoList.get(i).get(37));
				salesSlipDTO.setDestinationBuildingNm(saleSlipInfoList.get(i).get(38));
				salesSlipDTO.setDestinationCompanyNm(saleSlipInfoList.get(i).get(39));
				salesSlipDTO.setDestinationQuarter(saleSlipInfoList.get(i).get(40));
				salesSlipDTO.setSenderRemarks(saleSlipInfoList.get(i).get(41));
				salesSlipDTO.setSenderMemo(saleSlipInfoList.get(i).get(42));
				salesSlipDTO.setSlipNo(saleSlipInfoList.get(i).get(43));
				salesSlipDTO.setTransportCorporationSystem(saleSlipInfoList.get(i).get(44));
				salesSlipDTO.setInvoiceClassification(saleSlipInfoList.get(i).get(45));
				salesSlipDTO.setCashOnDeliveryCommission(Integer.valueOf(saleSlipInfoList.get(i).get(46)));
				String destinationAppointDate = saleSlipInfoList.get(i).get(47);
				if (destinationAppointDate.length() <= 10)
					salesSlipDTO.setDestinationAppointDate(destinationAppointDate);
				String destinationAppointTime = saleSlipInfoList.get(i).get(48);
				if (destinationAppointTime.length() <= 8)
					salesSlipDTO.setDestinationAppointTime(destinationAppointTime);
				salesSlipDTO.setShipmentPlanDate(saleSlipInfoList.get(i).get(49));
				salesSlipDTO.setSlipMemo(saleSlipInfoList.get(i).get(50));
				salesSlipDTO.setDiscommondity(Integer.valueOf(saleSlipInfoList.get(i).get(53)));
				salesSlipDTO.setGift(Integer.valueOf(saleSlipInfoList.get(i).get(54)));
				salesSlipDTO.setPostage(Integer.valueOf(saleSlipInfoList.get(i).get(55)));
				salesSlipDTO.setCodCommission(Integer.valueOf(saleSlipInfoList.get(i).get(56)));
				salesSlipDTO.setConsumptionTax(Integer.valueOf(saleSlipInfoList.get(i).get(57)));
				String classStr = saleSlipInfoList.get(i).get(63);
				if (StringUtils.equals(classStr, "内税")) {
					salesSlipDTO.setTaxClass("1");
				}else if (StringUtils.equals(classStr, "外税")) {
					salesSlipDTO.setTaxClass("2");
				}
				salesSlipDTO.setSumClaimPrice(Integer.valueOf(saleSlipInfoList.get(i).get(65)));

				SaleDAO saleDAO = new SaleDAO();

				long sysSalesSlipId = getSysSalesSlipId(salesSlipDTO.getOrderNo());
				salesSlipDTO.setSysSalesSlipId(sysSalesSlipId);

				String corporationNm = saleSlipInfoList.get(i).get(7);
				if (getCorporationId(corporationNm) >= 0)
					salesSlipDTO.setSysCorporationId(getCorporationId(corporationNm));

				String channelNm = saleSlipInfoList.get(i).get(8);
				if (getChannelId(channelNm) >= 0)
					salesSlipDTO.setSysChannelId(getChannelId(channelNm));

				ExtendSalesItemDTO salesItem = getExtendSalesItem(sysSalesSlipId);
				if (salesItem != null) {
					salesItem.setItemCode(saleSlipInfoList.get(i).get(58));
					salesItem.setItemNm(saleSlipInfoList.get(i).get(59));
					salesItem.setOrderNum(Integer.valueOf(saleSlipInfoList.get(i).get(60)));
					salesItem.setPieceRate(Integer.valueOf(saleSlipInfoList.get(i).get(61)));
					salesItem.setCost(Integer.valueOf(saleSlipInfoList.get(i).get(62)));
					
					saleDAO.updateSalesItem(salesItem);
				}

				System.out.println("Found SaleSlip DTO: (id, orderno, slipno)" + 
							sysSalesSlipId + ":" + salesSlipDTO.getOrderNo() + ":" + salesSlipDTO.getSlipNo());
				
				saleDAO.updateSalesSlip(salesSlipDTO);
			}
		}

		dto.setResult(result);
		dto.setExcelImportDTO(excelImportDTO);

		return dto;
	}
	
	private ExtendSalesSlipDTO getExtendSalesSlip(String orderNo) throws DaoException {
		ExtendSalesSlipDTO dto = new ExtendSalesSlipDTO();
		dto.setOrderNo(orderNo);
		dto = new SaleDAO().getSaleSlip(dto);

		if (dto == null) {

			return null;
		}

		return dto;		
	}
	
	private ExtendSalesItemDTO getExtendSalesItem(long sysSlipId) throws DaoException {
		ExtendSalesItemDTO salesItem = new ExtendSalesItemDTO();
		salesItem.setSysSalesSlipId(sysSlipId);
		salesItem = new SaleDAO().getSalesItemDTO(salesItem);
		if (salesItem == null) {

			return null;
		}

		return salesItem;		
	}

	private long getSysSalesSlipId(String orderNo) throws DaoException {

		ExtendSalesSlipDTO dto = new ExtendSalesSlipDTO();
		dto.setOrderNo(orderNo);
		dto = new SaleDAO().getSaleSlip(dto);

		if (dto == null) {

			return 0;
		}

		return dto.getSysSalesSlipId();
	}

	private long getCorporationId(String corporationNm) throws DaoException {

		CorporationDAO corporationDAO = new CorporationDAO();
		String corporationIdStr = corporationDAO.getCorporationId(corporationNm);
		long corporationId = Long.valueOf(corporationIdStr);
		return corporationId;
	}

	private long getChannelId(String channelNm) throws DaoException {

		ChannelDAO channelDAO = new ChannelDAO();
		long channelId = channelDAO.getChannelId(channelNm);
		return channelId;
	}
}
