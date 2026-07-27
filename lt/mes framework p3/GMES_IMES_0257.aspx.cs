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

/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0257.aspx
* @desc    : 생산실적 - 수율 REPORT - 수율(RTY) 변경조치관리
************************************************************************************************* 
* VER  DATE         AUTHOR              DESCRIPTION
*************************************************************************************************
* 1.0  2025/06/12   오정균              INIT
*************************************************************************************************
*/

public partial class GMES_IMES_0257 : GMESPage
{

    #region Member Variable
    public string manEmailString = String.Empty;
    #endregion

    #region Event
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            ParsingRequest();
        }

        //컨트롤 이벤트 정의
        InitEvent();
    }
    #endregion

    #region General Method
    public override void InitEvent()
    {
        manEmailString = System.Configuration.ConfigurationManager.AppSettings["PomManagerEmailAddress"].ToString();
    }

    private void ParsingRequest()
    {
        //권한설정
        if (Request["ACCESS_FLAG"] != null)
        {
            ViewState["ACCESS_FLAG"] = Request["ACCESS_FLAG"].ToString();
            hidAccessFlag.Value = ViewState["ACCESS_FLAG"].ToString();
        }

        ViewState["MENU_ID"] = null;
        if (Request["MENU_ID"] != null)
        {
            ViewState["MENU_ID"] = Request["MENU_ID"].ToString();
        }

        this.hidLangID.Value = SSUser.LangID;
        this.hidUserID.Value = SSUser.UserID;
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
    #endregion
}