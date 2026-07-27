<%--/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0279.aspx
* @desc    : [정보조회] 일지 현황판
************************************************************************************************* 
* VER     DATE             AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0     2023.08.08       은성우           INIT
* 1.1     2023.08.18       은성우           [양극재CheckSheet전산화2차] 대표라인포함 조회조건 추가
* 1.2     2023.08.28       은성우           [양극재CheckSheet전산화2차] 발생건수 조회 추가
*                                           (1) 발생건수(소분량 외) 범례 추가 (2) 칼럼 사이즈 수정
* 1.3     2023.09.06       은성우           [양극재CheckSheet전산화2차] 소분량점검일지 조회 추가
*                                           (1) 발생건수(소분량) 범례 추가
*                                           (2) 소분량점검 일지 LinkSearch 추가
* 1.4     2023.10.18       은성우           [양극재CheckSheet전산화2차] SetDailyRecord() 수정
*                                           (1) 호출 위치 수정 (2) Line param 제외 (3) 화면구분코드 param 조건 제외
* 1.5     2023.11.01       은성우           [양극재CheckSheet전산화2차] NEW_3070_DYRD_COOP2, 화면구분코드 DG05 추가
*                                           (1) dateFormat() 추가
* 1.6     2024.01.22       은성우           [양극재CheckSheet전산화] "DG05"인 경우, MENUID 추가
* 1.7     2024.05.21       은성우           [양극재CheckSheet전산화] 제외일지유형(EXCLUDE_DRTP) Parameter 추가
*************************************************************************************************
*/--%>

<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0279.aspx.cs" Inherits="GMES_IMS_0279" %>

<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>
<%--<%@ Register Src="../common/UserControl/UCAttachFile.ascx" TagName="AttachFile" TagPrefix="uc" %>--%>


