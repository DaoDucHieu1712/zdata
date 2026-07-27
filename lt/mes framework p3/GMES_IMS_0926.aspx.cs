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
* @source  : GMES_POM/GMES_IMS_0926.aspx.cs
* @desc    : [재고실사] 재고실사 ERP반영
************************************************************************************************* 
* VER         DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0     2022/03/09       LEE.BR           INIT
*************************************************************************************************
*/

public partial class GMES_IMS_0926 : GMESPage
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