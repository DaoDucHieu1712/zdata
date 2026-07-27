using BizApi;
using GMES.Util;
using GMES.Web;
using System;
using System.Data;
using System.Web.Script.Services;
using System.Web.Services;

/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0560_02.aspx
* @desc    : 생산실적 - 이상품 추적 - 관리기준
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2023/11/23   송상호              INIT
*************************************************************************************************
*/

public partial class GMES_IMES_0560_02 : GMESPage
{
    #region Public Memebers
    public string manEmailString = String.Empty;
    #endregion

    #region Page_Load
    /// <summary>
    /// 페이지 로드 시 처리
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            ParsingRequest();
        }
    }
    #endregion

    #region Private Methods
    /// <summary>
    /// 데이터를 초기화한다.
    /// </summary>
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
            this.hidMenuID.Value = Request["MENU_ID"].ToString();
        }

        this.hidTITLE.Value = Request["TITLE"].ToString();
        this.hidLangID.Value = SSUser.LangID;
        this.hidShopID.Value = SSUser.ShopID;
        this.hidUserID.Value = SSUser.UserID;
        this.hidMTRLTYPE.Value = Request["MTRLTYPE"].ToString();
        this.hidAREAID.Value = Request["AREAID"].ToString();
    }

    /// <summary>
    /// 이벤트를 설정한다.
    /// </summary>

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetData(string bizID, object[] items)
    {
        return FillBizActor_ReturnByApiResponse(bizID, items);
    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse ExecuteData(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return ExecuteBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetDataSet(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return FillBizActor_ReturnByApiResponseDataSet(bizID, items, inTableNames, outTableNames);
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

    #endregion
}