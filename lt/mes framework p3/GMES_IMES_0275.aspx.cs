using BizApi;
using GMES.Web;
using System;
using System.Web.Script.Services;
using System.Web.Services;
using System.Data;
using System.IO;

/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0275.aspx
* @desc    : 생산일지 - 생산팀 관리일지 - 소분량점검 일지
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2023.08.31   은성우               INIT
* 1.1  2023.09.12   은성우               [양극재CheckSheet전산화2차] 일지현황판(GMES_IMES_0279)에서 호출
*                                       (1) HiddenField 추가
*************************************************************************************************

*/

public partial class GMES_IMES_0275 : GMESPage
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
        //최초 로드 인 경우 
        if (!IsPostBack)
        {
            InitData();
            //컨트롤 이벤트 정의
            InitEvent();
        }
    }
    #endregion

    #region Private Methods
    /// <summary>
    /// 데이터를 초기화한다.
    /// </summary>
    private void InitData()
    {
        manEmailString = System.Configuration.ConfigurationManager.AppSettings["PomManagerEmailAddress"].ToString();

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
            this.hidMenuID.Value = Request["MENU_ID"].ToString();
        }

        this.hidUserID.Value = SSUser.UserID;
        this.hidLangID.Value = SSUser.LangID;
        this.hidShopID.Value = SSUser.ShopID;
        // 2022.09.12 은성우 Link로 넘겨받은 param 추가
        this.hidAreaID.Value = Request["AREAID"]; // 공장동
        this.hidEqsgID.Value = Request["EQSGID"]; // 라인
        this.hidDyrdTP.Value = Request["DYRDTP"]; // 유형
        this.hidDyrdID.Value = Request["DYRDID"]; // 일지
        this.hidWkDate.Value = Request["WKDATE"]; // 작업일
        this.hidAutoSearch.Value = Request["AUTOSEARCH"];
    }

    /// <summary>
    /// 이벤트를 설정한다.
    /// </summary>
    public override void InitEvent()
    {
    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetData(string bizID, object[] items)
    {
        return FillBizActor_ReturnByApiResponse(bizID, items);
    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetDataSet(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return FillBizActor_ReturnByApiResponseDataSet(bizID, items, inTableNames, outTableNames);
    }

    //2022.09.22 황유라 C20220906-000317 GMES 소분이력조회시 발생 오류 개선 요청의 건
    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse DownloadExcel(string bizID, object[] items, string inTableNames, string outTableNames, string langID)
    {
        ApiResponse rtn = new ApiResponse();
        string strFullPath = string.Empty;
        DataSet dsTarget = new DataSet();

        try
        {
            DataSet ds = FillBizActor(bizID, items, inTableNames, outTableNames);

            DataTable dtTarget = ds.Tables["OUTDATA"].Rows.Count > 0 ? ds.Tables["OUTDATA"].Select().CopyToDataTable() : new DataTable();

            if (dtTarget.Rows.Count > 0)
            {
                dsTarget.Tables.Add(dtTarget);
                strFullPath = Path.Combine(Path.GetTempPath(), "DailyRecordSBDV_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + "_export.xlsx");
                ExcelExportHelper excelHelper = new ExcelExportHelper();
                excelHelper.ExportDsToExcel(dsTarget, strFullPath, langID);

                rtn.data = strFullPath;
                rtn.status = "OK";
            }
            else
            {
                rtn.message = "No Result";
                rtn.status = "FAIL";
            }
        }
        catch (Exception ex)
        {
            rtn.message = GetMessage(ex); //ex.Message.ToString();
            rtn.status = "FAIL";
        }

        return rtn;
    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse ExecuteData(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return ExecuteBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }

    #endregion

}