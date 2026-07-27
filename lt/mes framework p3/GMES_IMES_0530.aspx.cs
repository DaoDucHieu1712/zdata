// ---------------------------------------------------------------
// 시 스 템 : LGCI.GMES.IMS
// 작 성 자 : 조상국
// 작 성 일 : 2017-12-21
#region // 개발이력
/*
 *  2017-12-21(조상국)
 *  + 신규개발
 *  
 */
#endregion
// ---------------------------------------------------------------

using System;
using System.Data;
using System.IO;
using System.Web.Script.Services;
using System.Web.Services;
using BizApi;
using GMES.Web;


/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMS_0480.aspx.cs
* @desc    : 재고관리 - ERP I/F - 인터페이스 이력조회[생산/투입 실적]
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2017/12/21   조상국              INIT
* 1.1  2018/02/05   한유진              조회조건 - 투입실적LOT 추가 
*************************************************************************************************
*/

public partial class GMES_IMS_0480 : GMESPage
{
    #region Public Members
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
            //컨트롤 이벤트 정의
            InitData();
            InitEvent();
        }        
    }
    #endregion

    #region Private Methods
    /// <summary>
    /// 데이터를 초기화한다.
    /// </summary>
    void InitData()
    {
        manEmailString = System.Configuration.ConfigurationManager.AppSettings["PomManagerEmailAddress"].ToString();

        // 권한설정
        if (Request["ACCESS_FLAG"] != null)
        {
            ViewState["ACCESS_FLAG"] = Request["ACCESS_FLAG"].ToString();
            hidAccessFlag.Value = ViewState["ACCESS_FLAG"].ToString();
        }

        // HiddenField 값 설정
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
    public static ApiResponse GetDataMulti(string bizID, object[] items, string inTableNames, string outTableNames)
    {

        return FillBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse ExecuteData(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return ExecuteBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }

    #endregion
}