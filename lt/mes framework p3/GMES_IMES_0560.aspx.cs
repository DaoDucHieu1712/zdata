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
* @source  : GMES_IM_POM/GMES_IMES_0560.aspx.cs 
* @desc    : 생산실적 - 실적조정관리 - 이상품추적
************************************************************************************************* 
* VER     DATE                          AUTHOR        DESCRIPTION
*************************************************************************************************
* 1.0     2025/02/10                    ssh0423        
*************************************************************************************************
* planner  :  
*************************************************************************************************
*/

public partial class GMES_IMES_0560 : GMESPage
{
    #region Member Variable
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

    }

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

        this.hidLangID.Value = SSUser.LangID;
        this.hidUserID.Value = SSUser.UserID;
        this.hidShopID.Value = SSUser.ShopID;
    }
    #endregion

    #region Web Method

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetData(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        //ResponseCompressGzip();

        return FillBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);

    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse ExecuteData_old(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return ExecuteBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse ExecuteData(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return ExecuteBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }


    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetDataList(string bizID, object[] items, string inTableNames, string outTableNames, string scanLotId)
    {
        ApiResponse res = new ApiResponse();
        try
        {
            DataSet ds = FillBizActor(bizID, items, inTableNames, outTableNames);
            //DataTable dtOutDataResult = new DataTable("OUTDATA_LOTID");
            //dtOutDataResult.Columns.Add("SCAN_LOTID");
            //DataRow dr = dtOutDataResult.NewRow();
            //dr["SCAN_LOTID"] = scanLotId;
            //dtOutDataResult.Rows.Add(dr);
            //ds.Tables.Add(dtOutDataResult);


            res.data = UtilCommon.dataTableToRowList(ds);
            //res.data = new List<Dictionary<string, object>>();
        }
        catch (Exception ex)
        {
            res.message = GetMessage(ex);// ex.Message.ToString(); 
            res.status = scanLotId;
        }
        //return FillBizActor_ReturnByApiResponse(bizID, items);
        return res;
    }
    #endregion



}