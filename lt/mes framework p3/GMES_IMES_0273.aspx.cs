using BizApi;
using GMES.Util;
using GMES.Web;
using LGChem.Common;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0273.aspx
* @desc    : [일지관리] 양극제 Job Change 일지 관리
************************************************************************************************* 
* VER         DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0     2023/04/12       YHJ              INIT
* 1.1     2023/08/17       은성우            [양극재CheckSheet전산화2차] 일지현황판(GMES_IMES_0279)에서 호출
*                                           (1) HiddenField 추가
*************************************************************************************************
*/

public partial class GMES_IMS_0273 : GMESPage
{
	#region Event
	protected void Page_Load(object sender, EventArgs e)
	{
		if (!IsPostBack)
		{
			ParsingRequest();
		}
	}
	#endregion

	#region General Method
	private void ParsingRequest()
	{
		//권한설정
		if (Request["ACCESS_FLAG"] != null)
		{
			ViewState["ACCESS_FLAG"] = Request["ACCESS_FLAG"].ToString();
		}

		ViewState["MENU_ID"] = null;
		if (Request["MENU_ID"] != null)
		{
			ViewState["MENU_ID"] = Request["MENU_ID"].ToString();
		}

		this.hidUserID.Value = SSUser.UserID;
		this.hidLangID.Value = SSUser.LangID;
		this.hidShopID.Value = SSUser.ShopID;
        // 2022.08.17 은성우 Link로 넘겨받은 param 추가
        this.hidAreaID.Value = Request["AREAID"]; // 공장동
        this.hidEqsgID.Value = Request["EQSGID"]; // 라인
        this.hidDyrdTP.Value = Request["DYRDTP"]; // 유형
        this.hidDyrdID.Value = Request["DYRDID"]; // 일지
        this.hidWkDate.Value = Request["WKDATE"]; // 일지
        this.hidAutoSearch.Value = Request["AUTOSEARCH"];
    }

	#endregion

	#region Web Method
	[WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
	public static ApiResponse GetData(string bizID, object[] items, string inTableNames, string outTableNames)
	{
		ResponseCompressGzip();
		return FillBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
	}

	[WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
	public static ApiResponse GetDataWithTableName(string bizID, object[] items, string inTableNames, string outTableNames, string tableName)
	{
		ApiResponse rtn = new ApiResponse();

		try
		{
			DataSet ds = FillBizActor(bizID, items, inTableNames, outTableNames);

			string[] arrOutTableNames = tableName.Split(',');

			if (arrOutTableNames.Length > 0)
			{
				if (arrOutTableNames[0].Length > 0)
					rtn.data = UtilCommon.dataTableToRowList(ds.Tables[arrOutTableNames[0]]);
				else
					rtn.data = UtilCommon.dataTableToRowList(ds.Tables["RQSTDT"]);
			}
			else
				rtn.data = UtilCommon.dataTableToRowList(ds.Tables["RQSTDT"]);


		}
		catch (Exception ex)
		{
			rtn.message = GetMessage(ex);
			rtn.status = "FAIL";
		}

		return rtn;
	}

	[WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
	public static ApiResponse GetDataSet(string bizID, object[] items, string inTableNames, string outTableNames)
	{
		return FillBizActor_ReturnByApiResponseDataSet(bizID, items, inTableNames, outTableNames);
	}

	[WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
	public static ApiResponse ExecuteData(string bizID, object[] items, string inTableNames, string outTableNames)
	{
		return ExecuteBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
	}

	#endregion



}