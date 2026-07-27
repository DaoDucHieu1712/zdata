<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0531.aspx.cs" Inherits="GMES_IMES_0531" %>

<%--/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMES_0531.aspx
* @desc    : 재고관리 - ERP I/F - 인터페이스 이력조회(기타)
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2018/02/19   한유진              ERP 인터페이스 현황 (기타)
*************************************************************************************************
*/--%>
<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealGrid.ascx" TagName="Realgrid" TagPrefix="uc" %>
<%--<%@ Register Src="~/GMES_POM/Controls/UCGrid.ascx" TagName="Realgrid" TagPrefix="uc" %>--%>

<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js"></script>
    <script type="text/javascript" language="javascript">        
        // 조회구분을 선택하여 주십시요.
        var msgSearchTypeRequired = "<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["Search"]%> " +"<%=lang.word["Classification"]%>");
        // 공장/동을 선택하여 주십시요.
        var msgAreaRequired = "<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["Shop/Area"]%>");
        // 단위공정을 선택하여 주십시요.
        var msgProcessRequired = "<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["Process"]%>");
        // 라인/실을 선택하여 주십시요.
        var msgLineRequired = "<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["Line/Equipment Seg."]%>");
        // 조회내역이 존재하지 않습니다.
        var msgNotFoundList = "<%=lang.message["20051"]%>";
        
        //#region resize
        $(window).resize(function () {
            AutoHeightSpread();
        });
        //#endregion        

        //#region onSlideResize
        function onSlideResize() {
            AutoHeightSpread();
        };
        //#endregion

        //#region xInitPage
        function xInitPage() {
            AutoHeightSpread();
        }
        //#endregion

        //#region AutoHeightSpread - RealGrid의 높이를 재설정한다
        function AutoHeightSpread() {
            var gridMaster = document.getElementById("UCRealGrid");

            var masterHeight = document.getElementById("tbContents").offsetTop;
            var pageHeight = document.documentElement.clientHeight;
            var dockh = 0;

            if (IsDock()) {
                dockh = DockHeight();

                if (dockh > 0) {
                    dockh = dockh - 20;
                }
            }

            var i = 0;
            i = pageHeight - masterHeight - dockh - 40;

            gridMaster.style.height = String(i) + 'px';

            UCRealGrid.ResetSize();
        }
        //#endregion        

        //#region ready
        $(document).ready(function () {      
            InitControls();             
        });
        //#endregion        
         
        //#region InitControls - 컨트롤을 초기 셋팅한다
        function InitControls() {
            /// <summary>컨트롤을 초기 셋팅한다.</summary>        
            SetDateTime();
            SetSearchType();
            SetProcessingState();
        };
        //#endregion

        //#region SetDateTime - 날짜를 설정한다.
        function SetDateTime() {
            /// <summary>날짜를 설정한다.</summary>  
            var fromday = new Date();
            var today = new Date();

            fromday.setDate(fromday.getDate() - 7);
            $('#dtDateRange').daterangebox('SetFromDate', fromday);
            $('#dtDateRange').daterangebox('SetToDate', today);
        }
        //#endregion

        //#region SetSearchType - 조회 구분 콤보박스에 데이터를 설정한다
        function SetSearchType() {
            /// <summary>처리 상태 콤보박스에 데이터를 설정한다.</summary> 
            $('#cbo_SearchType').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_COMMONCODE_CBO&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&CMCDTYPE=EAI_TO_IMS_TYPE&CBOOPT=ALL|CMCODE|CMCDNAME',
                valueField: 'CMCODE',
                textField: 'CMCDNAME',
                onSelect: function (row) {
                    InitGrid(row.CMCODE);
                },
                onLoadSuccess: function () {
                    var items = $(this).combobox("getData");
                    if (items.length > 1) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                }
            });
        }
        //#endregion

        //#region SetProcessingState - 처리 상태 콤보박스에 데이터를 설정한다
        function SetProcessingState() {
            /// <summary>처리 상태 콤보박스에 데이터를 설정한다.</summary> 
            $('#cbo_ProcessingState').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_COMMONCODE_CBO&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&CMCDTYPE=PROCESSING_STATUS&CBOOPT=ALL|CMCODE|CMCDNAME',
                valueField: 'CMCODE',
                textField: 'CMCDNAME',
                onLoadSuccess: function () {
                    var items = $(this).combobox("getData");
                    if (items.length === 2) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                }
            });
        }
        //#endregion

        function dateConvert(date) {
            // YYYYMMDD 로 리턴한다.
            var tmpDate = date.split(" ");
            var strDate = tmpDate[0].split("-");
            var rtnDate = "";

            for (var i = 0; i <= strDate.length - 1; i++) {
                rtnDate = rtnDate + strDate[i];
            }

            return rtnDate
        }

        //#region InquiryData - 검색 조건에 해당하는 데이터를 조회한다.
        function InquiryData() {
            var fromdate = $('#dtDateRange').daterangebox('GetFromDate');
            var todate = $('#dtDateRange').daterangebox('GetToDate');
             
            var items = {};
            items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1);
            items.SHOPID = XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1); 
             
            //다중LOTID. 
            var options = { opt1: '<%=HttpContext.Current.Session["multiProdGr"]%>', opt2: 'Y'};
            var deferred = CallCheckMultiLine($('#txtLotID'), options);

            deferred.done(function (strLots, arrLots) {
                if (strLots != '') {
                    var spt = strLots.split(',');
                    if (spt.length == 1) {
                        items.LOTID = strLots.replace("'", "").replace("'", ""); 
                    }
                    else {
                        items.LOTID_LIST = strLots; 
                    }
                } else {                     
                    items.MTRLID = $('#txtProductCode').textbox('getValue');               //제품코드
                    items.TXNSTAT = $('#cbo_ProcessingState').combobox('getValue');
                }                                                                                                                                        

                items.DATE_FROM = fromdate;
                items.DATE_TO = todate;

                var param = {};
                var code = $('#cbo_SearchType').combobox('getValue');

                if (code == "EAI200") {
                    param.bizID = "DA_PRD_SEL_ERP_IF_WIPCLOSE";
                }
                else {
                    param.bizID = "DA_PRD_SEL_ERP_IF_MOVESTOCK";
                }

                param.items = items; 

                var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

                UCRealGrid.CallRequest(url, param);
            }); 
        }
        //#endregion  

        //#region onButtonClick - 버튼 클릭 이벤트 후 처리
        function onButtonClick(id) {
            /// <summary>버튼 클릭 이벤트 후 처리</summary>  
            /// <param name="id" type="string">버튼 ID</param> 
            try {
                switch (id) {
                    case "btnSearch":
                        if (!Validate("SEARCH")) return;
                        InquiryData();
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

        // #region ExcelExport - 그리드 데이터를 엑셀 파일로 출력한다.
        function ExcelExport() {
            /// <summary>그리드 데이터를 엑셀 파일로 출력한다</summary>       
            var fNameToday = "ErpInterfaceInfo_" + new Date().format("yyyyMMdd_hhmmss") + "_export.xlsx";
            UCRealGrid.ExcelExport(fNameToday, true);
        }
        // #endregion
         
        // #region Validate - 함수 실행 전 유효성 체크
        function Validate(type) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            var result = true;

            switch (type) {
                case "SEARCH":
                    if ($('#cbo_SearchType').combobox('getValue') == "")
                    {
                        xAlert(msgSearchTypeRequired);
                        return;
                    }
                    break;
                case "EXCEL":
                    if (UCRealGrid.GetRowCount() == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }
                    ExcelExport();
                    break;
                default:
            }

            return result;
        }
        // #endregion

        var bInit = true;
        function InitGrid(code) {
            /// <summary>RealGrid를 초기화한다.</summary>  
            UCRealGrid.ColumnsClear();
 
            if (code === "EAI200") { 
     
                 
                if (bInit){
                    UCRealGrid.Init("<%=ViewState["MENU_ID"].ToString()%>", vRealgridFields, vRealgridColumns_200, true, false, true);
                    bInit = false;
                }
                else {
                    UCRealGrid.InitControl(vRealgridFields, vRealgridColumns_200, false, true, true);
                }

                var menuLabels = [
                    "<%=lang.word["Product Lot Info"]%>"
                    , "<%=lang.word["Input Lot Info"]%>"
                    , "<%=lang.word["Defect Information"]%>"
                    , "<%=lang.word["Use Information"]%>"
                    , "<%=lang.word["SURVEY HISTORY."]%>"
                    , "<%=lang.word["Quality Information"]%>"
                    , "<%=lang.word["Remark Info"]%>"
                    , "<%=lang.word["Process Report Print"]%>"];

                SetCommonContextMenu3(UCRealGrid, menuLabels, "LOTID");
                 
                UCRealGrid_gridView.onLinkableCellClicked = function (grid, index, url) {
                    if (index.fieldName == "LOTID") {
                        var currentRow = UCRealGrid.GetCurrent();
                        SetCommonContextMenu3_Fixed(UCRealGrid, null, index, index.fieldName, currentRow, menuLabels);
                    }
                };

            } else {
               
                if (bInit) {
                    UCRealGrid.Init("<%=ViewState["MENU_ID"].ToString()%>", vRealgridFields, vRealgridColumns_100, true, false, true);
                    bInit = false;
                }
                else {
                    UCRealGrid.InitControl(vRealgridFields, vRealgridColumns_100, false, true, true);
                }
                 
                var menuLabels = [
                    "<%=lang.word["Product Lot Info"]%>"
                    , "<%=lang.word["Input Lot Info"]%>"
                    , "<%=lang.word["Defect Information"]%>"
                    , "<%=lang.word["Quality Information"]%>"
                    , "<%=lang.word["Remark Info"]%>"
                    , "<%=lang.word["Process Report Print"]%>"];

                SetCommonContextMenu(UCRealGrid, menuLabels, "FR_CHARG_30");
            }             
        }
        
        function UCRealGrid_LoadDataCompleted(rtn) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            $("#totalConunt").html("<%=lang.word["Search results"]%> ( Total <span class='red01'>" + UCRealGrid.GetRowCount() + "</span> Found )");
            if (UCRealGrid.GetRowCount() == 0) {
                xAlert(msgNotFoundList);
            }             
        }
        
        //== Realgrid Column & Filed Info ==============================
        var vRealgridFields =
            [
                //EAI100 재고이전전기
                  { fieldName: "RET_COD"}
                , { fieldName: "EAI_CREATEDTTM", dataType: "datetime" }
                , { fieldName: "FR_CHARG_30" }
                , { fieldName: "ZGUBUN" }
                , { fieldName: "MTRLID" }
                , { fieldName: "MTRLNAME" }
                , { fieldName: "MENGE", dataType: "number" }
                , { fieldName: "FR_WERKS" }
                , { fieldName: "FR_LGORT" }
                , { fieldName: "SLOCNAME_FROM" }
                , { fieldName: "TO_MATNR" }
                , { fieldName: "TO_WERKS" }
                , { fieldName: "SLOCNAME_TO" }
                , { fieldName: "RET_MSG" }
                //-------------------------

                //EAI200 ERP재고마감이력  
                , { fieldName: "ERP_TXNERRDESC" }
                , { fieldName: "EAI_CREATEDTTM", dataType: "datetime" }
                , { fieldName: "LOTID" }
                , { fieldName: "ADJST" }
                , { fieldName: "WIPQTY_ERPIN", dataType: "number" }
                , { fieldName: "MENGE", dataType: "number" }
                , { fieldName: "WO_ID" } 
                , { fieldName: "MTRLID" }
                , { fieldName: "BUDAT" } 
                //------------------------- 
            ];
        
        var vRealgridColumns_100 =
        [ 
            {
                name: "RET_COD" // 전송결과
                , fieldName: "RET_COD"
                , header: { text: "<%=lang.word["Transfer Result"]%>" }
                , styles: { textAlignment: "center" }
                , editable: false 
                , width: 70
            }, 
            {
                name: "EAI_CREATEDTTM" // 데이터 생성 일시
                , fieldName: "EAI_CREATEDTTM"
                , header: { text: "<%=lang.word["ERP Result Date"]%>" } 
                , styles: { textAlignment: "center", datetimeFormat: getLocaleDateFormat('<%=SSUser.LangID%>') + " HH:mm:ss" }
                , editable: false
                , width: 150
            },
            {
                name: "FR_CHARG_30" //LOT (From)
                , fieldName: "FR_CHARG_30"
                , header: { text: "<%=lang.word["LOTID"]%>" }
                , styles: { textAlignment: "center" }
                , editable: false
                , width: 150
            },
            {
                name: "ZGUBUN" // 이동구분
                , fieldName: "ZGUBUN"
                , header: { text: "<%=lang.word["Classification Code"]%>" }
                , styles: { textAlignment: "center" }
                , editable: false
                , width: 100
            },
            {
              "type": "group",
              "name": "<%=lang.word["From"]%>",
              "width": 760,
              "columns": [
                    {
                        name: "MTRLID" // 제품코드
                        , fieldName: "MTRLID"
                        , header: { text: "<%=lang.word["Product Code"]%>" }
                        , styles: { textAlignment: "center" }                    
                        , editable: false
                        , width: 130
                    },
                    {
                        name: "MTRLNAME" // 제품명
                        , fieldName: "MTRLNAME"
                        , header: { text: "<%=lang.word["Product Name"]%>" }
                        , styles: { textAlignment: "near" }
                        , editable: false
                        , width: 200
                    },
                    {
                        name: "MENGE" // 이전 수량
                        , fieldName: "MENGE"
                        , header: { text: "<%=lang.word["Prev. Qty."]%>" }
                        , styles: { textAlignment: "far", numberFormat: "#,##0" }
                        , editable: false
                        , width: 80
                    },
                    {
                            name: "FR_WERKS" // 플랜트 (From)
                        , fieldName: "FR_WERKS"
                        , header: { text: "<%=lang.word["SHOPID"]%>" }
                        , styles: { textAlignment: "center" }
                        , editable: false
                        , width: 100
                    },
                    {
                        name: "FR_LGORT" // 저장위치 (From)
                        , fieldName: "FR_LGORT"
                        , header: { text: "<%=lang.word["Sloc. ID"]%>" }
                        , styles: { textAlignment: "center" }
                        , editable: false
                        , width: 100
                    },
                    {
                        name: "SLOCNAME_FROM" // 저장위치 명 (From)
                        , fieldName: "SLOCNAME_FROM"
                        , header: { text: "<%=lang.word["Sloc. Name"]%>" }
                        , styles: { textAlignment: "near" }
                        , editable: false
                        , width: 150
                    }
                        ]
            },
            {
              "type": "group",
              "name": "<%=lang.word["To"]%>",
              "width": 760,
              "columns": [
                           {
                               name: "TO_MATNR" // 플랜트 (To)
                               , fieldName: "TO_MATNR"
                               , header: { text: "<%=lang.word["Product Code"]%>" }
                               , styles: { textAlignment: "center" }
                               , editable: false
                               , width: 130
                           },
                           {
                               name: "TO_WERKS" // 저장위치 (To)
                               , fieldName: "TO_WERKS"
                               , header: { text: "<%=lang.word["SHOPID"]%>" }
                               , styles: { textAlignment: "center" }
                               , editable: false
                               , width: 100
                           },
                           {
                               name: "TO_LGORT" // 저장위치 (To)
                               , fieldName: "TO_LGORT"
                               , header: { text: "<%=lang.word["Sloc. ID"]%>" }
                               , styles: { textAlignment: "center" }
                               , editable: false
                               , width: 100
                           },
                           {
                               name: "SLOCNAME_TO" // 저장위치 명 (To)
                               , fieldName: "SLOCNAME_TO"
                               , header: { text: "<%=lang.word["Sloc. Name"]%>" }
                               , styles: { textAlignment: "near" }
                               , editable: false
                               , width: 150
                           }
                         ]
            },
            {
                name: "RET_MSG" // 메세지
                , fieldName: "RET_MSG"
                , header: { text: "<%=lang.word["Message"]%>" }
                , styles: { textAlignment: "near" }
                , editable: false
                , width: 180
            }
        ];
        //============================================================== 
        
        var vRealgridColumns_200 =
        [ 
            {
                name: "ERP_TXNERRDESC" // 전송결과
                , fieldName: "ERP_TXNERRDESC"
                , header: { text: "<%=lang.word["Transfer Result"]%>" }
                , styles: { textAlignment: "center" }
                , editable: false 
                , width: 70
            }, 
            {
                name: "EAI_CREATEDTTM" // ERP처리일시
                , fieldName: "EAI_CREATEDTTM"
                , header: { text: "<%=lang.word["ERP Result Date"]%>" } 
                , styles: { textAlignment: "center", datetimeFormat: getLocaleDateFormat('<%=SSUser.LangID%>') + " HH:mm:ss" }
                , editable: false
                , width: 150
            },
            {
                name: "LOTID" //LOT  
                , fieldName: "LOTID"
                , header: { text: "<%=lang.word["LOTID"]%>" }
                , styles: { textAlignment: "center" }
                , editable: false
                , width: 150
            },
            {
                name: "ADJST" // 이동구분
                , fieldName: "ADJST"
                , header: { text: "<%=lang.word["Classification Code"]%>" }
                , styles: { textAlignment: "center" }
                , editable: false
                , width: 100
            },
            {
                name: "WIPQTY_ERPIN" // 전산수량
                , fieldName: "WIPQTY_ERPIN"
                , header: { text: "<%=lang.word["Computer Quantity"]%>" }
                , styles: { textAlignment: "far", numberFormat: "#,##0" }
                , editable: false
                , width: 80
            },
            {
                name: "MENGE" // ERP재고수량
                , fieldName: "MENGE"
                , header: { text: "ERP<%=lang.word["Stock Qty"]%>" }
                , styles: { textAlignment: "far", numberFormat: "#,##0" }
                , editable: false
                , width: 80
            },
            {
                name: "WO_ID" // 작업지시번호
                , fieldName: "WO_ID"
                , header: { text: "<%=lang.word["W/O"]%>" }
                , styles: { textAlignment: "near" }
                , editable: false
                , width: 150
            },
            {
                name: "MTRLID" // 제품코드
                , fieldName: "MTRLID"
                , header: { text: "<%=lang.word["Product Code"]%>" }
                , styles: { textAlignment: "center" }                    
                , editable: false
                , width: 130
            },
            {
                name: "MTRLNAME" // 제품명
                , fieldName: "MTRLNAME"
                , header: { text: "<%=lang.word["Product Name"]%>" }
                , styles: { textAlignment: "near" }
                , editable: false
                , width: 200
            },
            {
                name: "BUDAT" // 전기일자
                , fieldName: "BUDAT"
                , header: { text: "<%=lang.word["STODOCDATE"]%>" }
                , styles: { textAlignment: "center" }                    
                , editable: false
                , width: 70
            }
        ];
        //============================================================== 
    </script>
</asp:Content>

<asp:Content ID="UIContent" ContentPlaceHolderID="bodyHolder" runat="server">
    <form id="form1" runat="server">
        <asp:HiddenField ID="hidAccessFlag" runat="server" />
        <asp:HiddenField ID="hidMenuID" runat="server" />
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />   
        <asp:HiddenField ID="hidUserID" runat="server" />   
        <asp:ScriptManager runat="server" ID="ScriptManager1"></asp:ScriptManager>

        <!-- 검색조건 영역 시작 -->
        <div class="tableInquiry searchBox" id="divSearchPart">
            <div class="itemBox">
                <table>
                    <colgroup>
                        <col class="col_10p" />
                        <col class="col_17p" />
                        <col class="col_10p" />
                        <col class="col_15p" />
                        <col class="col_10p" />
                        <col class="col_15p" />
                        <col class="col_10p" />
                        <col />
                    </colgroup>
                    <tbody>
                        <tr>
                            <!-- 조회 구분 -->
                            <th><span class="textPink">*</span><%=lang.word["Search Type"]%></th>
                            <td>
                                <select id="cbo_SearchType" class="easyui-combobox" style="float: left; width: 100%; max-width: 200px;" />
                            </td>
                            <!-- 처리 상태 -->
                            <th><%=lang.word["Processing State"]%></th>
                            <td>
                                <select id="cbo_ProcessingState" class="easyui-combobox" style="width: 100%; max-width: 200px"/>
                            </td>
                            <!-- 조회 기간 -->
                            <th ><span class="textPink">*</span><%=lang.word["Search Period"]%></th>
                            <td>
                                <input id="dtDateRange" class="easyui-daterangebox" style="width: 100%; max-width: 200px" />
                            </td>
                            <!--LOTID-->
                            <th rowspan="2"><%=lang.word["LOTID"]%></th>
                            <td rowspan="2"><input id="txtLotID" class="easyui-textbox" style="width: 100%; max-width: 200px; height: 100%; max-height: 80px;" data-options="multiple:true, multiline:true"  /></td>    
                       </tr>
                        <tr>
                            <!--제품 코드-->
                            <th><%=lang.word["Product Code"]%></th>
                            <td><input id="txtProductCode" class="easyui-textbox" style="width: 100%; max-width: 200px;"/></td>  
                            <th></th>    
                            <td></td>
                            <th></th>    
                            <td></td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <div class="tableBtnSearch">
                <button type="button" id="btnSearch" onclick="onButtonClick(this.id)"><span><%=lang.word["Search"]%></span></button> 
            </div>
            <uc:SearchToggleContent ID="SearchToggleContent2" runat="server" />
        </div>
        <!-- 검색조건 영역 끝 -->

        <!--  CRUD Button Area start -->
        <div class="buttonArea" id="tbContents">
            <div id="totalConunt" class="floatLeft01"><%=lang.word["Search results"]%> ( Total <span class="red01">0</span> Found )</div>
            <ul id="ulButton" runat="server" class="btn_crud">
                <li><a class="excel" id="btnExcel" onclick="onButtonClick(this.id)"></a></li>
            </ul>
        </div>
        <!-- CRUD Button Area end -->

        <!-- Contents 시작  -->
        <div id="dvContents_Mid" class="table">
            <uc:Realgrid ID="UCRealGrid" CALLID="UCRealGrid" HEIGHT="660" runat="server"  LAYOUTSAVING="Y" />
        </div>
        <!-- Contents 종료 -->        
        <input type="hidden" id="hidReference" />
        <input type="hidden" id="hidSelectedValue" />
        <input type="hidden" id="hidPartNoValue" />
        <input type="hidden" id="hidProdNameValue" />
        <input type="hidden" id="hidProdIdValue" />
    </form>
</asp:Content>