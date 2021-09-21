package jp.co.kts.app.output.entity;

import jp.co.kts.app.common.entity.SalesSlipDTO;
import jp.co.kts.service.common.Result;

public class SaleSlipErrorExcelImportDTO {

	/** エラー */
	Result<SalesSlipDTO> result = new Result<SalesSlipDTO>();

	/** Excel */
	SalesSlipDTO excelImportDTO = new SalesSlipDTO();

	/**
	 * @return result
	 */
	public Result<SalesSlipDTO> getResult() {
		return result;
	}

	/**
	 * @param result セットする result
	 */
	public void setResult(Result<SalesSlipDTO> result) {
		this.result = result;
	}

	/**
	 * @return excelImportDTO
	 */
	public SalesSlipDTO getExcelImportDTO() {
		return excelImportDTO;
	}

	/**
	 * @param excelImportDTO セットする excelImportDTO
	 */
	public void setExcelImportDTO(SalesSlipDTO excelImportDTO) {
		this.excelImportDTO = excelImportDTO;
	}


}