<%-- Fucntion --%>
<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">

    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js"></script>
    <script type="text/javascript">        
        //#region== Page Init.  Main ==============================
        var gWeekName = "";
        var gLastDay = 31;
        var gBeforeDate = "";
        var gLabelCnt = 5;
        var gSCRN_DIVS_CD = 'DG01';
        var gSearchChk = false;
        var gGridChk = false;
        var getAreaID = "";
        var getAreaName = "";
        var getLineID = "";
        var getLineName = "";
        var getDailyRecordID = "";
        var getDailyRecordName = "";
        var getTemplateID = "";
        var getTemplateName = "";
        var getGradeID = "";
        var getDate = "";
        var gType = "";
        //var gOpenDsp = false;
        var gSearch = false;
        var gChkCrtnLnIncYn = "N";    // 대표라인포함 선택여부

        $(document).ready(function () {
            // 메뉴ID에 따른 권한 처리
            // IUSM360080 : 생산일지 > 정보조회 > 일지현황판
            // IUSM360090 : 협력사일지 > 정보조회 > 일지현황판
            if (XSSReplace( $("[id$=hidMenuID]").val()  , 1) == "IUSM360080") {
                gSCRN_DIVS_CD = "DG01"; // 정직
            } else {
                if ($("[id$=hidAuthID]").val() == "NEW_3070_DYRD_COOP2")
                {
                    gSCRN_DIVS_CD = "DG05"; // 협력사2
                } else
                {
                    gSCRN_DIVS_CD = "DG03"; // 협력사
                }
            }

            InitData();
            //Color();
            $('#btnApproval').hide();
            $('#btnCancel').hide();
            //$('#lawExp9').hide();
            //$('#lawExp10').hide();
            //$('#lawExp11').hide();
        });

        function InitData() {
            //console.log("AuthID :" + $("[id$=hidAuthID]").val());
            SetArea();
            SetDateTime();
        };

        function onButtonClick(id) {
            /// <summary>버튼클릭 이벤트 처리</summary>  
            try {
                switch (id) {
                    case "btnSearch":
                        if (!Validate("SEARCH")) return;
                        //fnSearch();
                        gSearchChk = true;
                        SetDateTime();
                        gSearch = true;
                        break;
                    case "chkCrtnLnIncYn":
                        var chk = $('#chkCrtnLnIncYn').is(":checked");
                        if (chk) {
                            gChkCrtnLnIncYn = "Y";
                        } else {
                            gChkCrtnLnIncYn = "N";
                        }
                        break;
                    case "btnExcel":
                        if (!Validate("EXCEL")) return;
                        fnExcel();
                        break;
                    default:
                }
            } catch (e) {
                xAlert(e.message);
            }
        }

        function Validate(type) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            var result = true;

            switch (type) {
                case "SEARCH":
                    if ($('#cboArea').combobox('getValue') == '') {
                        msg = "<%=lang.message["25305"]%>";    //공장동을 선택해주세요
                        xAlert(msg);
                        return;
                    }
                    break;

                case "EXCEL":
                    if (RealGrid1.GetRowCount() == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }
                    break;
                default:
            }
            return result;
        }


        //#endregion===========================================================

        //#region== Message & Word ============================================
        // 전체
        var vAllText = "<%=lang.word["All"]%>";
        // 조회내역이 존재하지 않습니다.
        var msgNotFoundList = "<%=lang.message["20051"]%>";
        //#endregion===========================================================
        var vGridFields = [
              { fieldName: "PLAR_CD" }
            , { fieldName: "EQP_SGMT_ID" }
            , { fieldName: "EQP_SGMT_NM" }
            , { fieldName: "LVL1_DYRD_ID" }
            , { fieldName: "LVL1_DYRD_NM" }
            , { fieldName: "LVL2_DYRD_ID" }
            , { fieldName: "LVL2_DYRD_NM" }
            , { fieldName: "CRTN_LN_ID" }
            , { fieldName: "CRTN_LN_YN" }
            , { fieldName: "SCRN_DIVS_CD" }
            , { fieldName: "SAVE_CNT" }
            , { fieldName: "CFM_CNT" }
            , { fieldName: "APRV_CNT" }
            , { fieldName: "MISS_CNT" }
            , { fieldName: "DAY1" }
            , { fieldName: "DAY2" }
            , { fieldName: "DAY3" }
            , { fieldName: "DAY4" }
            , { fieldName: "DAY5" }
            , { fieldName: "DAY6" }
            , { fieldName: "DAY7" }
            , { fieldName: "DAY8" }
            , { fieldName: "DAY9" }
            , { fieldName: "DAY10" }
            , { fieldName: "DAY11" }
            , { fieldName: "DAY12" }
            , { fieldName: "DAY13" }
            , { fieldName: "DAY14" }
            , { fieldName: "DAY15" }
            , { fieldName: "DAY16" }
            , { fieldName: "DAY17" }
            , { fieldName: "DAY18" }
            , { fieldName: "DAY19" }
            , { fieldName: "DAY20" }
            , { fieldName: "DAY21" }
            , { fieldName: "DAY22" }
            , { fieldName: "DAY23" }
            , { fieldName: "DAY24" }
            , { fieldName: "DAY25" }
            , { fieldName: "DAY26" }
            , { fieldName: "DAY27" }
            , { fieldName: "DAY28" }
            , { fieldName: "DAY29" }
            , { fieldName: "DAY30" }
            , { fieldName: "DAY31" }
            , { fieldName: "DAY1_CD" }
            , { fieldName: "DAY2_CD" }
            , { fieldName: "DAY3_CD" }
            , { fieldName: "DAY4_CD" }
            , { fieldName: "DAY5_CD" }
            , { fieldName: "DAY6_CD" }
            , { fieldName: "DAY7_CD" }
            , { fieldName: "DAY8_CD" }
            , { fieldName: "DAY9_CD" }
            , { fieldName: "DAY10_CD" }
            , { fieldName: "DAY11_CD" }
            , { fieldName: "DAY12_CD" }
            , { fieldName: "DAY13_CD" }
            , { fieldName: "DAY14_CD" }
            , { fieldName: "DAY15_CD" }
            , { fieldName: "DAY16_CD" }
            , { fieldName: "DAY17_CD" }
            , { fieldName: "DAY18_CD" }
            , { fieldName: "DAY19_CD" }
            , { fieldName: "DAY20_CD" }
            , { fieldName: "DAY21_CD" }
            , { fieldName: "DAY22_CD" }
            , { fieldName: "DAY23_CD" }
            , { fieldName: "DAY24_CD" }
            , { fieldName: "DAY25_CD" }
            , { fieldName: "DAY26_CD" }
            , { fieldName: "DAY27_CD" }
            , { fieldName: "DAY28_CD" }
            , { fieldName: "DAY29_CD" }
            , { fieldName: "DAY30_CD" }
            , { fieldName: "DAY31_CD" }
            ];

        var vGridColumns = [
              { name: "PLAR_CD", fieldName: "PLAR_CD", header: { text: "<%=lang.word["PLAR_CD"]%>" }, editable: false, readOnly: true, visible: false, width: 100, styles: { textAlignment: "center" } }
            , { name: "EQP_SGMT_ID", fieldName: "EQP_SGMT_ID", header: { text: "<%=lang.word["EQP_SGMT_ID"]%>" }, editable: false, readOnly: true, visible: false, width: 100, styles: { textAlignment: "center" } }
            , { name: "LVL1_DYRD_ID", fieldName: "LVL1_DYRD_ID", header: { text: "<%=lang.word["LVL1_DYRD_ID"]%>" }, editable: false, readOnly: true, visible: false, width: 100, styles: { textAlignment: "center" } }
            , { name: "LVL2_DYRD_ID", fieldName: "LVL2_DYRD_ID", header: { text: "<%=lang.word["LVL2_DYRD_ID"]%>" }, editable: false, readOnly: true, visible: false, width: 100, styles: { textAlignment: "center" } }
            , { name: "CRTN_LN_ID", fieldName: "CRTN_LN_ID", header: { text: "<%=lang.word["CRTN_LN_ID"]%>" }, editable: false, readOnly: true, visible: false, width: 100, styles: { textAlignment: "center" } }
            , { name: "CRTN_LN_YN", fieldName: "CRTN_LN_YN", header: { text: "<%=lang.word["CRTN_LN_YN"]%>" }, editable: false, readOnly: true, visible: false, width: 100, styles: { textAlignment: "center" } }
            , { name: "SCRN_DIVS_CD", fieldName: "SCRN_DIVS_CD", header: { text: "<%=lang.word["SCRN_DIVS_CD"]%>" }, editable: false, readOnly: true, visible: false, width: 100, styles: { textAlignment: "center" } }
            , {
                type: "group",
                name: "LEVEL",
                header: { text: "<%=lang.word["Item"]%>" },
                style: { textAligment: "center" },
                hideChildHeaders: false,
                width: 260,
                columns: [
                          { name: "EQP_SGMT_NM", fieldName: "EQP_SGMT_NM", header: { text: "<%=lang.word["Line"]%>" }, editable: false, readOnly: true, visible: true, width: 60, styles: { textAlignment: "center" } }
                        , { name: "LVL1_DYRD_NM", fieldName: "LVL1_DYRD_NM", header: { text: "<%=lang.word["Type"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                        , { name: "LVL2_DYRD_NM", fieldName: "LVL2_DYRD_NM", header: { text: "<%=lang.word["DailyRecord"]%>" }, editable: false, readOnly: true, visible: true, width: 130, styles: { textAlignment: "center" } }
                ]
              }
            , {
                type: "group",
                name: "STATUS",
                header: { text: "<%=lang.word["Status"]%>(<%=lang.word["Count."]%>)" },
                style: { textAligment: "center" },
                hideChildHeaders: false,
                width: 240,
                columns: [
                          { name: "SAVE_CNT", fieldName: "SAVE_CNT", header: { text: "<%=lang.word["TEMPSAVE"]%>" }, editable: false, readOnly: true, visible: true, width: 60, styles: { textAlignment: "center" } }
                        , { name: "CFM_CNT" , fieldName: "CFM_CNT" , header: { text: "<%=lang.word["Inspection completed"]%>" }, editable: false, readOnly: true, visible: true, width: 60, styles: { textAlignment: "center" } }
                        , { name: "APRV_CNT", fieldName: "APRV_CNT", header: { text: "<%=lang.word["Approval"]%><%=lang.word["Complete"]%>" }, editable: false, readOnly: true, visible: true, width: 60, styles: { textAlignment: "center" } }
                        , { name: "MISS_CNT", fieldName: "MISS_CNT", header: { text: "<%=lang.word["Write"]%><%=lang.word["Omission"]%>" }, editable: false, readOnly: true, visible: true, width: 60, styles: { textAlignment: "center" } }
                ]
              }
            , {
                type: "group",
                name: "DATE",
                header: { text: "<%=lang.word["DATE"]%>" },
                style: { textAligment: "center" },
                hideChildHeaders: false,
                width: 3100,
                columns: [
                      { name: "DAY1", fieldName: "DAY1", header: { text: "<%=lang.word["1"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY2", fieldName: "DAY2", header: { text: "<%=lang.word["2"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY3", fieldName: "DAY3", header: { text: "<%=lang.word["3"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY4", fieldName: "DAY4", header: { text: "<%=lang.word["4"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY5", fieldName: "DAY5", header: { text: "<%=lang.word["5"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY6", fieldName: "DAY6", header: { text: "<%=lang.word["6"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY7", fieldName: "DAY7", header: { text: "<%=lang.word["7"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY8", fieldName: "DAY8", header: { text: "<%=lang.word["8"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY9", fieldName: "DAY9", header: { text: "<%=lang.word["9"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY10", fieldName: "DAY10", header: { text: "<%=lang.word["10"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY11", fieldName: "DAY11", header: { text: "<%=lang.word["11"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY12", fieldName: "DAY12", header: { text: "<%=lang.word["12"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY13", fieldName: "DAY13", header: { text: "<%=lang.word["13"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY14", fieldName: "DAY14", header: { text: "<%=lang.word["14"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY15", fieldName: "DAY15", header: { text: "<%=lang.word["15"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY16", fieldName: "DAY16", header: { text: "<%=lang.word["16"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY17", fieldName: "DAY17", header: { text: "<%=lang.word["17"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY18", fieldName: "DAY18", header: { text: "<%=lang.word["18"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY19", fieldName: "DAY19", header: { text: "<%=lang.word["19"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY20", fieldName: "DAY20", header: { text: "<%=lang.word["20"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY21", fieldName: "DAY21", header: { text: "<%=lang.word["21"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY22", fieldName: "DAY22", header: { text: "<%=lang.word["22"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY23", fieldName: "DAY23", header: { text: "<%=lang.word["23"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY24", fieldName: "DAY24", header: { text: "<%=lang.word["24"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY25", fieldName: "DAY25", header: { text: "<%=lang.word["25"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY26", fieldName: "DAY26", header: { text: "<%=lang.word["26"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY27", fieldName: "DAY27", header: { text: "<%=lang.word["27"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY28", fieldName: "DAY28", header: { text: "<%=lang.word["28"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY29", fieldName: "DAY29", header: { text: "<%=lang.word["29"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY30", fieldName: "DAY30", header: { text: "<%=lang.word["30"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                    , { name: "DAY31", fieldName: "DAY31", header: { text: "<%=lang.word["31"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }

                    , { name: "DAY1_CD" , fieldName: "DAY1_CD", header: { text: "<%=lang.word["1"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY2_CD" , fieldName: "DAY2_CD", header: { text: "<%=lang.word["2"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY3_CD" , fieldName: "DAY3_CD", header: { text: "<%=lang.word["3"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY4_CD" , fieldName: "DAY4_CD", header: { text: "<%=lang.word["4"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY5_CD" , fieldName: "DAY5_CD", header: { text: "<%=lang.word["5"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY6_CD" , fieldName: "DAY6_CD", header: { text: "<%=lang.word["6"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY7_CD" , fieldName: "DAY7_CD", header: { text: "<%=lang.word["7"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY8_CD" , fieldName: "DAY8_CD", header: { text: "<%=lang.word["8"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY9_CD" , fieldName: "DAY9_CD", header: { text: "<%=lang.word["9"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY10_CD", fieldName: "DAY10_CD", header: { text: "<%=lang.word["10"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY11_CD", fieldName: "DAY11_CD", header: { text: "<%=lang.word["11"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY12_CD", fieldName: "DAY12_CD", header: { text: "<%=lang.word["12"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY13_CD", fieldName: "DAY13_CD", header: { text: "<%=lang.word["13"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY14_CD", fieldName: "DAY14_CD", header: { text: "<%=lang.word["14"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY15_CD", fieldName: "DAY15_CD", header: { text: "<%=lang.word["15"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY16_CD", fieldName: "DAY16_CD", header: { text: "<%=lang.word["16"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY17_CD", fieldName: "DAY17_CD", header: { text: "<%=lang.word["17"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY18_CD", fieldName: "DAY18_CD", header: { text: "<%=lang.word["18"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY19_CD", fieldName: "DAY19_CD", header: { text: "<%=lang.word["19"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY20_CD", fieldName: "DAY20_CD", header: { text: "<%=lang.word["20"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY21_CD", fieldName: "DAY21_CD", header: { text: "<%=lang.word["21"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY22_CD", fieldName: "DAY22_CD", header: { text: "<%=lang.word["22"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY23_CD", fieldName: "DAY23_CD", header: { text: "<%=lang.word["23"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY24_CD", fieldName: "DAY24_CD", header: { text: "<%=lang.word["24"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY25_CD", fieldName: "DAY25_CD", header: { text: "<%=lang.word["25"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY26_CD", fieldName: "DAY26_CD", header: { text: "<%=lang.word["26"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY27_CD", fieldName: "DAY27_CD", header: { text: "<%=lang.word["27"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY28_CD", fieldName: "DAY28_CD", header: { text: "<%=lang.word["28"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY29_CD", fieldName: "DAY29_CD", header: { text: "<%=lang.word["29"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY30_CD", fieldName: "DAY30_CD", header: { text: "<%=lang.word["30"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                    , { name: "DAY31_CD", fieldName: "DAY31_CD", header: { text: "<%=lang.word["31"]%>" }, editable: false, readOnly: true, visible: false, width: 60, styles: { textAlignment: "center" } }
                ]
              }
        ];

        function InitRealgrid(LabelCnt, LastDay) {
            RealGrid1.ColumnsClear();
            if (!gGridChk) {
                RealGrid1.Init("<%=ViewState["MENU_ID"].ToString()%>", vGridFields, vGridColumns, false, false, true);

                RealGrid1_gridView.setOptions({
                    body: {
                        rowStylesFirst: "true"
                    }
                });

                var options = RealGrid1_gridView.getSortingOptions();
                options.enabled = false;
                RealGrid1_gridView.setSortingOptions(options);

                gGridChk = true;

                RealGrid1_gridView.setFixedOptions({ colCount: 2 });
            }

            RealGrid1_gridView.setColumnProperty("DATE", "header", { text: $('#dtDate').datetimespinner('getValue') });

            // 2023.11.01 은성우 "DG05"인 경우, DSP 이미지 표현
            if (gSCRN_DIVS_CD == "DG03") {
                RealGrid1_gridView.setColumnProperty("LEVEL", "header", { text: "<%=lang.word[" "]%>", imageLocation: "left", imageUrl: "/images/proscom.png" });
            } else if (gSCRN_DIVS_CD == "DG05") {
                RealGrid1_gridView.setColumnProperty("LEVEL", "header", { text: "<%=lang.word[" "]%>", imageLocation: "left", imageUrl: "/images/logo_dsp.png" });
            }

            if (gWeekName.indexOf("요일") > 0) gWeekName = gWeekName.substr(0, 1);
            else if (gWeekName.indexOf("星") > -1) gWeekName = gWeekName;
            else gWeekName = gWeekName.substr(0, 3);

            for (var i = 1; i < Number(LastDay) + 1; i++) {
                var fGroundColor = "#000000";
                var bGroundColor = "#FFFFFF";
                var toDay = dateFormat(new Date(), "yyyyMMdd");
                // 현재일이 오늘인 경우, 칼럼속성(foreground, background)을 변경한다.
                if (toDay.substr(0, 6) == gBeforeDate.substr(0, 6)) {
                    if (toDay.substr(6, 2) == i) {
                        fGroundColor = "#FFFFFF";
                        bGroundColor = "#000000";
                    }
                }
                var hText = i + "(" + gWeekName + ")";

                if (gWeekName == "토" || gWeekName == "Sat") RealGrid1_gridView.setColumnProperty("DAY" + i, "header", { text: hText, styles: { foreground: "#0054FF", background: bGroundColor } });
                else if (gWeekName == "일" || gWeekName == "Sun" || gWeekName == "星期六" || gWeekName == "星期日") RealGrid1_gridView.setColumnProperty("DAY" + i, "header", { text: hText, styles: { foreground: "#ff0000", background: bGroundColor } });
                else RealGrid1_gridView.setColumnProperty("DAY" + i, "header", { text: hText, styles: { foreground: fGroundColor, background: bGroundColor } });

                if (gWeekName == "월" || gWeekName == "Mon" || gWeekName == "星期一") gWeekName = "<%=lang.word["Tuesday"]%>";//"화";
                else if (gWeekName == "화" || gWeekName == "Tue" || gWeekName == "星期二") gWeekName = "<%=lang.word["Wednesday"]%>";//"수";
                else if (gWeekName == "수" || gWeekName == "Wed" || gWeekName == "星期三") gWeekName = "<%=lang.word["Thursday"]%>";//"목";
                else if (gWeekName == "목" || gWeekName == "Thu" || gWeekName == "星期四") gWeekName = "<%=lang.word["Friday"]%>";//"금";
                else if (gWeekName == "금" || gWeekName == "Fri" || gWeekName == "星期五") gWeekName = "<%=lang.word["Saturday"]%>";//"토";
                else if (gWeekName == "토" || gWeekName == "Sat" || gWeekName == "星期六") gWeekName = "<%=lang.word["Sunday"]%>";//"일";
                else if (gWeekName == "일" || gWeekName == "Sun" || gWeekName == "星期日") gWeekName = "<%=lang.word["Monday"]%>";//"월";

                if (gWeekName.indexOf("요일") > 0) gWeekName = gWeekName.substr(0, 1);
                else if (gWeekName.indexOf("星") > -1) gWeekName = gWeekName;
                else gWeekName = gWeekName.substr(0, 3);
            }
           
            // mergeRule 정의
            RealGrid1_gridView.setColumnProperty("EQP_SGMT_NM", "mergeRule", { criteria: "values['EQP_SGMT_NM']" });
            RealGrid1_gridView.setColumnProperty("LVL1_DYRD_NM", "mergeRule", { criteria: "values['LVL1_DYRD_NM'] + values['EQP_SGMT_NM']" });

            if (LastDay == 28) {
                RealGrid1_gridView.setColumnProperty("DAY29", "visible", false);
                RealGrid1_gridView.setColumnProperty("DAY30", "visible", false);
                RealGrid1_gridView.setColumnProperty("DAY31", "visible", false);
                RealGrid1_gridView.setColumnProperty("DATE" , "width"  , 2800);
            }
            else if (LastDay == 29) {
                RealGrid1_gridView.setColumnProperty("DAY29", "visible", true);
                RealGrid1_gridView.setColumnProperty("DAY30", "visible", false);
                RealGrid1_gridView.setColumnProperty("DAY31", "visible", false);
                RealGrid1_gridView.setColumnProperty("DATE" , "width"  , 2900);
            }
            else if (LastDay == 30) {
                RealGrid1_gridView.setColumnProperty("DAY29", "visible", true);
                RealGrid1_gridView.setColumnProperty("DAY30", "visible", true);
                RealGrid1_gridView.setColumnProperty("DAY31", "visible", false);
                RealGrid1_gridView.setColumnProperty("DATE" , "width"  , 3000);
            }
            else if (LastDay == 31) {
                RealGrid1_gridView.setColumnProperty("DAY29", "visible", true);
                RealGrid1_gridView.setColumnProperty("DAY30", "visible", true);
                RealGrid1_gridView.setColumnProperty("DAY31", "visible", true);
                RealGrid1_gridView.setColumnProperty("DATE" , "width"  , 3100);
            }

            // 그리드 더블클릭 이벤트
            RealGrid1_DblClicked = function (grid, index) {
                var current = RealGrid1.GetCurrent();
                if (current != null) {
                    fnLinkSearch(current, index);
                }
            }
            //gOpenDsp = true;
        }
        //#region== Realgrid Column & Field Info ==============================      
        

        //#endregion==============================================================

        //#region== Button Event ==============================
        function fnSearch() {
            var items = {};
            getAreaID = $('#cboArea').combobox('getValue');
            getAreaName = $('#cboArea').combobox('getText');
            getLineID = $('#cboLine').combobox('getValue');
            getLineName = $('#cboLine').combobox('getText');
            getDailyRecordID = $('#cboDailyRecord').combobox('getValue');
            getDailyRecordName = $('#cboDailyRecord').combobox('getText');

            items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1);
            items.PLNT_CD = XSSReplace($("[id$=hidShopID]").val()   , 1);
            items.PLAR_CD = getAreaID;
            items.EQP_SGMT_ID = getLineID;
            items.DYRD_TP = getDailyRecordID;
            items.SCRN_DIVS_CD = gSCRN_DIVS_CD;

            getDate = $('#dtDate').datetimespinner('getValue');
            items.WK_DT = getDate.replace(/-/g, ''); //getDate.replace("-", "");
            items.CRTN_LN_INC_YN = gChkCrtnLnIncYn; // 대표라인포함여부

            var param = {};
            param.bizID = "BR_IM_PRD_SEL_DYRD_DASHBOARD";
            param.items = items;
            param.inTableNames = "INDATA";
            param.outTableNames = "OUTDATA";

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";
            RealGrid1.CallRequest(url, param);
            RealGrid1.Refresh();
        };

        /**
         * 그리드 Cell을 더블클릭한 경우, 화면Tab을 추가 후 조회조건을 자동설정하고 자동조회한다.
         */
        function fnLinkSearch(current, index)
        {
            var plarCd     = RealGrid1_dataProvider.getValue(current.dataRow, "PLAR_CD");
            var eqpSgmtId  = RealGrid1_dataProvider.getValue(current.dataRow, "EQP_SGMT_ID");
            var lvl1DyrdId = RealGrid1_dataProvider.getValue(current.dataRow, "LVL1_DYRD_ID");
            var lvl2DyrdId = RealGrid1_dataProvider.getValue(current.dataRow, "LVL2_DYRD_ID");
            var scrnDivsCd = RealGrid1_dataProvider.getValue(current.dataRow, "SCRN_DIVS_CD");
            var scrnDivsCd = RealGrid1_dataProvider.getValue(current.dataRow, "SCRN_DIVS_CD");

            var menuId = null;
            var wkDate = getDate;

            if (scrnDivsCd == "DG01")
            {
                // 일지관리(GMES_IMES_0272)
                menuId = "IUSM360040";
            } else if (scrnDivsCd == "DG02")
            {
                // JC일지관리(GMES_IMES_0273)
                menuId = "IUSM360050";
            } else if (scrnDivsCd == "DG03")
            {
                // 프로에스컴 일지관리(GMES_IMES_0272)
                menuId = "IUSM360060";
            } else if (scrnDivsCd == "DG04")
            {
                // 소분량점검 일지(GMES_IMES_0275)
                menuId = "IUSM360100";

                //var field = RealGrid1.GetOrgFieldNames();
                //var fieldIndex = RealGrid1.findField(field, index.fieldName);
                var fieldName = index.fieldName.replace("DAY", "");
                var sDay = (fieldName.length == 1 ? "0" : "") + fieldName; // "9" -> "09"
                wkDate = getDate + "-" + sDay; // yyyy-mm-dd
            } else if (scrnDivsCd == "DG05")
            {
                // 디에스피일지관리(GMES_IMES_0272)
                menuId = "IUSM360110";
            }

            var items = {};
            items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1);
            items.MENUID = menuId;
            var param = {};
            param.bizID = "COM_SEL_MenuInfo";
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            sendRequestMethod(function (id, datas) {
                if (datas != null && datas.length > 0) {
                    var url = null;
                    var title = null;

                    url = "../" + datas[0].MENUPATH;

                    if (url.indexOf('?') == -1) {
                        url = url + "?";
                    }

                    url = url + "ACCESS_FLAG=" + "<%=ViewState["ACCESS_FLAG"].ToString()%>"
                                + "&AUTHID=" + $("[id$=hidAuthID]").val()
                                + "&AREAID=" + plarCd
                                + "&EQSGID=" + eqpSgmtId
                                + "&DYRDTP=" + lvl1DyrdId
                                + "&DYRDID=" + lvl2DyrdId
                                + "&WKDATE=" + wkDate
                                + "&AUTOSEARCH=Y";
                    console.log(url);
                    title = datas[0].MENUNAME;

                    // 2023.08.16 화면Tab을 추가하고 해당화면을 Open한다.(go_DetailTab에서 menuId가 인수로 추가되므로 url에서는 넣지 않는다.)
                    fnAddDetailTab(url, title, menuId, "<%=ViewState["ACCESS_FLAG"].ToString()%>", $("[id$=hidAuthID]").val());
                } else
                {
                    alert("이동할 페이지 경로가 없습니다!");
                    return;
                }
            }, param, "POST", url);
        }

        /**
         * 화면Tab을 추가하고 해당화면을 Open한다.
         */
        function fnAddDetailTab(url, title, menuId, access_flag, authid) {
            // "../FrmFirst.aspx/go_DetailTab" 호출
            window.top.go_DetailTab(url, title, menuId, access_flag, authid);
        }

        function AutoHeight() {

            var item = $('#pnlSubArea').panel('options').expandMode;

            var mainAreaHeight = document.getElementById('MainArea').offsetHeight;

            var subAreaHeight = document.getElementById('pnlSubArea').offsetHeight;

            if (item == 'Dock') {
                $('.ifCss').css('height', $(window).height() - subAreaHeight - 35 + 'px');
                $('.ifCss').css('width', +$(window).width() + 'px');

                $('.ifSubCss').css('height', subAreaHeight - 15 + 'px');
                $('.ifSubCss').css('width', +$(window).width() + 'px');
            }
            else {
                $('.ifCss').css('height', $(window).height() - 35 + 'px');
                $('.ifCss').css('width', +$(window).width() + 'px');

                $('.ifSubCss').css('height', subAreaHeight - 15 + 'px');
                $('.ifSubCss').css('width', +$(window).width() + 'px');
            }
        }

        function fnExcel(obj) {


            var vToday = getDailyRecordName + "_" + getTemplateName + "_" + new Date().format("yyyyMMddhhmmss") + ".xlsx";
            if (gSCRN_DIVS_CD == "DG03") {
                RealGrid1.ExcelExport_WithImage(vToday, "LEVEL");
            }
            else {
                RealGrid1_gridView.exportGrid({
                    target: "local",
                    type: "excel",
                    applyDynamicStyles: "true",
                    fileName: vToday,
                    compatibility: true,
                    lookupDisplay: true
                });
            }
        };
        
        function RealGrid1_LoadDataCompleted() {
            /// <summary></summary> 
            if (RealGrid1.GetRowCount() == 0) {
                xAlert(msgNotFoundList);
            }

            RealGrid1_gridView.setColumnProperty(
                RealGrid1_gridView.columnByField("LVL2_DYRD_NM")
                    , "dynamicStyles"
                    , [
                       {
                           criteria: "(value['CRTN_LN_YN'] = 'Y')"
                        , styles: { font: "Arial, 12", foreground: "#A6A6A6" }
                       }
                    ]
            );

            RealGrid1_gridView.setColumnProperty(
                RealGrid1_gridView.columnByField("SAVE_CNT")
                    , "dynamicStyles"
                    , [
                       {
                           criteria: "(value['CRTN_LN_YN'] = 'Y')"
                        , styles: { font: "Arial, 12", foreground: "#A6A6A6" }
                       }
                    ]
            );

            RealGrid1_gridView.setColumnProperty(
                RealGrid1_gridView.columnByField("CFM_CNT")
                    , "dynamicStyles"
                    , [
                       {
                           criteria: "(value['CRTN_LN_YN'] = 'Y')"
                        , styles: { font: "Arial, 12", foreground: "#A6A6A6" }
                       }
                    ]
            );

            RealGrid1_gridView.setColumnProperty(
                RealGrid1_gridView.columnByField("APRV_CNT")
                    , "dynamicStyles"
                    , [
                       {
                           criteria: "(value['CRTN_LN_YN'] = 'Y')"
                        , styles: { font: "Arial, 12", foreground: "#A6A6A6" }
                       }
                    ]
            );

            RealGrid1_gridView.setColumnProperty(
                RealGrid1_gridView.columnByField("MISS_CNT")
                    , "dynamicStyles"
                    , [
                       { 
                           criteria: "(value['MISS_CNT'] > 0)" // 누락건수 > 0
                        , styles: { font: "Arial, 12", foreground: "#FF0000" }
                       },
                       {
                           criteria: "(value['CRTN_LN_YN'] = 'Y')" // 대표라인여부
                        , styles: { font: "Arial, 12", foreground: "#FFA6A6" }
                       },
                       {
                           criteria: "(value['MISS_CNT'] = 0)" // 누락건수 = 0
                        , styles: { font: "Arial, 12", foreground: "#000000" }
                       }
                      ]
            );

            for (var i = 1; i < Number(gLastDay) + 1; i++) {
                RealGrid1_gridView.setColumnProperty(
                    RealGrid1_gridView.columnByField("DAY" + i)
                    , "dynamicStyles"
                    , [
                       // 대표라인ID가 미존재하는 경우
                       { 
                           criteria: "(value['DAY" + i + "_CD'] = 'MISS')" // 회색 : 누락
                        , styles: { font: "Arial, 12", background: "#D5D5D5", foreground: "#000000" }
                       }, 
                       { 
                           criteria: "(value['DAY" + i + "_CD'] = 'SAVE')" // 살색 : 임시저장
                        , styles: { font: "Arial, 12", background: "#FF8E7F", foreground: "#000000" }
                       }, 
                       {   
                           criteria: "(value['DAY" + i + "_CD'] = 'CFM')" // 파랑 : 점검완료
                        , styles: { font: "Arial, 12", background: "#89A5EA", foreground: "#000000" }
                       }, 
                       {
                           criteria: "(value['DAY" + i + "_CD'] = 'APRV')" // 녹색 : 승인완료
                        , styles: { font: "Arial, 12", background: "#A5EA89", foreground: "#000000" }
                       },
                       // 대표라인ID가 존재하는 경우
                       {
                           criteria: "(value['CRTN_LN_YN'] + value['DAY" + i + "_CD'] = 'YMISS')" // 회색 : 누락
                        , styles: { font: "Arial, 12", background: "#EAEAEA", foreground: "#A6A6A6" }
                       },
                       {
                           criteria: "(value['CRTN_LN_YN'] + value['DAY" + i + "_CD'] = 'YSAVE')" // 살색 : 임시저장
                        , styles: { font: "Arial, 12", background: "#FFD0C9", foreground: "#A6A6A6" }
                       },
                       {
                           criteria: "(value['CRTN_LN_YN'] + value['DAY" + i + "_CD'] = 'YCFM')" // 파랑 : 점검완료
                        , styles: { font: "Arial, 12", background: "#C0CCEB", foreground: "#A6A6A6" }
                       },
                       {
                           criteria: "(value['CRTN_LN_YN'] + value['DAY" + i + "_CD'] = 'YAPRV')" // 녹색 : 승인완료
                        , styles: { font: "Arial, 12", background: "#CCEBC0", foreground: "#A6A6A6" }
                       }
                      ]
                );
            }
        }

        //#endregion==============================================================


        //#region== Set Control ==============================
        <%-- 2023.08.17 삭제
        function GetLevel(Code) {

            var items = {};
            items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1);
            items.PLNT_CD  = XSSReplace($("[id$=hidShopID]").val()   , 1);
            items.PLAR_CD = $('#cboArea').combobox('getValue');
            items.EQP_SGMT_ID = $('#cboLine').combobox('getValue');
            items.PRNT_DYRD_CD = Code;
            var param = {};
            param.bizID = "DA_IM_BAS_SEL_DAILYRECORD_TEMPLATE";
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            sendRequestMethod(function (id, datas) {
                if (datas != null && datas.length > 0) {
                    gLabelCnt = datas[0].LABELCNT;
                }
            }, param, "POST", url);
        }
        --%>

        <%-- 2023.08.17 삭제
        function GetApprovalUser(Code) {
            if (Code == "") {
                $('#btnApproval').hide();
                $('#btnCancel').hide();
                return;
            }
            else if (gSCRN_DIVS_CD == 'DG03' && $("[id$=hidAuthID]").val() != "NEW_3070_DYRD_COOP")
            {
                $('#btnApproval').hide();
                $('#btnCancel').hide();
                return;
            }

            var items = {};
            items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1);
            items.CMCDTYPE = 'DYRD_APPROVER'
            items.ATTRIBUTE1 = XSSReplace($("[id$=hidShopID]").val()   , 1); // 플랜트
            if ($("[id$=hidAuthID]").val() != "NEW_3070_DYRD_COOP" && gSCRN_DIVS_CD != 'DG03') items.ATTRIBUTE2 = Code; // 단위플랜트
            //items.ATTRIBUTE2 = $('#cboArea').combobox('getValue'); // 단위플랜트
            //items.ATTRIBUTE3 = Code; //라인
            items.CMCODE = XSSReplace( $("[id$=hidUserID]").val()  , 1);

            var param = {};
            param.bizID = "DA_IM_PRD_SEL_DYRD_COMMON";
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            sendRequestMethod(function (id, datas) {
                if (datas != null && datas.length > 0) {
                    $('#btnApproval').show();
                    $('#btnCancel').show();
                }
                else {
                    $('#btnApproval').hide();
                    $('#btnCancel').hide();
                }
            }, param, "POST", url);
        }
        --%>

        //일자 세팅
        function SetDateTime() {
            var items = {};
            var dt = $('#dtDate').datetimespinner('getValue');
            var toDay = dateFormat(new Date(), "yyyyMM");
            
            items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1);
            if (dt != "" && dt != null) items.DATE = dateFormat(new Date(dt), "yyyyMM");
            else items.DATE = toDay;

            var param = {};
            param.bizID = "DA_IM_BAS_SEL_DAILYRECORD_MONTH_DAY_WEEK";
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            sendRequestMethod(function (id, datas) {
                if (datas != null && datas.length > 0) {
                    $('#dtDate').datetimespinner('setValue', datas[0].STARTMONTHDATE);
                    gWeekName = datas[0].WEEKNAME;
                    gLastDay = datas[0].LASTDAY;
                    gBeforeDate = datas[0].STARTMONTHDATE.replace("-", "").substr(0, 6);
                    InitRealgrid(gLabelCnt, gLastDay);
                    if (gSearchChk) {
                        fnSearch();
                        gSearchChk = false;
                    }
                }
                else {
                    var toDay = dateFormat(new Date(), "yyyyMM");
                    $('#dtDate').datetimespinner('setValue', toDay);
                }
            }, param, "POST", url);
        }

        function dateFormat(dateTime, formatStr) {
            var str = formatStr;
            var Week = ['日', '一', '二', '三', '四', '五', '六'];
            var month = dateTime.getMonth() + 1;
            str = str.replace(/yyyy|YYYY/, dateTime.getFullYear());
            str = str.replace(/yy|YY/, (dateTime.getYear() % 100) > 9 ? (dateTime.getYear() % 100).toString() : '0' + (dateTime.getYear() % 100));

            str = str.replace(/MM/, month > 9 ? month.toString() : '0' + month);
            str = str.replace(/M/g, month);

            str = str.replace(/w|W/g, Week[dateTime.getDay()]);

            str = str.replace(/dd|DD/, dateTime.getDate() > 9 ? dateTime.getDate().toString() : '0' + dateTime.getDate());
            str = str.replace(/d|D/g, dateTime.getDate());

            str = str.replace(/hh|HH/, dateTime.getHours() > 9 ? dateTime.getHours().toString() : '0' + dateTime.getHours());
            str = str.replace(/h|H/g, dateTime.getHours());
            str = str.replace(/mm/, dateTime.getMinutes() > 9 ? dateTime.getMinutes().toString() : '0' + dateTime.getMinutes());
            str = str.replace(/m/g, dateTime.getMinutes());

            str = str.replace(/ss|SS/, dateTime.getSeconds() > 9 ? dateTime.getSeconds().toString() : '0' + dateTime.getSeconds());
            str = str.replace(/s|S/g, dateTime.getSeconds());

            return str;
        }

        function SetArea() {
            /// <summary>공장/동 콤보박스에 데이터를 설정한다.</summary>  
            
            $('#cboArea').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_AREA_CBO&AREAIUSE=Y&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1)
                    + '&SHOPID=' + XSSReplace($("[id$=hidShopID]").val()   , 1) + '&SHOPIUSE=Y&EQSGTYPE=LINE&USERID=' + XSSReplace( $("[id$=hidUserID]").val()  , 1) + '&CBOOPT=OPT|AREAID|AREANAME_ML',
                valueField: 'AREAID',
                textField: 'AREANAME_ML',
                onSelect: function (row) {
                    SetLine(row);
                    SetDailyRecord(row);
                    //GetApprovalUser(row.AREAID);
                },
                onLoadSuccess: function () {
                    var items = $(this).combobox("getData");
                    if (items.length === 2) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                },
                onLoadSuccess: function () {

                    var autoSelect = false;
                    var AREAIDValue = "<%=SSUser.AreaID%>";

                        if (AREAIDValue.length > 0) {
                            var items = $(this).combobox("getData");
                            var opts = $(this).combobox("options");
                            var strIn = false;
                            for (var i = 0; i < items.length; i++) {
                                if (items[i][opts.valueField] == AREAIDValue) { // 콤보박스 데이터가 있다면 있음 표시 하고 SELECT될 수 있도록 한다.
                                    strIn = true;
                                    break;
                                }
                            }
                            if (strIn) {
                                $(this).combobox("select", AREAIDValue);
                            } else {
                                autoSelect = true;
                            }
                        } else {
                            autoSelect = true;
                        }

                        if (autoSelect) {

                            var items = $(this).combobox("getData");
                            if (items.length === 2) {
                                var opts = $(this).combobox("options");
                                $(this).combobox("select", items[1][opts.valueField]);
                            }
                        }
                    }
                });
            }

        function SetLine(areaRow) {
            /// <summary>Line</summary>
            $('#cboLine').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&AREAID=' + areaRow.AREAID
                    + '&SHOPID=' + XSSReplace($("[id$=hidShopID]").val()   , 1) + '&PCSGID=PG0056' + '&CBOOPT=ALL|EQSGID|EQSGNAME'
                //url: '../common/xml/CallBizJson.aspx?sp_name=COR_SEL_EQUIPMENTSEGMENT_BY_AREAID&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&AREAID=' + areaRow.AREAID
                //+ '&CBOOPT=OPT|EQSGID|EQSGNAME'
                , valueField: 'EQSGID'
                , textField: 'EQSGNAME'
                , onSelect: function (row) {
                    //SetDailyRecord(row.EQSGID);
                    //if(gOpenDsp) RealGrid1_dataProvider.clearRows();
                }
            });
        }

        //function SetDailyRecord(Code) {
        function SetDailyRecord(areaRow) {
            // 정직(DG01)인 경우, 모든 일지 유형을 조회할 수 있도록 하고, 
            // 협력사인 경우, 해당 구분코드에 해당하는 일지 유형만 조회한다.
            var scrnDivsCd = gSCRN_DIVS_CD;
            var urlString = "";

            // 2023.10.18 은성우 Line param 제외, 화면구분코드 param 조건 제외
            // 2024.05.21 은성우 제외일지유형(EXCLUDE_DRTP) Parameter 추가
            if (gSCRN_DIVS_CD == "DG01")
            {
                urlString = '../common/xml/CallBizJson.aspx?sp_name=DA_IM_BAS_SEL_DAILYRECORD_TYPE&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&PLNT_CD=' + XSSReplace($("[id$=hidShopID]").val()   , 1)
                          + '&PLAR_CD=' + areaRow.AREAID + '&EXCLUDE_DRTP=DRTP014&CBOOPT=ALL|CODE|NAME';
            } else
            {
                urlString = '../common/xml/CallBizJson.aspx?sp_name=DA_IM_BAS_SEL_DAILYRECORD_TYPE&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&PLNT_CD=' + XSSReplace($("[id$=hidShopID]").val()   , 1)
                          + '&PLAR_CD=' + areaRow.AREAID + '&SCRN_DIVS_CD=' + scrnDivsCd + '&EXCLUDE_DRTP=DRTP014&CBOOPT=ALL|CODE|NAME';
            }

            $('#cboDailyRecord').combobox({
                url: urlString,
                valueField: 'CODE',
                textField: 'NAME',
                onSelect: function (row) {
                    //if (row.CODE != '') GetLevel(row.CODE);
                    gSearch = false;
                }
            });
        }

        //#endregion==============================================================

        //#region== Layout Framework ============================== 
        $(window).resize(function () {
            AutoHeightSpread();
        });

        function onSlideResize() {
            AutoHeightSpread();
        };

        function xInitPage() {
            AutoHeightSpread();
        };

        function AutoHeightSpread() {
            var gridMaster = document.getElementById("RealGrid1");
            var masterHeight = document.getElementById("divMasterContent").offsetTop;
            var pageHeight = document.documentElement.clientHeight;
            var dockh = 0;
            if (IsDock()) {
                dockh = DockHeight();
                if (dockh > 0) {
                    dockh = dockh;
                };
            };
            var i = 0;
            i = pageHeight - masterHeight - dockh - 40;
            gridMaster.style.height = String(i) + 'px';
            RealGrid1.ResetSize();
        };

        if (typeof (window.top.MainAlert) != 'function') {
            window.top.MainAlert = function (type, message, popupcallback) {
                if (type == 'Confirm') {
                    var a = confirm(message);
                    popupcallback(a);
                } else {
                    alert(message);
                }
            };

            window.top.ShowPopup = function (url, vWidth, vHeight, vTitle, callback, presizable) { 

                window.open(url, vWidth, vHeight, vTitle, callback, true, presizable);
            };
        }

        Array.prototype.unique = function () {
            var a = {};
            for (var h = 0; h < this.length; h++) {
                if (typeof a[this[h]] == "undefined") a[this[h]] = 1;
            };
            this.length = 0;
            for (var i in a) {
                this[this.length] = i;
            };
            return this;
        };

        function formatter2(date) {
            if (!date) { return ''; }
            var y = date.getFullYear();
            var m = date.getMonth() + 1;
            return y + '-' + (m < 10 ? ('0' + m) : m);
        }

        function parser2(s) {
            if (!s) { return null; }
            var ss = s.split('-');
            var y = parseInt(ss[0], 10);
            var m = parseInt(ss[1], 10);
            if (!isNaN(y) && !isNaN(m)) {
                return new Date(y, m - 1, 1);
            } else {
                return new Date();
            }
        }
        //#endregion==============================================================
    </script>

</asp:Content>


<%-- View --%>
<asp:Content ID="UIContent" ContentPlaceHolderID="bodyHolder" runat="server">

    <form id="form1" runat="server">
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidAuthID" runat="server" />
        <asp:HiddenField ID="hidMenuID" runat="server" />
        <asp:HiddenField ID="hidMenuName" runat="server" />
        <asp:ScriptManager runat="server" ID="ScriptManager1"></asp:ScriptManager>
        
        <div class="tableInquiry searchBox" id="divSearchPart">
            <div class="itemBox">
                <table>
                    <colgroup>
                        <col class="col_10p" />
                        <col class="col_10p" />
                        <col class="col_10p" />
                        <col class="col_10p" />
                        <col class="col_10p" />
                        <col class="col_10p" />
                        <col class="col_10p" />
                        <col class="col_20p" />
                    </colgroup>
                    <tbody>
                        <tr>
                            <!--공장동--> 
                            <th><span class="textPink">*</span><%=lang.word["Area"]%></th>
                            <td>
                                <div style="float: left">
                                    <select id="cboArea" class="easyui-combobox" style="width: 200px" ></select>
                                </div>
                            </td>
                            <!--라인--> 
                            <th><%=lang.word["Line"]%></th>
                            <td>
                                <div style="float: left">
                                    <select id="cboLine" class="easyui-combobox" style="width: 200px"></select></div>
                            </td>
                            <!--유형--> 
                            <th><%=lang.word["Type"]%></th>
                            <td>
                                <div style="float: left">
                                    <select id="cboDailyRecord" class="easyui-combobox" style="width: 200px" ></select>
                                </div>
                            </td>
                            <!--일지--> 
                            <%-- 20230808 삭제
                            <th><span class="textPink">*</span><%=lang.word["DailyRecord"]%></th>
                            <td>
                                <div style="float: left">
                                    <select id="cboTemplate" class="easyui-combobox" style="width: 200px"></select></div>
                            </td>
                            --%>
                            <!--대상월-->
                            <th><span class="textPink">*</span><%=lang.word["TargetMonth"]%></th>
                            <td>
                                <input id="dtDate" class="easyui-datetimespinner" data-options="formatter:formatter2,parser:parser2,selections:[[0,4],[5,7]]" style="width: 100px; min-width: 70px; resize: horizontal; " />
                                <label for="chkCrtnLnIncYn">
                                    <input type="checkbox" id="chkCrtnLnIncYn" onclick="onButtonClick(this.id);"><%=lang.word["Representative"]%><%=lang.word["Line"]%> <%=lang.word["Inclusion"]%>
                                </label>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <div class="tableBtnSearch">
                <button type="button" id="btnSearch" onclick="onButtonClick(this.id);"><span><%=lang.word["Search"]%></span></button>
            </div>
            <uc:SearchToggleContent ID="SearchToggleContent2" runat="server" />
        </div>
        <div id="divMasterContent">
            <div class="buttonArea" id="divMidButton">
                <div id="lawExp1"  class="floatLeft01" style="float:left;">(1) <%=lang.word["DailyRecord"]%><%=lang.word["State"]%> :</div>
                <ul id="ul1" runat="server" class="floatLeft01">
                    <li><a class="table_bar"></a></li>
                </ul> 
                <div id="lawExp2"  class="floatLeft01" style="float:left; background: #FF8E7F; border-color: #FF8E7F"><%=lang.word["TEMPSAVE"]%></div>
                <ul id="ul2" runat="server" class="floatLeft01">
                    <li><a class="table_bar"></a></li>
                </ul> 
                <div id="lawExp3"  class="floatLeft01" style="float:left; background: #89A5EA; border-color: #89A5EA"><%=lang.word["Inspection completed"]%></div>
                <ul id="ul3" runat="server" class="floatLeft01">
                    <li><a class="table_bar"></a></li>
                </ul> 
                <div id="lawExp4"  class="floatLeft01" style="float:left; background: #A5EA89; border-color: #A5EA89"><%=lang.word["Approval"]%><%=lang.word["Complete"]%></div>
                <ul id="ul4" runat="server" class="floatLeft01">
                    <li><a class="table_bar"></a></li>
                </ul> 
                <div id="lawExp5"  class="floatLeft01" style="float:left; background: #D5D5D5; border-color: #D5D5D5"><%=lang.word["Write"]%><%=lang.word["Omission"]%></div>
                <ul id="ul5" runat="server" class="floatLeft01">
                    <li><a class="table_bar"></a></li>
                    <li><a class="table_bar"></a></li>
                    <li><a class="table_bar"></a></li>
                </ul> 

                <!-- 발생건수(소분량) -->
                <div id="lawExp6"  class="floatLeft01" style="float:left;">(2) <%=lang.word["Occurs Count"]%>(<%=lang.word["Quantity of Subdivision"]%>) :</div>
                <ul id="ul6" runat="server" class="floatLeft01">
                    <li><a class="table_bar"></a></li>
                </ul> 
                <!-- 2023.09.06 은성우 범례 추가 - 전체 (점검완료/승인완료) -->
                <div id="lawExp7"  class="floatLeft01" style="float:left; background: #D5D5D5; border-color: #D5D5D5"><%=lang.word["All"]%>(<%=lang.word["Inspection completed"]%>/<%=lang.word["Approval"]%><%=lang.word["Complete"]%>)  </div>
                <ul id="ul7" runat="server" class="floatLeft01">
                    <li><a class="table_bar"></a></li>
                </ul> 

                <!-- 발생건수(소분량 외) -->
                <div id="lawExp8"  class="floatLeft01" style="float:left;">(3) <%=lang.word["Occurs Count"]%>(<%=lang.word["Quantity of Subdivision"]%> <%=lang.word["Except"]%>) :</div>
                <ul id="ul8" runat="server" class="floatLeft01">
                    <li><a class="table_bar"></a></li>
                </ul>

                <!-- 2023.08.28 은성우 범례 추가 - (사진누락/NG발생/SPEC초과/항목값누락) -->
                <div id="lawExp9"  class="floatLeft01" style="float:left; background: #D5D5D5; border-color: #D5D5D5">(<%=lang.word["PICTURE"]%><%=lang.word["Omission"]%>/NG<%=lang.word["Occur"]%>/SPEC<%=lang.word["Excess"]%>/<%=lang.word["ItemValue"]%><%=lang.word["Omission"]%>) </div>
                <ul id="ul9" runat="server" class="floatLeft01">
                    <li><a class="table_bar"></a></li>
                </ul> 

                <ul id="ulBttomButton" runat="server" class="btn_crud"> 
                    <li><a id ="btnExcel" class="excel" onclick="onButtonClick(this.id)"></a></li>
                </ul>
            </div>
            <div id="divMasterGrid" class="table">
                <uc:Realgrid ID="RealGrid1" CALLID="RealGrid1" runat="server" HEIGHT="200" LAYOUTSAVING="Y" />                
            </div>
        </div>
    </form>
</asp:Content>


