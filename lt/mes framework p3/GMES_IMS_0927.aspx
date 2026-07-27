<%--/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMS_0927.aspx
* @desc    : 무상사급차후조정
************************************************************************************************* 
* VER         DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0     2022/04/25       이병래           INIT
* 1.1     2023/02/21       전찬혁           C20230223-000041 구미 양극재 PJT 요청 다국어 적용
*************************************************************************************************
*/--%>

<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMS_0927.aspx.cs" Inherits="GMES_IMS_0927" %>

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
        })

        function InitData() {
            InitGrid();
            SetMultiHeight();  //Grid Height 조절
            SetRangeDate();    //Set Date Range
        }

        function onButtonClick(id) {
            try {
                switch (id) {
                    case "btnSearch":
                        if (!Validate("SEARCH")) return;
                        fnSearch();
                        break;
                    case "btnAdjust":
                        if (!Validate("ADJUST")) return;
                        xConfirm('<%=lang.message["38114"]%>', function (ok) { if (ok) { fnAdjust(); } });   //차후조정 하시겠습니까?
                        break;
                    case "btnExcel1":
                        if (!Validate("EXCEL1")) return;
                        fnExcel1();
                        break;
                    case "btnExcel2":
                        if (!Validate("EXCEL2")) return;
                        fnExcel2();
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
        //#endregion==============================================================


        //#region== Realgrid Column & Filed Info ==============================        
        function InitGrid() {
            RealGrid1.Init("<%=ViewState["MENU_ID"].ToString()%>", vMasterGridFields, vMasterGridColumns, true, false, true);
            RealGrid1_gridView.setOptions({
                fitStyle: "even"
                , indicator: { visible:  true}
                , checkBar: { visible: false, showAll: false }
                , stateBar: { visible: false }
                , footer: { visible: false }
                , edit: { insertable: false, appendable: false, updatable: false, editable: false, readOnly: true }
                , softDeleting: false
                , deleteCreated: false
                , hideDeletedRows: false
            });

            RealGrid2.Init("<%=ViewState["MENU_ID"].ToString()%>", vSubGridFields, vSubGridColumns, true, false, true);
            RealGrid2_gridView.setCheckBar({
                visible: true
            });

            RealGrid2_gridView.addCellStyle("editCellStyle", {
                "editable": true,
                "background": "#ffffff33" 
            }, true);

            RealGrid2_gridView.onCellEdited = function (grid, itemIndex, dataRow, field) {
                var vQty = RealGrid2_gridView.getValue(itemIndex, "UPDQTY");
                if (vQty != null && vQty != '' && vQty != 'undefined') {
                    RealGrid2_gridView.checkItem(itemIndex, true);
                }
                else {
                    RealGrid2_gridView.checkItem(itemIndex, false);
                }
            };

            RealGrid2_gridView.onEditRowPasted = function (grid, itemIndex, dataRow, fields, oldValues, newValues) {
                var vQty = RealGrid2_gridView.getValue(itemIndex, "UPDQTY");
                if (vQty != null && vQty != '' && vQty != 'undefined') {
                    RealGrid2_gridView.checkItem(itemIndex, true);
                }
                else {
                    RealGrid2_gridView.checkItem(itemIndex, false);
                }
            };

            var vValues = [];
            var vTexts = [];
            vValues = ["543", "544"];
            vTexts = ["[543]과다소비","[544]미달소비"];

            var column = RealGrid2_gridView.columnByField("MOVETYPE");
            column.editor = { type: "dropDown", dropDownCount: 2 };
            column.values = vValues;
            column.labels = vTexts;
            RealGrid2_gridView.setColumn(column);
            
            var vFilters = ["POSTDATE", "SUPPLIERID", "SUPPLIERNM", "PO", "POITEM", "MTRLID", "MTRLNM", "UNIT", "QTY", "SLOCID", "BTCHNO", "STMTNO", "POSTYEAR", "IPGODATE"];
            RealGrid1.SetColsFilter(vFilters);
            //RealGrid1.SetFixedColumn(2);

            RealGrid2_gridView.setColumnProperty("UPDQTY", "dynamicStyles", function (grid, index, value) {
                var ret = {};
                ret.editor = {
                    type: "number",
                    positiveOnly: true
                };
                return ret;
            });
        }

        var vMasterGridFields =
            [  
                  { fieldName: "POSTDATE" }  //전기일
                , { fieldName: "SHOPID" }    //플랜트
                , { fieldName: "SUPPLIERID" }  //공급사
                , { fieldName: "SUPPLIERNM" }  //공급사명
                , { fieldName: "PO" }      //PO번호
                , { fieldName: "POITEM" }  //PO품목
                , { fieldName: "MTRLID" }  //자재
                , { fieldName: "MTRLNM" }  //자재명
                , { fieldName: "UNIT" }    //단위
                , { fieldName: "QTY", dataType: "number" }  //수량
                , { fieldName: "SLOCID" }  //저장위치
                , { fieldName: "SLOCNM" }  //저장위치명
                , { fieldName: "BTCHNO" }  //배치번호
                , { fieldName: "STMTNO" }  //전표번호
                , { fieldName: "POSTYEAR" }  //전기년도
                , { fieldName: "IPGODATE" }  //입고일   
                , { fieldName: "MOVETYPE" }  //이동유형
            ];

        var vMasterGridColumns = [
                 { name: "POSTDATE",  fieldName: "POSTDATE", header: { text: "<%=lang.word["Posting Date"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                ,{ name: "SHOPID",  fieldName: "SHOPID", header: { text: "Plant" }, editable: false, readOnly: true, visible: false, width: 80, styles: { textAlignment: "center" } }
                ,{ name: "SUPPLIERID",  fieldName: "SUPPLIERID", header: { text: "<%=lang.word["Supplier Company"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                ,{ name: "SUPPLIERNM",  fieldName: "SUPPLIERNM", header: { text: "<%=lang.word["SUP_NM"]%>" }, editable: false, readOnly: true, visible: true, width: 180, styles: { textAlignment: "near" } }
                ,{ name: "PO", fieldName: "PO", header: { text: "PO <%=lang.word["No."]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                ,{ name: "POITEM",  fieldName: "POITEM", header: { text: "PO <%=lang.word["Item"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
                ,{ name: "MTRLID",  fieldName: "MTRLID", header: { text: "<%=lang.word["Material Code."]%>" }, editable: false, readOnly: true, visible: true, width: 120, styles: { textAlignment: "near" } }
                ,{ name: "MTRLNM",  fieldName: "MTRLNM", header: { text: "<%=lang.word["Material Name"]%>" }, editable: false, readOnly: true, visible: true, width: 250, styles: { textAlignment: "near" } }
                ,{ name: "UNIT",  fieldName: "UNIT", header: { text: "<%=lang.word["Unit"]%>" }, editable: false, readOnly: true, visible: true, width: 60, styles: { textAlignment: "center" } }
                ,{ name: "QTY", fieldName: "QTY", header: { text: "<%=lang.word["Qty."]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "far", numberFormat: "##,##0.##;.;,;f" } }
                ,{ name: "MOVETYPE", fieldName: "MOVETYPE", header: { text: "<%=lang.word["Movement Division"]%>" }, editable: false, readOnly: true, visible: true, width: 80, styles: { textAlignment: "center" } }
                ,{ name: "SLOCID", fieldName: "SLOCID", header: { text: "<%=lang.word["Storage"]%>" }, editable: false, readOnly: true, visible: false, width: 80, styles: { textAlignment: "near" } }
                ,{ name: "SLOCNM",  fieldName: "SLOCNM", header: { text: "<%=lang.word["Storage Location"]%>" }, editable: false, readOnly: true, visible: true, width: 150, styles: { textAlignment: "near" } }
                ,{ name: "BTCHNO",  fieldName: "BTCHNO", header: { text: "<%=lang.word["Batch No."]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "near" } }
                ,{ name: "STMTNO",  fieldName: "STMTNO", header: { text: "<%=lang.word["MAT_DOC_NO"]%>" }, editable: false, readOnly: true, visible: true, width: 120, styles: { textAlignment: "center" } }
                ,{ name: "POSTYEAR",  fieldName: "POSTYEAR", header: { text: "<%=lang.word["PSN_YY"]%>" }, editable: false, readOnly: true, visible: true, width: 80, styles: { textAlignment: "center" } }
                ,{ name: "IPGODATE",  fieldName: "IPGODATE", header: { text: "<%=lang.word["TO_DT"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "center" } }
        ];

        var vSubGridFields = [
                  { fieldName: "SEQ" }       //시퀀스
                , { fieldName: "MTRLID" }    //자재
                , { fieldName: "MTRLNM" }    //자재명
                , { fieldName: "UNIT" }      //단위
                , { fieldName: "OUTQTY", dataType: "number" }  //출고수량
                , { fieldName: "SLOCID" }    //저장위치
                , { fieldName: "MOVETYPE" }  //이동유형
                , { fieldName: "UPDQTY", dataType: "number" }  //보정수량
                , { fieldName: "MBLNR" }     //전표번호
                , { fieldName: "ERPFLAG" }   //ERP처리결과
                , { fieldName: "ERPMSG" }    //ERP처리메시지
                , { fieldName: "PO" }        //PO
                , { fieldName: "POITEM" }    //PO품목
                , { fieldName: "POSTYEAR" }  //참조 회계연도
                , { fieldName: "STMTNO" }    //참조 전표번호
                , { fieldName: "SHOPID" }    //플랜트
                , { fieldName: "BTCHNO" }    //배치
                , { fieldName: "REGUSER" }   //ERP등록자
        ];

        var vSubGridColumns = [
                 { name: "SEQ", fieldName: "SEQ", header: { text: "<%=lang.word["SEQ"]%>" }, editable: false, readOnly: true, visible: false, width: 100, styles: { textAlignment: "near" } }//시퀀스 -> 순서 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
                ,{ name: "MTRLID",  fieldName: "MTRLID", header: { text: "<%=lang.word["Material Code."]%>" }, editable: false, readOnly: true, visible: true, width: 130, styles: { textAlignment: "near" } }
                ,{ name: "MTRLNM",  fieldName: "MTRLNM", header: { text: "<%=lang.word["Material Name"]%>" }, editable: false, readOnly: true, visible: true, width: 300, styles: { textAlignment: "near" } }
                ,{ name: "UNIT",  fieldName: "UNIT", header: { text: "<%=lang.word["Unit"]%>" }, editable: false, readOnly: true, visible: true, width: 60, styles: { textAlignment: "center" } }
                ,{ name: "OUTQTY", fieldName: "OUTQTY", header: { text: "<%=lang.word["Issue Count"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" } }
                ,{ name: "SLOCID",  fieldName: "SLOCID", header: { text: "<%=lang.word["Storage Location"]%>" }, editable: false, readOnly: true, visible: false, width: 80, styles: { textAlignment: "center" } }
                ,{ name: "MOVETYPE",  fieldName: "MOVETYPE", header: { text: "<%=lang.word["Movement Division"]%>" }, editable: true, readOnly: false, visible: true, width: 80, styles: { textAlignment: "center" }}
                ,{ name: "UPDQTY", fieldName: "UPDQTY", header: { text: "<%=lang.word["Correction Amount Qty"]%>" }, editable: true, readOnly: false, visible: true, width: 80, styles: { textAlignment: "far", numberFormat: "##,##0.###;.;,;f" }, editor: { type: 'number', positiveOnly: true, editFormat: "##,##0.###;.;,;f" } }
                ,{ name: "MBLNR",  fieldName: "MBLNR", header: { text: "<%=lang.word["MAT_DOC_NO"]%>" }, editable: false, readOnly: true, visible: true, width: 120, styles: { textAlignment: "near" } }
                ,{ name: "ERPFLAG",  fieldName: "ERPFLAG", header: { text: "ERP<%=lang.word["PROC_MSG"]%>" }, editable: false, readOnly: true, visible: true, width: 100, styles: { textAlignment: "near" } }
                ,{ name: "ERPMSG", fieldName: "ERPMSG", header: { text: "ERP<%=lang.word["Transfer Desc"]%>" }, editable: false, readOnly: true, visible: true, width: 400, styles: { textAlignment: "near" }, renderer: { showTooltip: true } }
                ,{ name: "PO",  fieldName: "PO", header: { text: "PO<%=lang.word["No."]%>" }, editable: false, readOnly: true, visible:false, width: 80, styles: { textAlignment: "near" } }

                ,{ name: "POITEM", fieldName: "POITEM", header: { text: "PO<%=lang.word["Item"]%>" }, editable: false, readOnly: true, visible: false, width: 80, styles: { textAlignment: "near" } }
                , { name: "POSTYEAR", fieldName: "POSTYEAR", header: { text: "<%=lang.word["SPC Reference"]%>" + "<%=lang.word["Fiscal Year"]%>" }, editable: false, readOnly: true, visible: false, width: 80, styles: { textAlignment: "near" } }//참조 회계연도 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
                , { name: "STMTNO", fieldName: "STMTNO", header: { text: "<%=lang.word["SPC Reference"]%>" + "<%=lang.word["Statement Number"]%>" }, editable: false, readOnly: true, visible: false, width: 80, styles: { textAlignment: "near" } }//참조 전표번호 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
                , { name: "SHOPID", fieldName: "SHOPID", header: { text: "<%=lang.word["SHOPID"].Replace("ID","")%>" }, editable: false, readOnly: true, visible: false, width: 80, styles: { textAlignment: "near" } }//플랜트 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
                , { name: "BTCHNO", fieldName: "BTCHNO", header: { text: "<%=lang.word["Batch No."]%>" }, editable: false, readOnly: true, visible: false, width: 80, styles: { textAlignment: "near" } }//배치 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
                , { name: "REGUSER", fieldName: "REGUSER", header: { text: "<%=lang.word["ERP"]%>" + "<%=lang.word["INS_USER"]%>" }, editable: false, readOnly: true, visible: false, width: 80, styles: { textAlignment: "near" } }//ERP 등록자 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
        ];


        function RealGrid2_LoadDataCompleted(rtn) {
            /// <summary></summary> 
            $("#subCnt").html("<%=lang.word["ITEM_CRS"]%> ( Total <span class='red01'>" + RealGrid2.GetRowCount() + "</span> Found )");
            if (RealGrid2.GetRowCount() == 0) {
                xAlert("<%=lang.message["20051"]%>");
            }

            var crRowidxArray = [];
            for (var intX = 0; intX < RealGrid2.GetRowCount() ; intX++) {
                crRowidxArray.push(intX);
            }

            RealGrid2_gridView.setCellStyles(crRowidxArray, ["UPDQTY"], "editCellStyle", true);
            RealGrid2_gridView.setCellStyles(crRowidxArray, ["MOVETYPE"], "editCellStyle", true);
        }
        
        //#endregion==============================================================


        //#region== Button Event ==============================
        function Validate(type) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            var result = true;
            RealGrid2_gridView.commit();
            switch (type) {
                case "SEARCH":
                    if ($("#txtPO").textbox("getValue").length == 0 && $("#txtPOItem").textbox("getValue").length > 0) {
                        xAlert("<%=lang.message["38115"] %>");      //PO ITEM값을 검색하려면 PO번호를 입력해야 합니다.
                        return;
                    }
                    break;
                case "ADJUST":
                    var rows = RealGrid2_gridView.getCheckedRows();
                    if (rows.length == 0) {
                        xAlert("<%=lang.message["20194"] %>");      //선택값이 없으므로 처리 할 수 없습니다.
                        return;
                    }
                    break;
                case "EXCEL1":
                    if (RealGrid1.GetRowCount() == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }
                    break;
                case "EXCEL2":
                    if (RealGrid2.GetRowCount() == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }
                    break;
                default:
            }

            return result;
        }


        function fnSearch() {
            clearSpread();              

            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.MOVETYPE = '101,102';
            items.FR_DATE = $('#dtDateRange').daterangebox('GetFromDateString');
            items.TO_DATE = $('#dtDateRange').daterangebox('GetToDateString');
            items.MTRLID = $("#txtProdId").textbox("getValue");
            items.STMTNO = $("#txtStmtNo").textbox("getValue");
            items.PO = $("#txtPO").textbox("getValue");
            items.POITEM = $("#txtPOItem").textbox("getValue");
            items.SUPPLIERID = $("#txtSupply").textbox("getValue");
                          
            var param = {};
            param.bizID = "DA_PRD_SEL_ERP_POST_RESULT";
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";
            RealGrid1.CallRequest(url, param);
            RealGrid1.Refresh();
        }

        function RealGrid1_LoadDataCompleted(rtn) {
            /// <summary></summary> 
            $("#totalCnt").html("<%=lang.word["Search results"]%> ( Total <span class='red01'>" + RealGrid1.GetRowCount() + "</span> Found )");
            if (RealGrid1.GetRowCount() == 0) {
                xAlert("<%=lang.message["20051"]%>");
            }

            $('#txtCMtrllD').textbox('setText', '');
            $('#txtCMtrlNM').textbox('setText', '');
            $('#txtCBtchNo').textbox('setText', '');
            $('#txtCMblnr').textbox('setText', '');
        }


        function RealGrid1_DblClicked() {
            var currentRow = RealGrid1_dataProvider.getJsonRow(RealGrid1_gridView.getCurrent().dataRow);
            fnDetail(currentRow);

            $("[id$=hidPoMtrlID]").val(currentRow.MTRLID);
            $("[id$=hidPoBtchName]").val(currentRow.BTCHNAME);
            $("[id$=hidPoDocNo]").val(currentRow.STMTNO);

            $('#txtCMtrllD').textbox('setText', currentRow.MTRLID);
            $('#txtCMtrlNM').textbox('setText', currentRow.MTRLNM);
            $('#txtCBtchNo').textbox('setText', currentRow.BTCHNO);
            $('#txtCMblnr').textbox('setText', currentRow.STMTNO);
        }


        function fnDetail(curRowData) {
            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.MOVETYPE = '543,544';
            items.FR_DATE = $('#dtDateRange').daterangebox('GetFromDateString');
            items.TO_DATE = $('#dtDateRange').daterangebox('GetToDateString');
            items.PO = curRowData.PO;
            items.POITEM = curRowData.POITEM;
            //items.MTRLID = curRowData.MTRLID;;
            items.STMTNO = curRowData.STMTNO;
            
            var param = {};
            param.bizID = "DA_PRD_SEL_ERP_POST_RESULT_DETAIL";
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";
            RealGrid2.CallRequest(url, param);
        }


        function fnAdjust() {
            var items = [];
            var subItems = [];
            var param = {};
            var url;
            var idx = 0;

            // 시퀀스 넣기
            var rows = RealGrid2_dataProvider.getJsonRows(0, -1)

            for (var i in rows) {
                RealGrid2_gridView.setValue(idx, "SEQ", idx);
                idx++;
            }

            RealGrid2_gridView.commit();

            inItem = [];
            inData = [];
            idx = 0;
            var rows = RealGrid2_gridView.getCheckedRows();
            var vRequstID = new Date().format("yyyyMMddhhmmss");

            inData[0] = [
                  { name: "WERKS", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                , { name: "REQUEST_ID", value: vRequstID, dataType: _DataType.String }
                , { name: "SEND_TYPE", value: "P", dataType: _DataType.String }
                , { name: "USERID", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
                , { name: "POSTDATE", value: $('#dtPostDate').datebox('GetDateString').replace(/-/gi, ''), dataType: _DataType.String }
            ];

            for (var intX = 0; intX < rows.length; intX++) {

                var curRows = RealGrid2_gridView.getDataSource().getJsonRow(rows[intX]);

                //부모 1회생성, 수량0 
                if (intX == 0) {
                    inItem[idx] = [
                      { name: "PO", value: curRows.PO, dataType: _DataType.String }
                    , { name: "POITEM", value: curRows.POITEM, dataType: _DataType.String }
                    , { name: "REF_POSTYEAR", value: curRows.POSTYEAR, dataType: _DataType.String }
                    , { name: "REF_DOCNO", value: $("[id$=hidPoDocNo]").val(), dataType: _DataType.String }
                    , { name: "MTRLID", value: $("[id$=hidPoMtrlID]").val(), dataType: _DataType.String }
                    , { name: "SLOCID", value: '', dataType: _DataType.String }
                    , { name: "BTCHNAME", value: $("[id$=hidPoBtchName]").val(), dataType: _DataType.String }
                    , { name: "ZGUBUN", value: '1', dataType: _DataType.String }
                    , { name: "QTY", value: 0, dataType: _DataType.Decimal }
                    , { name: "UNIT", value: curRows.UNIT, dataType: _DataType.String }
                    , { name: "SC_ADJUST", value: curRows.MOVETYPE == '543' ? ' ' : 'X', dataType: _DataType.String }
                    , { name: "SGTXT", value: '', dataType: _DataType.String }
                    , { name: "MOVETYPE", value: curRows.MOVETYPE, dataType: _DataType.String }
                    , { name: "OUTBOUNDQTY", value: curRows.OUTQTY, dataType: _DataType.Decimal }
                    , { name: "REGUSER", value: curRows.REGUSER, dataType: _DataType.String }
                    , { name: "SEQ", value: '999', dataType: _DataType.String }
                    , { name: "MENGE", value: '0', dataType: _DataType.String }
                    , { name: "WERKS", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                    ];
                    idx++;
                }


                inItem[idx] = [
                      { name: "PO", value: curRows.PO.replace(/-/gi, ''), dataType: _DataType.String }
                    , { name: "POITEM", value: curRows.POITEM.replace(/-/gi, ''), dataType: _DataType.String }
                    , { name: "REF_POSTYEAR", value: curRows.POSTYEAR, dataType: _DataType.String }
                    , { name: "REF_DOCNO", value: curRows.STMTNO, dataType: _DataType.String }
                    , { name: "MTRLID", value: curRows.MTRLID, dataType: _DataType.String }
                    , { name: "SLOCID", value: curRows.SLOCID, dataType: _DataType.String }
                    , { name: "BTCHNAME", value: curRows.BTCHNO, dataType: _DataType.String }
                    , { name: "ZGUBUN", value: '2', dataType: _DataType.String }
                    , { name: "QTY", value: curRows.UPDQTY < 0 ? curRows.UPDQTY * -1 : curRows.UPDQTY, dataType: _DataType.Decimal }
                    , { name: "UNIT", value: curRows.UNIT, dataType: _DataType.String }
                    , { name: "SC_ADJUST", value: curRows.MOVETYPE == '543' ? ' ' : 'X', dataType: _DataType.String }
                    , { name: "SGTXT", value: '', dataType: _DataType.String }
                    , { name: "MOVETYPE", value: curRows.MOVETYPE, dataType: _DataType.String }
                    , { name: "OUTBOUNDQTY", value: curRows.OUTQTY, dataType: _DataType.Decimal }
                    , { name: "REGUSER", value: curRows.REGUSER, dataType: _DataType.String }
                    , { name: "SEQ", value: curRows.SEQ, dataType: _DataType.String }
                    , { name: "MENGE", value: curRows.UPDQTY, dataType: _DataType.String }
                    , { name: "WERKS", value: $("[id$=hidShopID]").val(), dataType: _DataType.String }
                ];
                idx++;
            }


            items[0] = inData;
            items[1] = inItem;
            url = "/GMES_POM/GMES_IMS_0927.aspx/GetDataSet";

            param.bizID = "BR_PRD_SND_SUPPLY_ADJUST_MM0476_SO";
            param.items = items;
            param.inTableNames = "IN_HEAD,IN_BODY";
            param.outTableNames = "OUT_INFO,RSLT_ITEM";

            ShowLoading();

            sendRequestMethod(function () {
                CloseLoading();

                if (data != null) {
                    if (data[0].OUT_INFO[0].RSLT_FLAG != "OK") {  
                        xAlert("<%=lang.message["20126"]%>");     // 20126 : 처리되지 않았습니다.
                    }
                    else {

                        for (var intX = 0; intX < data[0].RSLT_ITEM.length; intX++) {
                            var item = data[0].RSLT_ITEM[intX];
                            var rows = RealGrid2_dataProvider.getJsonRows(0, -1)

                            for (var intY = 0; intY < rows.length; intY++) {

                                if (item.SEQ == rows[intY].SEQ) {
                                    RealGrid2_gridView.setValue(intY, "MBLNR", item.E_MBLNR);
                                    RealGrid2_gridView.setValue(intY, "ERPFLAG", item.E_RETN_FLAG);
                                    RealGrid2_gridView.setValue(intY, "ERPMSG", item.E_MESSAGE);
                                }
                            }
                        }

                    }
                }
                else {
                    xAlert("<%=lang.message["20126"]%>"); // 20126 : 처리되지 않았습니다.
                }
            }, param, "POST", url);
        }
        
        function fnExcel1() {
            var vToday = "MTRL_DOC_NO_" + new Date().format("yyyyMMddhhmmss") + ".xlsx";
            RealGrid1.ExcelExport(vToday);
        }

        function fnExcel2() {
            var vToday = "ITEM_LIST_" + new Date().format("yyyyMMddhhmmss") + ".xlsx";
            RealGrid2.ExcelExport(vToday);
        }

        function clearSpread() {
            if (RealGrid2_dataProvider != null) {
                if (RealGrid2.GetRowCount() > 0) {
                    RealGrid2_dataProvider.clearRows();
                    $("#subTitle").html(" <%=lang.word["Registered Rows"]%>( Total <span class='textPink'>" + RealGrid2.GetRowCount() + "</span> Found )");
                }
            }
        }
        //#endregion==============================================================


        //#region== Set Control ==============================        

        function ShowProductCodePopup(value) {
            ShowPopup("../GMES_COM/GMES_COM_0003.aspx?DVALUE=RAW&MTRLFLAG=" + "ES122" + "&SHOPID=" + $("[id$=hidShopID]").val() + "&MENU_ID=<%=ViewState["MENU_ID"].ToString()%>&PROD_SEARCH=" + value, 790, 500, "<%=lang.word["Inquiry Product"]%>", SetProductName);
        };

        function SetProductName(data) {
            if (data == undefined) return;
            if (data.length != 3) return;
            $("#txtProdId").textbox("setValue", data[2]);
            $("#txtProdName").textbox("setValue", data[1]);
        };

        // 전기일자 세팅
        function SetRangeDate() {
            var toDay = new Date();
            var fromDayVal = new Date(toDay.getFullYear(), toDay.getMonth(), 1);
            var toDayVal = new Date(toDay.getFullYear(), toDay.getMonth(), toDay.getDate());
            $('#dtDateRange').daterangebox('SetFromDate', fromDayVal);
            $('#dtDateRange').daterangebox('SetToDate', toDayVal);


            var vDay = $.fn.datebox.defaults.formatter(new Date());
            var now = new Date(vDay);
            var firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
            var lastMonth = new Date(firstDayOfMonth.setDate(firstDayOfMonth.getDate() - 1));
            var vDay = $.fn.datebox.defaults.formatter(lastMonth);
            $('#dtPostDate').datebox('setValue', vDay);
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

        function SetMultiHeight() {
            var uc1 = document.getElementById("RealGrid1");
            var uc2 = document.getElementById("RealGrid2");

            $('#divLayout').layout('panel', 'center').panel({
                onResize: function (width, height) {
                    uc1.style.width = width - 5;
                    uc1.style.height = height - 15;
                    RealGrid1.ResetSize();
                }
            });

            $('#divLayout').layout('panel', 'south').panel({
                onResize: function (width, height) {
                    uc2.style.width = width - 5;
                    uc2.style.height = height - 230;
                    RealGrid2.ResetSize();
                }
            });
        };

        //#endregion==============================================================


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
    </script>

</asp:Content>


<%-- View --%>
<asp:Content ID="UIContent" ContentPlaceHolderID="bodyHolder" runat="server">

    <form id="form1" runat="server">
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />

        <asp:HiddenField ID="hidPoMtrlID" runat="server" />
        <asp:HiddenField ID="hidPoBtchName" runat="server" />
        <asp:HiddenField ID="hidPoDocNo" runat="server" />

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
                            <!--입고일자--> 
                            <th id="lblDate"><%=lang.word["STODOCDATE"]%></th>
                            <td><input id="dtDateRange" class="easyui-daterangebox" style="width: 50%; min-width: 70px; resize: horizontal; " /></td>
                            <!--자재문서번호-->
                            <th><span class="textPink"></span><%=lang.word["MAT_DOC_NO"]%></th>
                            <td><input id="txtStmtNo" class="easyui-textbox" style="width: 200px"/></td>
                            <!--자재코드-->
                            <th><%=lang.word["Material Code."]%></th>
                            <td>
                                <div style="width: 100%; ">
                                    <div style="float: left; width: 38%; ">
                                        <input id="txtProdId" class="easyui-searchbox" style="width: 100%; " data-options="searcher:ShowProductCodePopup, inputEvents: $.extend({}, $.fn.searchbox.defaults.inputEvents, { keyup: function(e){ $('#txtProdName').textbox('setText', ''); } })" />
                                    </div>
                                    <div style="float: left; width: 60%; padding-left: 5px; ">
                                        <input id="txtProdName" class="easyui-textbox" style="width: 100%; " disabled="disabled"/>
                                    </div>
                                </div>
                            </td>
                        </tr>

                        <tr>
                            <!--PO번호-->
                            <th><span class="textPink"></span>PO<%=lang.word["No."]%></th>
                            <td><input id="txtPO" class="easyui-textbox" style="width: 185px"/></td>
                            <!--PO품목-->
                            <th><span class="textPink"></span>PO<%=lang.word["Item"]%></th>
                            <td><input id="txtPOItem" class="easyui-numberbox" style="width: 200px"/></td>                             
                            <!--공급업체-->
                            <th><span class="textPink"></span><%=lang.word["Supplier Company"]%>ID</th>
                            <td><input id="txtSupply" class="easyui-textbox" style="width: 200px"/></td>
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
                <div id="totalCnt" class="floatLeft01"><%=lang.word["Search results"]%> ( Total <span class='red01'>0</span> Found )</div>
                <ul id="ulBttomButton" runat="server" class="btn_crud">                    
                    <li><a class="excel" id="btnExcel1" onclick="onButtonClick(this.id)"></a></li>
                </ul>
            </div>   
                       

            <div id="divMasterGrid" class="table" > 
                <div id="divLayout" class="easyui-layout" style="width:100%;height:100%;">
                    <div id="divGrid" data-options="region:'center',border:false">
                        <uc:Realgrid ID="RealGrid1" CALLID="RealGrid1" LAYOUTSAVING="Y" runat="server" />
                    </div>
                    <div id="divGrid2" data-options="region:'south', title:'', split:true, border:false">
                        <div class="buttonArea" id="divBotButton">
                            <div id="subCnt" class="floatLeft01"><%=lang.word["ITEM_CRS"]%>( Total <span class='red01'>0</span> Found ) </div> <!-- 품목현황 -->
                            <ul id="ul1" runat="server" class="btn_crud">
                                <li><a class="red"  id ="btnAdjust" onclick="onButtonClick(this.id)"><span><%=lang.word["AFT_ADJ"]%></span></a></li>  <!-- 차후조정 -->              
                                <li><a class="excel" id="btnExcel2" onclick="onButtonClick(this.id)"></a></li>
                            </ul>
                            <div style="float:left;">&nbsp;&nbsp;&nbsp;&nbsp;
                                <%=lang.word["Material Code."]%>: <input id="txtCMtrllD" class="easyui-textbox" style="width: 120px; " disabled="disabled"/>
                                &nbsp;&nbsp;<%=lang.word["Material Name"]%>: <input id="txtCMtrlNM" class="easyui-textbox" style="width: 250px; " disabled="disabled"/>
                                &nbsp;&nbsp;<%=lang.word["Batch No."]%>: <input id="txtCBtchNo" class="easyui-textbox" style="width: 100px; " disabled="disabled"/>     <!-- 배치번호 -->
                                &nbsp;&nbsp;<%=lang.word["MAT_DOC_NO"]%>: <input id="txtCMblnr" class="easyui-textbox" style="width: 120px; " disabled="disabled"/>   <!-- 자재문서번호 -->                    
                            </div>
                            <div style="float:Right;"><%=lang.word["STODOCDATE"]%> <!-- 전기일 -->
                                <input id="dtPostDate" class="easyui-datebox" style="width: 120px;" />
                                &nbsp;&nbsp;
                            </div>
                        </div>
                        <div>
                            <uc:Realgrid ID="RealGrid2" CALLID="RealGrid2" HEIGHT="500" LAYOUTSAVING="Y" runat="server" /> 
                        </div>
                    </div>
                </div> 
            </div>

        </div>

    </form>
</asp:Content>


