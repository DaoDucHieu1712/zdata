using System;
using System.Data;
using System.IO;
using System.Web.Script.Services;
using System.Web.Services;
using BizApi;
using GMES.Web;

/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMS_0581.aspx
* @desc    : 재고관리 - ERP I/F - ERP 투입조정
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2022/04/04   문창완              INIT
*************************************************************************************************
*/

public partial class GMES_IMS_0581 : GMESPage
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
        this.hidMenuName.Value = sMenuName;
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

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse ExecuteDataSet(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        ApiResponse res = new ApiResponse();
        bool chkAll = true;
        try
        {
            string[] arrInTableNames = inTableNames.Split(',');
            object[] indata = new object[items.Length];

            indata[0] = items[0];

            object[] item = items[1] as object[];
            for(int idx = 0; idx < item.Length; idx++)
            {
                try
                {
                    object[] temp = new object[1];
                    temp[0] = item[idx] as object[];
                    indata[arrInTableNames.Length - 1] = temp;
                    DataSet ds = FillBizActor(bizID, indata, inTableNames, outTableNames);
                }
                catch(Exception ex)
                {
                    chkAll = false;
                }                
            }

            if (chkAll)
            {
                res.message = "SUCCESS";
                res.status = "OK";
            }
            else
            {
                res.message = "FAIL";
                res.status = "NG";
            }

        }
        catch (Exception ex)
        {
            res.message = ex.Message.ToString();
            res.status = "EX";
        }

        return res; //FillBizActor_ReturnByApiResponseDataSet(bizID, items, inTableNames, outTableNames);
    }
    #endregion


}