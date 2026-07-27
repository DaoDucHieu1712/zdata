<%--/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMS_0926.aspx
* @desc    : [재고실사] 재고실사 ERP반영
*            전송플래그(ERP_IFFLAG): Y(전송완료), N(배부완료,전송취소), P(전송중), C(취소중), E(ERP처리ERROR,전송대기,배부완료)
************************************************************************************************* 
* VER         DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0     2022/03/14       이병래           INIT
* 1.1     2022/09/07       이병윤           ERP 전송 처리중 로딩처리 숨김
* 1.2     2023/02/21       전찬혁           C20230223-000041 구미 양극재 PJT 요청 다국어 적용 
*************************************************************************************************
*/--%>

<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMS_0926.aspx.cs" Inherits="GMES_IMS_0926" %>

<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>

<%-- Fucntion --%>
<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">

    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js"></script>
    <script type="text/javascript">        
        //#region== Page Init.       ==============================
        $(document).ready(function () {
            InitData();
        });

        function InitData() {
            InitGrid();
            SetStorage();
            SetMonth();

            $('#divErpUpload').css("display", "none");
            var vMonth = $('#dtMonth').val() + '-01';
            var now = new Date(vMonth);
            var firstDayOfMonth = new Date(now.getFullYear(), now.getMonth()+1, 1);
            var lastMonth = new Date(firstDayOfMonth.setDate(firstDayOfMonth.getDate() - 1));
            var vDay = $.fn.datebox.defaults.formatter(lastMonth);
            $('#dtPostDate').datebox('setValue', vDay);
        }

        let timerId; //timer session ID

        function onButtonClick(id) {
            /// <summary>버튼 클릭 이벤트 후 처리</summary>  
            try {
                switch (id) {
                    case "btnSearch":
                        if (!Validate("SEARCH")) return;
                        fnSearch();
                        break;
                    case "btnSend":
                        if (!Validate("SEND")) return;
                        var vMsg = '<%=lang.word["STODOCDATE"]%>' + '[' + $('#dtPostDate').val() + '] ';//2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
                        xConfirm(vMsg + '<%=lang.message["20148"]%>', function (ok) { if (ok) { fnSend(); } });   //전기일 yyyy-mm-dd으로 전송하시겠습니까
                        break;
                    case "btnSendCancel":
                        if (!Validate("CANCEL")) return;
                        xConfirm('<%=lang.message["25051"]%>', function (ok) { if (ok) { fnSendCancel(); } });   //전송취소하시겠습니까?
                        break;
                    case "btnDelete":
                        if (!Validate("DELETE")) return;
                        xConfirm('<%=lang.message["20010"]%>', function (ok) { if (ok) { fnSendDelete(); } });   //삭제하시겠습니까
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
        //#endregion==============================================================

        //#region== Message & Word ============================================
        // 조회내역이 존재하지 않습니다.
        var msgNotFoundList = "<%=lang.message["20051"]%>";
        //처리 되었습니다. 
        var msgProcessComplete = "<%=lang.message["20006"]%>";
        //ERP 저장위치가 없습니다. 
        var msgNotSlocID = "<%=lang.message["25164"]%>";
        //전송가능flag선언
        var blnSendFlag = true;
        //#endregion==============================================================

        //#region== Realgrid Column & Filed Info ==============================        
        function InitGrid() {
            /// <summary>그리드설정</summary>
            RealGrid1.Init("<%=ViewState["MENU_ID"].ToString()%>", vMasterRealgridFields, vMasterRealgridColumns, false, false, true);
            RealGrid1_gridView.setOptions({
                  fitStyle: "even"
                , indicator: { visible: true }
                , checkBar: { visible: false, showAll: false }
                , stateBar: { visible: false }
                , footer: { visible: false }
                , edit: { insertable: false, appendable: false, updatable: false, editable: false, readOnly: true }
                , softDeleting: false
                , deleteCreated: false
                , hideDeletedRows: false
            });

            var vFilters = ["POSTDATE", "MTRLID", "MTRLNAME", "SLOCID", "ERPWOID", "MOVETYPE", "QTY", "UNIT", "BTCHNAME", "MTRLID_PR", "ERPPCSGID", "SPCLSTCK", "PRODORDNO", "SONO", "ERPTRNFDTTM", "ERP_IFFLAG", "ERP_IFFLAG_NAME", "ERP_MSG", "BELNR"];
            RealGrid1.SetColsFilter(vFilters);
            //RealGrid1.SetFixedColumn(2);

            RealGrid1_gridView.addCellStyle("ingCellStyle", {
                "background": "#F1B0BD"
            }, true);

            RealGrid1_gridView.addCellStyle("endCellStyle", {
                "background": "#93CC8D"
            }, true);

            RealGrid1_gridView.addCellStyle("errCellStyle", {
                "background": "#FE9A2E"
            }, true);
        }

        var vMasterRealgridFields =
            [  
                { fieldName: "SHOPID" },
                { fieldName: "SHOPNAME" },
                { fieldName: "POSTDATE", dataType: "datetime" },
                { fieldName: "MTRLID" },
                { fieldName: "MTRLNAME" },
                { fieldName: "SLOCID" },
                { fieldName: "SLOCNM" },
                { fieldName: "ERPWOID" },
                { fieldName: "MOVETYPE" },
                { fieldName: "QTY", dataType: "number" },
                { fieldName: "UNIT" },
                { fieldName: "BTCHNAME" },
                { fieldName: "MTRLID_PR" },
                { fieldName: "ERPPCSGID" },
                { fieldName: "SPCLSTCK" },
                { fieldName: "PRODORDNO" },
                { fieldName: "SONO" },
                { fieldName: "ERPTRNFDTTM" },
                { fieldName: "ERP_IFFLAG" },
                { fieldName: "ERP_IFFLAG_NAME" },
                { fieldName: "ERP_MSG" },
                { fieldName: "BELNR" },
                { fieldName: "INSUSER" },
                { fieldName: "INSDTTM" },
                { fieldName: "REQUEST_ID" },
                { fieldName: "POSTDT" },
                { fieldName: "USGQTY", dataType: "number" },
                { fieldName: "GVOTRT", dataType: "number" },
                { fieldName: "ACUMQTY", dataType: "number" },
                { fieldName: "DIFQTY", dataType: "number" },
                { fieldName: "CHKFLAG" },
                { fieldName: "CHKMSG" }
            ];

        var vMasterRealgridColumns = [
             { name: "POSTDATE", fieldName: "POSTDATE", header: { text: "<%=lang.word["STODOCDATE"]%>" }, visible: false, width: 100, styles: { textAlignment: "center", datetimeFormat: "yyyy-MM-dd" }, editable: false, readOnly: true }
            ,{ name: "YYYYMM", fieldName: "POSTDATE", header: { text: "<%=lang.word["Closing Stock"]%>"+" "+"<%=lang.word["Year and Month"]%>" }, width: 100, styles: { textAlignment: "center", datetimeFormat: "yyyy-MM" }, editable: false, readOnly: true }
            ,{ name: "SHOPID", fieldName: "SHOPID", header: { text: "Plant" }, readOnly: true, visible: true, styles: { textAlignment: "center" }, width: 80 }
            ,{ name: "SHOPNAME", fieldName: "SHOPNAME", header: { text: "<%=lang.word["Plant"]%>" }, visible: false, width: 130, styles: { textAlignment: "center" }, editable: false, readOnly: true }
            ,{ name: "SLOCID", fieldName: "SLOCID", header: { text: "<%=lang.word["Storage Location"]%>" }, visible: false, width: 80, styles: { textAlignment: "center" }, editable: false, readOnly: true }
            ,{ name: "SLOCNM", fieldName: "SLOCNM", header: { text: "<%=lang.word["Storage Location"]%>" }, width: 130, styles: { textAlignment: "near" }, editable: false, readOnly: true }
            , { name: "MTRLID_PR", fieldName: "MTRLID_PR", header: { text: "<%=lang.word["Parent Material"]%>"+"<%=lang.word["Code"]%>" }, width: 90, styles: { textAlignment: "center" }, editable: false, readOnly: true, visible: false }//모자재 코드 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            , { name: "ERPPCSGID", fieldName: "ERPPCSGID", header: { text: "<%=lang.word["Workcenter"]%>" }, width: 90, styles: { textAlignment: "center" }, editable: false, readOnly: true, visible: false }//작업장 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            , { name: "SPCLSTCK", fieldName: "SPCLSTCK", header: { text: "<%=lang.word["Special Stock"]%>" }, width: 80, styles: { textAlignment: "center" }, editable: false, readOnly: true, visible: false }//특별재고 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            ,{ name: "MOVETYPE", fieldName: "MOVETYPE", header: { text: "<%=lang.word["Movement Division"]%>" }, width: 80, styles: { textAlignment: "center" }, editable: false, readOnly: true }
            ,{ name: "MTRLID", fieldName: "MTRLID", header: { text: "<%=lang.word["Material Code."]%>" }, width: 120, styles: { textAlignment: "near" }, editable: false, readOnly: true }
            ,{ name: "MTRLNAME", fieldName: "MTRLNAME", header: { text: "<%=lang.word["Material Name"]%>" }, width: 240, styles: { textAlignment: "near" }, editable: false, readOnly: true }
            ,{ name: "ERPWOID", fieldName: "ERPWOID", header: { text: "<%=lang.word["Workorder Id"]%>" }, width: 120, styles: { textAlignment: "center" }, editable: false, readOnly: true }
            , { name: "SONO", fieldName: "SONO", header: { text: "<%=lang.word["Sales"]%>" + "Order" }, width: 80, styles: { textAlignment: "center" }, editable: false, readOnly: true, visible: false }//판매Order 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            ,{ name: "QTY", fieldName: "QTY", header: { text: "<%=lang.word["Qty."]%>" }, width: 100, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, editable: false, readOnly: true }
            ,{ name: "UNIT", fieldName: "UNIT", header: { text: "<%=lang.word["Unit"]%>" }, width: 50, styles: { textAlignment: "center" }, editable: false, readOnly: true, }
            ,{ name: "BTCHNAME", fieldName: "BTCHNAME", header: { text: "<%=lang.word["Batch Name"]%>" }, width: 100, styles: { textAlignment: "center" }, editable: false, readOnly: true }
            ,{ name: "CHKFLAG", fieldName: "CHKFLAG", header: { text: "<%=lang.word["INSP_GB"]%>" }, visible: true, readOnly: true, visible: true, styles: { textAlignment: "center" }, width: 60 }
            ,{ name: "ERP_IFFLAG", fieldName: "ERP_IFFLAG", visible: true, header: { text: "ERP <%=lang.word["TRANSDTTM"]%>" }, width: 60, editable: false, readOnly: true, styles: { textAlignment: "center" }, visible: false }
            , { name: "ERP_IFFLAG_NAME", fieldName: "ERP_IFFLAG_NAME", visible: true, header: { text: "<%=lang.word["Reflect ERP"]%>" + "<%=lang.word["State"]%>" }, width: 120, editable: false, readOnly: true, styles: { textAlignment: "center" } }//ERP 반영상태 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            , { name: "ERPTRNFDTTM", fieldName: "ERPTRNFDTTM", visible: true, header: { text: "<%=lang.word["ERP Send"]%>" + "<%=lang.word["Date Time"]%>" }, width: 150, editable: false, readOnly: true, styles: { textAlignment: "center" } }//ERP 전송일시 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            ,{ name: "POSTDT", fieldName: "POSTDT", header: { text: "<%=lang.word["Posting Date"]%>" }, readOnly: true, visible: true, styles: { textAlignment: "center"}, width: 100 }

            ,{ name: "BELNR", fieldName: "BELNR", visible: true, header: { text: "<%=lang.word["MAT_DOC_NO "]%>" }, width: 100, editable: false, readOnly: true, styles: { textAlignment: "center" } }
            , { name: "ERP_MSG", visible: true, fieldName: "ERP_MSG", header: { text: "<%=lang.word["ERP Transfer Result"]%>" + "<%=lang.word["Message"]%>" }, width: 200, editable: false, readOnly: true, styles: { textAlignment: "near" }, renderer: { showTooltip: true } }//ERP 처리결과 메시지 -> ERP 전송결과 메세지 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            ,{ name: "REQUEST_ID", visible: true, fieldName: "REQUEST_ID", header: { text: "<%=lang.word["REQUEST ID"]%>" }, width: 150, editable: false, readOnly: true, styles: { textAlignment: "center" }, visible: false }
            ,{ name: "USGQTY", fieldName: "USGQTY", header: { text: "<%=lang.word["Usage"]%>" }, visible: false, editable: true, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 70 }
            ,{ name: "GVOTRT", fieldName: "GVOTRT", header: { text: "<%=lang.word["Distribution Rate (%)"]%>" }, visible: false, editable: true, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 70 }
            ,{ name: "ACUMQTY", fieldName: "ACUMQTY", header: { text: "<%=lang.word["Cum. Usage Qty"]%>" }, visible: false, editable: true, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 70 }          
            ,{ name: "DIFQTY", fieldName: "DIFQTY", header: { text: "<%=lang.word["Difference Qty."]%>" }, visible: false, editable: true, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 70 }            
            , { name: "CHKMSG", fieldName: "CHKMSG", header: { text: "<%=lang.word["Message"]%>" }, visible: false, readOnly: true, styles: { textAlignment: "near" }, width: 150 }//메시지 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
        ];


        //#endregion==============================================================


        //#region== Button Event ==============================
        function Validate(type) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            var result = true;
            RealGrid1_gridView.commit();
            switch (type) {
                case "SEARCH":
                    if ($('#cboStockLocation').combobox('getValue') == '') {     
                        xAlert(msgNotSlocID);
                        return;
                    };
                    break;
                case "SEND":
                    if (RealGrid1.GetRowCount() == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }

                    if (!blnSendFlag)
                    {
                        xAlert("<%=lang.message["38121"]%>");           //배부값에 문제가 있으므로 전송 할 수 없습니다
                        return;
                    }

                    //var vMonth = $('#dtMonth').val() + '-01';
                    var curRows = RealGrid1_gridView.getDataSource().getJsonRow(0);
                    var vMonth = $.fn.datebox.defaults.formatter(curRows.POSTDATE).substring(0,7) + '-01';
                    var now = new Date(vMonth);
                    var firstDayOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
                    var lastMonth = new Date(firstDayOfMonth.setDate(firstDayOfMonth.getDate() - 1));
                    var vDay = $.fn.datebox.defaults.formatter(lastMonth);

                    var day = new Date();
                    var today = $.fn.datebox.defaults.formatter(day);

                    var vFdate = vMonth.replace(/-/gi, '');
                    var vTdate = vDay.replace(/-/gi, '');
                    var vSdate = $('#dtPostDate').datebox('GetDateString').replace(/-/gi, '');
                    var vNdate = today.replace(/-/gi, '');

                    if (vFdate > vSdate || vTdate < vSdate)
                    {
                        xAlert("<%=lang.message["38116"]%>");       //전기일이 설정한 월을 벗어났습니다.
                        return;
                    }

                    if (vSdate > vNdate) {
                        xAlert("<%=lang.message["38117"]%>");       //오늘 이후로 설정할 수 없습니다
                        return;
                    }

                    break;
                case "CANCEL":
                case "DELETE":
                    if (RealGrid1.GetRowCount() == 0) {
                        xAlert(msgNotFoundList);
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

        function fnSearch() {
            /// <summary>기본조회</summary>
            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.STCKCNTMNTH = $('#dtMonth').val().replace(/-/gi,'');
            items.SLOCID = $('#cboStockLocation').combobox('getValue');

            if ($('input[name="rdoErpIFFlag"]:checked').val() != 'A')
            {
                items.ERP_IFFLAG = $('input[name="rdoErpIFFlag"]:checked').val();
            }            

            var param = {};
            param.bizID = "DA_PRD_SEL_ERP_STOCK_GAP_DISB";
            param.items = items;
            param.inTableNames = 'INDATA'; 
            param.outTableNames = 'OUTDATA';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";
            RealGrid1.CallRequest(url, param);
            RealGrid1.Refresh();                   
            
        };


        function RealGrid1_LoadDataCompleted(rtn) {
            $("#totalConunt").html("<%=lang.word["Search results"]%> ( Total <span class='red01'>" + RealGrid1.GetRowCount() + "</span> Found )");
            if (RealGrid1.GetRowCount() == 0) {
                xAlert(msgNotFoundList);
            }

            var arIdxIng = [];
            var arIdxEnd = [];
            var arIdxErr = [];
            var curRows;
            blnSendFlag = true;

            for (var intX = 0; intX < RealGrid1.GetRowCount() ; intX++) {
                curRows = RealGrid1_gridView.getDataSource().getJsonRow(intX);

                if (curRows.ERP_IFFLAG == "P" || curRows.ERP_IFFLAG == "C") {
                    arIdxIng.push(intX);
                }
                else if (curRows.ERP_IFFLAG == "Y") {
                    arIdxEnd.push(intX);
                }

                //배부점검결과
                if (curRows.CHKFLAG == "E") {
                    arIdxErr.push(intX);
                    blnSendFlag = false;
                }
            }
            RealGrid1_gridView.setCellStyles(arIdxIng, ["ERP_IFFLAG_NAME"], "ingCellStyle", true);
            RealGrid1_gridView.setCellStyles(arIdxEnd, ["ERP_IFFLAG_NAME"], "endCellStyle", true);
            RealGrid1_gridView.setCellStyles(arIdxErr, ["CHKFLAG"], "errCellStyle", true);

            fnCheckSendStat();
        }


        function fnSend() {
            /// <summary>ERP전송</summary>
            var items = [];
            var param = {};
            var url;
            var subHeader = [];
            var subBody = [];
            var curRows;
            //var idx = 0;

            RealGrid1_gridView.commit();
            curRows = RealGrid1_gridView.getDataSource().getJsonRow(0);

            subHeader[0] = [
                  { name: "REQUEST_ID", value: '', dataType: _DataType.String }
                , { name: "WERKS", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                , { name: "BUDAT", value: $('#dtPostDate').datebox('GetDateString').replace(/-/gi, ''), dataType: _DataType.String }
                , { name: "MODE", value: 'A', dataType: _DataType.String }
                , { name: "SEND_TYPE", value: 'P', dataType: _DataType.String }
                , { name: "USERID", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
                , { name: "POSTDATE", value: $.fn.datebox.defaults.formatter(curRows.POSTDATE).replace(/-/gi, ''), dataType: _DataType.String }
            ];

            for (var intX = 0; intX < RealGrid1.GetRowCount() ; intX++) {

                curRows = RealGrid1_gridView.getDataSource().getJsonRow(intX);
                subBody[intX] = [
                      { name: "MATNR", value: curRows.MTRLID, dataType: _DataType.String }
                    , { name: "AUFNR", value: curRows.ERPWOID, dataType: _DataType.String }
                    , { name: "BWART", value: curRows.MOVETYPE, dataType: _DataType.String }
                    , { name: "ERFMG", value: (eval(curRows.QTY) < 0) ? (-1 * curRows.QTY).toFixed(3) : curRows.QTY.toFixed(3), dataType: _DataType.Decimal }
                    , { name: "ERFME", value: curRows.UNIT, dataType: _DataType.String }
                    , { name: "LGORT", value: curRows.SLOCID, dataType: _DataType.String }
                    , { name: "CHARG", value: curRows.BTCHNAME, dataType: _DataType.String }
                    , { name: "SOBKZ", value: '', dataType: _DataType.String }
                    , { name: "KDAUF", value: '', dataType: _DataType.String }
                    , { name: "KDPOS", value: '', dataType: _DataType.String }
                ];
            }
            items[0] = subHeader;
            items[1] = subBody;

            url = "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";
            param.bizID = "BR_PRD_SND_DISB_DIFF_PP0547_SO";
            param.items = items;
            param.inTableNames = "IN_HEAD,IN_BODY";
            param.outTableNames = "OUTDATA";

            ShowLoading();

            sendRequestMethod(function () {
                if (data != null) {
                    if (data[0].RETURN != "OK") {
                        xAlert(data[0].MESSAGE);
                    }
                    else {
                        xAlert(msgProcessComplete);
                        fnSearch();
                    };
                };

                CloseLoading();
            }, param, "POST", url);
        }
        
        function fnSendCancel() {
            /// <summary>전송취소</summary>
            var items = [];
            var param = {};
            var url;
            var subHeader = [];
            var subBody = [];
            var curRows;
            var intZ = 0;
            
            RealGrid1_gridView.commit();
            curRows = RealGrid1_gridView.getDataSource().getJsonRow(0);

            subHeader[0] = [
                  { name: "REQUEST_ID", value: '', dataType: _DataType.String }
                , { name: "WERKS", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                //, { name: "BUDAT", value: curRows.POSTDT.replace(/-/gi, ''), dataType: _DataType.String }
                , { name: "BUDAT", value: $.fn.datebox.defaults.formatter(curRows.POSTDATE).replace(/-/gi, ''), dataType: _DataType.String } //2022.09.02 이상인 취소시 전기일 라인의 값으로 변경
                , { name: "MODE", value: 'A', dataType: _DataType.String }
                , { name: "SEND_TYPE", value: 'C', dataType: _DataType.String }
                , { name: "USERID", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
                , { name: "POSTDATE", value: $.fn.datebox.defaults.formatter(curRows.POSTDATE).replace(/-/gi, ''), dataType: _DataType.String }
            ];

            for (var intX = 0; intX < RealGrid1.GetRowCount() ; intX++) {

                curRows = RealGrid1_gridView.getDataSource().getJsonRow(intX);
                
                if (curRows.BELNR != '') {
                    subBody[intZ] = [
                          { name: "MATNR", value: curRows.MTRLID, dataType: _DataType.String }
                        , { name: "AUFNR", value: curRows.ERPWOID, dataType: _DataType.String }
                        , { name: "BWART", value: curRows.MOVETYPE == '995' ? '996' : '995', dataType: _DataType.String }
                        , { name: "ERFMG", value: (eval(curRows.QTY) < 0) ? (-1 * curRows.QTY).toFixed(3) : curRows.QTY.toFixed(3), dataType: _DataType.Decimal }
                        , { name: "ERFME", value: curRows.UNIT, dataType: _DataType.String }
                        , { name: "LGORT", value: curRows.SLOCID, dataType: _DataType.String }
                        , { name: "CHARG", value: curRows.BTCHNAME, dataType: _DataType.String }
                        , { name: "SOBKZ", value: '', dataType: _DataType.String }
                        , { name: "KDAUF", value: '', dataType: _DataType.String }
                        , { name: "KDPOS", value: '', dataType: _DataType.String }
                    ];
                    intZ = intZ + 1;
                }
            }
            items[0] = subHeader;
            items[1] = subBody;

            url = "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";
            param.bizID = "BR_PRD_SND_DISB_DIFF_PP0547_SO";
            param.items = items;
            param.inTableNames = "IN_HEAD,IN_BODY";
            param.outTableNames = "OUTDATA";

            ShowLoading();

            sendRequestMethod(function () {
                if (data != null) {
                    if (data[0].RETURN != "OK") {
                        xAlert(data[0].MESSAGE);
                    }
                    else {
                        xAlert(msgProcessComplete);
                        fnSearch();
                    };
                };

                CloseLoading();
            }, param, "POST", url);
        }


        function fnSendDelete() {
            var items = [];
            var param = {};
            var url;
            var subHeader = [];
            var subBody = [];
            var curRows;
            var intZ = 0;

            RealGrid1_gridView.commit();
            curRows = RealGrid1_gridView.getDataSource().getJsonRow(0);

            subHeader[0] = [
                  { name: "REQUEST_ID", value: '', dataType: _DataType.String }
                , { name: "WERKS", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                , { name: "BUDAT", value: $.fn.datebox.defaults.formatter(curRows.POSTDATE).replace(/-/gi, ''), dataType: _DataType.String }
                , { name: "MODE", value: 'A', dataType: _DataType.String }
                , { name: "SEND_TYPE", value: 'D', dataType: _DataType.String }
                , { name: "USERID", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
            ];

            for (var intX = 0; intX < RealGrid1.GetRowCount() ; intX++) {

                curRows = RealGrid1_gridView.getDataSource().getJsonRow(intX);

                if (1==1) {
                    subBody[intZ] = [
                          { name: "MATNR", value: curRows.MTRLID, dataType: _DataType.String }
                        , { name: "AUFNR", value: curRows.ERPWOID, dataType: _DataType.String }
                        , { name: "LGORT", value: curRows.SLOCID, dataType: _DataType.String }
                        , { name: "CHARG", value: curRows.BTCHNAME, dataType: _DataType.String }
                    ];
                    intZ = intZ + 1;
                }
            }
            items[0] = subHeader;
            items[1] = subBody;

            url = "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";
            param.bizID = "BR_PRD_UPD_DISB_SENDFLAG";
            param.items = items;
            param.inTableNames = "IN_HEAD,IN_BODY";
            param.outTableNames = "OUTDATA";

            ShowLoading();

            sendRequestMethod(function () {
                if (data != null) {
                    if (data[0].RETURN != "OK") {
                        xAlert(data[0].MESSAGE);
                    }
                    else {
                        xAlert(msgProcessComplete);
                        fnSearch();
                    };
                };

                CloseLoading();
            }, param, "POST", url);
        }

        function fnSendReturn() {
            var items = [];
            var subHeader = [];
            var param = {};
            var url;

            subHeader[0] = [
                { name: "USERID", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
            ];
            items[0] = subHeader;
            url = "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";
            param.bizID = "BR_PRD_RETURN_RSLT_PP0547";
            param.items = items;
            param.inTableNames = "";
            param.outTableNames = "OUTDATA";
            sendRequestMethod(function () {1==1;}, param, "POST", url);
        }

        function fnExcel(obj) {
            var vToday = "STOCK_ERP_SEND_" + new Date().format("yyyyMMddhhmmss") + ".xlsx";
            RealGrid1.ExcelExport(vToday);
        };

        function fnCheckSendStat() {
            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.STCKCNTMNTH = $('#dtMonth').val().replace(/-/gi, '');
            items.SLOCID = $('#cboStockLocation').combobox('getValue');

            var param = {};
            param.bizID = "DA_PRD_SEL_CHK_SEND_STAT";
            param.items = items;
            param.inTableNames = 'RQSTDT';
            param.outTableNames = 'RSLTDT';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            sendRequestMethod(function (targetID, data, message, status) {
                fnRCheckSendStat(data, 0, status, message);
            }, param, "POST", url);
        }

        function fnRCheckSendStat(data, index, status, message) {
            var vStat = '';
            if (status == "FAIL") {
                if (message.split(":")[1] == null) {
                    xAlert(message);
                } else {
                    xAlert(message.split(":")[1]);
                }
                return;
            }
            else if (status == "OK") {
                data.forEach(function (value, index, array) {
                    vStat = value.SEND_STAT;
                });
                SetButton(vStat);
                // v1.1_로딩div 숨김처리
                //SetErpUp(vStat);

                //전송값 반복처리
                if (IsCheckErpSendState()) {
                    clearInterval(timerId);
                }
                else {
                    // v1.1_조회후 1번만 실행변경_fnLoopRun()주석처리 
                    //fnLoopRun();    //반복실행
                    fnSendReturn(); //현재상태값 조회
                }
            }
        }

        function fnLoopRun() {
            clearInterval(timerId);
            if (!IsCheckErpSendState()) {
                timerId = setInterval(fnSearch, 10000); //30초간격 조회실행
            }
        }

        function IsCheckErpSendState() {
            if (RealGrid1.GetRowCount() == 0)
            {
                return true;
            }

            for (var intX=0; intX < RealGrid1.GetRowCount() ; intX++) {
                var curRows = RealGrid1_gridView.getDataSource().getJsonRow(intX);
                if (curRows.ERP_IFFLAG == 'P' || curRows.ERP_IFFLAG == 'C')
                {
                    return false;
                }
            }
            return true;
        }
        //#endregion==============================================================


        //#region== Set Control ==============================
        function SetStorage() {
            /// <summary></summary>
            $('#cboStockLocation').combobox({
                 //url: '../common/xml/CallBizJson.aspx?sp_name=CUS_SEL_STOCKLOCATION_AREAID_CBO&SHOPID=' + $("[id$=hidShopID]").val() + '&LANGID=' + $("[id$=hidLangID]").val() + '&CBOOPT=OPT|SLOCID|SLOCNAME'
                 url: '../common/xml/CallBizJson.aspx?sp_name=CUS_SEL_STORAGELOCATION_RANGE_CBO&LANGID=' + $("[id$=hidLangID]").val() + '&SHOPID=' + $("[id$=hidShopID]").val() + '&USEFLAG=Y&CBOOPT=OPT|SLOCID|SLOCNAME'
                ,valueField: 'SLOCID'
                ,textField: 'SLOCNAME'
                ,onLoadSuccess: function () {
                    var items = $(this).combobox("getData");
                    if (items.length > 0) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                    //fnCheckSendStat();
                }
            });
        }

        function SetMonth() {
            var toDay = new Date();
            var now = new Date(toDay);
            var firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
            var lastMonth = new Date(firstDayOfMonth.setDate(firstDayOfMonth.getDate() - 1));
            var year = lastMonth.getFullYear();
            var month = lastMonth.getMonth() + 1;
            var vMon = year + '-' + (month < 10 ? "0" : "") + month + '-01';
            var dtMon = new Date(vMon);
            $('#dtMonth').datemonthbox('SetDate', dtMon);
        }

        function SetButton(id) {
            try {
                switch (id) {
                    case "BEGIN":  //전송대기
                        SetButtonEnable('#btnSend', true);
                        SetButtonEnable('#btnSendCancel', false);
                        SetButtonEnable('#btnDelete', false);
                        break;
                    case "ING":    //전송중
                        SetButtonEnable('#btnSend', false);
                        SetButtonEnable('#btnSendCancel', false);
                        SetButtonEnable('#btnDelete', false);
                        break;
                    case "SEND":   //전송완료
                        SetButtonEnable('#btnSend', false);
                        SetButtonEnable('#btnSendCancel', true);
                        SetButtonEnable('#btnDelete', true);
                        break;
                    case "ERR":    //전송 미처리
                        SetButtonEnable('#btnSend', false);
                        SetButtonEnable('#btnSendCancel', false);
                        SetButtonEnable('#btnDelete', true);
                        break;
                    case "DEL":
                    case "CLOSE":  //삭제, 전송마감(전송불가)
                        SetButtonEnable('#btnSend', false);
                        SetButtonEnable('#btnSendCancel', false);
                        SetButtonEnable('#btnDelete', false);
                        break;
                    default:
                }
            } catch (e) {
                xAlert(e.message);
            }
        }

        function SetErpUp(id) {
            try {
                switch (id) {
                    case "ING":
                        // v1.1_로딩바숨김처리
                        //$('#divErpUpload').show();
                        $('#divErpUpload').css("display", "none");
                        break;
                    default:
                        $('#divErpUpload').css("display", "none");   
                }
            } catch (e) {
                xAlert(e.message);
            }
        }

        //#endregion==============================================================

    </script>

    <script>
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
        //#endregion==============================================================
    </script>
    <style type="text/css">
        @keyframes blink-effect {
            50% {
                opacity: 0;
            }
        }
        .blink {
            animation: blink-effect 1s step-end infinite;
            color: #3d4045;            
        }
    </style>

</asp:Content>


<%-- View --%>
<asp:Content ID="UIContent" ContentPlaceHolderID="bodyHolder" runat="server">

    <form id="form1" runat="server">
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:ScriptManager runat="server" ID="ScriptManager1"></asp:ScriptManager>
        
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
                    </colgroup>
                    <tbody>
                        <tr>     
                            <!--년월--> 
                            <th><span class="textPink">*</span><%=lang.word["Closing Stock"]%> <%=lang.word["Year and Month"]%></th>
                            <td><input id="dtMonth" class="easyui-datemonthbox" style="width: 100px;" /></td>
                            <!--저장위치-->
                            <th><span class="textPink">*</span><%=lang.word["Storage"]%></th>
                            <td>
                                <div style="float: left">
                                    <select id="cboStockLocation" class="easyui-combobox" style="width: 200px"></select>
                                </div>
                            </td>  
                            <!--erp전기여부-->                           
                            <th><%=lang.word["ERP Posting Status"]%></th>
                            <td style="width: 250px; " >
                               <label>
                                  <input type="radio" id="rdoAll" name="rdoErpIFFlag" value="A" checked="checked"/><%=lang.word["ALL"]%>
                               </label>
                               <label>
                                  <input type="radio" id="rdoSend" name="rdoErpIFFlag" value="Y"/><%=lang.word["Send"]%><!--전송 -->
                               </label>
                               <label>
                                  <input type="radio" id="rdoWait" name="rdoErpIFFlag" value="N"/>미<%=lang.word["Send"]%><!--미전송 -->
                               </label>
                            </td> 
                        </tr>                       

                    </tbody>
                </table>
            </div>
            <div class="tableBtnSearch">
                <button type="button" id="btnSearch" onclick="onButtonClick(this.id)"><span><%=lang.word["Search"]%></span></button>
            </div>
            <uc:SearchToggleContent ID="SearchToggleContent2" runat="server" />
        </div>
        <div id="divMasterContent">
            <div class="buttonArea" id="divMidButton">
                <div id="totalConunt" class="floatLeft01"><%=lang.word["Search results"]%> ( Total <span class='red01'>0</span> Found )</div>
                <ul id="ulBttomButton" runat="server" class="btn_crud">
                    <li><a class="red"  id ="btnSend" onclick="onButtonClick(this.id)"><span><%=lang.word["ERP Send"]%></span></a></li>                                  <!--ERP전송 -->
                    <li><a class="red"  id ="btnSendCancel" onclick="onButtonClick(this.id)"><span><%=lang.word["ERP Send"]%><%=lang.word["Cancel"]%></span></a></li>    <!--ERP전송 취소 -->
                    <li><a class="red"  id ="btnDelete" onclick="onButtonClick(this.id)"><span><%=lang.word["Delete"]%></span></a></li>           <!--삭제 -->
                    <li><a class="excel" onclick="fnExcel(this)" ></a></li>
                </ul>
                <!-- v1.1_로딩div display:none;추가  -->
                <div style="display:none;text-align:center; color:red" id="divErpUpload">
                   <p class="blink"><span class="textPink"><%=lang.word["ERP Send"]%><%=lang.word["Processing"]%>...</span> &nbsp&nbsp&nbsp<img src="../images/loading32x32.gif"></p><!-- ERP 전송 처리중 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용 -->
                </div>

                <div style="float:Right;"><%=lang.word["STODOCDATE"]%> <!-- 전기일 -->
                   <input id="dtPostDate" class="easyui-datebox" style="width: 120px;" />&nbsp;&nbsp;
                </div>

            </div>
            
            <div id="divMasterGrid" class="table">
                <uc:Realgrid ID="RealGrid1" CALLID="RealGrid1" runat="server" HEIGHT="200" LAYOUTSAVING="Y" />
            </div>
        </div>
    </form>
</asp:Content>


