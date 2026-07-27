using BizApi;
using GMES.Util;
using GMES.Web;
using LGChem.Common;
using System;
using System.Web.Script.Services;
using System.Web.Services;
using System.Data;
using System.IO;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Linq;
using System.Web;
using System.Net;
using System.Web.UI;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Spreadsheet;
using System.Drawing;
using System.Drawing.Imaging;
using A = DocumentFormat.OpenXml.Drawing;
using Xdr = DocumentFormat.OpenXml.Drawing.Spreadsheet;
using System.Drawing.Drawing2D;

/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0277.aspx
* @desc    : [일지관리] 양극제 일지 관리
************************************************************************************************* 
* VER         DATE      AUTHOR        DESCRIPTION
*************************************************************************************************
* 1.0     2022.11.11    YHJ           INIT
* 1.1     2023.08.17    은성우        [양극재CheckSheet전산화2차] 일지현황판(GMES_IMES_0279)에서 호출
*                                     (1) HiddenField 추가
* 1.2     2024.01.26    은성우        [양극재CheckSheet전산화] 이미지엑셀다운로드 추가
*                                     (1) DownloadExcelImage (2) CreateExcelImage (3) ExcelTools.AddImage
*************************************************************************************************
*/

public partial class GMES_IMES_0277 : GMESPage
{
    static string BizMode = System.Configuration.ConfigurationManager.AppSettings["BizMode"].ToString();

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

