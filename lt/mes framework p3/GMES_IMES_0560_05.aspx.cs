using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Collections;
using System.Data;
using System.Data.SqlClient;
using AjaxControlToolkit;
using Newtonsoft.Json;
using System.Web.Script.Serialization;
using System.Web.UI.HtmlControls;
using System.Drawing;
using System.IO;
using System.Windows;
using NPOI.SS.Formula.Functions;
using System.Web.Script.Services;
using LGChem.Common;
using GMES.Web;
using GMES.Web.Extensions;
using GMES.Util;
using BizApi;
using System.Collections.Specialized;


/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMES_0560_05.aspx
* @desc    : 분산 투입 계산 팝업
************************************************************************************************* 
* VER     DATE                          AUTHOR        DESCRIPTION
*************************************************************************************************
* 1.0     2025-07-09                    오정균        신규 (분산 투입 계산 팝업)
*************************************************************************************************
*/

public partial class GMES_IMES_0560_05 : GMESPage
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            ParsingRequest();
        }
    }

    private void ParsingRequest()
    {
        ViewState["AUTHID"] = "";
        if (!String.IsNullOrEmpty(Request.QueryString["AUTHID"].SafeToString()))
        {
            ViewState["AUTHID"] = Request.QueryString["AUTHID"];
        }

        if (!String.IsNullOrEmpty(Request.QueryString["MENU_ID"].SafeToString()))
        {
            ViewState["MENU_ID"] = Request.QueryString["MENU_ID"];
        }

        this.hidTYPE.Value = Request["TYPE"].ToString();
        this.hidTITLE.Value = Request["TITLE"].ToString();
        this.hidUserID.Value = SSUser.UserID;
        this.hidLangID.Value = SSUser.LangID;
        this.hidShopID.Value = SSUser.ShopID;

        string encodedData = Request.QueryString["LOTLIST"];

        if (!string.IsNullOrEmpty(encodedData))
        {
            string decodedData = DecodeBase64(encodedData);
            NameValueCollection queryParameters = HttpUtility.ParseQueryString(decodedData);

            this.hidLOTLIST.Value = queryParameters["LOTLIST"];
        }
    }

    private string DecodeBase64(string base64EncodedData)
    {
        byte[] base64EncodedBytes = Convert.FromBase64String(base64EncodedData);
        return System.Text.Encoding.UTF8.GetString(base64EncodedBytes);
    }

    #region Web Method
    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetData(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return FillBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }
    #endregion


}