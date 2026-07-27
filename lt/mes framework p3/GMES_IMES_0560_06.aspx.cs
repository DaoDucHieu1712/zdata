using BizApi;
using GMES.Util;
using GMES.Web;
using System;
using System.Data;
using System.Web.Script.Services;
using System.Web.Services;

/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0560_06.aspx
* @desc    : 생산실적 - 이상품 추적 - 확정 취소 팝업
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2025/08/14   오정균              INIT
*************************************************************************************************
*/

public partial class GMES_IMES_0560_06 : GMESPage
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

        this.hidLangID.Value = SSUser.LangID;
        this.hidShopID.Value = SSUser.ShopID;
        this.hidUserID.Value = SSUser.UserID;
        this.hidAREAID.Value = Request["AREAID"].ToString();
        this.hidPRODIDLIST.Value = Request["PRODIDLIST"].ToString();
    }
    #endregion
}