        this.hidUserID.Value = SSUser.UserID;
        this.hidLangID.Value = SSUser.LangID;
        this.hidShopID.Value = SSUser.ShopID;
        hidAuthID.Value = Request["AUTHID"].ToString();
        hidMenuID.Value = Request["MENU_ID"].ToString();
        // 2022.08.09 은성우 Link로 넘겨받은 param 추가
        this.hidAreaID.Value = Request["AREAID"]; // 공장동
        this.hidEqsgID.Value = Request["EQSGID"]; // 라인
        this.hidDyrdTP.Value = Request["DYRDTP"]; // 유형
        this.hidDyrdID.Value = Request["DYRDID"]; // 일지
        this.hidWkDate.Value = Request["WKDATE"]; // 일지
        this.hidAutoSearch.Value = Request["AUTOSEARCH"];
    }

    #endregion

    #region Web Method
    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetData(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        ResponseCompressGzip();
        return FillBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
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

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse GetDataSet(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return FillBizActor_ReturnByApiResponseDataSet(bizID, items, inTableNames, outTableNames);
    }

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse ExecuteData(string bizID, object[] items, string inTableNames, string outTableNames)
    {
        return ExecuteBizActor_ReturnByApiResponse(bizID, items, inTableNames, outTableNames);
    }

    #endregion

    [WebMethod(EnableSession = true), ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public static ApiResponse DownloadExcelImage(string bizID, object[] items, string inTableNames, string outTableNames, string dyrdNm, string templateNm, string labelCnt,
                                                 string weekName, string lastDay)
    {
        ApiResponse rtn = new ApiResponse();

        try
        {
            DataSet dataSet = new DataSet();

            //dataSet = FillBizActor(bizID, items, inTableNames, outTableNames);
            dataSet = FillBizActor_ReturnByDataSet(bizID, items, inTableNames, outTableNames); // BR_IM_PRD_SEL_DYRD_GID_IMG

            for (int i = 0; i < dataSet.Tables.Count; i++)
            {
                WriteConsoleDataTableToString(dataSet.Tables[i]);
            }

            string strFullPath = Path.Combine(Path.GetTempPath(), "DailyRecord" + "_" + dyrdNm + "_" + templateNm + "_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xlsx");

            bool hasData = dataSet.Tables.Count > 1;
            if (hasData)
            {
                CreateExcelImage(strFullPath, dataSet.Tables["OUTDATA"], labelCnt, weekName, lastDay);
            }

            rtn.data = strFullPath;
            rtn.status = "OK";
        }
        catch (Exception ex)
        {
            rtn.message = "[GMES_IMES_0277] DownloadExcelImage exception occurred";
            rtn.status = "FAIL";
        }

        return rtn;
    }

    /// <summary>
    /// Datatable 내용을 문자열로 출력
    /// </summary>
    private static void WriteConsoleDataTableToString(DataTable dataTable)
    {
        StringBuilder outString = new StringBuilder();
        int[] columnWidths = new int[dataTable.Columns.Count];

        Regex reg = new Regex("[ㄱ-ㅎ가-힣]");

        // Get column widths
        foreach (DataRow row in dataTable.Rows)
        {
            for (int i = 0; i < dataTable.Columns.Count; i++)
            {
                int length = row[i].ToString().Length;

                MatchCollection matchCollection = reg.Matches(row[i].ToString());
                if (matchCollection.Count > 0)
                {
                    length += matchCollection.Count;
                }

                if (columnWidths[i] < length)
                {
                    columnWidths[i] = length;
                }
            }
        }

        // Get Colmn titles
        for (int i = 0; i < dataTable.Columns.Count; i++)
        {
            int length = dataTable.Columns[i].ColumnName.Length;
            if (columnWidths[i] < length)
            {
                columnWidths[i] = length;
            }
        }

        outString.AppendLine("");
        // Write Column titles
        for (int i = 0; i < dataTable.Columns.Count; i++)
        {
            string text = dataTable.Columns[i].ColumnName;
            outString.Append(String.Format("| {0,-" + (columnWidths[i] + 2) + "} ", text));
        }
        outString.AppendLine("");
        outString.AppendLine(new string('_', outString.Length));

        int dataFieldWidth = 0;

        // Write Rows
        foreach (DataRow row in dataTable.Rows)
        {
            for (int i = 0; i < dataTable.Columns.Count; i++)
            {
                string text = row[i].ToString();

                // 찍을 때는 추가된 부분을 제거애햐 함. 
                dataFieldWidth = columnWidths[i] + 2;

                MatchCollection matchCollection = reg.Matches(row[i].ToString());
                if (matchCollection.Count > 0)
                {
                    dataFieldWidth -= matchCollection.Count;
                }

                outString.Append(String.Format("| {0,-" + dataFieldWidth + "} ", text));
            }
            outString.AppendLine("");
        }

        System.Diagnostics.Debug.WriteLine(outString.ToString());
    }

    /// <summary>
    /// Generate SheetStyle
    /// </summary>
    /// <param name="langID"></param>
    /// <returns></returns>
    private static Stylesheet CreateStyleSheet()
    {

        Stylesheet styleSheet = new Stylesheet();

        // ******** 폰트 ********
        Fonts fonts = new Fonts();
        DocumentFormat.OpenXml.Spreadsheet.Font font = null;

        // Index 0 : Defalut (11. Calibri)
        font = new DocumentFormat.OpenXml.Spreadsheet.Font(
            new DocumentFormat.OpenXml.Spreadsheet.FontSize() { Val = 11 },
            new ForegroundColor() { Rgb = new HexBinaryValue() { Value = "000000" } },
            new FontName() { Val = "Calibri" }
            );
        fonts.Append(font);

        // Index 1 : Column Header (Bold, 11, Calibri)
        font = new DocumentFormat.OpenXml.Spreadsheet.Font(
            new DocumentFormat.OpenXml.Spreadsheet.Bold(),
            new DocumentFormat.OpenXml.Spreadsheet.FontSize() { Val = 11 },
            new ForegroundColor() { Rgb = new HexBinaryValue() { Value = "000000" } },
            new FontName() { Val = "Calibri" }
            );
        fonts.Append(font);

        // index 2 : Sub Title (20, Calibri)
        font = new DocumentFormat.OpenXml.Spreadsheet.Font(
            new DocumentFormat.OpenXml.Spreadsheet.FontSize() { Val = 20 },
            new ForegroundColor() { Rgb = new HexBinaryValue() { Value = "000000" } },
            new FontName() { Val = "Calibri" }
            );
        fonts.Append(font);
        styleSheet.Append(fonts);


        // ******** 배경색 ********
        Fills fills = new Fills();
        Fill fill = null;

        // Index 0 : Default
        fill = new Fill(new PatternFill() { PatternType = PatternValues.None });
        fills.Append(fill);

        // Index 1 : Column Header (밝은 하늘색)
        fill = new Fill(new PatternFill(new ForegroundColor() { Rgb = new HexBinaryValue() { Value = "FFBBD0E6" } }) { PatternType = PatternValues.None });
        fills.Append(fill);
        styleSheet.Append(fills);


        // ******** 테두리 ********
        Borders borders = new Borders();
        Border border = null;

        // Index 0 : Default (기본테두리)
        border = new Border(
            new LeftBorder() { Color = new DocumentFormat.OpenXml.Spreadsheet.Color() { Theme = (UInt32Value)1U }, Style = BorderStyleValues.Thin },
            new RightBorder() { Color = new DocumentFormat.OpenXml.Spreadsheet.Color() { Theme = (UInt32Value)1U }, Style = BorderStyleValues.Thin },
            new TopBorder() { Color = new DocumentFormat.OpenXml.Spreadsheet.Color() { Theme = (UInt32Value)1U }, Style = BorderStyleValues.Thin },
            new BottomBorder() { Color = new DocumentFormat.OpenXml.Spreadsheet.Color() { Theme = (UInt32Value)1U }, Style = BorderStyleValues.Thin }
            );
        borders.Append(border);

        // Index 1 : Column Header (열제목 테두리)
        border = new Border(
            new LeftBorder() { Color = new DocumentFormat.OpenXml.Spreadsheet.Color() { Theme = (UInt32Value)1U }, Style = BorderStyleValues.Medium },
            new RightBorder() { Color = new DocumentFormat.OpenXml.Spreadsheet.Color() { Theme = (UInt32Value)1U }, Style = BorderStyleValues.Medium },
            new TopBorder() { Color = new DocumentFormat.OpenXml.Spreadsheet.Color() { Theme = (UInt32Value)1U }, Style = BorderStyleValues.Medium },
            new BottomBorder() { Color = new DocumentFormat.OpenXml.Spreadsheet.Color() { Theme = (UInt32Value)1U }, Style = BorderStyleValues.Medium },
            new DiagonalBorder());
        borders.Append(border);
        styleSheet.Append(borders);


        // ******** CellFormat 정의 ********
        CellFormats cellFormats = new CellFormats();
        CellFormat cellFormat = null;

        // Index 0 : Default (기본)
        cellFormat = new CellFormat() { FontId = 0, FillId = 0, BorderId = 0, ApplyFill = true, ApplyBorder = true };
        cellFormats.Append(cellFormat);

        // Index 1 : Column Header
        cellFormat = new CellFormat() { FontId = 1, FillId = 1, BorderId = 1, ApplyFill = true, ApplyBorder = true, Alignment = new Alignment() { Horizontal = HorizontalAlignmentValues.Center, Vertical = VerticalAlignmentValues.Center } };
        cellFormats.Append(cellFormat);

        // Index 2 : Sub title
        cellFormat = new CellFormat() { FontId = 2, FillId = 0 };
        cellFormats.Append(cellFormat);

        // Index 3 : 테스트
        cellFormat = new CellFormat() { FontId = 0, FillId = 0, BorderId = 0, ApplyFill = true, ApplyBorder = true };
        cellFormats.Append(cellFormat);

        styleSheet.Append(cellFormats);

        return styleSheet;
    }


    private static string GetNextWeekName(string curWeekName)
    {
        string rtnWeekName = "";

        string[] arrLangId = { "ko-KR", "en-US", "zh-CN", "zh-TW" };
        string[] arrWeekName_Mon = { "월", "Mon", "星期一", "星期一" };
        string[] arrWeekName_Tue = { "화", "Mon", "星期二", "星期二" };
        string[] arrWeekName_Wed = { "수", "Tue", "星期三", "星期三" };
        string[] arrWeekName_Thu = { "목", "Thu", "星期四", "星期四" };
        string[] arrWeekName_Fri = { "금", "Fri", "星期五", "星期五" };
        string[] arrWeekName_Sat = { "토", "Sat", "星期六", "星期六" };
        string[] arrWeekName_Sun = { "일", "Sun", "星期日", "星期日" };

        int langCnt = 0;
        for (int i = 0; i < arrLangId.Length; i++)
        {
            if (HttpContext.Current.Session["langid"].ToString() == arrLangId[i].ToString())
            {
                langCnt = i;
                break;
            }
        }

        if (curWeekName == arrWeekName_Mon[langCnt].ToString()) rtnWeekName = arrWeekName_Tue[langCnt].ToString(); // "화";
        else if (curWeekName == arrWeekName_Tue[langCnt].ToString()) rtnWeekName = arrWeekName_Wed[langCnt].ToString(); // "수";
        else if (curWeekName == arrWeekName_Wed[langCnt].ToString()) rtnWeekName = arrWeekName_Thu[langCnt].ToString(); // "목";
        else if (curWeekName == arrWeekName_Thu[langCnt].ToString()) rtnWeekName = arrWeekName_Fri[langCnt].ToString(); // "금";
        else if (curWeekName == arrWeekName_Fri[langCnt].ToString()) rtnWeekName = arrWeekName_Sat[langCnt].ToString(); // "토";
        else if (curWeekName == arrWeekName_Sat[langCnt].ToString()) rtnWeekName = arrWeekName_Sun[langCnt].ToString(); // "일";
        else if (curWeekName == arrWeekName_Sun[langCnt].ToString()) rtnWeekName = arrWeekName_Mon[langCnt].ToString(); // "월";

        return rtnWeekName;
    }


    /**
     * Excel 생성(Insert Image)
     */
    private static void CreateExcelImage(string fullFileName, DataTable dataTable, string labelCnt, string weekName, string lastDay)
    {
        using (SpreadsheetDocument document = SpreadsheetDocument.Create(fullFileName, SpreadsheetDocumentType.Workbook))
        {
            WorkbookPart workbookPart = document.AddWorkbookPart();
            workbookPart.Workbook = new Workbook();

            WorksheetPart worksheetPart = workbookPart.AddNewPart<WorksheetPart>();
            worksheetPart.Worksheet = new Worksheet();

            Sheets sheets = workbookPart.Workbook.AppendChild(new Sheets());
            Sheet sheet = new Sheet() { Id = workbookPart.GetIdOfPart(worksheetPart), SheetId = 1, Name = "DailyRecord" }; // Sheet 이름
            sheets.Append(sheet);
            workbookPart.Workbook.Save();

            // 스타일 적용
            WorkbookStylesPart stylesPart = workbookPart.AddNewPart<WorkbookStylesPart>();
            ExcelExportHelper helper = new ExcelExportHelper();
            stylesPart.Stylesheet = CreateStyleSheet();
            stylesPart.Stylesheet.Save(stylesPart);

            //var imageUrl = "http://10.46.35.234/UploadedFiles/BRN/DYRD/202312/3157.jpg"; // Replace with the actual image URL
            var serverUrl = "";
            if ("PROD".Equals(BizMode))
            {
                if (HttpContext.Current.Session["shopid"].ToString() == "3070")
                {
                    serverUrl = "http://10.46.35.94"; // 청주 운영
                }
                else if (HttpContext.Current.Session["shopid"].ToString() == "G621")
                {
                    serverUrl = "http://10.48.131.51"; // 우시 운영
                }
            }
            else
            {
                if (HttpContext.Current.Session["shopid"].ToString() == "3070")
                {
                    serverUrl = "http://10.46.35.234"; // 청주 통테
                }
                else if (HttpContext.Current.Session["shopid"].ToString() == "G621")
                {
                    serverUrl = "http://10.48.131.240"; // 우시 통테
                }
            }

            int maxPicpath = 31; // 이미지 최대 개수

            /* 이미지 Size 조회
            Dictionary<String, int> imgSizeDic = GetImageSize(serverUrl, dataTable, maxDA);

            int imgWidth = 0;
            int imgHeight = 0;
            if (imgSizeDic != null && imgSizeDic.Count > 0)
            {
                imgWidth = imgSizeDic["WIDTH"]; // Width : 640
                imgHeight = imgSizeDic["HEIGHT"]; // Height : 360
            }
            */

            // 컬럼 너비 조정
            Columns columns = new Columns();

            // Min : 시작열, Max : 종료열
            columns.Append(new Column() { Min = 1, Max = 1, Width = 8, CustomWidth = true });
            columns.Append(new Column() { Min = 2, Max = 3, Width = 10, CustomWidth = true }); // 1~2Level

            if (int.Parse(labelCnt) == 3) // 3Level
            {
                columns.Append(new Column() { Min = 4, Max = 4, Width = 28, CustomWidth = true }); // 3Level
                if (int.Parse(lastDay) == 28)
                {
                    columns.Append(new Column() { Min = 5, Max = 32, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                } else if (int.Parse(lastDay) == 29)
                {
                    columns.Append(new Column() { Min = 5, Max = 33, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                } else if (int.Parse(lastDay) == 30)
                {
                    columns.Append(new Column() { Min = 5, Max = 34, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                } else if (int.Parse(lastDay) == 31)
                {
                    columns.Append(new Column() { Min = 5, Max = 35, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                }
            }
            else if (int.Parse(labelCnt) == 4) // 4Level
            {
                columns.Append(new Column() { Min = 4, Max = 5, Width = 28, CustomWidth = true }); // 3~4Level
                if (int.Parse(lastDay) == 28)
                {
                    columns.Append(new Column() { Min = 6, Max = 33, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                } else if (int.Parse(lastDay) == 29)
                {
                    columns.Append(new Column() { Min = 6, Max = 34, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                } else if (int.Parse(lastDay) == 30)
                {
                    columns.Append(new Column() { Min = 6, Max = 35, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                } else if (int.Parse(lastDay) == 31)
                {
                    columns.Append(new Column() { Min = 6, Max = 36, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                }
                
            }
            else // 5Level
            {
                columns.Append(new Column() { Min = 4, Max = 6, Width = 28, CustomWidth = true }); // 3~5Level
                if (int.Parse(lastDay) == 28)
                {
                    columns.Append(new Column() { Min = 7, Max = 34, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                } else if (int.Parse(lastDay) == 29)
                {
                    columns.Append(new Column() { Min = 7, Max = 35, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                } else if (int.Parse(lastDay) == 30)
                {
                    columns.Append(new Column() { Min = 7, Max = 36, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                } else if (int.Parse(lastDay) == 31)
                {
                    columns.Append(new Column() { Min = 7, Max = 37, Width = 20, CustomWidth = true });  // Resize Image의 크기에 맞춰서 Width 지정
                }
            }

            worksheetPart.Worksheet.Append(columns);

            // 시트 데이터 저장
            SheetData sheetData = worksheetPart.Worksheet.AppendChild(new SheetData());

            // Constructing header
            Row row = new Row();
            // Header 수정 해야 함. 종류별로 다르게 처리 

            int rowSeq = 1;

            // 1일의 요일명을 inputWeekName1에 입력하고, 다음날의 요일명을 GetNextWeekName()에서 구하여 inputWeekName2에 입력한다.
            string inputWeekName1 = weekName;
            string inputWeekName2 = GetNextWeekName(inputWeekName1);
            string inputWeekName3 = GetNextWeekName(inputWeekName2);
            string inputWeekName4 = GetNextWeekName(inputWeekName3);
            string inputWeekName5 = GetNextWeekName(inputWeekName4);
            string inputWeekName6 = GetNextWeekName(inputWeekName5);
            string inputWeekName7 = GetNextWeekName(inputWeekName6);

            // Header
            if (int.Parse(labelCnt) == 3) // 3Level
            {
                if (int.Parse(lastDay) == 28) // 28Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U)
                    );
                }
                else if (int.Parse(lastDay) == 29) // 29Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("29" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U)
                    );
                }
                else if (int.Parse(lastDay) == 30) // 30Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("29" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("30" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U)
                    );
                }
                else if (int.Parse(lastDay) == 31) // 31Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("29" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("30" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("31" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U)
                    );
                }
            }
            else if (int.Parse(labelCnt) == 4) // 4Level
            {
                if (int.Parse(lastDay) == 28) // 28Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL4", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U)
                    );
                }
                else if (int.Parse(lastDay) == 29) // 29Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL4", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("29" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U)
                    );
                }
                else if (int.Parse(lastDay) == 30) // 30Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL4", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("29" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("30" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U)
                    );
                }
                else if (int.Parse(lastDay) == 31) // 31Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL4", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("29" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("30" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("31" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U)
                    );
                }
            }
            else // 5Level
            {
                if (int.Parse(lastDay) == 28) // 28Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL4", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL5", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U)
                    );
                }
                else if (int.Parse(lastDay) == 29) // 29Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL4", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL5", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("29" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U)
                    );
                }
                else if (int.Parse(lastDay) == 30) // 30Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL4", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL5", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("29" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("30" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U)
                    );
                }
                else if (int.Parse(lastDay) == 31) // 31Day
                {
                    row.Append(
                        ConstructCell("No", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL1", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL2", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL3", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL4", CellValues.String, (UInt32)1U),
                        ConstructCell("LEVEL5", CellValues.String, (UInt32)1U),
                        ConstructCell("1" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("2" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("3" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("4" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("5" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("6" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("7" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("8" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("9" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("10" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("11" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("12" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("13" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("14" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("15" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("16" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("17" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("18" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("19" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("20" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("21" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("22" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("23" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("24" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("25" + "(" + inputWeekName4 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("26" + "(" + inputWeekName5 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("27" + "(" + inputWeekName6 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("28" + "(" + inputWeekName7 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("29" + "(" + inputWeekName1 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("30" + "(" + inputWeekName2 + ")", CellValues.String, (UInt32)1U),
                        ConstructCell("31" + "(" + inputWeekName3 + ")", CellValues.String, (UInt32)1U)
                    );
                }
            }

            sheetData.AppendChild(row);

            // lastDay를 감안하여 maxPicpath를 재계산한다.
            maxPicpath = maxPicpath - (31 - int.Parse(lastDay));

            // Content
            foreach (DataRow r in dataTable.Rows)
            {
                string key = "";
                Boolean isExistImage = false;
                for (int i = 1; i < maxPicpath + 1; i++)
                {
                    key = ("PICPATH" + i).ToString();
                    if (r[key].ToString() != null && r[key].ToString().Length > 0)
                    {
                        isExistImage = true;
                        break;
                    }
                }

                // 이미지가 있는 경우, RowHeight 변경
                if (isExistImage)
                {
                    row = new Row() { Height = 61, CustomHeight = true }; // Resize Image의 크기에 맞춰서 Height 지정
                }
                else
                {
                    row = new Row();
                }

                if (int.Parse(labelCnt) == 3) // 3Level
                {
                    if (int.Parse(lastDay) == 28) // 28Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    } else if (int.Parse(lastDay) == 29) // 29Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH29"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    } else if (int.Parse(lastDay) == 30) // 30Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH29"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH30"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    } else if (int.Parse(lastDay) == 31) // 31Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH29"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH30"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH31"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    }
                } else if (int.Parse(labelCnt) == 4) // 4Level
                {
                    if (int.Parse(lastDay) == 28) // 28Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    }
                    else if (int.Parse(lastDay) == 29) // 29Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH29"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    }
                    else if (int.Parse(lastDay) == 30) // 30Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH29"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH30"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    }
                    else if (int.Parse(lastDay) == 31) // 31Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH29"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH30"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH31"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    }
                } else // 5Level
                {
                    if (int.Parse(lastDay) == 28) // 28Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    }
                    else if (int.Parse(lastDay) == 29) // 29Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH29"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    }
                    else if (int.Parse(lastDay) == 30) // 30Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH29"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH30"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    }
                    else if (int.Parse(lastDay) == 31) // 31Day
                    {
                        row.Append(
                            ConstructCell("" + rowSeq++, CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["LEVEL5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH1"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH2"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH3"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH4"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH5"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH6"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH7"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH8"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH9"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH10"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH11"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH12"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH13"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH14"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH15"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH16"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH17"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH18"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH19"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH20"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH21"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH22"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH23"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH24"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH25"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH26"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH27"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH28"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH29"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH30"].ToString(), CellValues.String, (UInt32)0U),
                            ConstructCell(r["PICPATH31"].ToString(), CellValues.String, (UInt32)0U)
                        );
                    }
                }

                sheetData.AppendChild(row);
                int maxLevel = 5;
                int startImageCol = 7 - (maxLevel - int.Parse(labelCnt)); // 이미지 시작Column, "PICPATH1" Column부터 시작

                // AddImage To Cell
                for (int i = 1; i < maxPicpath + 1; i++)
                {
                    key = ("PICPATH" + i).ToString();
                    var imageFileUrl = "";
                    if (r[key].ToString() != null && r[key].ToString().Length > 0)
                    {
                        imageFileUrl = serverUrl + r[key].ToString(); // imageFileUrl : " / UploadedFiles/BRN/DYRD/202312/3157.jpg"
                        // Download Image to MemoryStream
                        using (var webClient = new WebClient())
                        {
                            var imageBytes = webClient.DownloadData(new Uri(imageFileUrl));
                            using (var imageStream = new MemoryStream(imageBytes))
                            {
                                /* 해상도가 낮아지므로 사용하지 않고, AddImage()에서 extent의 x, y 값을 resize한다.
                                // Image From Stream
                                System.Drawing.Image image = System.Drawing.Image.FromStream(imageStream);
                                // Image Resize
                                image = ResizeImage(image, 30, 30);
                                // Image To Stream
                                var resizeStream = ToStream(image, ImageFormat.Jpeg);
                                // Use parameter[ResizeStream]
                                ExcelTools.AddImage(worksheetPart, resizeStream, imageFileUrl, (i + startImageCol - 1), rowSeq); // col, row
                                */
                                ExcelTools.AddImage(worksheetPart, imageStream, imageFileUrl, (i + startImageCol - 1), rowSeq); // col, row
                            }
                        }
                    }
                }
            }

            worksheetPart.Worksheet.Save();
        }
    }

    /*
    public static Dictionary<string, int> GetImageSize(string serverUrl, DataTable dataTable, int maxDA)
    {
        var rtnDic = new Dictionary<string, int>();
        string key = "";

        foreach (DataRow r in dataTable.Rows)
        {
            for (int i = 1; i < maxDA + 1; i++)
            {
                key = ("DA" + i).ToString();
                var imageFileUrl = "";
                if (r[key].ToString() != null && r[key].ToString().Length > 0)
                {
                    imageFileUrl = serverUrl + r[key].ToString();
                    using (var webClient = new WebClient())
                    {
                        var imageBytes = webClient.DownloadData(new Uri(imageFileUrl));
                        using (var imageStream = new MemoryStream(imageBytes))
                        {
                            Bitmap bm = new Bitmap(imageStream);
                            rtnDic.Add("WIDTH", bm.Width);
                            rtnDic.Add("HEIGHT", bm.Height);
                            break;
                        }
                    }
                }
            }
        }

        return rtnDic;
    }
    */


    public static Stream ToStream(Image image, ImageFormat format)
    {
        var stream = new System.IO.MemoryStream();
        image.Save(stream, format);
        stream.Position = 0;
        return stream;
    }

    public static Image ResizeImage(Image image, int new_height, int new_width)
    {
        Bitmap new_image = new Bitmap(new_width, new_height);
        Graphics g = Graphics.FromImage((Image)new_image);
        g.InterpolationMode = InterpolationMode.High;
        g.DrawImage(image, 0, 0, new_width, new_height);
        return new_image;
    }

    public static Image ScaleImage(Image image, int maxWidth)
    {
        var newImage = new Bitmap(maxWidth, image.Height);
        Graphics.FromImage(newImage).DrawImage(image, 0, 0, maxWidth, image.Height);
        return newImage;
    }

    private static Cell ConstructCell(string value, CellValues dataType, UInt32 styleIndex = 0)
    {
        return new Cell()
        {
            CellValue = new CellValue(value),
            DataType = new EnumValue<CellValues>(dataType),
            StyleIndex = UInt32Value.FromUInt32(styleIndex)
        };
    }


    public class ExcelTools
    {
        public static ImagePartType GetImagePartTypeByBitmap(Bitmap image)
        {
            if (ImageFormat.Bmp.Equals(image.RawFormat))
                return ImagePartType.Bmp;
            else if (ImageFormat.Gif.Equals(image.RawFormat))
                return ImagePartType.Gif;
            else if (ImageFormat.Png.Equals(image.RawFormat))
                return ImagePartType.Png;
            else if (ImageFormat.Tiff.Equals(image.RawFormat))
                return ImagePartType.Tiff;
            else if (ImageFormat.Icon.Equals(image.RawFormat))
                return ImagePartType.Icon;
            else if (ImageFormat.Jpeg.Equals(image.RawFormat))
                return ImagePartType.Jpeg;
            else if (ImageFormat.Emf.Equals(image.RawFormat))
                return ImagePartType.Emf;
            else if (ImageFormat.Wmf.Equals(image.RawFormat))
                return ImagePartType.Wmf;
            else
                throw new Exception("Image type could not be determined.");
        }

        public static WorksheetPart GetWorksheetPartByName(SpreadsheetDocument document, string sheetName)
        {
            IEnumerable<Sheet> sheets =
               document.WorkbookPart.Workbook.GetFirstChild<Sheets>().
               Elements<Sheet>().Where(s => s.Name == sheetName);

            if (sheets.Count() == 0)
            {
                // The specified worksheet does not exist
                return null;
            }

            string relationshipId = sheets.First().Id.Value;
            return (WorksheetPart)document.WorkbookPart.GetPartById(relationshipId);
        }

        public static void AddImage(bool createFile, string excelFile, string sheetName,
                                    string imageFileName, string imgDesc,
                                    int colNumber, int rowNumber)
        {
            using (var imageStream = new FileStream(imageFileName, FileMode.Open))
            {
                AddImage(createFile, excelFile, sheetName, imageStream, imgDesc, colNumber, rowNumber);
            }
        }

        public static void AddImage(WorksheetPart worksheetPart,
                                    string imageFileName, string imgDesc,
                                    int colNumber, int rowNumber)
        {
            using (var imageStream = new FileStream(imageFileName, FileMode.Open))
            {
                AddImage(worksheetPart, imageStream, imgDesc, colNumber, rowNumber);
            }
        }

        public static void AddImage(bool createFile, string excelFile, string sheetName,
                                    Stream imageStream, string imgDesc,
                                    int colNumber, int rowNumber)
        {
            SpreadsheetDocument spreadsheetDocument = null;
            WorksheetPart worksheetPart = null;
            if (createFile)
            {
                // Create a spreadsheet document by supplying the filepath
                spreadsheetDocument = SpreadsheetDocument.Create(excelFile, SpreadsheetDocumentType.Workbook);

                // Add a WorkbookPart to the document
                WorkbookPart workbookpart = spreadsheetDocument.AddWorkbookPart();
                workbookpart.Workbook = new Workbook();

                // Add a WorksheetPart to the WorkbookPart
                worksheetPart = workbookpart.AddNewPart<WorksheetPart>();
                worksheetPart.Worksheet = new Worksheet(new SheetData());

                // Add Sheets to the Workbook
                Sheets sheets = spreadsheetDocument.WorkbookPart.Workbook.
                    AppendChild<Sheets>(new Sheets());

                // Append a new worksheet and associate it with the workbook
                Sheet sheet = new Sheet()
                {
                    Id = spreadsheetDocument.WorkbookPart.GetIdOfPart(worksheetPart),
                    SheetId = 1,
                    Name = sheetName
                };
                sheets.Append(sheet);
            }
            else
            {
                // Open spreadsheet
                spreadsheetDocument = SpreadsheetDocument.Open(excelFile, true);

                // Get WorksheetPart
                worksheetPart = GetWorksheetPartByName(spreadsheetDocument, sheetName);
            }

            AddImage(worksheetPart, imageStream, imgDesc, colNumber, rowNumber);

            worksheetPart.Worksheet.Save();

            spreadsheetDocument.Close();
        }

        public static void AddImage(WorksheetPart worksheetPart,
                                    Stream imageStream, string imgDesc,
                                    int colNumber, int rowNumber)
        {
            // We need the image stream more than once, thus we create a memory copy
            MemoryStream imageMemStream = new MemoryStream();
            imageStream.Position = 0;
            imageStream.CopyTo(imageMemStream);
            imageStream.Position = 0;

            var drawingsPart = worksheetPart.DrawingsPart;
            if (drawingsPart == null)
                drawingsPart = worksheetPart.AddNewPart<DrawingsPart>();

            if (!worksheetPart.Worksheet.ChildElements.OfType<Drawing>().Any())
            {
                worksheetPart.Worksheet.Append(new Drawing { Id = worksheetPart.GetIdOfPart(drawingsPart) });
            }

            if (drawingsPart.WorksheetDrawing == null)
            {
                drawingsPart.WorksheetDrawing = new Xdr.WorksheetDrawing();
            }

            var worksheetDrawing = drawingsPart.WorksheetDrawing;

            Bitmap bm = new Bitmap(imageMemStream);

            var imagePart = drawingsPart.AddImagePart(GetImagePartTypeByBitmap(bm));
            imagePart.FeedData(imageStream);

            A.Extents extents = new A.Extents();
            //var extentsCx = bm.Width * (long)(914400 / bm.HorizontalResolution);
            //var extentsCy = bm.Height * (long)(914400 / bm.VerticalResolution);
            // Width, Height -> 비율 Resize
            //var extentsCx = bm.Width/3 * (long)(914400 / bm.HorizontalResolution);
            //var extentsCy = bm.Height/3 * (long)(914400 / bm.VerticalResolution);
            // 사진 파일의 크기에 따라 Size가 변동되므로, 26KB의 33% 계산된 값을 고정하여 사용한다.
            var extentsCx = 1352550;
            var extentsCy = 762000;
            bm.Dispose();

            var colOffset = 0;
            var rowOffset = 0;

            var nvps = worksheetDrawing.Descendants<Xdr.NonVisualDrawingProperties>();
            var nvpId = nvps.Count() > 0
                ? (UInt32Value)worksheetDrawing.Descendants<Xdr.NonVisualDrawingProperties>().Max(p => p.Id.Value) + 1
                : 1U;

            var oneCellAnchor = new Xdr.OneCellAnchor(
                new Xdr.FromMarker
                {
                    ColumnId = new Xdr.ColumnId((colNumber - 1).ToString()),
                    RowId = new Xdr.RowId((rowNumber - 1).ToString()),
                    ColumnOffset = new Xdr.ColumnOffset(colOffset.ToString()),
                    RowOffset = new Xdr.RowOffset(rowOffset.ToString())
                },
                new Xdr.Extent { Cx = extentsCx, Cy = extentsCy }, // 크기
                new Xdr.Picture(
                    new Xdr.NonVisualPictureProperties(
                        new Xdr.NonVisualDrawingProperties { Id = nvpId, Name = "Picture " + nvpId, Description = imgDesc },
                        new Xdr.NonVisualPictureDrawingProperties(new A.PictureLocks { NoChangeAspect = true })
                    ),
                    new Xdr.BlipFill(
                        new A.Blip { Embed = drawingsPart.GetIdOfPart(imagePart), CompressionState = A.BlipCompressionValues.Print },
                        new A.Stretch(new A.FillRectangle())
                    ),
                    new Xdr.ShapeProperties(
                        new A.Transform2D(
                            new A.Offset { X = 0, Y = 0 },
                            new A.Extents { Cx = extentsCx, Cy = extentsCy } // 크기
                        ),
                        new A.PresetGeometry { Preset = A.ShapeTypeValues.Rectangle }
                    )
                ),
                new Xdr.ClientData()
            );

            worksheetDrawing.Append(oneCellAnchor);
        }
    }

}