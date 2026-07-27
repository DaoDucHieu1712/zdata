<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0257.aspx.cs" Inherits="GMES_IMES_0257" %>

<%--/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0257.aspx
* @desc    : 생산실적 - 정보조회 - DataLake 지표
************************************************************************************************* 
* VER  DATE         AUTHOR              DESCRIPTION
*************************************************************************************************
* 1.0  2025/06/12   오정균              INIT
*************************************************************************************************
*/--%>
<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc2" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>
<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <style type="text/css">
        .th_auto {
            width : auto;
            min-width: 70px;
        }
        .td_fix {
            width: auto;
            max-width: 210px;
        }
        .td_fixEnd {
            width: auto;
            max-width: 210px;
        }
        .search_width {
            width: 210px;
        }
    </style>
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js?v=<%=DateTime.Now.ToString("yyyyMMddHHmmss")%>"></script>
    <script language="javascript" type="text/javascript">
        //#region 익스플로러 대응으로 인한 선언
        // padStart
        String.prototype.padStart = function padStart(targetLength, padString) {
            targetLength = targetLength >> 0; //truncate if number or convert non-number to 0;
            padString = String((typeof padString !== 'undefined' ? padString : ' '));
            if (this.length > targetLength) {
                return String(this);
            }
            else {
                targetLength = targetLength - this.length;
                if (targetLength > padString.length) {
                    padString += padString.repeat(targetLength / padString.length); //append to original to ensure we are longer than needed
                }
                return padString.slice(0, targetLength) + String(this);
            }
        };
        // padStart
        //#endregion

        //#region 변수선언
        // 날짜
        const newDate = new Date();
        const today = '' + newDate.getFullYear() + (newDate.getMonth() + 1).toString().padStart(2, '0') + newDate.getDate().toString().padStart(2, '0') + '';
        // 날짜
        // grid
        const cNumberFormat = "#,##0";  /*기본 숫자 소수점 X*/
        const cQtyFormat = "#,##0.000";  /*수량 소수점 3자리X*/
        const defaultBorder = "#808080, 1";
        var realGridNames;
        var realGridDivs;
        var slideRealGridNames;
        var slideRealGridDivs;
        var autoFilter = {};
        // grid

        const selectBizName = 'DA_SEL_FN_DL_';
        const monthsDay = 31;
        const delay = 300;
        const noGroupBorderBottom = " #ffcccccc, 1";
        var tabIndex = 0;
        var slideTabIndex = 0;
        var timer = null;
        //#endregion

        $(document).ready(function () {
            InitData();
        });

        $(window).resize(function () {
            clearTimeout(timer); // 높이 가지고 오는 시점으로 인한 Timout 처리
            timer = setTimeout(function () {
                AutoHeightSpread();
            }, delay);
        });

        function onSlideResize() {
            AutoHeightSpread();
        };

        function xInitPage() {
            realGridNames = $('[name="realGrid"]'); // realGridNames
            realGridDivs = $('[name="realGrid"]').find('.realGridDiv'); // realGridDiv 클래스
            slideRealGridNames = $('[name="slideRealGrid"]'); // realGridNames
            slideRealGridDivs = $('[name="slideRealGrid"]').find('.realGridDiv'); // realGridDiv 클래스

            AutoHeightSpread();
        };

        //#region AutoHeightSpread - RealGrid의 높이를 재설정한다.
        function AutoHeightSpread() {
            // main
            if (!onNullCheck(realGridDivs)) {
                for (var i = 0; i < realGridDivs.length; i++) {
                    gridResetSize("main", realGridDivs[i].id, getValNewFunction(realGridDivs[i].id), null);
                }
            }
            // main

            // slide
            if (!onNullCheck(slideRealGridDivs)) {
                for (var i = 0; i < slideRealGridDivs.length; i++) {
                    gridResetSize("slide", slideRealGridDivs[i].id, getValNewFunction(slideRealGridDivs[i].id), $("#divSearchPart" + (i + 1)));
                }
            }
            // slide
        }

        function gridResetSize(type, realGridElementById, realGrid, subTabSearch) {
            const slideTabFixHeight = 35; // 슬라이드 TAB 높이
            const mainLayout = parent.$('#MainLayout'); // 화면 (영역은 TAB 포함)
            const mainTabsHeight = mainLayout.find('.tabs-wrap').height(); // 화면 TAB 높이
            var gridHeight = 0; // 높이

            var funCss = function (id, style) {
                var value = id.css(style);
                return (onNullCheck(value) ? 0 : parseInt(value.replace(/[^0-9]/g, "")));
            }

            var divSlideTap = document.getElementById('divSlideTap'); // sub TAP
            var divSlideTapHeight = onZeroCheck(divSlideTap.offsetHeight) ? 0 : (divSlideTap.offsetHeight - (mainTabsHeight - slideTabFixHeight)); // sub TAP 높이 (공통으로 기본 한줄의 TAB 높이만 제외 두줄 이상은 TAB 높이 계산해서 처리)

            switch (type) {
                case "main":
                    const mainLayoutHeight = mainLayout.height(); // 화면 높이 (영역은 TAB 포함) > 사용 가능 : parent.window.document.getElementById('MainLayout').offsetHeight
                    const fixHeight = 82; /*TAB + 버튼*/
                    var minTitleHeight = document.getElementById("div_mainTitle").offsetHeight; // 화면 타이틀 높이
                    var divSearchArea = $("#divSearchArea"); // 화면 조회조건
                    var divSearchAreaHeight = divSearchArea.height() + funCss(divSearchArea, 'margin-bottom'); // 화면 조회조건 높이 (margin 포함)

                    var gridHeight = mainLayoutHeight - mainTabsHeight - minTitleHeight - divSearchAreaHeight - fixHeight - divSlideTapHeight;
                    break
                case "slide":
                    var divSlideTapHeader = $("#SlidePanel").find('.tabs-header'); // subTab의 Tab
                    var divSlideTapHeaderHeight = Math.ceil(divSlideTapHeader.height() + funCss(divSlideTapHeader, 'padding-top')); // subTab의 Tab 높이(padding 포함)
                    var subTabSearchHeight = onNullCheck(subTabSearch) ? 0 : subTabSearch.height(); // subTab의 조회 조건 높이
                    const bottomFixHeight = 13; // 하단 그리드 공백

                    gridHeight = divSlideTapHeight - divSlideTapHeaderHeight - subTabSearchHeight - bottomFixHeight;
                    break
            }

            gridMaster = document.getElementById(realGridElementById);
            gridMaster.style.height = gridHeight + 'px';
            realGrid.ResetSize();
        }
        //#endregion

        //#region Main Realgrid Field, Column 설정
        //#region 양품률
        var ucGoodQtyRateRealgridFields = [
            { fieldName: "AREANAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["AREANAME"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "EQSGNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Equipment Segment"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "PROCNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Process"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "APPLY_DATE", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["Packaging Date"]%>" } },
            { fieldName: "PRODID", columnSetting: { type: "main_id", filterType: false, header: "<%=lang.word["Product Code"]%>" } },
            { fieldName: "PRODNAME", columnSetting: { type: "main_name", filterType: false, header: "<%=lang.word["Drawing No. Name"]%>" } },
            { fieldName: "PACKQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["Packing Qty"]%>" } },
            { fieldName: "RWKQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["Rework"]%> <%=lang.word["Input"]%>" } },
            { fieldName: "REALQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["RealQty"]%>" } },
            { fieldName: "PACKQTY_NG", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["unsuitable"]%> <%=lang.word["Packing Qty"]%>" } },
            { fieldName: "GOODRATE", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["QualityGoods"]%>(%)" } }
        ];
        //#endregion

        //#region 로스율
        var ucLossRateRealgridFields = [
            { fieldName: "AREANAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["AREANAME"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "EQSGNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Equipment Segment"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "APPLY_DATE", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["AGGREGATION"]%> <%=lang.word["Date"]%>" } },
            // 20250617 차후 추가 될 가능성 있음.
            //{ fieldName: "PRODID", columnSetting: { type: "main_id", header: "<%=lang.word["Product Code"]%>" } },
            //{ fieldName: "PRODNAME", columnSetting: { type: "main_name", header: "<%=lang.word["Drawing No. Name"]%>" } },
            // 20250617 차후 추가 될 가능성 있음.
            { fieldName: "PACKQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["Packing Qty"]%>" } },
            { fieldName: "RWKQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["Rework"]%> <%=lang.word["Input"]%>" } },
            { fieldName: "REALQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["RealQty"]%>" } },
            { fieldName: "RESNCODE", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["LossCode"]%>" } },
            { fieldName: "RESNNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["LossName"]%>" } },
            { fieldName: "LOSSQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["LossQty"]%>(Kg)" } },
            { fieldName: "LossRate", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["LossRate"]%>(%)" } }
        ];
        //#endregion

        //#region 제품별 수율
        var ucProductRateRealgridFields = [
            { fieldName: "PTYPE", columnSetting: { type: "main_data", filterType: true, header: "<%=lang.word["Classification"]%>" } },
            { fieldName: "DGROUP", columnSetting: { type: "main_data", filterType: true, header: "<%=lang.word["AGGREGATION"]%> <%=lang.word["Type"]%>" } },
            { fieldName: "DTYPE", columnSetting: { type: "main_data", filterType: true, header: "<%=lang.word["AGGREGATION"]%> <%=lang.word["Group"]%>" } },
            { fieldName: "PROCTYPENAME", columnSetting: { type: "main", filterType: true, header: "<%=lang.word["PROCNAME"]%> <%=lang.word["타입"]%>" } },
            { fieldName: "DTVAL", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["Year"]%>, <%=lang.word["Month"]%>, <%=lang.word["Day"]%>" } },
            { fieldName: "AREANAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["AREANAME"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "EQSGNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Equipment Segment"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "PRODID_GD", columnSetting: { type: "main_id", filterType: false, header: "<%=lang.word["Finished Goods Code"]%>" } },
            { fieldName: "PRODNAME_GD", columnSetting: { type: "main_name", filterType: false, header: "<%=lang.word["Finished Goods"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "PRODID", columnSetting: { type: "main_id", filterType: false, header: "<%=lang.word["Product Code"]%>" } },
            { fieldName: "PRODNAME", columnSetting: { type: "main_name", filterType: false, header: "<%=lang.word["Drawing No. Name"]%>" } },
            { fieldName: "YIELD_TG", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["Target"]%> <%=lang.word["Yield"]%>" } },
            { fieldName: "YIELD", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["Yield"]%>" } },
            { fieldName: "OUTQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["PROD_QTY"]%>" } },
            { fieldName: "INQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["INPUT_QTY"]%>" } },
            { fieldName: "WIPQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["WipQty."]%>" } },
            { fieldName: "WIPQTYNXT", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["TheNextDay"]%> <%=lang.word["WipQty."]%>" } },
            { fieldName: "INPUTQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["INPUT_QTY"]%>(<%=lang.word["WIP"]%><%=lang.word["Inclusion"]%>)" } }
        ]
        //#endregion 

        //#region 생산량(소성기준)
        var ucProdQtySoseongRealgridFields = [
            { fieldName: "AREANAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["AREANAME"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "EQSGNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Equipment Segment"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "APPLY_DATE", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["Burning"]%> <%=lang.word["Date"]%>" } },
            { fieldName: "PRODID", columnSetting: { type: "main_id", filterType: false, header: "<%=lang.word["Product Code"]%>" } },
            { fieldName: "PRODNAME", columnSetting: { type: "main_name", filterType: false, header: "<%=lang.word["Drawing No. Name"]%>" } },
            { fieldName: "PRODQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["PROD_QTY"]%>" } }
        ];
        //#endregion

        //#region 생산량(소성기준)
        var ucProdQtySobunRealgridFields = [
            { fieldName: "AREANAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["AREANAME"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "EQSGNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Equipment Segment"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "PCSGNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["PROC_GROUP"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "PROCNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Process"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "EQPTNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["EQUIPID"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "APPLY_DATE", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["Subdivision"]%> <%=lang.word["Date"]%>" } },
            { fieldName: "PRODID", columnSetting: { type: "main_id", filterType: false, header: "<%=lang.word["Product Code"]%>" } },
            { fieldName: "PRODNAME", columnSetting: { type: "main_name", filterType: false, header: "<%=lang.word["Drawing No. Name"]%>" } },
            { fieldName: "PRODCNT", dataType: "number", columnSetting: { type: "main_number", filterType: false, header: "<%=lang.word["Subdivision"]%> <%=lang.word["Cycle"]%>" } },
            { fieldName: "PRODQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["Quantity of Subdivision"]%>" } },
            { fieldName: "PRODQTY_1TIME", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["TheFirst"]%> <%=lang.word["Quantity of Subdivision"]%>" } }
        ];
        //#endregion
        //#endregion

        //#region Slide Realgrid Field, Column 설정
        //#region 포장실적
        var ucSlidePackingRealgridFields = [
            { fieldName: "AREANAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["AREANAME"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "EQSGNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Equipment Segment"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "PROCNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Process"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "APPLY_DATE", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["Packaging Date"]%>" } },
            { fieldName: "PRODID", columnSetting: { type: "main_id", filterType: false, header: "<%=lang.word["Product Code"]%>" } },
            { fieldName: "PRODNAME", columnSetting: { type: "main_name", filterType: false, header: "<%=lang.word["Drawing No. Name"]%>" } },
            { fieldName: "LOTID", columnSetting: { type: "main_lotid", filterType: false, header: "<%=lang.word["homogeneous"]%> <%=lang.word["LOTID"]%>" } },
            { fieldName: "LOTID_USER_BATCH", columnSetting: { type: "main_lotid", filterType: false, header: "<%=lang.word["homogeneous"]%> <%=lang.word["LOTID_USER"]%>" } },
            { fieldName: "LOTKIND", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["LOT Type"]%>" } },
            { fieldName: "WIPQTY_PACK", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["homogeneous"]%> <%=lang.word["Product QTY"]%>" } },
            { fieldName: "WIPQTY_BATCH", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["Packing Qty"]%>" } },
            { fieldName: "WIPQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["WipQty."]%>" } },
            { fieldName: "INSPRESULT_PROD", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["PROD"]%><%=lang.word["Inspection Result"]%>" } },
            { fieldName: "OQCPASS", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["Shipping Inspection Result"]%>" } },
            { fieldName: "INSPRESULT", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["Inspection Result"]%>" } }
        ];
        //#endregion

        //#region 재작업 투입
        var ucSlideReworkInputRealgridFields = [
            { fieldName: "AREANAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["AREANAME"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "EQSGNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Equipment Segment"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "PROCNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Process"]%> <%=lang.word["Name2"]%>" } },
            { fieldName: "APPLY_DATE", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["Rework"]%> <%=lang.word["Input."]%><%=lang.word["Date"]%>" } },
            { fieldName: "PRODID", columnSetting: { type: "main_id", filterType: false, header: "<%=lang.word["Product Code"]%>" } },
            { fieldName: "PRODNAME", columnSetting: { type: "main_name", filterType: false, header: "<%=lang.word["Drawing No. Name"]%>" } },
            { fieldName: "WOID", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Workorder Id"]%>" } },
            { fieldName: "LOTID", columnSetting: { type: "main_lotid", filterType: false, header: "<%=lang.word["LOTID"]%>" } },
            { fieldName: "LOTID_USER_BATCH", columnSetting: { type: "main_lotid", filterType: false, header: "<%=lang.word["LOTID_USER"]%>" } },
            { fieldName: "RWKQTY", dataType: "number", columnSetting: { type: "main_qty", filterType: false, header: "<%=lang.word["Rework"]%> <%=lang.word["INPUT_QTY"]%>" } },
            { fieldName: "EQPTNAME", columnSetting: { type: "main", filterType: false, header: "<%=lang.word["Input."]%><%=lang.word["EQUIPID"]%>" } },
            { fieldName: "ERP_SNDFLAG", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["ERP Transmission Status"]%>" } },
            { fieldName: "INSPRESULT", columnSetting: { type: "main_data", filterType: false, header: "<%=lang.word["Inspection Result"]%>" } },
            { fieldName: "INSDTTM", dataType: "datetime", columnSetting: { type: "main_dataTime", filterType: false, header: "<%=lang.word["Consumed Datetime"]%>" } },
            { fieldName: "UPDDTTM", dataType: "datetime", columnSetting: { type: "main_dataTime", filterType: false, header: "<%=lang.word["수정일시"]%>" } }
        ];
        //#endregion
        //#endregion

        //#region InitData
        // 컬럼 타입 별 기준 정보 변경
        function setTypeColumn(vType, vColumn) {
            switch (vType) {
                case "main_id":
                    //vColumn.styles.textAlignment = "near";
                    vColumn.width = 200;
                    break
                case "main_name":
                    //vColumn.styles.textAlignment = "near";
                    vColumn.width = 250;
                    break
                case "main_qty":
                    //vColumn.styles.textAlignment = "far";
                    vColumn.styles.numberFormat = cQtyFormat;
                    vColumn.width = 110;
                    vColumn.styles.paddingRight = "6"; // 고정 된 컬럼에 padding 추가
                    break
                case "main_number":
                    //vColumn.styles.textAlignment = "far";
                    vColumn.styles.numberFormat = cNumberFormat;
                    vColumn.width = 110;
                    vColumn.styles.paddingRight = "6"; // 고정 된 컬럼에 padding 추가
                    break
                case "main_data":
                    vColumn.width = 100;
                    break
                case "main_dataTime":
                    vColumn.width = 200;
                    break
                case "main_type":
                    vColumn.width = 80;
                    break
                case "main_type_name":
                    vColumn.width = 250;
                    break
                case "main_lotid":
                    vColumn.width = 200;
                    break
            }

            return vColumn;
        }
        // 컬럼 타입 별 기준 정보 변경

        function InitData() {
            setInitSelectCom();/*콤보박스 초기화*/
            setTabSetting();/*Tab 설정*/
            setSelectCom("AREA", null, $("[id$=hidShopID]").val()); /*조회 조건 설정*/
            SetDateTime();/*초기 날짜 설정*/

            // main
            if (!onNullCheck(realGridNames)) {
                for (var i = 0; i < realGridNames.length; i++) {
                    var isGroup = $("#" + realGridNames[i].id).data("options").group;
                    var isDblClicked = $("#" + realGridNames[i].id).data("options").dblclicked;
                    var dblclicktabindex = $("#" + realGridNames[i].id).data("options").dblclicktabindex;
                    var dblclicktabColumn = $("#" + realGridNames[i].id).data("options").dblclicktabcolumn;

                    var realGrid = realGridNames[i].id + "Realgrid";
                    var dblClickedOptions = [
                        isDblClicked,
                        realGrid + "_DblClicked",
                        dblclicktabindex,
                        dblclicktabColumn
                    ];

                    InitRealgrid(getValNewFunction(realGrid), realGrid, getValNewFunction(realGrid + "Fields"), isGroup, dblClickedOptions);
                }
            }
            // main

            // slide
            if (!onNullCheck(slideRealGridDivs)) {
                for (var i = 0; i < slideRealGridDivs.length; i++) {
                    var slideRealGrid = slideRealGridDivs[i].id;

                    InitRealgrid(getValNewFunction(slideRealGrid), slideRealGrid, getValNewFunction(slideRealGrid + "Fields"), false, [false]);
                }
            }
            // slide
        }

        function InitRealgrid(realGrid, realGridName, realgridFields, isGroup, dblClickedOptions/* 배열 > 0 : 더블클릭이벤트 사용여부, 1 : 더블클릭이벤트 명, 2 : 최초 선택할 INDEX*/) {
            var setColumn = function (isGroup, vType, vFieldName, vHeader) {
                // 해당 Detailgrid 공통 컬럼 설정
                var column = {
                    name: vFieldName,
                    fieldName: vFieldName,
                    header: { text: vHeader },
                    styles: { textAlignment: "center", borderBottom: noGroupBorderBottom },
                    visible: true,
                    editable: false,
                    width: 150,
                    footer: {
                        styles: { textAlignment: "center" }
                    }
                };
                // 해당 Detailgrid 공통 컬럼 설정

                if (isGroup.type) {
                    const noGroupBorderRight = "#d7d7d7,1";

                    column.movable = false; // 그룹 안에서는 컬럼 이동 못하도록 설정
                    column.mergeRule = {};  // 그룹 안에서는 mergeRule 제외
                    column.styles.borderRight = (isGroup.endColumn) ? defaultBorder : noGroupBorderRight;
                    column.footer.styles.borderRight = (isGroup.endColumn) ? defaultBorder : noGroupBorderRight;
                }

                return setTypeColumn(vType, column);
            };

            var vRealgridFields = [];
            var vRealgridColumns = [];
            var vRealgridFilterColumns = [];

            realgridFields.forEach(function (a) {
                var vGroupWidth = 0;
                var masterColumns = [];

                if (a.type == "group") {
                    a.columns.forEach(function (b) {
                        vRealgridFields.push({ fieldName: b.fieldName, dataType: onNullCheck(b.dataType) ? 'text' : b.dataType });
                        var column = setColumn({ type: true, endColumn: b.columnSetting.endColumn, groupBy: b.columnSetting.groupBy }, b.columnSetting.type, b.fieldName, b.columnSetting.header);
                        masterColumns.push(column);
                        vGroupWidth += (column.visible) ? column.width : 0;

                        if(b.columnSetting.filterType){
                            vRealgridFilterColumns.push(a.fieldName);
                        }
                    });

                    vRealgridColumns.push({
                        type: a.type,
                        name: a.name,
                        header: a.header,
                        width: vGroupWidth,
                        columns: masterColumns
                    });
                } else {
                    if(a.columnSetting.filterType){
                        vRealgridFilterColumns.push(a.fieldName);
                    }
                    vRealgridFields.push({ fieldName: a.fieldName, dataType: onNullCheck(a.dataType) ? 'text' : a.dataType });
                    vRealgridColumns.push(setColumn({ groupByField: a.columnSetting.groupByField, type: false, groupBy: a.columnSetting.groupBy }, a.columnSetting.type, a.fieldName, a.columnSetting.header));
                }

            });

            realGrid.Init(null, vRealgridFields, vRealgridColumns, true, true, true);

            /*메뉴 ID 에 null을 등록하면 컬럼별 빼고 안빼고를 설정 할 수 없다. 일단은 NULL로 */
            var vGridView = getValNewFunction(realGridName + "_gridView");

            realGridSet(vGridView, isGroup);

            if(vRealgridFilterColumns.length > 0) {
                realGrid.SetColsFilter(vRealgridFilterColumns);

                autoFilter[realGridName] = {
                    "realGrid_autoFilterItemsKey": [],
                    "realGrid_autoFilterColumns": vRealgridFilterColumns
                };

                var funFilterActionClicked = function (grid, column, action, x, y) {
                    if (action == "autoFilter") {
                        var offset = $("#" + realGridNames[tabIndex].id + "Realgrid").position();

                        showAutoFiltering(realGridNames[tabIndex].id + "Realgrid", getValNewFunction(realGridNames[tabIndex].id + "Realgrid_gridView"), getValNewFunction(realGridNames[tabIndex].id + "Realgrid_dataProvider"), column, x + offset.left, y + offset.top);
                    }
                };

                new Function(realGridName + '_LoadDataCompleted = function () { ' + realGridName + '_gridView.onFilterActionClicked = ' + funFilterActionClicked + ' };')();

                realGrid.FilterCheck = function () {
                    filterCheck(realGridNames[tabIndex].id + "Realgrid", getValNewFunction(realGridNames[tabIndex].id + "Realgrid_gridView"), getValNewFunction(realGridNames[tabIndex].id + "Realgrid_dataProvider"));
                };

                realGrid.applyAutoFilter = function () {
                    applyAutoFilter(realGridNames[tabIndex].id + "Realgrid", getValNewFunction(realGridNames[tabIndex].id + "Realgrid_gridView"));
                };

                realGrid.closeAutoFilter = function () {
                    closeAutoFilter(realGridNames[tabIndex].id + "Realgrid", getValNewFunction(realGridNames[tabIndex].id + "Realgrid_gridView"));
                };
            }

            if (dblClickedOptions[0]) {
                var funColumn = ' ($.inArray(row.column, ' + JSON.stringify(dblClickedOptions[3]) + ' ) !== -1 ) ? 1 : ' + dblClickedOptions[2];

                var funDblClicked = ' = function (grid, row) {CollapseCommonSlideArea();  ExpandSlideArea(); CallTap("slide", false, ' + funColumn + ', slideRealGridNames); $("#divSlideTap").tabs("select", ' + funColumn + ');}';

                if (!onNullCheck(vGridView)) {
                    new Function(dblClickedOptions[1] + funDblClicked)();
                };
            };
        }

        function realGridSet(gridView, isGroup) {
            gridView.setOptions({
                edit: { insertable: true, appendable: true }
                , softDeleting: true
                , deleteCreated: true
                , hideDeletedRows: true
            });

            gridView.setSortingOptions({ enabled: true });

            gridView.setEditOptions({
                editable: false
            });

            gridView.setStateBar({
                visible: false
            });

            gridView.setCheckBar({
                visible: false
            });

            gridView.setFooter({
                visible: false
            });

            gridView.setRowGroup({
                footerCellMerge: true,
                expandedAdornments: "footer",
                collapsedAdornments: "footer",
                mergeMode: true,
                mergeExpander: false
            });

            gridView.setDisplayOptions({
                fitStyle: "even" // 컬럼 채우기 "none" 이면 설정한 넓이 기준
            });

            if (isGroup) {
                gridView.setHeader(
                    { height: 50 } // 헤더 높이 +10
                );
            }
        }

        // #region 필터 재설정
        // #region 필터 팝업 init
        function showAutoFiltering(grid, gridView, dataProvider, column, x, y) {
            if ($("#" + grid + "_divAutoFilter")[0].style.display != "none") {
                $("#" + grid + "_divAutoFilter").hide();
                return;
            }

            autoFilter[grid]["autoFiltercolumn"] = column;
            autoFilter[grid]["realGrid_autoFiltercolumn"] = column;

            var columnObj = gridView.columnByName(column);
            var fieldName = gridView.columnByName(column).fieldName;

            document.getElementById(grid + "_filterValue").value = '';

            var values;

            values = dataProvider.getDistinctValues(fieldName, 500);

            var span = $("#" + grid + "_spanFilters");
            span.empty();

            $("#" + grid + "_ChkAll").prop("checked", false);

            var autoFilterItems = [];

            if (autoFilter[grid]["realGrid_autoFilterItemsKey"][column] != undefined)
            {
                autoFilterItems = autoFilter[grid]["realGrid_autoFilterItemsKey"][column];
            }

            var inputvalue = document.getElementById(grid + "_filterValue").value;
            var filtervalues = null;
            if (inputvalue != '')
            {
                if (Array.isArray(values))
                {
                    var filtervalues;
                    if (columnObj.lookupDisplay == true && columnObj.values != [])
                    {
                        var tmpfiltervalues = columnObj.labels.filter(function(val) { return val.indexOf(inputvalue) >= 0;});

                        for(i=0 ; i < tmpfiltervalues.length ; i++ )
                        {
                            filtervalues.push(columnObj.valuse[columnObj.labels.indexOf(tmpfiltervalues[i])]);
                        }
                    }else
                    {
                        filtervalues = values.filter(function(val) { return val.indexOf(inputvalue) >= 0;});
                    }
                }

                if (filtervalues != null && filtervalues.length > 0)
                {
                    values = filtervalues;
                }
            }

            values.forEach(function (v) {
                var label = $("<label />").appendTo(span);

                var existsFilter = autoFilterItems.indexOf(v) >= 0;

                $("<input />", { type: "checkbox", name: "chkAutoFilterItem", value: v, checked: existsFilter, style: "margin-left:7px"}).appendTo(label);
                if (columnObj.lookupDisplay == true && columnObj.values != [])
                {
                    var idxNM = columnObj.values.indexOf(v);

                    if (idxNM >= 0)
                    {
                        label.append(columnObj.labels[idxNM]);
                    }else
                    {
                        label.append(v);
                    }
                }else
                {   
                    label.append(v);
                }
                
                span.append("<br/>");
            });

            $("#" + grid + "_divAutoFilter").css("left", x);
            $("#" + grid + "_divAutoFilter").css("top", y);
            $("#" + grid + "_divAutoFilter").show();
        }
        //#endregion

        // #region 필터 팝업 확정
        function applyAutoFilter(grid, gridView) {
            var filterExpr = "";
            var filterItems = $('input[name="chkAutoFilterItem"]:checked');

            autoFilter[grid]["realGrid_autoFilterItemsKey"][autoFilter[grid]["autoFiltercolumn"]] = [];

            for (var i = 0; i < filterItems.length; i++) {
                autoFilter[grid]["realGrid_autoFilterItemsKey"][autoFilter[grid]["autoFiltercolumn"]].push(filterItems[i].value);

                if (filterExpr != "") {
                    filterExpr += " or ";
                }
                filterExpr += "(value = '" + filterItems[i].value + "')";
            };

            var filters = {
                name: "auto_result",
                criteria: filterExpr,
                active: true,
                hidden:true
                };

            gridView.addColumnFilters(autoFilter[grid]["autoFiltercolumn"], filters, true);

            if (autoFilter[grid]["realGrid_autoFilterItemsKey"][autoFilter[grid]["autoFiltercolumn"]].length == 0) {
                gridView.activateAllColumnFilters(autoFilter[grid]["autoFiltercolumn"], false);
            }

            $("#" + realGridNames[tabIndex].id + "Realgrid_divAutoFilter").hide();
        };
        //#endregion

        // #region 필터 팝업 초기화
        function closeAutoFilter(grid, gridView) {
            if (autoFilter[grid]["autoFiltercolumn"] != null) {
                if (autoFilter[grid]["realGrid_autoFilterItemsKey"][autoFilter[grid]["autoFiltercolumn"]] != undefined) {
                    autoFilter[grid]["realGrid_autoFilterItemsKey"][autoFilter[grid]["autoFiltercolumn"]] = [];
                }

                gridView.activateAllColumnFilters(autoFilter[grid]["autoFiltercolumn"], false);
            }
           
            document.getElementById(grid + "_filterValue").value = "";
            $("#" + grid + "_divAutoFilter").hide();
        }
        //#endregion

        // #region 필터 팝업 조회
        function filterCheck(grid, gridView, dataProvider) {
            if (autoFilter[grid]["realGrid_autoFiltercolumn"] != null) {

                if (autoFilter[grid]["realGrid_autoFilterItemsKey"][autoFilter[grid]["realGrid_autoFiltercolumn"]] != undefined)
                {
                    autoFilter[grid]["realGrid_autoFilterItemsKey"][autoFilter[grid]["realGrid_autoFiltercolumn"]] = [];
                }

                var column = autoFilter[grid]["realGrid_autoFiltercolumn"];
                var columnObj = gridView.columnByName(column);
                var fieldName = gridView.columnByName(column).fieldName;
                var values = dataProvider.getDistinctValues(fieldName, 500);

                var span = $("#" + grid + "_spanFilters");
                span.empty();

                $("#" + grid + "_ChkAll").prop("checked", false);

                var inputvalue = document.getElementById(grid + "_filterValue").value;

                var filtervalues = null;

                if (Array.isArray(values)) {
                    //var filtervalues = values.filter(function(val) { return val.indexOf(inputvalue) >= 0;});
                    var filtervalues;
                    if (columnObj.lookupDisplay == true && columnObj.values != []) {
                        var tmpfiltervalues = columnObj.labels.filter(function (val) { return val.toLowerCase().indexOf(inputvalue.toLowerCase()) >= 0; });

                        for (i = 0; i < tmpfiltervalues.length; i++) {
                            filtervalues.push(columnObj.valuse[columnObj.labels.indexOf(tmpfiltervalues[i])]);
                        }
                    } else {
                        filtervalues = values.filter(function (val) { return val.toLowerCase().indexOf(inputvalue.toLowerCase()) >= 0; });
                    }
                }

                if (filtervalues != null) {
                    values = filtervalues;
                }

                values.forEach(function (v) {
                    var label = $("<label />").appendTo(span);
                    var existsFilter = false;//autoFilterItems.indexOf(v) >= 0;
                    $("<input />", { type: "checkbox", name: "chkAutoFilterItem", value: v, checked: existsFilter, style: "margin-left:7px" }).appendTo(label);
                    if (columnObj.lookupDisplay == true && columnObj.values != []) {
                        var idxNM = columnObj.values.indexOf(v);

                        if (idxNM >= 0) {
                            label.append(columnObj.labels[idxNM]);
                        } else {
                            label.append(v);
                        }
                    } else {
                        label.append(v);
                    }
                    span.append("<br/>");
                });
            }
        }
        // #endregion
        // #endregion

        // #endregion

        // #region 조회조건 설정
        // #region 콤보박스 초기화
        function setInitCom(vCbo, vCboOptions) {
            var com = {}
            com[vCboOptions.valueField] = '';
            com[vCboOptions.textField] = setCBOOPTName(vCboOptions.cBoopt);

            setCombobox(vCbo, com);
        }

        function setCBOOPTName(id) {
            var vNAME = "";

            switch (id) {
                case 'OPT':
                    vNAME = '<%=lang.word["OPTION"]%>';
                    break;
                case 'ALL':
                    vNAME = '<%=lang.word["ALL"]%>';
                    break;
            }

            return vNAME;
        }

        function setCombobox(cbo, data) {
            cbo.combobox('clear');
            cbo.combobox('loadData', [data]);
            cbo.combobox('select', '');
        }
        // #endregion

        // #region 조회조건 콤보박스 초기화
        function setInitSelectCom() {
            var cboSelectNames = $('[name="cboSelect"]').children('input');

            for (var i = 0; i < cboSelectNames.length; i++) {
                var id = $("#" + cboSelectNames[i].id);
                setInitCom(id, id.combobox("options"));
            }
        }
        // #endregion

        function setSelectCom(vType, vRecord, vSelectValue) {
            var bizID = '';
            var bizInData = '';
            var vCbo;

            const funSelectCombobox = function (com, items) {
                if (items.length === 2) {
                    var opts = com.combobox("options");
                    com.combobox("select", items[1][opts.valueField]);
                }
            }

            var onLoadSuccess = function () {
                funSelectCombobox($(this), $(this).combobox("getData"));
            };

            var onSelect = undefined;

            switch (vType) {
                case "AREA":
                    bizID = 'BR_IM_SEL_AREA_CBO';
                    bizInData = '&AREAIUSE=Y' + '&SHOPID=' + vSelectValue + '&SHOPIUSE=Y&EQSGTYPE=LINE&USERID=' + $("[id$=hidUserID]").val();
                    vCbo = $('#cboArea');
                    onLoadSuccess = function () {
                        var areaCombobox = $(this);
                        var AREAIDValue = "<%=SSUser.AreaID%>";
                        var items = areaCombobox.combobox("getData");
                        var itemUserAreaID = items.filter(function (v) { return v.AREAID == AREAIDValue });

                        if (itemUserAreaID.length > 0) {
                            itemUserAreaID.forEach(function (b) {
                                areaCombobox.combobox("select", b.AREAID);
                            });
                        } else {
                            funSelectCombobox(areaCombobox, items);
                        }
                    };
                    onSelect = function (row) {
                        setSelectCom("PDGR", null, row.AREAID);
                    };
                    break
                case "PDGR":
                    bizID = 'BR_IM_SEL_PRODUCTGROUP_BY_AREA_CBO';
                    bizInData = '&AREAID=' + vSelectValue;
                    vCbo = $('#cboGrade');
                    onSelect = function (row) {
                        setSelectCom("EQSG", { areaId: vSelectValue }, row.PDGRID);
                    };
                    break
                case "EQSG":
                    bizID = 'BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO';
                    bizInData = '&AREAID=' + vRecord.areaId + '&SHOPID=' + $("[id$=hidShopID]").val() + '&PDGRID=' + vSelectValue + '&EQSGTYPE=LINE';
                    vCbo = $('#cboLine');
                    onSelect = function (row) {
                        setSelectCom("PCSG", { areaId: vRecord.areaId, pdgrId: vSelectValue }, row.EQSGID);
                    };
                    break
            }

            if (!onNullCheck(vCbo)) {
                const cboOptions = vCbo.combobox("options");

                if (!onNullCheck(vSelectValue)) {
                    const vUrl = '../common/xml/CallBizJson.aspx?sp_name=';

                    vCbo.combobox({
                        loader: function (param, success, error) {
                            var opts = $(this).combobox('options');
                            if (!opts.url) return false;
                            $.ajax({
                                type: opts.method,
                                url: opts.url,
                                data: param,
                                async: false, // 동기식
                                dataType: 'json',
                                success: function (data) {
                                    success(data);
                                },
                                error: function () {
                                    error.apply(this, arguments);
                                }
                            });
                        },
                        url: vUrl + bizID + '&LANGID=' + $("[id$=hidLangID]").val() + bizInData + '&CBOOPT=' + cboOptions.cBoopt + '|' + cboOptions.valueField + '|' + cboOptions.textField,
                        onLoadSuccess: onLoadSuccess,
                        onSelect: function (row) {
                            if (!onNullCheck(onSelect)) {
                                onSelect(row);
                            }
                            //setClear();
                            setClear("main", realGridNames);
                        }
                    });
                } else {
                    setInitCom(vCbo, cboOptions);
                }
            }
        }
        // #endregion

        // #region Tab 설정
        function setTabSetting() {
            // main Tap
            $('#divTap').tabs({
                onSelect: function (title, index) {
                    tabIndex = index;
                    CallTap("main", false, tabIndex, realGridNames);
                }
            });
            // main Tap

            // Slide Tap
            $('#divSlideTap').tabs({
                onSelect: function (title, index) {
                    slideTabIndex = index;
                    CallTap("slide", false, slideTabIndex, slideRealGridNames);
                }
            });
            // Slide Tap
        }
        // #endregion

        // #region Tab 조회
        function CallTap(type, selectCheckType, index, vRealGridNames) {
            setClear(type, vRealGridNames);

            AutoHeightSpread();

            var dateFrom = $.fn.datebox.defaults.formatter($('#dtDateRange').daterangebox('GetFromDate'));
            var dateTo = $.fn.datebox.defaults.formatter($('#dtDateRange').daterangebox('GetToDate'));

            if (!onNullCheck(vRealGridNames)) {
                var realGrid = getValNewFunction(vRealGridNames[index].id + "Realgrid");
                var bizID = selectBizName + $("#" + vRealGridNames[index].id).data("options").bizID;
                var selectNoCheck = $("#" + vRealGridNames[index].id).data("options").selectNoCheck;

                if (!butSelectCheck(selectCheckType, dateFrom, dateTo, selectNoCheck)) {
                    GridShowLoading();

                    GetData(dateFrom, dateTo, realGrid, bizID, function () {
                        setTotalCount([$("#" + vRealGridNames[index].id + "TotalCount"), realGrid.GetRowCount()]);

                        GridCloseLoading();
                    });
                }
            };
        }
        // #endregion

        // #region 하단 팝업 닫기
        function ButtonClick_Collapse(obj) {
            CollapseSlideArea();
        };
        // #endregion

        // #region 조회 체크
        function butSelectCheck(alertType, dateFrom, dateTo, selectNoCheckTab) {
            var msg = '<%=lang.message["10012"]%>';
            var value = false;

            if (!selectNoCheckTab && $("#cboLine").val() == "") {
                msg = msg.replace("%1", "<%=lang.word["Line/Equipment Seg."]%>");
                value = true;
            } else if (dateFrom > dateTo) {
                msg = '<%=lang.message["20114"]%>';
                value = true;
            } else if (dateDiff(dateFrom, dateTo, monthsDay) > 0) {
                msg = "<%=lang.message["97507"]%>";
                value = true;
            }

            if (alertType && value) {
                xAlert(msg);
            }

            return value;
        }
        // #endregion

        // #region 데이터 초기화
        function setClear(type, vRealGridNames) {
            if (!onNullCheck(vRealGridNames)) {
                for (var i = 0; i < vRealGridNames.length; i++) {
                    var realGrid = vRealGridNames[i].id + "Realgrid";
                    var realGridDataProvider = getValNewFunction(realGrid + "_dataProvider");
                    var realGridView = getValNewFunction(realGrid + "_gridView");

                    if (!onNullCheck(realGridDataProvider)) {
                        realGridDataProvider.clearRows();
                    }

                    setTotalCount([$("#" + vRealGridNames[i].id + "TotalCount"), 0]);

                    if (!onNullCheck(realGridView)) {
                        realGridView.orderBy([], []); /*순서 초기화*/
                    }

                    if (!onNullCheck(autoFilter[realGrid])) {
                        autoFilter[realGrid]["realGrid_autoFilterItemsKey"] = [];

                        autoFilter[realGrid]["realGrid_autoFilterColumns"].forEach(function (v) {
                            realGridView.activateAllColumnFilters(realGridView.columnByField(v), false);
                        });

                        $("#" + realGrid + "_divAutoFilter").hide();
                    }
                }
            }

            switch (type) {
                case "main":
                    CollapseSlideArea(); // 하단 슬라이드 닫기
                    setClear("slide", slideRealGridNames);
                    break;
                case "slide":
                    break;
            }
        }
        // #endregion

        // #region 버튼 이벤트
        function onButtonClick(id) {
            try {
                switch (id) {
                    case "btnSearch":
                        butSelectClick();
                        break;
                    default:
                        break;
                }
            } catch (e) {
                alert(e.message);
            }
        }
        // #endregion

        // #region 조회
        function butSelectClick() {
            CallTap("main",true, tabIndex, realGridNames);
        }

        function GetData(dateFrom, dateTo, realGrid, bizID, funCallBack) {
            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.AREAID = $('#cboArea').combobox('getValue');
            items.EQSGID = $('#cboLine').combobox('getValue');
            items.STDATE = dateFrom;
            items.EDDATE = dateTo;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            var param = {};
            param.bizID = bizID;
            param.items = items;
            param.inTableNames = "RQSTDT";
            param.outTableNames = "RSLTDT";

            realGrid.CallRequest(url, param, funCallBack);
            realGrid.Refresh();
        }
        // #endregion

        // #region Excel
        function onExcelButtonClick(grid, slide) {
            try {
                GridToExcel(grid, slide);
            } catch (e) {
                xAlert(e.message);
            }
        }

        function GridToExcel(grid, slide) {
            if (grid.GetRowCount() == 0) {
                xAlert('<%=lang.message["20051"]%>');
                return;
            }

            //var title = parent.$('#tt').tabs('getSelected').panel('options').title; // 선택한 화면의 title 명
            var tabTitle = $('#divTap').tabs('getSelected').panel('options').title; // 선택한 TAB의 title 명
            var tabSlideTitle = slide ? ("-" + $('#divSlideTap').tabs('getSelected').panel('options').title) : ''; // 선택한 Slide TAB의 title 명

            //grid.ExcelExport('(' + today + ')' + title + ("-" + tabTitle) + tabSlideTitle + ".xlsx");
            grid.ExcelExport('(' + today + ') ' + tabTitle + tabSlideTitle + ".xlsx");
        }
        // #endregion

        // #region 날짜
        function dateDiff(_date1, _date2, _day) {
            var diffDate_1 = _date1 instanceof Date ? _date1 : new Date(_date1);
            var diffDate_2 = _date2 instanceof Date ? _date2 : new Date(_date2);

            var diff = Math.abs(diffDate_2.getTime() - diffDate_1.getTime());
            diff = Math.ceil(diff / (1000 * 3600 * 24)) + 1;

            return (diff > _day) ? _day : 0;
        }

        function SetDateTime() {
            var fromDayVal = new Date(newDate.getFullYear(), newDate.getMonth(), 1); // 현재월 1일 setting

            $('#dtDateRange').daterangebox('SetDate', fromDayVal, newDate);
        }
        // #endregion

        // #region 0 값 체크
        function onZeroCheck(value) {
            if (value === null || value === undefined || value <= 0) {
                return true;
            } else {
                return false;
            }
        }
        // #endregion

        // #region 빈 값 체크
        function onNullCheck(value) {
            if (value === null || value === undefined || valueIsNaN(value) || value.toString().trim() === '') {
                return true;
            } else {
                return false;
            }
        }
        function valueIsNaN(v) {
            return v !== v;
        }
        // #endregion

        // #region 카운트
        function setTotalCount(count) {
            if (!onNullCheck(count)) {
                count[0].text(count[1]);
            }
        }
        // #endregion

        // #region eval 대신 new Function 을 사용(보안을 위함(오브젝트 형식이 더 좋지만 변수를 선언해서 object에 담아야 함으로 명칭으로 할 수 있는 new Function 사용)))
        function getValNewFunction(value) {
            //return new Function(`return ${value}`)();
            return new Function('return ' + value)(); // 익스플로러에서 사용하기 위함
        }
        // #endregion

        // #region Detail Loading
        function GridShowLoading() {
            $("#LoadingPanel").show();
        }

        function GridCloseLoading() {
            $("#LoadingPanel").hide();
        }
        // #endregion

        // #region Detail Loading
        function dateRangeToChanged(date) {
            setClear("main", realGridNames);
        }
        // #endregion
    </script>

</asp:Content>
<asp:Content ID="UIContent" ContentPlaceHolderID="bodyHolder" runat="server">
    <form id="form1" runat="server">
        <!-- hidden Field Start-->
        <asp:HiddenField ID="hidHeight" runat="server" />
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidLoginuser" runat="server" />
        <asp:HiddenField ID="hidAccessFlag" runat="server" />
        <asp:HiddenField ID="hidSelectedValue" runat="server" />
        <asp:HiddenField ID="hidKeyReprocess" runat="server" />
        <!-- hidden Field End-->
        <asp:ScriptManager runat="server" ID="ScriptManager1"></asp:ScriptManager>

        <!-- 검색조건 영역 시작 -->
        <div class="tableInquiry searchBox" id="divSearchArea">
            <div class="itemBox">
                <table>
                    <tbody>
                        <tr>
                            <!--공장/동-->
                            <th class="th_auto"><%=lang.word["Shop/Area"]%></th>
                            <td class="td_fix">
                                <table class="tableShopArea">
                                    <tr>
                                        <td name="cboSelect"><input id="cboArea" data-options="valueField: 'AREAID',textField: 'AREANAME_ML', cBoopt: 'ALL'" class="easyui-combobox search_width" /></td>
                                    </tr>
                                    <tr class="ProdGR" >
                                        <td name="cboSelect"><input id="cboGrade" data-options="valueField: 'PDGRID',textField: 'PDGRNAME', cBoopt: 'ALL'" class="easyui-combobox search_width" /></td>
                                    </tr>
                                </table>
                            </td>               
                            <!--공장/동-->
                            
                            <!--라인/실-->
                            <th class="th_auto"><%=lang.word["Line/Equipment Seg."]%></th>
                            <td class="td_fix" name="cboSelect">
                                <input id="cboLine" data-options="valueField: 'EQSGID',textField: 'EQSGNAME', cBoopt: 'ALL'" class="easyui-combobox search_width"  />
                            </td>
                            <!--라인/실-->

                            <!-- 조회기간 -->
                            <th class="th_auto"><span class="textPink">*</span><%=lang.word["AGGREGATION"]%><%=lang.word["Date"]%></th>
                            <td class="td_fixEnd">
                                <input id="dtDateRange" data-options="onChange:dateRangeToChanged" class="easyui-daterangebox" style="width: 100%; max-width: 200px;" />
                            </td>
                            <!-- 조회기간 -->
                        </tr>
                    </tbody>
                </table>
            </div>
            <div id="divButtonArea" class="tableBtnSearch" >
                <button type="button" id="btnSearch" onclick="onButtonClick(this.id)"><span><%=lang.word["Search"]%></span></button><!-- 조회 -->
            </div>
            <uc:SearchToggleContent ID="SearchToggleContent1" runat="server" />
            <div class="clear"></div>
        </div>
        <!-- 검색조건 영역 끝 -->
        <div id="divMainLayout" class="easyui-layout" style="width:100%; height: 100%;"> 
            <div data-options="region:'center',title:'',border:false">
                <div id="divTap" class="easyui-tabs" style="width:100%; height:100%" data-options="fit:true">
                    <!-- 양품률 -->
                    <div class="bottom_panel" title="<%=lang.word["Good Qty"]%>" >
                        <div class="buttonArea" id="divGoodQtyRateButton" style="padding: 6px; margin-bottom: 0px; padding-left:10px; padding-right:10px; border-bottom: 0px;">
                            <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucGoodQtyRateTotalCount" class='red01'>0</span> Found)</div>
                            <ul class="btn_crud">
                                <li><a class="excel" onclick="onExcelButtonClick(ucGoodQtyRateRealgrid, false)"></a></li>
                            </ul>
                        </div>
                        <div name="realGrid" id="ucGoodQtyRate" data-options='{"group":false, "bizID":"GOODRATE", "dblclicked":true, "dblclicktabindex":0, "dblclicktabcolumn":["RWKQTY"], "selectNoCheck":false}' class="table">
                            <uc:Realgrid ID="ucGoodQtyRateRealgrid" CALLID="ucGoodQtyRateRealgrid" HEIGHT="300" runat="server" LAYOUTSAVING="Y" />
                        </div>
                    </div>
                    <!-- 양품률 -->
                        
                    <!-- 로스율 -->
                    <div class="bottom_panel" title="<%=lang.word["LossRate"]%>">
                        <div class="buttonArea" id="divLossRateButton" style="padding: 6px; margin-bottom: 0px; padding-left:10px; padding-right:10px; border-bottom: 0px;">
                            <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucLossRateTotalCount" class='red01'>0</span> Found)</div>
                            <ul class="btn_crud">
                                <li><a class="excel" onclick="onExcelButtonClick(ucLossRateRealgrid, false)"></a></li>
                            </ul>
                        </div>
                        <div name="realGrid" id="ucLossRate" data-options='{"group":false, "bizID":"LOSSRATE", "dblclicked":false, "dblclicktabindex":0, "selectNoCheck":false}' class="table">
                            <uc:Realgrid ID="ucLossRateRealgrid" CALLID="ucLossRateRealgrid" HEIGHT="300" runat="server" LAYOUTSAVING="Y" />
                        </div>
                    </div>
                    <!-- 로스율 -->

                    <!-- 제품별 수율 -->
                    <div class="bottom_panel" title="<%=lang.word["by Product"]%> <%=lang.word["Yield"]%>">
                        <div class="buttonArea" id="divProductRateButton" style="padding: 6px; margin-bottom: 0px; padding-left:10px; padding-right:10px; border-bottom: 0px;">
                            <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucProductRateTotalCount" class='red01'>0</span> Found)</div>
                            <ul class="btn_crud">
                                <li><a class="excel" onclick="onExcelButtonClick(ucProductRateRealgrid, false)"></a></li>
                            </ul>
                        </div>
                        <div name="realGrid" id="ucProductRate" data-options='{"group":false, "bizID":"YIELD_RTY_SHOP", "dblclicked":false, "dblclicktabindex":0, "selectNoCheck":true}' class="table">
                            <uc:Realgrid ID="ucProductRateRealgrid" CALLID="ucProductRateRealgrid" HEIGHT="300" runat="server" LAYOUTSAVING="Y" />
                        </div>
                    </div>
                    <!-- 제품별 수율 -->
                        
                    <!-- 생산량(소성기준) -->
                    <div class="bottom_panel" title="<%=lang.word["PROD_QTY"]%>(<%=lang.word["Burning"]%><%=lang.word["Standard"]%>)">
                        <div class="buttonArea" id="divProdQtySoseongButton" style="padding: 6px; margin-bottom: 0px; padding-left:10px; padding-right:10px; border-bottom: 0px;">
                            <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucProdQtySoseongTotalCount" class='red01'>0</span> Found)</div>
                            <ul class="btn_crud">
                                <li><a class="excel" onclick="onExcelButtonClick(ucProdQtySoseongRealgrid, false)"></a></li>
                            </ul>
                        </div>
                        <div name="realGrid" id="ucProdQtySoseong"  data-options='{"group":false, "bizID":"BURNING", "dblclicked":false, "dblclicktabindex":0, "selectNoCheck":false}'  class="table">
                            <uc:Realgrid ID="ucProdQtySoseongRealgrid" CALLID="ucProdQtySoseongRealgrid" HEIGHT="300" runat="server" LAYOUTSAVING="Y" />
                        </div>
                    </div>
                    <!-- 생산량(소성기준) -->
                        
                    <!-- 생산량(소분기준) -->
                    <div class="bottom_panel" title="<%=lang.word["PROD_QTY"]%>(<%=lang.word["Subdivision"]%><%=lang.word["Standard"]%>)">
                        <div class="buttonArea" id="divProdQtySobunButton" style="padding: 6px; margin-bottom: 0px; padding-left:10px; padding-right:10px; border-bottom: 0px;">
                            <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucProdQtySobunTotalCount" class='red01'>0</span> Found)</div>
                            <ul class="btn_crud">
                                <li><a class="excel" onclick="onExcelButtonClick(ucProdQtySobunRealgrid, false)"></a></li>
                            </ul>
                        </div>
                        <div name="realGrid" id="ucProdQtySobun" data-options='{"group":false, "bizID":"SUBDIVISION", "dblclicked":false, "dblclicktabindex":0, "selectNoCheck":false}' class="table">
                            <uc:Realgrid ID="ucProdQtySobunRealgrid" CALLID="ucProdQtySobunRealgrid" HEIGHT="300" runat="server" LAYOUTSAVING="Y" />
                        </div>
                    </div>
                    <!-- 생산량(소분기준) -->

                </div>
            </div>  
        </div>
    </form>
</asp:Content>

<asp:Content ID="Content1" ContentPlaceHolderID="slideHolder" runat="server">
    <div id="divSlideTap" class="easyui-tabs" data-options="fit:true" style="height: 300px">
        <div class="bottom_panel" title="<%=lang.word["Packing Result"]%>">
            <div id="divSearchPart1">
                <div class="buttonArea" style="padding: 6px; margin-bottom: 0px; padding-left:10px; padding-right:10px; border-bottom: 0px;">
                    <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucSlidePackingTotalCount" class='red01'>0</span> Found)</div>
                    <ul class="btn_crud">
                        <li><a class="excel" onclick="onExcelButtonClick(ucSlidePackingRealgrid, true)"></a></li>
                        <li><a class="table_bar"></a></li>
                        <li><a class="red" onclick="ButtonClick_Collapse(this)"><span><%=lang.word["Close"]%></span></a></li>
                    </ul>
                </div>
            </div>
            <!-- Contents 시작  -->
            <div name="slideRealGrid" id="ucSlidePacking" data-options='{"bizID":"PACKHISTORY"}' class="table" style="margin-bottom: 8px;">
                <uc:Realgrid ID="ucSlidePackingRealgrid" CALLID="ucSlidePackingRealgrid" runat="server"/>
            </div>
            <!-- Contents 종료  -->
        </div>
        <div class="bottom_panel" title="<%=lang.word["Rework Input"]%>">
            <div id="divSearchPart2">
                <div class="buttonArea" style="padding: 6px; margin-bottom: 0px; padding-left:10px; padding-right:10px; border-bottom: 0px;">
                <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucSlideReworkInputTotalCount" class='red01'>0</span> Found)</div>
                    <ul class="btn_crud">
                        <li><a class="excel" onclick="onExcelButtonClick(ucSlideReworkInputRealgrid, true)"></a></li>
                        <li><a class="table_bar"></a></li>
                        <li><a class="red" onclick="ButtonClick_Collapse(this)"><span><%=lang.word["Close"]%></span></a></li>
                    </ul>
                </div>
            </div>
            <!-- Contents 시작  -->
            <div name="slideRealGrid" id="ucSlideReworkInput" data-options='{"bizID":"REWORKHISTORY"}'  class="table" style="margin-bottom: 8px;">
                <uc:Realgrid ID="ucSlideReworkInputRealgrid" CALLID="ucSlideReworkInputRealgrid" runat="server"/>
            </div>
            <!-- Contents 종료  -->
        </div>
    </div>
    <div id="LoadingPanel" class="modal"></div>
</asp:Content>

