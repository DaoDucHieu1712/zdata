using BizApi;
using GMES.Web;
using System;
using System.Web.Script.Services;
using System.Web.Services;

/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0312.aspx
* @desc    : 생산실적 - 정보조회 - 재처리실적 조회 [관리자]
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2023/03/29   황유라              C20230214-000081 세척용Lot 투입관리 메뉴 개선 件
*************************************************************************************************
*/

public partial class GMES_IMES_0312 : GMESPage
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
    #endregion

}