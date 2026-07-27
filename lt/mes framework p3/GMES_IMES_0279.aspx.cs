using BizApi;
using GMES.Util;
using GMES.Web;
using System;
using System.Data;
using System.Web.Script.Services;
using System.Web.Services;

/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0279.aspx.cs
* @desc    : [정보조회] 일지 현황판 Service
************************************************************************************************* 
* VER        DATE            AUTHOR        DESCRIPTION
*************************************************************************************************
* 1.0        2023/08/08      은성우         INIT
*************************************************************************************************
*/

public partial class GMES_IMS_0279 : GMESPage
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
        hidAuthID.Value = Request["AUTHID"].ToString();
        hidMenuID.Value = Request["MENU_ID"].ToString();
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