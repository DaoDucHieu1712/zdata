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
* @source  : GMES_POM/GMES_IMS_0585.aspx
* @desc    : 재고관리 - ERP I/F - ERP 시점재고I/F 이력조회
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2022/08/08   문창완              INIT
*************************************************************************************************
*/

public partial class GMES_IMS_0585 : GMESPage
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

    public override void InitEvent()
    {

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

        this.hidUserID.Value = SSUser.UserID;
        this.hidLangID.Value = SSUser.LangID;
        this.hidShopID.Value = SSUser.ShopID;

        this.hidMenuName.Value = sMenuName;
    }

    #endregion


    #region Web Method

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetSearchData(string AREAID, string PROCID, string EQPTID, string LOTID, string FROM_DATE, string TO_DATE)
    {
        ApiResponse res = new ApiResponse();

        try
        {
            BizData biz = new BizData("DA_PRD_SEL_WIPHISTORY_BY_WORKORDER_MNT");

            biz.AddTable("INDATA");
            biz.AddColumn("INDATA", "LANGID", typeof(string));
            biz.AddColumn("INDATA", "SHOPID", typeof(string));
            biz.AddColumn("INDATA", "AREAID", typeof(string));
            biz.AddColumn("INDATA", "PROCID", typeof(string));
            biz.AddColumn("INDATA", "EQPTID", typeof(string));
            biz.AddColumn("INDATA", "LOTID", typeof(string));
            biz.AddColumn("INDATA", "FROM_DATE", typeof(System.DateTime));
            biz.AddColumn("INDATA", "TO_DATE", typeof(System.DateTime));

            biz.AddRow("INDATA");
            biz.SetData("INDATA", "LANGID", HttpContext.Current.Session["langid"].ToString());
            biz.SetData("INDATA", "SHOPID", HttpContext.Current.Session["shopid"].ToString());
            biz.SetData("INDATA", "AREAID", AREAID);
            biz.SetData("INDATA", "PROCID", PROCID);
            biz.SetData("INDATA", "EQPTID", EQPTID);
            biz.SetData("INDATA", "LOTID", LOTID);
            biz.SetData("INDATA", "FROM_DATE", FROM_DATE);
            biz.SetData("INDATA", "TO_DATE", TO_DATE);

            DataSet dtable = biz.Submit();

            //res.data = UtilCommon.dataTableToRowList(ds.Tables["OUTDATA"]);

            res.data = UtilCommon.dataTableToRowList(dtable);
        }
        catch (Exception ex)
        {
            res.message = GetMessage(ex); //ex.Message.ToString();
            res.status = "FAIL";
        }

        return res;
    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse ExecuteData(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return ExecuteBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }
    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetDataMulti(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return FillBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }


    #endregion
}