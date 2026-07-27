using BizApi;
using GMES.Util;
using GMES.Web;
using LGChem.Common;
using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI.DataVisualization.Charting;

/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0560_04.aspx
* @desc    : 생산실적 - 이상품 추적 - 검사항목 관리
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2023/11/23   송상호              INIT
*************************************************************************************************
*/

public partial class GMES_IMES_0560_04 : GMESPage
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
        this.hidAreaID.Value = Request["AREAID"].ToString();
        this.hidProdID.Value = Request["PRODID"].ToString();
        this.hidWhID.Value = Request["WHID"].ToString();
        this.hidMTRLTYPE.Value = Request["MTRLTYPE"].ToString();
        this.hidINLOTID.Value = Request["INLOTID"].ToString();

        GetChart();
    }

    void GetChart()
    {
        string bizID = "BR_IM_STK_GET_RACK_ABNORMAL";

        BizData data = new BizData(bizID, "RSLTDT");

        data.AddTable("INDATA");
        data.AddColumn("INDATA", "LANGID", typeof(string));
        data.AddColumn("INDATA", "SHOPID", typeof(string));
        data.AddColumn("INDATA", "AREAID", typeof(string));
        data.AddColumn("INDATA", "WHID", typeof(string));
        data.AddColumn("INDATA", "MTRLTYPE", typeof(string));
        data.AddColumn("INDATA", "PRODID", typeof(string));
        data.AddColumn("INDATA", "INLOTID", typeof(string));

        data.AddRow("INDATA");
        data.SetData("INDATA", "LANGID", SSUser.LangID);
        

        if (!string.IsNullOrWhiteSpace(hidINLOTID.Value))
        {
            data.SetData("INDATA", "INLOTID", hidINLOTID.Value);
        }
        else
        {
            data.SetData("INDATA", "SHOPID", hidShopID.Value);
            data.SetData("INDATA", "AREAID", hidAreaID.Value);
            data.SetData("INDATA", "WHID", hidWhID.Value);
            data.SetData("INDATA", "MTRLTYPE", hidMTRLTYPE.Value);
            data.SetData("INDATA", "PRODID", hidProdID.Value);
        }

        DataSet dataSet = data.Submit();
        DataTable RSLTDT = dataSet.Tables["RSLTDT"];

        Chart1.Titles["Title1"].Text = GetArea();
        if (RSLTDT.Rows.Count <= 0) return;

        DataView dataView = new DataView(RSLTDT);
        dataView.Sort = "LINE,LINE_MAKER_LI";
        //라인별 생산량
        DataTable dtLineGroup = dataView.Table.Rows.Count > 0 ? (
          dataView.Table.AsEnumerable()
                  .GroupBy(r => new
                  {
                      LINE = r["LINE"]
                     ,
                      LINENAME = r["LINENAME"]
                     ,
                      LINE_MAKER_LI = r["LINE_MAKER_LI"]
                      ,
                      PRODID = r["PRODID"]
                  })
                  .Select(g =>
                  {
                      var row = dataView.Table.NewRow();
                      row["LINE"] = g.Key.LINE;
                      row["LINENAME"] = g.Key.LINENAME;
                      row["LINE_MAKER_LI"] = g.Key.LINE_MAKER_LI;
                      row["PRODID"] = g.Key.PRODID;
                      return row;
                  }).Where(x => !string.IsNullOrWhiteSpace(x["LINE_MAKER_LI"].ToString())).CopyToDataTable()
          ) : new DataTable();

        Dictionary<string, string> INPUTTYEP_LIST = null;
        INPUTTYEP_LIST = GetCommoncode();

        if (INPUTTYEP_LIST == null)
            return;

        DataTable ResultTbl = new DataTable();
        ResultTbl.Columns.Add("ROW_SEQ", typeof(int));
        ResultTbl.Columns.Add("LINE", typeof(string));
        ResultTbl.Columns.Add("LINENAME", typeof(string));
        ResultTbl.Columns.Add("LINE_MAKER_LI", typeof(string));
        ResultTbl.Columns.Add("PRODID", typeof(string));

        foreach (var dictem in INPUTTYEP_LIST)
        {
            ResultTbl.Columns.Add(dictem.Key.ToString(), typeof(Double));//재공량
        }

        DataView LineGroupView = new DataView(dtLineGroup);
        LineGroupView.Sort = "LINE,LINE_MAKER_LI";

        DataRow newRow = null;
        int ROW_SEQ = 0;
        foreach (DataRowView dview in LineGroupView)
        {
            DataRow drow = dview.Row;

             //단독투입 재공수량
            Double S_WIPQTY = (RSLTDT.Select().Where(x => x["LINE"].ToString() == drow["LINE"].ToString()
               && x["LINE_MAKER_LI"].ToString() == drow["LINE_MAKER_LI"].ToString()
               && x["PRODID"].ToString() == drow["PRODID"].ToString()
               && x["SINGLE_INPUT_YN"].ToString() == "S"
               && Convert.ToDouble(x["WIPQTY"]) > 0
               ).ToList().Sum(x => Convert.ToDouble(x["WIPQTY"]))) * 0.001;

            //분산투입 재공수량
            Double D_WIPQTY = (RSLTDT.Select().Where(x => x["LINE"].ToString() == drow["LINE"].ToString()
             && x["LINE_MAKER_LI"].ToString() == drow["LINE_MAKER_LI"].ToString()
             && x["PRODID"].ToString() == drow["PRODID"].ToString()
             && x["SINGLE_INPUT_YN"].ToString() == "D"
             && Convert.ToDouble(x["WIPQTY"]) > 0

             ).ToList().Sum(x => Convert.ToDouble(x["WIPQTY"]))) * 0.001;
             
            //투입보류 재공수량
            Double H_WIPQTY = (RSLTDT.Select().Where(x => x["LINE"].ToString() == drow["LINE"].ToString()
             && x["LINE_MAKER_LI"].ToString() == drow["LINE_MAKER_LI"].ToString()
             && x["PRODID"].ToString() == drow["PRODID"].ToString()
             && x["SINGLE_INPUT_YN"].ToString() == "H"
             && Convert.ToDouble(x["WIPQTY"]) > 0
             ).ToList().Sum(x => Convert.ToDouble(x["WIPQTY"]))) * 0.001;

            newRow = ResultTbl.NewRow();
            newRow["ROW_SEQ"] = ROW_SEQ++;
            newRow["LINE"] = drow["LINE"];
            newRow["LINENAME"] = drow["LINENAME"];
            newRow["LINE_MAKER_LI"] = drow["LINE_MAKER_LI"];
            newRow["PRODID"] = drow["LINENAME"] + " " + drow["LINE_MAKER_LI"] + " " + drow["PRODID"];

            S_WIPQTY = Math.Round(S_WIPQTY, 0);
            if (S_WIPQTY <= 0)
            {
                newRow["S"] = DBNull.Value;
            }else
            {
                newRow["S"] = S_WIPQTY;
            }

            D_WIPQTY = Math.Round(D_WIPQTY, 0);
            if (D_WIPQTY <= 0)
            {
                newRow["D"] = DBNull.Value;
            }
            else
            {
                newRow["D"] = D_WIPQTY;
            }

            H_WIPQTY = Math.Round(H_WIPQTY, 0);
            if (H_WIPQTY <= 0)
            {
                newRow["H"] = DBNull.Value;
            }
            else
            {
                newRow["H"] = H_WIPQTY;
            }
             
            ResultTbl.Rows.Add(newRow);

        }

        DataView bindingView = new DataView(ResultTbl);
        bindingView.Sort = "LINE,LINE_MAKER_LI";
         
        //Font SeriesFont = new Font(FontFamily.GenericSansSerif, 8, FontStyle.Bold);
        Chart1.Series["Series1"].Points.DataBind(bindingView, "PRODID", "S", "");//X,Y 값표시 하기
        Chart1.Series["Series1"].IsValueShownAsLabel = true;    //막대그래프 값표시 
        Chart1.Series["Series1"].LegendText = INPUTTYEP_LIST["S"];

        Chart1.Series["Series2"].Points.DataBind(bindingView, "PRODID", "D", "");//X,Y 값표시 하기
        Chart1.Series["Series2"].IsValueShownAsLabel = true;    //막대그래프 값표시 
        Chart1.Series["Series2"].LegendText = INPUTTYEP_LIST["D"];

        Chart1.Series["Series3"].Points.DataBind(bindingView, "PRODID", "H", "");//X,Y 값표시 하기
        Chart1.Series["Series3"].IsValueShownAsLabel = true;    //막대그래프 값표시 
        Chart1.Series["Series3"].LegendText = INPUTTYEP_LIST["H"];

        Chart1.Series["Series1"].IsVisibleInLegend = true;
        Chart1.Series["Series2"].IsVisibleInLegend = true;
        Chart1.Series["Series3"].IsVisibleInLegend = true;

        Chart1.ChartAreas["Default"].AxisX.LabelStyle.Interval = 1;  //X축 간격 설정  
        Chart1.ChartAreas["Default"].AxisX.IsLabelAutoFit = true;
        Chart1.ChartAreas["Default"].AxisX.LabelStyle.Enabled = true;
        Chart1.ChartAreas["Default"].AxisX.Enabled = AxisEnabled.Auto;
        Chart1.ChartAreas["Default"].AxisX.Interval = 1;
        Chart1.ChartAreas["Default"].AxisY.TitleAlignment = StringAlignment.Center;

        Chart1.Legends["Legend1"].Alignment = System.Drawing.StringAlignment.Far;
        Chart1.Legends["Legend1"].Docking = Docking.Top;
    }

    string GetArea()
    {
        string AREANAME = string.Empty;
        try
        {
            string bizID = "DA_IM_SEL_AREA_CBO";

            BizData data = new BizData(bizID, "RSLTDT");

            data.AddTable("RQSTDT");
            data.AddColumn("RQSTDT", "LANGID", typeof(string));
            data.AddColumn("RQSTDT", "AREAID", typeof(string));

            data.AddRow("RQSTDT");
            data.SetData("RQSTDT", "LANGID", SSUser.LangID);
            data.SetData("RQSTDT", "AREAID", hidAreaID.Value);

            DataSet dataSet = data.Submit();
            DataTable RSLTDT = dataSet.Tables["RSLTDT"];

            if (RSLTDT.Rows.Count > 0)
            {
                AREANAME = RSLTDT.Select().FirstOrDefault()["AREANAME"].ToString();
                AREANAME = AREANAME + " " + lang.word["Half-Finished Goods"] + " " + lang.word["WareHouse_List_Tab"];
            }
        }
        catch (Exception ex)
        {
            throw;
        }

        return AREANAME;
    }

    Dictionary<string, string> GetCommoncode()
    {
        Dictionary<string, string> rtn = null;

        try
        {


            string bizID = "BR_IM_SEL_CommonCode";

            BizData data = new BizData(bizID, "OUTDATA");

            data.AddTable("INDATA");
            data.AddColumn("INDATA", "LANGID", typeof(string));
            data.AddColumn("INDATA", "CMCDTYPE", typeof(string));

            data.AddRow("INDATA");
            data.SetData("INDATA", "LANGID", SSUser.LangID);
            data.SetData("INDATA", "CMCDTYPE", "ABNORMAL_INPUT_TYPE");


            DataSet dataSet = data.Submit();
            DataTable RSLTDT = dataSet.Tables["OUTDATA"];

            if (RSLTDT.Rows.Count > 0)
            {
                rtn = new Dictionary<string, string>();
                foreach (DataRow dItem in RSLTDT.Rows)
                {
                    rtn.Add(dItem["CMCODE"].ToString(), dItem["CMCDNAME"].ToString());
                }
            }
        }
        catch (Exception ex)
        {

            throw;
        }

        return rtn;
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