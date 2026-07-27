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
using GMES.Web;
using System;

/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMS_0580.aspx.cs
* @desc    : 재고관리 - ERP I/F - 인터페이스 이력조회(기타)
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2018/02/19   한유진              ERP 인터페이스 현황 (기타)
*************************************************************************************************
*/

public partial class GMES_IMES_0531 : GMESPage
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
    #endregion
}