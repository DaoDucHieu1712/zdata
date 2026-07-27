<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMS_0581.aspx.cs" Inherits="GMES_IMS_0581"  %>

<%--/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMS_0581.aspx
* @desc    : 재고관리 - ERP I/F - ERP 투입조정
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2022/04/04   문창완              INIT
*************************************************************************************************
*/--%>
<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc2" %>
<%@ Register Src="../common/UserControl/UCRealGrid.ascx" TagName="Realgrid" TagPrefix="uc" %>
<%--<%@ Register Src="~/GMES_POM/Controls/UCGrid.ascx" TagName="Realgrid" TagPrefix="uc" %>--%>

<asp:Content ID="Content1" ContentPlaceHolderID="headHolder" runat="server">
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js"></script>
    <%-- Controls Init --%>
    <script type="text/javascript" language="javascript"> 
        // 조회내역이 존재하지 않습니다.
        var msgNotFoundList = "<%=lang.message["20051"]%>";
        //처리 되었습니다. 
        var msgProcessComplete = "<%=lang.message["20006"]%>";
        //작업중
        var msgWork = "<%=lang.message["PSS9156"]%>";            
        
        //#region Variables
        var vAreaID = '<%:SSUser.AreaID%>';
        var vFirst = true;
        var vIsEdit = false;

        var aLabel = [];
        var aValue = [];        
        var currLinkedRow;
        var vtoDay = '';
        var vmultiProdGr = '<%=HttpContext.Current.Session["multiProdGr"]%>';
        var vQuery = false;   //조회중
        //#endregion

        //#region resize
        $(window).resize(function () {
            AutoHeightSpread();
        });

        function onSlideResize() {
            AutoHeightSpread(false);
        }
        //#endregion

        //#region xInitPage
        function xInitPage() {
            AutoHeightSpread();
        }
        //#endregion

        //#region AutoHeightSpread - RealGrid의 높이를 재설정한다 
        function AutoHeightSpread(cSize) {
            var gridMaster = document.getElementById("UCRealGrid");

            var searchHeight = document.getElementById("divSearchPart").clientHeight;
            var buttonHeight = document.getElementById("divMidButton").clientHeight;
            var pageHeight = document.documentElement.clientHeight;
            var dockh = 0;

            if (IsDock()) {
                dockh = DockHeight();

                if (dockh > 0) {
                    dockh = dockh;
                };
            };

            var i = 0;
            i = pageHeight - (searchHeight + buttonHeight + dockh + 73)

            gridMaster.style.height = String(i) + 'px';

            if (vIsEdit) {

                var gridSlide = document.getElementById("ucOutAddRealgrid");

                var divAddEntry = document.getElementById("divAddEntry").offsetHeight;
                var divButtonAddEntryContent = document.getElementById("divButtonAddEntryContent").offsetHeight;
                var divMidButtonDetail = document.getElementById("divMidButtonDetail").offsetHeight;

                i = divAddEntry - (divButtonAddEntryContent + divMidButtonDetail + 30);

                gridSlide.style.height = String(i) + 'px';

                ucOutAddRealgrid.ResetSize();
            }

            UCRealGrid.ResetSize();
        }; 
        //#endregion

        //#region ready
        $(document).ready(function () {            

            $("#uploadFile").change(ExcelImport);
            gridDetailCombo();
        });                         

        
        function gridDetailCombo() {
            var items = [];
            var subItems = [];
            var WORKTYPE = ["AREAID", "SLOCID", "PROCID", "PDGRID", "WIPSTAT", "LOTTYPE", "SUFFIX", "MTRLTYPE", "MTRLFORM", "WHID", "EXCLUDE", "CLOSEMONTH"];
            var OutTables = '';
            for (var i = 0; i < WORKTYPE.length; i++) {
                subItems[i] = [
                      { name: "LANGID", value: $("[id$=hidLangID]").val(), dataType: _DataType.String }
                    , { name: "SHOPID", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                    , { name: "WORKTYPE", value: WORKTYPE[i].toString(), dataType: _DataType.String }
                ];
                OutTables += ((i == 0) ? '' : ',') + 'OUT_' + WORKTYPE[i].toString();
            }

            items[0] = subItems;

            var param = {};
            param.bizID = "BR_COM_GET_MULTI_CLOSING_CBO";
            param.items = items;
            param.inTableNames = "INDATA";
            param.outTableNames = OutTables;

            var url = "/GMES_POM/GMES_IMS_0581.aspx/GetDataSet";

            sendRequestMethod(function (id, datas) {                
                if (datas != null && datas.length > 0) {
                    var sLabel = [];
                    var sValue = [];
                    var idx = 0;                    
                    aLabel[idx] = sLabel; aValue[idx++] = sValue;
                    sLabel = []; sValue = [];
                    datas[0].OUT_SLOCID.forEach(function (value, index, array) {
                        sValue[index] = datas[0].OUT_SLOCID[index].SLOCID; sLabel[index] = datas[0].OUT_SLOCID[index].SLOCNAME;
                    });
                    aLabel[idx] = sLabel; aValue[idx++] = sValue;                    
                }

                InitGrid();
                InitAddGrid();

                InitControls();
            }, param, "POST", url);
            
        };

        //#region InitControls - 컨트롤을 초기 셋팅한다
        function InitControls() {
            //setBtnSearchEnabled(true);
            
            SetRangeDate();             // 조회조건 전기일 Range

            SetDateTime();              // 슽라이드 전기일자   

            SetMoveType(); // 이동 유형 세팅

            SetStorage(); // 저장위치 세팅

            $("#divPage").css("display", "none");            
        }
        //#endregion

        // 전기일자 세팅
        function SetRangeDate() {
            var toDay = new Date();
            var fromDayVal = new Date(toDay.getFullYear(), toDay.getMonth(), 1);
            var toDayVal = new Date(toDay.getFullYear(), toDay.getMonth(), toDay.getDate());

            $('#dtDateAppr').daterangebox('SetFromDate', fromDayVal);
            $('#dtDateAppr').daterangebox('SetToDate', toDayVal);
        }

        // 슬라이드 전기일자
        function SetDateTime() {            
            var toDay = $.fn.datebox.defaults.formatter(new Date());

            $('#dtStoDocDate').datebox('setValue', toDay);
                                 
        }

        function dtStoDocDateChange() {
            //clearSpread();

            //SetStorage();
        }

        // 공통 작업지시 조회 팝업창을 Open하여 WOID / 제품코드 / 코드명을 리턴받는다. : 생산Lot 정보 Slid에서 제품검색
        function ShowWoProductCodePopup(value) {
            // 공통 작업지시 조회 팝업창을 Open한다.</summary>    
            var _workDate = $('#dtStoDocDate').combobox('getValue');
            ShowPopup("../GMES_COM/GMES_COM_0021.aspx?MENU_ID=<%=ViewState["MENU_ID"].ToString()%>&COMID=" + $("#hidAreaID").val() + "&WORKDATE=" + _workDate, 1150, 650, '<%=lang.word["Report:Work Order"]%><%=lang.word["Find"]%>', SetWoProductName);
        }
        
        // 공통 작업지시 조회 팝업 후 리턴받은 제품 정보 제품코드/명 을 생산Lot 정보 Slid에 text box에 적용
        function SetWoProductName(data) {

            if (data == undefined) return;

            $("#txtWoId2").textbox("setValue", data[3]);
            $("#txtProdId2").textbox("setValue", data[2]);
            $("#txtProdName2").textbox("setValue", data[1]);
        }        

        //#region Grid 초기화
        function clearSpread() {

            if (ucOutAddRealgrid_dataProvider != null) {

                if (ucOutAddRealgrid.GetRowCount() > 0) {
                    ucOutAddRealgrid_dataProvider.clearRows();
                    $("#subTitle").html(" <%=lang.word["Registered Rows"]%>( Total <span class='textPink'>" + ucOutAddRealgrid.GetRowCount() + "</span> Found )");
                }
            }
        }
        //#endregion                       

        //#region SetStorage - 저장위치 콤보박스에 데이터를 설정한다
        function SetStorage() {
            /// <summary>저장위치 콤보박스에 데이터를 설정한다.</summary>  
            var vSLOCID = '';
            if ($("[id$=hidShopID]").val() == 'A020' || $("[id$=hidShopID]").val() == 'A070') {
                vSLOCID = '&SLOCID_FR=3000&SLOCID_TO=4999';
            }

            $('#cboStorage').combobox({
                //url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_STOCKLOCATION_AREAID_CBO&LANGID=' + $("[id$=hidLangID]").val() + AREAID
                //    + '&CBOOPT=ALL|SLOCID|SLOCNAME',
                url: '../common/xml/CallBizJson.aspx?sp_name=CUS_SEL_STORAGELOCATION_CBO&LANGID=' + $("[id$=hidLangID]").val() + '&SHOPID=' + $("[id$=hidShopID]").val() + vSLOCID
                    + '&USEFLAG=Y&CBOOPT=OPT|SLOCID|SLOCNAME',
                valueField: 'SLOCID',
                textField: 'SLOCNAME',
                onLoadSuccess: function () {
                    //
                }
            });
        } 
        //#endregion             

        // #region ShowProductCodePopup - 제품코드명 팝업창을 Open한다.
        function ShowProductCodePopup(value) {
            /// <summary>제품코드명 팝업창을 Open한다.</summary>     
            ShowPopup("../GMES_COM/GMES_COM_0003.aspx?MENU_ID=" + $("[id$=hidMenuID]").val() + "&PROD_SEARCH=" + value, 790, 500, '<%=lang.word["Drawing No."]%>' + '<%=lang.word["Search"]%>', SetProductName);
        }
        // #endregion

        // #region SetProductName - 제품코드 검색 팝업 후 선택 제품 정보 제품코드 text box에 적용
        function SetProductName(data) {
            if (data !== undefined && data.length > 0) { 
                $("#txtProdId").textbox('setValue', data[2]);  //제품코드
                //$("#txtProductName").textbox('setValue', data[1]); //제품명
            }
        }

        // 투입자재 조회
        function ShowProductCodePopup2(value) {
            /// <summary>제품코드명 팝업창을 Open한다.</summary>     
            ShowPopup("../GMES_COM/GMES_COM_0003.aspx?MENU_ID=" + $("[id$=hidMenuID]").val() + "&DVALUE=RAW&PROD_SEARCH=" + value, 790, 500, '<%=lang.word["Drawing No."]%>' + '<%=lang.word["Search"]%>', SetProductName2);
        }
        // #endregion

        // #region SetProductName - 자재코드 검색 팝업 후 선택 제품 정보 제품코드 text box에 적용
        function SetProductName2(data) {
            if (data !== undefined && data.length > 0) { 
                $("#txtMtrlId").textbox('setValue', data[2]);  //자재코드
                $("#txtMtrlName").textbox('setValue', data[1]); //자재명
            }
        } 
        // #endregion  
         
        function SetMoveType() {
            $('#cboMoveType').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=COM_SEL_CommonCode&LANGID=' + $("[id$=hidLangID]").val() + '&CMCDTYPE=ERP_MOVE_TYPE&CMCODE=261,262'
                    + '&CMCDIUSE=Y&SORTBYSEQ=1&CBOOPT=OPT|CMCODE|CMCDNAME2',
                valueField: 'CMCODE',
                textField: 'CMCDNAME2',
                onSelect: function (row) {
                    //
                },
                onLoadSuccess: function () {
                    //
                }
            });            
        }

        //#region onButtonClick - 버튼 클릭 이벤트 후 처리
        function onButtonClick(id) {
            /// <summary>버튼 클릭 이벤트 후 처리</summary>  
            /// <param name="name" type="string">버튼 ID</param> 
            try {
                switch (id) {
                    case "btnSearch": 
                        if (!Validate("SEARCH")) return;
                        vQuery = true;
                        $("#divPage").css("display", "none");
                        InquiryData();
                        break;
                    case "btnOpenSlide":
                        //==================================================================================================================================
                        //  메인 "등록"  버튼 클릭 시                                                                        
                        if (vIsEdit) { xAlert(msgWork); return; } 
                        CallSlideArea(); 
                        break;
                    case "btnInitOutAdd":
                        initOutAdd();
                        break;
                    case "btnUploadExcel":
                        // 엑셀업로드
                        $("#uploadFile").click();
                        break;
                    case "btnAddRow":
                        AddRow();
                        break;
                    case "btnDelRow":
                        DelRow();
                        break;
                    case "btnErpConfirm":
                        // 확정
                        fnChkSendToErpData();                        
                        
                        break;
                    case "btnErpCancel":
                        // 확정 취소
                        fnChkCancelConfirmData();

                        break;
                    case "btnCloseSlide":
                        vIsEdit = false;
                        initOutAdd();
                        topControlsEnable(true);
                        CollapseSlideArea(); //슬라이드 CLOSE 
                        break;
                    case "btnExcel":
                        Validate("EXCEL");
                        break;
                    default:
                }
            } catch (e) {
                xAlert(e.message);
            }
        }
        //#endregion

        // #region Validate - 함수 실행 전 유효성 체크
        function Validate(type) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            var result = true;

            switch (type) {
                case "SEARCH": 
                    //
                    break;
                case "EXCEL":
                    if (UCRealGrid.GetRowCount() == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }
                    ExcelExport();
                    break;                
                default:
                    break;
            }

            return result;
        }
        //#endregion        

        //#region InquiryData - 검색 조건에 해당하는 데이터를 조회한다.
        function InquiryData(page) {

            clearSpread();            

            UCRealGrid_gridView.commit();                                    

            for (var i = 0; i < vFilters.length; i++) {
                UCRealGrid_gridView.activateAllColumnFilters(vFilters[i], false);
            }

            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.FROM_DATE = $('#dtDateAppr').daterangebox('GetFromDateString');
            items.TO_DATE = $('#dtDateAppr').daterangebox('GetToDateString');
            items.PRODID = $("[id$=txtProdId]").val();
            items.WOID = $("#txtWoId").textbox("getValue");
            items.SENDEDERP = document.getElementById("chkSendedErp").checked ? "Y" : null;

                          
            var param = {};
            param.bizID = "DA_PRD_SEL_ERP_INPUT_ADJUST";
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            UCRealGrid.CallRequest(url, param);
        }
        //#endregion        
            
        

        // #region ExcelExport - 그리드 데이터를 엑셀 파일로 출력한다.
        function ExcelExport() {
            /// <summary>그리드 데이터를 엑셀 파일로 출력한다</summary>
            var fNameToday = $("[id$=hidMenuName]").val() + new Date().format("yyyyMMdd_hhmmss") + "_export.xlsx";
            UCRealGrid.ExcelExport(fNameToday);
        }
        // #endregion  

        // 필터 적용
        var vFilters = ["POSTDATE", "WOID", "PRODID", "PRODNAME", "MTRLID", "MTRLNAME", "BTCHNO", "MOVETYPE", "SLOCID", "ERP_DOCNO", "ERP_CNCLDOCNO"];

        function InitGrid() {
            UCRealGrid.ColumnsClear();

            UCRealGrid.AddColumn("SEQ", "<%=lang.word["NO"]%>", 100, "center", ColumnType.TEXT, false, false, null, null);                                                  // 순번
            UCRealGrid.AddColumn("SHOPID", "<%=lang.word["SHOPID"]%>", 120, "center", ColumnType.TEXT, false, false, null, null);                                           // 플랜트 ID

            UCRealGrid.AddColumn("POSTDATE", "<%=lang.word["STODOCDATE"]%>", 80, "center", ColumnType.TEXT, false, true, null, null);                                      // 전기일                        
            UCRealGrid.AddColumn("WOID", "<%=lang.word["W/O"]%>", 120, "center", ColumnType.TEXT, false, true, null, null);                                                 // Work Order ID
            UCRealGrid.AddColumn("PRODID", "<%=lang.word["PRODID"]%>", 150, "center", ColumnType.TEXT, false, true, null, null);                                            // 제품 ID
            UCRealGrid.AddColumn("PRODNAME", "<%=lang.word["PRODNAME"]%>", 250, "near", ColumnType.TEXT, false, true, null, null);                                        // 제품명

            //UCRealGrid.AddColumn("ERP_WC", "<%=lang.word["Workcenter"]%>", 100, "center", ColumnType.TEXT, false, true, null, null);                                             // 작업장

            UCRealGrid.AddColumn("MTRLID", "<%=lang.word["Consume"]%>" + "<%=lang.word["Material ID"]%>", 150, "center", ColumnType.TEXT, false, true, null, null);         // 자재 ID
            UCRealGrid.AddColumn("MTRLNAME", "<%=lang.word["Consumed Material"]%>", 250, "near", ColumnType.TEXT, false, true, null, null);                               // 투입자재(자재명)
            UCRealGrid.AddColumn("BTCHNO", "<%=lang.word["Batch No."]%>", 100, "center", ColumnType.TEXT, false, true, null, null);                                         // 배치번호

            UCRealGrid.AddColumn("MOVETYPE", "<%=lang.word["이동유형"]%>", 80, "center", ColumnType.TEXT, false, true, null, null);                                         // 이동유형

            UCRealGrid.AddColumn("INPUTQTY", "<%=lang.word["Input Qty"]%>", 90, "#,##0.000", ColumnType.NUMBER, false, true, null, null);                                 // 투입 수량
            UCRealGrid.AddColumn("SLOCID", "<%=lang.word["Sloc. ID"]%>", 80, "center", ColumnType.TEXT, false, true, null, null);                                          // 저장위치 ID                        

            UCRealGrid.AddColumn("ERP_DOCNO", "<%=lang.word["DOCNO"]%>", 120, "center", ColumnType.TEXT, false, true, null, null);                                          // ERP 문서 번호                        
            UCRealGrid.AddColumn("ERP_ERRCODE", "ERP<%=lang.word["Remain Results"]%> <%=lang.word["Code"]%>", 100, "center", ColumnType.TEXT, false, true, null, null);        // ERP처리결과코드
            UCRealGrid.AddColumn("ERP_ERRDESC", "ERP<%=lang.word["Remain Results"]%> <%=lang.word["Message"]%>", 250, "near", ColumnType.TEXT, false, true, null, null);      // ERP처리결과메세지
            UCRealGrid.AddColumn("INSUSER", "<%=lang.word["Person"]%>", 100, "center", ColumnType.TEXT, false, true, null, null);                                           // 생성 작업자

            UCRealGrid.AddColumn("ERP_CNCLDOCNO", "<%=lang.word["DOCNO"]%>", 120, "center", ColumnType.TEXT, false, true, null, null);         // ERP 취소 문서 번호            
            UCRealGrid.AddColumn("ERP_CNCLERRCODE", "ERP<%=lang.word["Remain Results"]%> <%=lang.word["Code"]%>", 100, "center", ColumnType.TEXT, false, true, null, null);     // 취소ERP처리결과코드   
            UCRealGrid.AddColumn("ERP_CNCLERRDESC", "ERP<%=lang.word["Remain Results"]%> <%=lang.word["Message"]%>", 250, "near", ColumnType.TEXT, false, true, null, null);   // 취소ERP처리결과메세지
            UCRealGrid.AddColumn("UPDUSER", "<%=lang.word["Person"]%>", 100, "center", ColumnType.TEXT, false, true, null, null);              // 수정 작업자

            UCRealGrid.AddColumn("MTRLUNIT", "<%=lang.word["Material Unit"]%>", 150, "center", ColumnType.TEXT, false, false, null, null);                                   // 자재 단위            
            UCRealGrid.AddColumn("MTRLSEQ", "<%=lang.word["Material"]%>" + "<%=lang.word["NO"]%>", 150, "center", ColumnType.TEXT, false, false, null, null);                // 자재순번
            UCRealGrid.AddColumn("REQUESTID", "<%=lang.word["Request"]%>" + "<%=lang.word["No."]%>", 150, "center", ColumnType.TEXT, false, false, null, null);              // 요청 ID                        
                      
            
            
            UCRealGrid.AddColumn("INSDTTM", "<%=lang.word["DATETIME"]%>", 150, "center", ColumnType.TEXT, false, false, null, null);                                         // 생성 일시            
            UCRealGrid.AddColumn("UPDDTTM", "<%=lang.word["MODIFY"]%>" + "<%=lang.word["DATETIME"]%>", 150, "center", ColumnType.TEXT, false, false, null, null);            // 수정 일시

            UCRealGrid.InitGrid("<%=ViewState["MENU_ID"].ToString()%>", true, true, true);                                    

            var layout = [
                UCRealGrid.FIELDS[0].fieldName,
                UCRealGrid.FIELDS[1].fieldName,
                UCRealGrid.FIELDS[2].fieldName,
                UCRealGrid.FIELDS[3].fieldName,
                UCRealGrid.FIELDS[4].fieldName,
                UCRealGrid.FIELDS[5].fieldName,
                UCRealGrid.FIELDS[6].fieldName,
                UCRealGrid.FIELDS[7].fieldName,
                UCRealGrid.FIELDS[8].fieldName,
                UCRealGrid.FIELDS[9].fieldName,
                UCRealGrid.FIELDS[10].fieldName,
                UCRealGrid.FIELDS[11].fieldName,
                {
                    "header": "<%=lang.word["Confirm"]%>",
                    "orientation": "horizontal",
                    "width": 570,
                    "columns":
                        [UCRealGrid.FIELDS[12].fieldName,
                         UCRealGrid.FIELDS[13].fieldName,
                        UCRealGrid.FIELDS[14].fieldName,
                        UCRealGrid.FIELDS[15].fieldName]
                },
                {
                    "header": "<%=lang.word["Cancel"]%>",
                    "orientation": "horizontal",
                    "width": 570,
                    "columns":
                        [UCRealGrid.FIELDS[16].fieldName,
                         UCRealGrid.FIELDS[17].fieldName,
                        UCRealGrid.FIELDS[18].fieldName,
                        UCRealGrid.FIELDS[19].fieldName]
                },
                UCRealGrid.FIELDS[20].fieldName,
                UCRealGrid.FIELDS[21].fieldName,
                UCRealGrid.FIELDS[22].fieldName,
                UCRealGrid.FIELDS[23].fieldName,
                UCRealGrid.FIELDS[24].fieldName
            ];

            UCRealGrid_gridView.setColumnLayout(layout);

            //체크박스 선택 시 BOXID단위로 CHECK 
            UCRealGrid_gridView.onItemChecked = function (grid, itemIndex, checked) {
                if (typeof UCRealGrid_ItemChecked != "undefined") {
                    UCRealGrid_ItemChecked(grid, itemIndex, checked);
                }
            };                        

            //열고정
            UCRealGrid_gridView.setFixedOptions({
                //colCount: 4
            });

            

            UCRealGrid_gridView.setColumnProperty(
                UCRealGrid_gridView.columnByField("ERP_ERRCODE")
                , "dynamicStyles"
                , [{
                    criteria: "(value['ERP_ERRCODE'] = 'NG') or (value['ERP_ERRCODE'] = 'E')"
                    , styles: "foreground= #CC3D3D"
                }]);

            UCRealGrid.SetColsFilter(vFilters);
        }
  
        function UCRealGrid_ItemChecked(grid, itemIndex, checked) {
            var sel = { startItem: itemIndex, endItem: itemIndex, style: "rows" };
            
            UCRealGrid_gridView.setSelection(sel);            
        };

        function UCRealGrid_CellEdited(grid, itemIndex, dataRow, field) { 

            UCRealGrid_gridView.checkRow(itemIndex, true, false);            

            UCRealGrid_gridView.commit();
        };        

        function UCRealGrid_LoadDataCompleted(rtn) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            $("#totalConunt").html("<%=lang.word["Search results"]%> ( Total <span class='red01'>" + UCRealGrid.GetRowCount() + "</span> Found )");
            if (UCRealGrid.GetRowCount() == 0) {
                xAlert("<%=lang.message["20051"]%>");
            }

            UCRealGrid_gridView.commit();

            for (var idx = 0; idx < UCRealGrid.GetRowCount() ; idx++) {
                var jsonData = UCRealGrid_dataProvider.getJsonRow(idx);
                if (jsonData.ERP_ERRCODE != 'S' || jsonData.ERP_CNCLERRCODE == 'S') {
                    UCRealGrid_gridView.setCheckable(idx, false);
                }
                
            }
        }        

        // #region 실사일자 설정
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

        
        function setBtnSearchEnabled(bCond) {
            var btnSearchEn = document.getElementById('btnSearch');
            btnSearchEn.disabled = bCond;             
        }
        function onSelectPage(page) {
            //페이지 선택시 재조회
            if (vQuery) { vQuery = false; return; };
            InquiryData(page);
        }
        
        //투입처리 시작 ===================================================
        function InitAddGrid() { 
            // 재공이동 등록 슬라이드 GRID...
            ucOutAddRealgrid.ColumnsClear();
            
            ucOutAddRealgrid.AddColumn("POSTDATE", "<%=lang.word["STODOCDATE"]%>", 80, "center", ColumnType.TEXT, false, true, null, null);                                      // 전기일            
            ucOutAddRealgrid.AddColumn("WOID_MES", "<%=lang.word["Work Order No."]%>", 150, "center", ColumnType.TEXT, false, true, null, null);                                       // 작업지시번호
            ucOutAddRealgrid.AddColumn("WOID", "<%=lang.word["W/O"]%>", 120, "center", ColumnType.TEXT, false, true, null, null);                                                 // ERP WORKORDER 번호
            ucOutAddRealgrid.AddColumn("PRODID", "<%=lang.word["PRODID"]%>", 150, "center", ColumnType.TEXT, false, true, null, null);                                            // 제품 ID
            ucOutAddRealgrid.AddColumn("PRODNAME", "<%=lang.word["PRODNAME"]%>", 220, "near", ColumnType.TEXT, false, true, null, null);                                        // 제품명

            //ucOutAddRealgrid.AddColumn("WORKCENTER", "<%=lang.word["Workcenter"]%>", 100, "center", ColumnType.TEXT, false, true, null, null);                                             // 작업장

            ucOutAddRealgrid.AddColumn("MTRLID", "<%=lang.word["Consume"]%>" + "<%=lang.word["Material ID"]%>", 120, "center", ColumnType.TEXT, false, true, null, null);         // 자재 ID
            ucOutAddRealgrid.AddColumn("MTRLNAME", "<%=lang.word["Consumed Material"]%>", 220, "near", ColumnType.TEXT, false, true, null, null);                               // 투입자재(자재명)
            ucOutAddRealgrid.AddColumn("BTCHNO", "<%=lang.word["Batch No."]%>", 100, "center", ColumnType.TEXT, false, true, null, null);                                         // 배치번호
            ucOutAddRealgrid.AddColumn("MOVETYPE", "<%=lang.word["이동유형"]%>", 100, "center", ColumnType.TEXT, false, true, null, null);                                         // 이동유형
            ucOutAddRealgrid.AddColumn("INPUTQTY", "<%=lang.word["Input Qty"]%>", 90, "#,##0.000", ColumnType.NUMBER, false, true, null, null);                                 // 투입 수량
            ucOutAddRealgrid.AddColumn("SLOCID", "<%=lang.word["Sloc. ID"]%>", 80, "center", ColumnType.TEXT, false, true, null, null);                                          // 저장위치 ID                        
            ucOutAddRealgrid.AddColumn("NOTE", "<%=lang.word["Remarks"]%>", 600, "near", ColumnType.TEXT, false, true, null, null);                                          // 비고
            ucOutAddRealgrid.AddColumn("MTRLSEQ", "<%=lang.word["MTRLSEQ"]%>", 80, "center", ColumnType.TEXT, false, false, null, null);                                          // 시퀀스 
            ucOutAddRealgrid.AddColumn("EXCELCHK", "<%=lang.word["EXCELCHK"]%>", 80, "center", ColumnType.TEXT, false, false, null, null);                                          // 엑셀업로드건 및 체크 여부 (Y : 엑셀건, K : 체크 완료) 


            ucOutAddRealgrid.InitGrid("<%=ViewState["MENU_ID"].ToString()%>", false, true, true);

            ucOutAddRealgrid_gridView.addCellStyle("noteCellStyle", {
                "foreground": "#FD0101"
            }, true);                                         
        }

        // CHECKBOX를 체크하면 동일BOXID가 선택되도록 한다.
        function ucOutAddRealgrid_ItemChecked(grid, items, checked) {
            var selBOXID = ucOutAddRealgrid_dataProvider.getValue(items, "BOXID");
            if (selBOXID == undefined || selBOXID == "") return;

            if (ucOutAddRealgrid_dataProvider.getJsonRows(0, -1).length > 0) {
                ucOutAddRealgrid_dataProvider.getJsonRows(0, -1).forEach(function (itemValue, index) {
                    var cBOXID = ucOutAddRealgrid.GetValue(index, "BOXID");
                    if (cBOXID != "" && selBOXID == cBOXID) {
                        ucOutAddRealgrid_gridView.checkItem(index, checked, false);
                    }
                });
            } 
        }

        //투입처리 Start =================================================
        function CallSlideArea() {
            vIsEdit = true;
              
            /// <summary>Slide 영역 표시</summary> 
            /// <param name="currentRow" type="object">현재 행 객체</param> 
            /// <param name="callID" type="string">Slide 호출 유형</param>  
            ExpandSlideArea();

            AutoHeightSpread(true);

            topControlsEnable(false); //버튼 컨트롤
            
            subTitle();
        };
        
        function topControlsEnable(bCond) {
            SetButtonEnable("#btnSave", bCond);
            //SetButtonEnable("#btnOutgoingAdd", bCond);                         
        }

        function subTitle() {
            $("#subTitle").html(" <%=lang.word["Registered Rows"]%>( Total <span class='textPink'>" + ucOutAddRealgrid.GetRowCount() + "</span> Found )");    
        }

        function initOutAdd() { //초기화
            SetDateTime();

            $('#cboStorage').combobox('setValue', '');
            $('#txtMtrlId').textbox('setValue', '');
            //$('#txtWorkCenter').textbox('setValue', '');
            $('#txtQty').numberbox('setValue', '');
            $('#txtBatchNo').textbox('setValue', '');
            $('#txtWoId2').textbox('setValue', '');
            $('#cboMoveType').combobox('setValue', '');

            ucOutAddRealgrid_dataProvider.clearRows();
            subTitle();
        }

        // 파라미터 검증
        function fnValidation(curRows, flag) {
            if (curRows.POSTDATE == undefined || curRows.POSTDATE == null || curRows.POSTDATE == "") {
                xAlert("<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["STODOCDATE"]%>"));// [%1](을)를 선택하여 주십시오. : 전기일자
                return false;
            }

            if (flag == true && (curRows.WOID_MES == undefined || curRows.WOID_MES == null || curRows.WOID_MES == "")) {
                xAlert("<%=lang.message["20058"]%>".replace("%1", "<%=lang.word["Work Order No."]%>"));// [%1]을 입력하세요. : 작업지시 번호
                return false;
            }
            

            if (curRows.MTRLID == undefined || curRows.MTRLID == null || curRows.MTRLID == "") {
                xAlert("<%=lang.message["20058"]%>".replace("%1", "<%=lang.word["Material"]%>"));// [%1]을 입력하세요. : 자재
                return false;
            }

            if (curRows.MOVETYPE == undefined || curRows.MOVETYPE == null || curRows.MOVETYPE == "") {
                xAlert("<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["이동유형"]%>"));// [%1](을)를 선택하여 주십시오. : 이동유형
                return;
            }

            if (curRows.MOVETYPE != "261" && curRows.MOVETYPE != "262") {
                xAlert("<%=lang.message["9163"]%>".replace("%1", "<%=lang.word["이동유형"]%>"));// [%1]을(를) 정확히 입력하십시오. : 이동유형
                return false;
            }
            

            if (curRows.INPUTQTY == undefined || curRows.INPUTQTY == null || curRows.INPUTQTY == "") {
                xAlert("<%=lang.message["20058"]%>".replace("%1", "<%=lang.word["Qty."]%>"));// [%1]을 입력하세요. : 수량
                return false;
            }

            if (curRows.INPUTQTY <= 0) {
                xAlert("<%=lang.message["10028"]%>".replace("%1", "<%=lang.word["Qty."]%>").replace("%2", "0"));// %1은 %2보다 큰 값이 입력되어야 합니다. : 수량, 0
                return false;
            }

            if (curRows.SLOCID == undefined || curRows.SLOCID == null || curRows.SLOCID == "") {
                xAlert("<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["Storage"]%>"));// [%1](을)를 선택하여 주십시오. : 저장위치
                return false;
            }

            return true;
        }

        // 입력 데이터 추가
        function AddRow() {
            
            values = {

                POSTDATE: $('#dtStoDocDate').combobox('getValue'),
                WOID_MES: $('#txtWoId2').textbox('getValue'),
                WOID : "",
                PRODID: $('#txtProdId2').textbox('getValue'),
                PRODNAME: $('#txtProdName2').textbox('getValue'),

                //WORKCENTER: $('#txtWorkCenter').textbox('getValue'),

                MTRLID: $('#txtMtrlId').textbox('getValue'),
                MTRLNAME: $('#txtMtrlName').textbox('getValue'),
                BTCHNO: $('#txtBatchNo').textbox('getValue'),
                MOVETYPE: $('#cboMoveType').combobox('getValue'),
                INPUTQTY: $('#txtQty').numberbox('getValue'),

                SLOCID: $('#cboStorage').combobox('getValue'),
                NOTE: "",
                MTRLSEQ : ""
            };                        

            if (!fnValidation(values, '')) {
                return;
            }

            ucOutAddRealgrid_gridView.commit();

            // 중복데이터 체크
            for (var i = 0 ; i < ucOutAddRealgrid.GetRowCount() ; i++) {
                var jsonData = ucOutAddRealgrid_dataProvider.getJsonRow(i);
                if (jsonData.POSTDATE == values.POSTDATE && jsonData.WOID_MES == values.WOID_MES && jsonData.MTRLID == values.MTRLID && jsonData.SLOCID == values.SLOCID &&
                    jsonData.MOVETYPE == values.MOVETYPE && jsonData.BTCHNO == values.BTCHNO) {
                    xAlert("<%=lang.message["10017"]%>"); // 입력하려는 값이 이미 존재합니다.
                    return;
                }
            };

            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.WOID = values.WOID_MES;
            items.MTRLID = values.MTRLID;

            var param = {};            
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            ShowLoading();
            param.bizID = "DA_PRD_GET_WORKORDER_INFO_COMMON_2";
            { 
                
                sendRequestMethod(function (id, datas) {
                    CloseLoading();
                    if (datas != null && datas.length > 0) {
                        values.WOID = datas[0].WOID_REP == undefined || datas[0].WOID_REP == null || datas[0].WOID_REP == "" ? values.WOID_MES : datas[0].WOID_REP;
                        values.PRODID = datas[0].PRODID == undefined || datas[0].PRODID == null || datas[0].PRODID == "" ? values.PRODID : datas[0].PRODID;
                        values.PRODNAME = datas[0].PRODNAME == undefined || datas[0].PRODNAME == null || datas[0].PRODNAME == "" ? values.PRODNAME : datas[0].PRODNAME;

                        param.bizID = "DA_PRD_SEL_MATERIALINFO";
                        ShowLoading();
                        sendRequestMethod(function (id2, datas2) {
                            CloseLoading();
                            if (datas2 != null && datas2.length > 0) {
                                values.MTRLID = datas2[0].MTRLID == undefined || datas2[0].MTRLID == null || datas2[0].MTRLID == "" ? values.MTRLID : datas2[0].MTRLID;
                                values.MTRLNAME = datas2[0].MTRLNAME == undefined || datas2[0].MTRLNAME == null || datas2[0].MTRLNAME == "" ? values.MTRLNAME : datas2[0].MTRLNAME;

                                var rowNo = ucOutAddRealgrid.GetRowCount();
                                ucOutAddRealgrid_dataProvider.insertRow(rowNo, values);
                                ucOutAddRealgrid_gridView.checkRow(rowNo, true, false);

                                // 추가 후 자재, 수량, 배치번호, 작업장은 초기화 한다.
                                $('#txtMtrlId').textbox('setValue', '');
                                $('#txtMtrlName').textbox('setValue', '');
                                $('#txtQty').numberbox('setValue', '');
                                $('#txtBatchNo').textbox('setValue', '');
                                //$('#txtWorkCenter').textbox('setValue', '');

                                subTitle();
                            } else {
                                xAlert("<%=lang.message["25059"]%>".replace("%1", values.MTRLID)); // 자재[%1] 정보가 존재하지 않습니다.
                                return;
                            }
                        }, param, "POST", url);

                    } else {
                        if ($("#chkWoId").prop("checked")) {
                            xAlert("<%=lang.message["9163"]%>".replace("%1", "<%=lang.word["Work Order No."]%>")); // [%1]을(를) 정확히 입력하십시오., 작업지시 번호
                            return;
                        } else {
                            values.WOID = values.WOID_MES;
                            param.bizID = "DA_PRD_SEL_MATERIALINFO";
                            ShowLoading();
                            sendRequestMethod(function (id2, datas2) {
                                CloseLoading();
                                if (datas2 != null && datas2.length > 0) {
                                    values.MTRLID = datas2[0].MTRLID == undefined || datas2[0].MTRLID == null || datas2[0].MTRLID == "" ? values.MTRLID : datas2[0].MTRLID;
                                    values.MTRLNAME = datas2[0].MTRLNAME == undefined || datas2[0].MTRLNAME == null || datas2[0].MTRLNAME == "" ? values.MTRLNAME : datas2[0].MTRLNAME;

                                    var rowNo = ucOutAddRealgrid.GetRowCount();
                                    ucOutAddRealgrid_dataProvider.insertRow(rowNo, values);
                                    ucOutAddRealgrid_gridView.checkRow(rowNo, true, false);

                                    // 추가 후 자재, 수량, 배치번호, 작업장은 초기화 한다.
                                    $('#txtMtrlId').textbox('setValue', '');
                                    $('#txtMtrlName').textbox('setValue', '');
                                    $('#txtQty').numberbox('setValue', '');
                                    $('#txtBatchNo').textbox('setValue', '');
                                    //$('#txtWorkCenter').textbox('setValue', '');

                                    subTitle();
                                } else {
                                    xAlert("<%=lang.message["25059"]%>".replace("%1", values.MTRLID)); // 자재[%1] 정보가 존재하지 않습니다.
                                    return;
                                }
                            }, param, "POST", url);
                        }
                        
                    }
                
                }, param, "POST", url); 
            } 
                                   
        }

        // 추가된 데이터 삭제
        function DelRow() {
            var rows = ucOutAddRealgrid_gridView.getCheckedRows();
            if (rows.length == 0) {
                xAlert("<%=lang.message["10008"]%>"); // 선택된 데이터가 없습니다.
                return;
            }

            var items = ucOutAddRealgrid_gridView.getCheckedRows();
            if (items == null) return false;

            for (var i = items.length - 1; i >= 0; i--) {
                if (ucOutAddRealgrid_dataProvider.getRowState(items[i]) == "created") {
                    ucOutAddRealgrid_dataProvider.setOptions({ softDeleting: false });
                    ucOutAddRealgrid_dataProvider.removeRow(items[i]);
                } 
            }  
        }

        function fnChkCancelConfirmData() {
            var rows = UCRealGrid_gridView.getCheckedRows();
            if (rows.length == 0) {
                xAlert("<%=lang.message["10008"]%>"); // 선택된 데이터가 없습니다.
                return;
            }

            for (var i in rows) {
                var curRows = UCRealGrid_gridView.getDataSource().getJsonRow(rows[i]);
                if (curRows.ERP_ERRCODE == "NG" || curRows.ERP_ERRCODE == "E") {

                    return;
                }
            }

            xConfirm("<%=lang.message["25051"]%>", function (parm) { if (parm) fnCancelErpData(); }); // 취소 하시겠습니까?
        }

        // #region fnChkSendToErp  
        function fnCancelErpData() {
            var items = [];
            var subItems = [];
            var param = {};
            var url;
            var idx = 0;                      

            UCRealGrid_gridView.commit();
            var inItem = [];
            var inData = [];
            
            idx = 0;
            var rows = UCRealGrid_gridView.getCheckedRows();

            inData[0] = [
                  { name: "SECTION", value: "CANCEL", dataType: _DataType.String }
                , { name: "SHOPID", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                , { name: "LANGID", value: $("[id$=hidLangID]").val(), dataType: _DataType.String }
                , { name: "USERID", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
            ];

            for (var i in rows) {
                var curRows = UCRealGrid_gridView.getDataSource().getJsonRow(rows[i]); // UCRealGrid_gridView.getValues(rows[i]);  (getValues->getJsonRow: 컬럼을 Sorting하게 되면 사용자가 선택한 Row와 전혀 다른 Data를 Return하는 오류 방지)                               
                
                inItem[idx] = [
                      { name: "POSTDATE", value: curRows.POSTDATE, dataType: _DataType.String } // $("[id$=hidShopID]").val()
                    , { name: "SHOPID", value: curRows.SHOPID, dataType: _DataType.String }
                    , { name: "WOID", value: curRows.WOID, dataType: _DataType.String }
                    , { name: "REQUESTID", value: curRows.REQUESTID, dataType: _DataType.String }
                    , { name: "ERP_DOCNO", value: curRows.ERP_DOCNO, dataType: _DataType.String }
                    , { name: "SEQ", value: curRows.SEQ, dataType: _DataType.String }
                    , { name: "INPUTQTY", value: curRows.INPUTQTY, dataType: _DataType.String }
                ];

                idx++;
            }

            if (idx > 0) {
                items[0] = inData;
                items[1] = inItem;

                url = "/GMES_POM/GMES_IMS_0581.aspx/GetDataSet";// "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";

                param.bizID = "BR_PRD_ERP_SEND_INPUT_ADJUST";
                param.items = items;
                param.inTableNames = "INDATA,INITEM";
                param.outTableNames = "OUTDATA,ERR_ITEM";

                ShowLoading();
                sendRequestMethod(function (targetId, data, message, status) {
                    CloseLoading();
                    {
                        if (status == "OK") {
                            xAlert("<%=lang.message["20180"]%>"); // 작업이 완료되었습니다.      
                            initOutAdd();
                            InquiryData();
                        } else {
                            xAlert(message); //                         
                        }
                    }

                }, param, "POST", url);
            } else {

            }
        }
        // #endregion

        

        function fnChkSendToErpData() {
            var rows = ucOutAddRealgrid_gridView.getCheckedRows();
            if (rows.length == 0) {
                xAlert("<%=lang.message["20021"]%>"); // 입력한 데이터가 없습니다.
                return;
            }
            xConfirm("<%=lang.message["20023"]%>", function (parm) { if (parm) fnChkSendToErp("CONFIRM"); });
        }

        // #region fnChkSendToErp  
        function fnChkSendToErp(flag) {
            var items = [];
            var subItems = [];
            var param = {};
            var url;
            var idx = 0;
           
            // 시퀀스 넣기
            var rows = ucOutAddRealgrid_dataProvider.getJsonRows(0, -1)            
            for (var i in rows) {                
                ucOutAddRealgrid_gridView.setValue(idx, "MTRLSEQ", idx);
                idx++;
            }

            ucOutAddRealgrid_gridView.commit();
            var inItem = [];
            var inData = [];
            
            idx = 0;
            var rows = ucOutAddRealgrid_gridView.getCheckedRows();

            inData[0] = [
                  { name: "SECTION", value: "SEND", dataType: _DataType.String }
                , { name: "SHOPID", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                , { name: "LANGID", value: $("[id$=hidLangID]").val(), dataType: _DataType.String }
                , { name: "USERID", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
                , { name: "WOID_FLAG", value: $("#chkWoId").prop("checked") ? "Y" : "N", dataType: _DataType.String }
            ];

            for (var i in rows) {
                var curRows = ucOutAddRealgrid_gridView.getDataSource().getJsonRow(rows[i]); // UCRealGrid_gridView.getValues(rows[i]);  (getValues->getJsonRow: 컬럼을 Sorting하게 되면 사용자가 선택한 Row와 전혀 다른 Data를 Return하는 오류 방지)                               
                
                if (flag != "EXCEL" && !fnValidation(curRows, '')) {
                    return;
                }
                
                //if (flag == "EXCEL" && curRows.EXCELCHK == "EXCEL") {
                //    inItem[idx] = [
                //      { name: "POSTDATE", value: curRows.POSTDATE, dataType: _DataType.String } // $("[id$=hidShopID]").val()
                //    , { name: "SHOPID", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                //    , { name: "WOID", value: curRows.WOID, dataType: _DataType.String }
                //    , { name: "MTRLID", value: curRows.MTRLID, dataType: _DataType.String }
                //    , { name: "INPUTQTY", value: curRows.MOVETYPE == "261" ? (curRows.INPUTQTY > 0 ? curRows.INPUTQTY : (curRows.INPUTQTY * -1)) : (curRows.INPUTQTY > 0 ? (curRows.INPUTQTY  * -1) : curRows.INPUTQTY), dataType: _DataType.Decimal }
                //    , { name: "SLOCID", value: curRows.SLOCID, dataType: _DataType.String }
                //    , { name: "BTCHNO", value: curRows.BTCHNO, dataType: _DataType.String }
                //    , { name: "MTRLSEQ", value: curRows.MTRLSEQ, dataType: _DataType.String }
                //    , { name: "MOVETYPE", value: curRows.MOVETYPE, dataType: _DataType.String }
                //    ];
                //} else {
                //    inItem[idx] = [
                //      { name: "POSTDATE", value: curRows.POSTDATE, dataType: _DataType.String } // $("[id$=hidShopID]").val()
                //    , { name: "SHOPID", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                //    , { name: "WOID", value: curRows.WOID, dataType: _DataType.String }
                //    , { name: "MTRLID", value: curRows.MTRLID, dataType: _DataType.String }
                //    , { name: "INPUTQTY", value: curRows.MOVETYPE == "261" ? (curRows.INPUTQTY > 0 ? curRows.INPUTQTY : (curRows.INPUTQTY * -1)) : (curRows.INPUTQTY > 0 ? (curRows.INPUTQTY * -1) : curRows.INPUTQTY), dataType: _DataType.Decimal }
                //    , { name: "SLOCID", value: curRows.SLOCID, dataType: _DataType.String }
                //    , { name: "BTCHNO", value: curRows.BTCHNO, dataType: _DataType.String }
                //    , { name: "MTRLSEQ", value: curRows.MTRLSEQ, dataType: _DataType.String }
                //    , { name: "MOVETYPE", value: curRows.MOVETYPE, dataType: _DataType.String }
                //    ];
                //}

                inItem[idx] = [
                      { name: "POSTDATE", value: curRows.POSTDATE, dataType: _DataType.String } // $("[id$=hidShopID]").val()
                    , { name: "SHOPID", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                    , { name: "WOID", value: curRows.WOID, dataType: _DataType.String }
                    , { name: "MTRLID", value: curRows.MTRLID, dataType: _DataType.String }
                    , { name: "INPUTQTY", value: curRows.MOVETYPE == "261" ? (curRows.INPUTQTY > 0 ? curRows.INPUTQTY : (curRows.INPUTQTY * -1)) : (curRows.INPUTQTY > 0 ? (curRows.INPUTQTY * -1) : curRows.INPUTQTY), dataType: _DataType.Decimal }
                    , { name: "SLOCID", value: curRows.SLOCID, dataType: _DataType.String }
                    , { name: "BTCHNO", value: curRows.BTCHNO, dataType: _DataType.String }
                    , { name: "MTRLSEQ", value: curRows.MTRLSEQ, dataType: _DataType.String }
                    , { name: "MOVETYPE", value: curRows.MOVETYPE, dataType: _DataType.String }
                ];
                

                idx++;
            }

            if (idx > 0) {
                items[0] = inData;
                items[1] = inItem;

                if (flag != "CONFIRM") {
                   
                   url = "/GMES_POM/GMES_IMS_0581.aspx/GetDataSet";// "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";

                   param.bizID = "BR_PRD_CHK_INPUT_ADJUST";
                   param.items = items;
                   param.inTableNames = "INDATA,INITEM";
                   param.outTableNames = "OUTDATA,ERR_ITEM,ITEM_INFO";

                   ShowLoading();
                   SetButtonEnable("#btnErpConfirm", false);
                   sendRequestMethod(function () {
                       CloseLoading();
                       SetButtonEnable("#btnErpConfirm", true);
                       if (data != null) {
                           if (data[0].OUTDATA[0].RSLT_FLAG != "OK") {
                               var temp = ucOutAddRealgrid_dataProvider.getJsonRows(0, -1)
                               for (var _row = 0; _row < temp.length; _row++) {
                                   ucOutAddRealgrid_gridView.setValue(_row, "NOTE", "");
                               }
                                                   
                               // 문제있는 값의 비고 내용 세팅              
                               for (var i=0; i < data[0].ERR_ITEM.length; i++) {
                                   var item = data[0].ERR_ITEM[i];
                                   var rows = ucOutAddRealgrid_dataProvider.getJsonRows(0, -1)                                    
                                   for (var _row = 0; _row < rows.length; _row++) {
                                       if (item.MTRLSEQ == rows[_row].MTRLSEQ) {
                                           // 작업지시 [%1] 정보가 존재하지 않습니다. : 자재[%1] 정보가 존재하지 않습니다. : [%1]을(를) 정확히 입력하십시오. : 이동유형
                                           var _errWo = item.ERR_WO == "W" ? "<%=lang.message["255347"]%>".replace("%1", rows[_row].WOID) : "";
                                           var _errMT = item.ERR_MT == "M" ? "<%=lang.message["25059"]%>".replace("%1", rows[_row].MTRLID) : "";
                                           var _errMV = item.ERR_MV == "V" ? "<%=lang.message["9163"]%>".replace("%1", "<%=lang.word["이동유형"]%>") : ""; 
                                           ucOutAddRealgrid_gridView.setValue(_row, "NOTE", _errWo + (_errWo.length > 0 && _errMT.length > 0 ? "/" + _errMT : _errMT));

                                           ucOutAddRealgrid_gridView.setCellStyles(_row, "NOTE", "noteCellStyle");
                                       }                                    
                                   }
                               }
                               // 엑셀 업로드시 제품정보 자재 정보 세팅
                               for (var idx = 0; idx < data[0].ITEM_INFO.length; idx++) {
                                   var _info = data[0].ITEM_INFO[idx];
                                   var rows = ucOutAddRealgrid_dataProvider.getJsonRows(0, -1)
                                   for (var _row = 0; _row < rows.length; _row++) {
                                       if (_info.MTRLSEQ == rows[_row].MTRLSEQ) {
                                           ucOutAddRealgrid_gridView.setValue(_row, "WOID_MES", _info.WOID);
                                           ucOutAddRealgrid_gridView.setValue(_row, "PRODID", _info.PRODID);
                                           ucOutAddRealgrid_gridView.setValue(_row, "PRODNAME", _info.PRODNAME);
                                           //ucOutAddRealgrid_gridView.setValue(_row, "MTRLID", _info.MTRLID);
                                           ucOutAddRealgrid_gridView.setValue(_row, "MTRLNAME", _info.MTRLNAME);
                                       }                                    
                                   }
                               }
                       
                               <%--if (flag != "EXCEL") {
                                   xAlert("<%=lang.message["20126"]%>"); // 20126 : 처리되지 않았습니다.
                               }--%>
                               return;
                           } else {
                               // 엑셀 업로드시 제품정보 자재 정보 세팅
                               for (var idx = 0; idx < data[0].ITEM_INFO.length; idx++) {
                                   var _info = data[0].ITEM_INFO[idx];
                                   var rows = ucOutAddRealgrid_dataProvider.getJsonRows(0, -1)
                                   for (var _row = 0; _row < rows.length; _row++) {
                                       if (_info.MTRLSEQ == rows[_row].MTRLSEQ) {
                                           ucOutAddRealgrid_gridView.setValue(_row, "WOID_MES", _info.WOID);
                                           ucOutAddRealgrid_gridView.setValue(_row, "PRODID", _info.PRODID);
                                           ucOutAddRealgrid_gridView.setValue(_row, "PRODNAME", _info.PRODNAME);
                                           //ucOutAddRealgrid_gridView.setValue(_row, "MTRLID", _info.MTRLID);
                                           ucOutAddRealgrid_gridView.setValue(_row, "MTRLNAME", _info.MTRLNAME);
                                       }
                                   }
                               }
                       
                               // 실제 ERP에 전송하는 모듈 호출
                               if (flag != "EXCEL") {
                                   CollapseSlideArea(); //슬라이드 CLOSE
                                   fnSendToErp(items)
                               }  
                               return;
                           }
                       } else {
                           xAlert("<%=lang.message["20126"]%>"); // 20126 : 처리되지 않았습니다.
                       }
               
                   }, param, "POST", url);
                } else {
                    CollapseSlideArea(); //슬라이드 CLOSE
                    fnSendToErp(items)
                }
               
            
            } else {
                xAlert("<%=lang.message["20064"]%>"); // 확정할 대상을 선택 하세요.
                return;
            }
        }
        // #endregion

        function fnSendToErp(_items) {
            var items = [];
            var param = {};
            var url = "/GMES_POM/GMES_IMS_0581.aspx/ExecuteDataSet";// "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";

            param.bizID = "BR_PRD_ERP_SEND_INPUT_ADJUST";
            param.items = _items;
            param.inTableNames = "INDATA,INITEM";
            param.outTableNames = "OUTDATA,ERR_ITEM";

            ShowLoading();
            sendRequestMethod(function (targetId, data, message, status) {
                CloseLoading();
                {
                    if (status == "OK") {
                        vIsEdit = false;
                        xAlert("<%=lang.message["20180"]%>"); // 작업이 완료되었습니다.  
                        initOutAdd();
                        InquiryData();
                    } else {
                        vIsEdit = false;
                        xAlert(message); // 오류 메시지
                        CallSlideArea();
                    }
                }

            }, param, "POST", url);                              
        }


        //이동저장 -- 참조 하고 삭제할것. 2022.04.08
        function SaveDataOutAdd() {
            var items = [];
            var subItems = [];
            var subClose = [];

            var param = {};
            var url;

            ucOutAddRealgrid_gridView.commit();
            var rows = ucOutAddRealgrid_dataProvider.getJsonRows(0, -1);
            var curRows;
            var idx = 0;

            //저장할 대상이 없습니다.
            if (ucOutAddRealgrid_dataProvider.getJsonRows(0, -1).length <= 0) {
                xAlert(msgNotSaveList);
                return;
            }

            //공정이동,라인이동인 경우에는 입고창고 세팅 
            for (var i in rows) {
                curRows = rows[i];
                subItems[idx] = [
                          { name: "LANGID", value: $("[id$=hidLangID]").val(), dataType: _DataType.String }
                        , { name: "SRCTYPE", value: "UI", dataType: _DataType.String }
                        , { name: "SHOPID_FROM", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                        , { name: "SHOPID_TO", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                        , { name: "AREAID_FROM", value: curRows.FR_AREAID, dataType: _DataType.String }
                        , { name: "AREAID_TO", value: curRows.IN_AREAID, dataType: _DataType.String }
                        , { name: "WHID_FROM", value: curRows.FR_WHID, dataType: _DataType.String }
                        , { name: "WHID_TO", value: curRows.IN_WHID, dataType: _DataType.String }
                        , { name: "MOVEUSER", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
                        , { name: "MOVENOTE", value: "", dataType: _DataType.String }
                        , { name: "MTRLTYPE", value: curRows.MTRLTYPE, dataType: _DataType.String }
                        , { name: "LOTID", value: curRows.LOTID, dataType: _DataType.String }
                        , { name: "BOXID", value: curRows.BOXID, dataType: _DataType.String }
                        , { name: "SLOCID_TO", value: curRows.IN_SLOCID, dataType: _DataType.String }
                        , { name: "SPLIT_QTY", value: curRows.WIPQTY, dataType: _DataType.String }
                ]
                idx++;
            }

            subClose[0] = [
                      { name: "SHOPID_CURR", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                    , { name: "WIPCLOSETYPE", value: "M", dataType: _DataType.String }
                    , { name: "CNTDATE", value: $("#hidCNTDATE").val(), dataType: _DataType.String }
                    , { name: "SNAPDATE", value: $("#hidSNAPDATE").val(), dataType: _DataType.String }
                    , { name: "LANGID", value: $("[id$=hidLangID]").val(), dataType: _DataType.String }
                    , { name: "CHKRSLT", value: "OK", dataType: _DataType.String }
                    , { name: "WIPCLOSEUSER_RPT", value: $('#cboReportorSave').combobox('getValue'), dataType: _DataType.String }    //마감담당자
                    , { name: "USERID", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
            ];

            items[0] = subItems;
            items[1] = subClose;

            url = "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";
            //param.bizID = "BR_PRD_REG_START_MOVE_WIP_V2";
            param.bizID = "BR_PRD_REG_START_MOVE_WIP_CLOSING";
            param.items = items;
            param.inTableNames = "INDATA,INDATA_SINGLE";
            param.outTableNames = "";

            try {
                SaveOK = false;
                sendRequestMethod(CallBackSave, param, "POST", url);

            } catch (e) {
                document.body.style.cursor = "default";
                xAlert(e.Message);
                return;
            }
        }
        // #region CallBackSave - 트랜잭션 콜백 처리 후 메시지 
        function CallBackSave(id, data) {
            if (data === null) return;
            if (data[0].RETURN === "FAIL") {
                xAlert(data[0].MESSAGE);
                return;
            }
            else if (data[0].RETURN === "OK") {
                xAlert(msgProcessComplete);//처리 되었습니다. 

                vQuery = false;
                InquiryData($('#cboPage').combobox('getValue'));
                return;
            }
        }
        // #endregion
        
        function fnExcelValidation(roa) {
            for (var i = 1; i < roa.length; i++) {
                if (roa[i][0] == null || roa[i][0] == "" || roa[i][1] == null || roa[i][1] == "" || roa[i][2] == null || roa[i][2] == "" ||
                    roa[i][4] == null || roa[i][4] == "" || roa[i][5] == null || roa[i][5] == "" || roa[i][6] == null || roa[i][6] == "") {                    

                    //입력이 제대로 안된 항목이 있습니다.
                    xAlert('<%=lang.message["6030"]%>');
                    return false;
                    //continue;
                } else if (roa[i][0].length != 10) {
                    // YYYY-MM-DD
                    //[%1]을(를) 정확히 입력하십시오.
                    xAlert('<%=lang.message["9163"]%>'.replace("%1", "<%=lang.word["POSTDATE"]%>"));
                    return false;
                } else if (roa[i][4] != "261" && roa[i][4] != "262") {
                    //[%1]을(를) 정확히 입력하십시오.
                    xAlert('<%=lang.message["9163"]%>'.replace("%1", "<%=lang.word["이동유형"]%>"));
                    return false;
                }
                <%--else if (roa[i][5] <= 0) {
                    //flag = true;
                    // %1은 %2보다 큰 값이 입력되어야 합니다. : 수량, 0
                    xAlert("<%=lang.message["10028"]%>".replace("%1", "<%=lang.word["Qty."]%>").replace("%2", "0"));
                    return false;
                }--%>
            }

            return true;
        }

        //
        function fnExcelChkData() {

        }

        function ExcelImport(e) {
            /// <summary>엑셀 파일을 읽어 들여 그리드에 표시한다.</summary>            
            var rABS = typeof FileReader !== "undefined" && (FileReader.prototype || {}).readAsBinaryString;
            //var file = f.value;
            var f = e.target.files[0];
            var check = f.name.toString();
            var reader = new FileReader();
            var result = [];
            var roa = {};
            var state;
            
            ShowLoading(); // MODIFY YN 체크가 끝날 때 까지 Loading 화면
            var flag = false;

            if (check.indexOf("ERP_SEND") != -1) {                 
                reader.onload = function (e) {                    
                    var data = e.target.result;
                    if (!rABS) data = new Uint8Array(data);
                    var workbook = XLSX.read(data, { type: rABS ? 'binary' : 'array' });
                    var sheet_name_list = workbook.SheetNames;
                                        
                    var roa = XLSX.utils.sheet_to_json(workbook.Sheets[workbook.SheetNames[0]], { header: 1 });
                    {
                        var isDup = false;
                        if (!fnExcelValidation(roa)) {
                            return;
                        }
                        // 0: 전기일자, 1: ERP W/O, 2: 자재 ID, 3: 배치번호, 4: 이동유형(261, 262), 5: 투입수량, 6: 저장위치 ID
                        for (var i = 1; i < roa.length; i++) {                                                       
                            values = {
                                POSTDATE: roa[i][0],
                                WOID_MES: "",
                                WOID: roa[i][1],
                                PRODID: "",
                                PRODNAME: "",                                
                                MTRLID: roa[i][2],
                                MTRLNAME: "",
                                BTCHNO: roa[i][3], // Nullable
                                MOVETYPE: roa[i][4],
                                INPUTQTY: roa[i][5] < 0 ? roa[i][5] * -1 : roa[i][5], // 음수를 양수로 변환한다.
                                SLOCID: roa[i][6],
                                NOTE: "",
                                MTRLSEQ: "",
                                EXCELCHK: "EXCEL"
                            };

                            // 동일건 체크
                            // 중복데이터 체크
                            var chkDup = false;
                            ucOutAddRealgrid_gridView.commit();

                            for (var idx = 0 ; idx < ucOutAddRealgrid.GetRowCount() ; idx++) {                                
                                var jsonData = ucOutAddRealgrid_dataProvider.getJsonRow(idx);
                                if (jsonData.POSTDATE == values.POSTDATE && jsonData.WOID == values.WOID && jsonData.MTRLID == values.MTRLID && jsonData.SLOCID == values.SLOCID && 
                                    jsonData.MOVETYPE == values.MOVETYPE && jsonData.BTCHNO == values.BTCHNO) {                                    
                                    chkDup = true;
                                    isDup = true;
                                    break;
                                }                                
                            };
                            
                            { // 중복데이터가 아니면 추가
                                rowNo = ucOutAddRealgrid.GetRowCount();
                                ucOutAddRealgrid_dataProvider.insertRow(rowNo, values);
                                ucOutAddRealgrid_gridView.checkRow(rowNo, chkDup == false ? true : false, false);
                            }                            
                        }

                        if (isDup) {
                            xAlert('<%=lang.message["125914"]%>'); // 중복데이터가 있습니다.
                        }
                    }

                    // 엑셀 업로드 데이터 검증
                    fnChkSendToErp("EXCEL");
                }
                CloseLoading();
                                
            } else {
                // msg(9017) : 업로드한 엑셀파일의 데이타가 잘못되었습니다. 확인 후 다시 처리하여 주십시오.
                //xAlert('<%=lang.message["9017"]%>');
                xAlert('<%=lang.message["10029"]%>' + '[' + "<%=lang.word["File Name"]%>" + " : ERP_SEND" + "] 필수 포함"); // 10029 : 선택하신 파일의 템플릿이 올바르지 않습니다. File Name : 파일 명
                CloseLoading(); 
                return;
            }
            

            if (rABS) {
                reader.readAsBinaryString(f);
            } else {
                reader.readAsArrayBuffer(f);
            }

            ucOutAddRealgrid_LoadDataCompleted();
            $('#uploadFile').val("");
        }

        function ucOutAddRealgrid_LoadDataCompleted() {
            ucOutAddRealgrid.Commit(true);
  
            $("#subTitle").html("<%=lang.word["Search results"]%> ( Total <span class='red01'>" + ucOutAddRealgrid.GetRowCount() + "</span> Found )");
       
        }
    </script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="bodyHolder" runat="server">
    <form id="form1" runat="server">
        <!-- hidden Field Start-->
        <asp:HiddenField ID="hidHeight" runat="server" />
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidLoginuser" runat="server" />
        <asp:HiddenField ID="hidAccessFlag" runat="server" />
        <asp:HiddenField ID="hidMenuID" runat="server" />
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidMenuName" runat="server" />      
        <!-- hidden Field End-->
        <asp:ScriptManager runat="server" ID="ScriptManager1"></asp:ScriptManager>

        <!-- 검색조건 영역 시작 -->
        <div class="tableInquiry searchBox" id="divSearchPart">
            <div class="itemBox">
                <table>
                    <colgroup>
                        <col class="col_10p" />
                        <col class="col_20p" />
                        <col class="col_10p" />
                        <col class="col_20p" />
                        <col class="col_10p" />
                        <col class="col_20p" /> 
                        <col class="col_10p" />
                        <col class="col_20p" />
                        <col class="col_10p" />
                    </colgroup>
                    <tbody>
                        <tr>                            
                            <!-- 전기일 -->                   
                            <th><span class="textPink">*</span><%=lang.word["STODOCDATE"]%></th>
                            <td>
                                <input id="dtDateAppr" class="easyui-daterangebox" style="width: 100%; max-width: 200px;" />
                            </td>                            
                            <!--제품코드-->
                            <th><%=lang.word["Product Code"]%></th>
                            <td>                                
                                <input id="txtProdId" style="width: 200px;" class="easyui-searchbox" data-options="searcher:ShowProductCodePopup, inputEvents: $.extend({}, $.fn.searchbox.defaults.inputEvents, { keyup: function(e){  } })" />
                            </td>                            
                            <!-- 작업지시서 -->
                            <th><%=lang.word["W/O"]%></th>
                            <td>                                
                                <input id="txtWoId" class="easyui-textbox" style="width: 200px;" />
                            </td>
                            <td>
                                <label for="chkSendedErp">
                                    <input type="checkbox" id="chkSendedErp" name="chkSendedErp"/>ERP <%=lang.word["Confirm"]%><%=lang.word["Count."]%>
                                </label>
                            </td>
                        </tr>                           
                    </tbody>
                </table>
            </div>
            <div class="tableBtnSearch">
                <button type="button" id="btnSearch" onclick="onButtonClick(this.id)" ><span><%=lang.word["Search"]%></span></button>
            </div>
            <uc:SearchToggleContent ID="SearchToggleContent2" runat="server" />
        </div>
        <!-- 검색조건 영역 끝 -->

        <!-- CRUD Button Area start -->
        <div class="buttonArea" id="divMidButton">
            <div id="totalConunt" class="floatLeft01">&nbsp;<%=lang.word["Search results"]%>( Total <span class="textPink">0</span> Found )</div>
            <ul id="ulButton" class="btn_crud">           
                <li><a class="save" id="btnOpenSlide" onclick="onButtonClick(this.id)"><%=lang.word["Entry"]%></a></li> <!-- 등록 -->                     
                <li><a class="table_bar"></a></li>
                <%--<li><a class="red" id="btnReSend" onclick="onButtonClick(this.id)"><%=lang.word["ReSend"]%></a></li> --%><!-- 재전송 -->                
                <li><a class="red" id="btnErpCancel" onclick="onButtonClick(this.id)"><%=lang.word["CANCELDOCNO"]%></a></li> <!-- 전표취소(확정취소) -->
                <li><a class="table_bar"></a></li>
                <li><a class="excel" id="btnExcel" onclick="onButtonClick(this.id)"></a></li>
            </ul>                                      
        </div>
        <div class="clear"></div>
        <!-- CRUD Button Area end -->

        <!-- Contents 시작  -->
        <div id="dvContents_Mid" class="table">
            <uc:Realgrid ID="UCRealGrid" CALLID="UCRealGrid" HEIGHT="660" LAYOUTSAVING="Y" runat="server"/>
        </div>
        <!-- Contents 종료 -->
    </form>
    
    <input type="hidden" id="hidAreaId" />
    <input type="hidden" id="hidAreaId_S" />
    <input type="hidden" id="hidCNTDATE" />
    <input type="hidden" id="hidSNAPDATE" />
    
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="slideHolder" runat="server">  <!-- 투입 처리 슬라이드 -->
    <div id="divSlideTap" class="easyui-tabs" data-options="fit:true" style="height: 365px"> 
        <div id="divAddEntry" title="<%=lang.word["Input Handling"]%>" style="margin-top: 5px;"> 
            <div id="divAddEntryContent" style="padding-left: 10px; padding-right: 10px">
                <div id="divButtonAddEntryContent">
                    <div id="divBottomAddEntryButton" class="buttonArea">
                        <table id="tblAddEntryContent" style="width: 100%; ">
                            <colgroup>
                                <col class="col_10p" />
                                <col class="col_20p" />
                                <col class="col_10p" />
                                <col class="col_20p" />
                                <col class="col_10p" />
                                <col class="col_20p" /> 
                                <col class="col_10p" />
                                <col class="col_20p" />
                                <col class="col_10p" />
                            </colgroup>
                            <tbody> 
                                <tr>
                                    <!-- 전기일자 -->
                                    <th style="font-size:small; border-top: 2px solid;  border-top-color: lightgray; border-bottom: 2px solid;  border-bottom-color: lightgray; border-left: 2px solid;  border-left-color: lightgray; background-color: lightgray  "><span class="textPink">*</span><%=lang.word["STODOCDATE"]%></th>
                                    <td style="padding-left: 5px; padding-right: 15px; ">
                                        <input id="dtStoDocDate" class="easyui-datebox" data-options="onChange:dtStoDocDateChange" style="width:200px" />

                                    </td>
                                    <!-- 작업지시번호 -->
                                    <th style="font-size:small; border-top: 2px solid;  border-top-color: lightgray; border-bottom: 2px solid;  border-bottom-color: lightgray; border-left: 2px solid;  border-left-color: lightgray; background-color: lightgray  "><span class="textPink">*</span><%=lang.word["Work Order No."]%></th>
                                    <td style="padding-left: 5px; padding-right: 15px; ">
                                        <input id="txtWoId2" class="easyui-searchbox" style="width: 200px;" data-options="searcher:ShowWoProductCodePopup, inputEvents: $.extend({}, $.fn.searchbox.defaults.inputEvents )" />
                                        <span style="display:none;"><input id="txtProdId2" class="easyui-textbox" style="width: 200px; " /><input id="txtProdName2" class="easyui-textbox" style="width: 200px; " /></span>
                                    </td>
                                    <!-- 자재 -->
                                    <th style="font-size:small; border-top: 2px solid;  border-top-color: lightgray; border-bottom: 2px solid;  border-bottom-color: lightgray; border-left: 2px solid;  border-left-color: lightgray; background-color: lightgray  "><span class="textPink">*</span><%=lang.word["Material"]%></th>
                                    <td style="padding-left: 5px; padding-right: 15px; ">
                                        <input id="txtMtrlId" style="width: 200px; " class="easyui-searchbox" data-options="searcher:ShowProductCodePopup2, inputEvents: $.extend({}, $.fn.searchbox.defaults.inputEvents, { keyup: function(e){  } })" />
                                        <span style="display:none;"><input id="txtMtrlName" class="easyui-textbox" style="width: 200px;"/></span>
                                    </td>
                                    <!-- 이동유형 -->
                                    <th style="font-size:small; border-top: 2px solid;  border-top-color: lightgray; border-bottom: 2px solid;  border-bottom-color: lightgray; border-left: 2px solid;  border-left-color: lightgray; background-color: lightgray  "><span class="textPink">*</span><%=lang.word["이동유형"]%></th>
                                    <td style="padding-left: 5px; padding-right: 15px; ">
                                        <input id="cboMoveType" class="easyui-combobox" style="width: 200px"/>
                                    </td> 
                                    
                                </tr>                                
                                <tr  style="border-top: 5px solid #fff;">                                    
                                    <!-- Bath번호 -->
                                    <th style="font-size:small; border-top: 2px solid;  border-top-color: lightgray; border-bottom: 2px solid;  border-bottom-color: lightgray; border-left: 2px solid;  border-left-color: lightgray; background-color: lightgray  "><%=lang.word["Batch No."]%></th> 
                                    <td style="padding-left: 5px; padding-right: 15px; ">
                                         <input id="txtBatchNo" class="easyui-textbox" style="width: 200px;" />
                                    </td> 
                                    <!-- 저장위치 -->
                                    <th style="font-size:small; border-top: 2px solid;  border-top-color: lightgray; border-bottom: 2px solid;  border-bottom-color: lightgray; border-left: 2px solid;  border-left-color: lightgray; background-color: lightgray  "><span class="textPink">*</span><%=lang.word["Storage Location"]%></th>
                                    <td style="padding-left: 5px; padding-right: 15px; ">
                                        <input id="cboStorage" class="easyui-combobox" style="width: 200px"/>
                                    </td>    
                                    <%--<!-- 작업장(WorkCenter -->
                                    <th style="font-size:small; border-top: 2px solid;  border-top-color: lightgray; border-bottom: 2px solid;  border-bottom-color: lightgray; border-left: 2px solid;  border-left-color: lightgray; background-color: lightgray  "><span class="textPink">*</span><%=lang.word["Workcenter"]%></th>
                                    <td style="padding-left: 5px; padding-right: 15px; ">
                                        <input id="txtWorkCenter" class="easyui-textbox" style="width: 200px;" />
                                    </td>   --%>
                                    <td></td>
                                    <td></td>
                                    <!-- 수량 -->
                                     <th style="font-size:small; border-top: 2px solid;  border-top-color: lightgray; border-bottom: 2px solid;  border-bottom-color: lightgray; border-left: 2px solid;  border-left-color: lightgray; background-color: lightgray  "><span class="textPink">*</span><%=lang.word["Qty."]%></th>
                                    <td style="padding-left: 5px; padding-right: 15px; ">
                                        <input id="txtQty" class="easyui-numberbox" style="width: 100%;" data-options="precision:3"/>
                                    </td>
                                </tr> 
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="buttonArea" id="divMidButtonDetail"> 
                    <div id="subTitle" class="floatLeft01">&nbsp;&nbsp;&nbsp;&nbsp;<%=lang.word["Registered Rows"]%>( Total <span class='red01'>0</span> )</div>     
                    <ul id="ul1" runat="server" class="btn_crud" style="margin: 0px 0px 0px 0px;">
                        <li><a class="table_bar"></a></li>
                        <li><a class="red" id="btnUploadExcel" onclick="onButtonClick(this.id)"><%=lang.word["Excel Down"]%> <%=lang.word["Upload"]%></a></li> <!-- 엑셀 Upload -->
                        <li><a class="red" id="btnAddRow" onclick="onButtonClick(this.id)"><%=lang.word["Add"]%></a></li> <!-- 추가 -->                        
                        <li><a class="red" id="btnDelRow" onclick="onButtonClick(this.id)"><%=lang.word["Delete"]%></a></li> <!-- 삭제 -->
                        <li><a class="table_bar"></a></li>
                        <li><a class="red" id="btnInitOutAdd" onclick="onButtonClick(this.id)"><span><%=lang.word["Reset"]%></span></a></li>    <!-- 초기화 -->
                        <li><a class="save" id="btnErpConfirm" onclick="onButtonClick(this.id)"><span><%=lang.word["Confirm"]%></span></a></li> <!-- 확정 -->
                        <li><a class="table_bar"></a></li>
                        <li><a class="red" id="btnCloseSlide" onclick="onButtonClick(this.id)"><span><%=lang.word["Close"]%></span></a></li> <!-- 슬라이드 닫기 -->
                        <li><input name="uploadFile" id="uploadFile" type="file" style="display:none;"/></li>
                    </ul>  
                    <div id="divChkWoId" style="margin: 5px 0px 0px 0px;float:right;padding-top: 0px;">
                        <label for="chkWoId">
                            <input type="checkbox" id="chkWoId" name="chkWoId" checked/> <%=lang.word["작업지시번호 확인"]%>
                        </label>
                    </div>                                  
                </div>
                <div id="divAddOutRealgrid" class="table" style="margin: 5px 0px 0px 0px; ">
                    <uc:Realgrid ID="ucOutAddRealgrid" CALLID="ucOutAddRealgrid" runat="server"/> 
                </div>
            </div>
        </div> 
    </div>
</asp:Content>