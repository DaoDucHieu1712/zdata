<%--/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMS_0924.aspx
* @desc    : [재고실사] 재고실사 실사 입력
************************************************************************************************* 
* VER         DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0     2022/03/14       이병래           INIT
* 1.1     2022/08/23       이병윤           엑셀 업로드 버튼 DISABLE 처리
* 1.2     2022/09/19       이병윤           AVAINVQTY컬럼추가
* 1.3     2023/02/21       전찬혁           C20230223-000041 구미 양극재 PJT 요청 다국어 적용
*************************************************************************************************
*/--%>

<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMS_0924.aspx.cs" Inherits="GMES_IMS_0924" %>

<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>

<%-- Fucntion --%>
<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js"></script>
    <script type="text/javascript">        
        //== Page Init.  Main ==============================
        $(document).ready(function () {
            InitData();
        });     
        
        function InitData() {
            InitGrid();
            SetStorage();
            SetMonth();                        
            SetButtonEnable('#btnAddRow', false);

            var now = new Date();
            var vDay = $.fn.datebox.defaults.formatter(now);            
            $('#dtPostDate').datebox('setValue', vDay); 
            $('#spPostDate').css("visibility", "hidden");  
            $("#uploadFile").change(ExcelImport);

            //$('#btnUploadExcel').css("visibility", "hidden");
            /* 2022-08-23, 엑셀 업로드 버튼 DISABLE 처리 */
            SetButtonEnable('#btnUploadExcel', false)
        };

        function onButtonClick(id) {
            /// <summary>버튼클릭 이벤트 처리</summary>  
            try {
                switch (id) {
                    case "btnSearch":
                        if (!Validate("SEARCH")) return;
                        fnSearch();
                        break;
                    case "btnSave":       //임시저장
                        if (!Validate("SAVE")) return;  
                        xConfirm(msgSave, function (ok) { if (ok) { fnRunCheck(''); } });
                        break;
                    case "btnConfirm":   //확정
                        if (!Validate("SAVE")) return;
                        xConfirm(msgCSave, function (ok) { if (ok) { fnRunCheck('Y'); } });
                        break;
                    case "btnConfirmCancel":  //확정취소
                        if (!Validate("CANCEL")) return;
                        xConfirm(msgCCancel, function (ok) { if (ok) { fnRunCheck('N'); } });
                        break;
                    case "btnAddRow":         //행추가
                        if (!Validate("ADDROW")) return;
                        AddRow();
                        break;
                    case "btnUploadExcel":    //엑셀업로드
                        if (!Validate("UPLOAD")) return;
                        $("#uploadFile").click();
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
        //==============================================================
        
        //== Message & Word ============================================

        // 전체
        var vAllText = "<%=lang.word["All"]%>";
        // 조회내역이 존재하지 않습니다.
        var msgNotFoundList = "<%=lang.message["20051"]%>";
        //처리 되었습니다. 
        var msgProcessComplete = "<%=lang.message["20006"]%>";
        //저장 하시겠습니까?
        var msgSave = '<%=lang.message["10073"]%>';
        //확정 하시겠습니까?
        var msgCSave = '<%=lang.message["25054"]%>';
        //ERP 저장위치가 없습니다. 
        var msgNotSlocID = "<%=lang.message["25164"]%>"; 
        //확정취소하면 입력한 정보가 초기화됩니다. 확정취소하시겠습니까?
        var msgCCancel = "<%=lang.message["45002"]%>"; //"확정취소하면 입력한 정보가 초기화됩니다. 확정취소 하시겠습니까?" 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용

        //==============================================================


        //== Realgrid Column & Field Info ============================== 
        function InitGrid() {
            RealGrid1.Init("<%=ViewState["MENU_ID"].ToString()%>", vMasterRealgridFields, vMasterRealgridColumns, true, false, true);
            RealGrid1_gridView.setCheckBar({
                visible: false
            });

            RealGrid1_gridView.addCellStyle("editCellStyle", {
                "editable": true,
                "background": "#ffffff33"
            }, true);

            RealGrid1_gridView.addCellStyle("lockCellStyle", {
                "editable": false,
                "background": "#ffffffff"
            }, true);

            // v1.2_투입실적이 없을경우 색상표시 
            RealGrid1_gridView.addCellStyle("zeroCellStyle", {
                "background": "#F1B0BD"
            }, true);


            //editing event
            RealGrid1_gridView.onCellEdited = function (grid, itemIndex, dataRow, field) {
                var vErpQty = RealGrid1_gridView.getValue(itemIndex, "STOCKQTY_ERP");
                var vMesQty = RealGrid1_gridView.getValue(itemIndex, "RELSTCKQTY");
                var gap;

                vErpQty = (vErpQty == null ? 0 : vErpQty);
                vMesQty = (vMesQty == null ? 0 : vMesQty);

                if (vMesQty != null) {
                    //gap = vErpQty - vMesQty;
                    gap = parseFloat(vErpQty - vMesQty).toFixed(3);
                    RealGrid1_gridView.setValue(itemIndex, "GAPSTCKQTY", gap);
                    RealGrid1_gridView.setValue(itemIndex, "DSTSTCKQTY", gap * -1);
                    RealGrid1_gridView.checkItem(itemIndex, true);
                }
                else {
                    RealGrid1_gridView.checkItem(itemIndex, false);
                }
            };

            //pasting event
            RealGrid1_gridView.onEditRowPasted = function (grid, itemIndex, dataRow, fields, oldValues, newValues) {
                var vErpQty = RealGrid1_gridView.getValue(itemIndex, "STOCKQTY_ERP");
                var vMesQty = RealGrid1_gridView.getValue(itemIndex, "RELSTCKQTY");
                var gap;

                vErpQty = (vErpQty == null ? 0 : vErpQty);
                vMesQty = (vMesQty == null ? 0 : vMesQty);

                if (vMesQty != null) {
                    //gap = vErpQty - vMesQty;
                    gap = parseFloat(vErpQty - vMesQty).toFixed(3);
                    RealGrid1_gridView.setValue(itemIndex, "GAPSTCKQTY", gap);
                    RealGrid1_gridView.setValue(itemIndex, "DSTSTCKQTY", gap * -1);
                    RealGrid1_gridView.checkItem(itemIndex, true);
                }
                else {
                    RealGrid1_gridView.checkItem(itemIndex, false);
                }
            };

            var vFilters = ["STCKCNTMNTH", "SHOPID", "MTRLID", "MTRLNAME", "SLOCID", "BTCHNAME", "STOCKQTY", "STOCKQTY_ERP", "RELSTCKQTY", "POSTRESULT_QTY", "GAPSTCKQTY", "DSTSTCKQTY", "UNIT", "AVAINVQTY"];
            RealGrid1.SetColsFilter(vFilters);

        };

        var vMasterRealgridFields =
            [  
                  { fieldName: "STCKCNTMNTH" } //재고실사 년월
                , { fieldName: "SHOPID" }      //PLANT
                , { fieldName: "SLOCID" }      //저장위치
                , { fieldName: "SLOCNM" }      //저장위치명
                , { fieldName: "MTRLID" }      //자재
                , { fieldName: "MTRLNAME" }    //자재명
                , { fieldName: "BTCHNAME" }    //배치번호
                , { fieldName: "ERPQTY", dataType: "number" }        //ERP전산재고
                , { fieldName: "STOCKQTY_ERP", dataType: "number" }  //ERP기말재고
                , { fieldName: "RELSTCKQTY", dataType: "number" }    //실사재고
                , { fieldName: "GAPSTCKQTY", dataType: "number" }    //실사재고차이
                , { fieldName: "USEQTY", dataType: "number" }        //당월사용량
                , { fieldName: "CHKRATE", dataType: "number" }       //실사재고율
                , { fieldName: "DSTSTCKQTY", dataType: "number" }    //차이배부량
                , { fieldName: "UNIT " }   //단위
                , { fieldName: "GUBUN " }  //구분
                , { fieldName: "AVAINVQTY", dataType: "number" } // 투입실적 v1.2_컬럼추가
            ];

        var vMasterRealgridColumns = [
            { name: "STCKCNTMNTH", fieldName: "STCKCNTMNTH", header: { text: "<%=lang.word["Closing Stock"]%>"+" "+"<%=lang.word["Year and Month"]%>" }, readOnly: true, visible: true, styles: { textAlignment: "center" }, width: 120 }
          , { name: "SHOPID", fieldName: "SHOPID", header: { text: "Plant" }, readOnly: true, visible: true, styles: { textAlignment: "center" }, width: 80 }
          , { name: "SLOCID", fieldName: "SLOCID", header: { text: "<%=lang.word["Storage Location"]%>" }, readOnly: true, visible: false, styles: { textAlignment: "center" }, width: 80 }
          , { name: "SLOCNM", fieldName: "SLOCNM", header: { text: "<%=lang.word["Storage Location"]%>" }, readOnly: true, visible: true, styles: { textAlignment: "near" }, width: 150 }
          , { name: "MTRLID", fieldName: "MTRLID", header: { text: "<%=lang.word["Material Code."]%>" }, readOnly: true, visible: true, styles: { textAlignment: "near" }, width: 140 }
          , { name: "MTRLNAME", fieldName: "MTRLNAME", header: { text: "<%=lang.word["Material Name"]%>" }, readOnly: true, visible: true, styles: { textAlignment: "near" }, width: 350 }
          , { name: "BTCHNAME", fieldName: "BTCHNAME", header: { text: "<%=lang.word["Batch No."]%>" }, readOnly: true, visible: true, styles: { textAlignment: "near" }, width: 150 }
          , { name: "ERPQTY", fieldName: "ERPQTY", header: { text: "<%=lang.word["ERP"]%>" + "<%=lang.word["Computer Inventory"]%>" }, visible: false, editable: true, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 100 }//ERP 전산재고 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
          , { name: "STOCKQTY_ERP", fieldName: "STOCKQTY_ERP", header: { text: "<%=lang.word["ERP"]%>" + "<%=lang.word["Cur. Stock"]%>" }, visible: true, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 100 }//ERP 재고 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
          , { name: "RELSTCKQTY", fieldName: "RELSTCKQTY", header: { text: "<%=lang.word["Physical Count Inventory"]%>" },readOnly: false, editable: true, visible: true, styles: {textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 100 }
          , { name: "GAPSTCKQTY", fieldName: "GAPSTCKQTY", header: { text: "<%=lang.word["Inventory Variance"]%>" }, readOnly: true, visible: true, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 100 }
          , { name: "USEQTY", fieldName: "USEQTY", header: { text: "<%=lang.word["THIS_MONTH"]%>" + "<%=lang.word["USED AMOUNT"]%>" }, readOnly: true, visible: false, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 100 }//당월 사용량 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
          , { name: "CHKRATE", fieldName: "CHKRATE", header: { text: "<%=lang.word["Physical Count"]%>" + "<%=lang.word["Inventory Rate"]%>" }, readOnly: true, visible: false, styles: { textAlignment: "far", numberFormat: "##,##0.0;.;,;f" }, width: 100 }//실사 재고율 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
          , { name: "DSTSTCKQTY", fieldName: "DSTSTCKQTY", header: { text: "<%=lang.word["Variance Distribution Quantity"]%>" }, readOnly: true, visible: true, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 100 }
          , { name: "UNIT", fieldName: "UNIT", header: { text: "<%=lang.word["Unit"]%>" }, readOnly: true, visible: true, styles: { textAlignment: "center" }, width: 60 }
          , { name: "GUBUN", fieldName: "GUBUN", header: { text: "<%=lang.word["Classification"]%>" }, readOnly: true, visible: false, styles: { textAlignment: "center" }, width: 50 }//구분
          // v1.2_컬럼추가
          , { name: "AVAINVQTY", fieldName: "AVAINVQTY", header: { text: "<%=lang.word["Input."]%>" + "<%=lang.word["Actual"]%>" }, readOnly: true, visible: true, styles: { textAlignment: "far", numberFormat: "##,##0.000;.;,;f" }, width: 100 }//투입실적 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
        ];
      
        //==============================================================


        //== Button Event ==============================
        function Validate(type) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            var result = true;
            var rows = RealGrid1.GetRowCount();
            RealGrid1_gridView.commit();

            switch (type) {
                case "SEARCH":
                    if ($('#cboStockLocation').combobox('getValue') == '') {
                        xAlert(msgNotSlocID);
                        return;
                    };

                    if ($('#chkNOW').is(":checked"))
                    {
                        var vMonth = $('#dtMonth').val() + '-01';
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

                        if (vFdate > vSdate || vTdate < vSdate) {
                            xAlert("<%=lang.message["38116"]%>");  //전기일이 설정한 월을 벗어났습니다.
                            return;
                        }

                        if (vSdate > vNdate) {
                            xAlert("<%=lang.message["38117"]%>"); //전기일을 오늘 이후로 설정 할 수 없습니다.
                            return;
                        }
                    }

                    break;
                case "SAVE":             
                case "CANCEL":
                    if (rows == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }
                    break;
                case "ADDROW":
                    if (rows == 0) {
                        msg = "<%=lang.message["38118"]%>";         //ROW를 추가할 때는 조회를 먼저해야합니다";
                        xAlert(msg);
                        return;
                    }

                    if ($('#txtMtrlId').textbox('getValue') == '') {
                        msg = "<%=lang.message["38119"]%>";         //ROW를 추가할 때는 자재를 선택해야합니다";
                        xAlert(msg);
                        return;
                    };
                    break;
                case "UPLOAD":
                    if (rows == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }
                    if ($('#cboStockLocation').combobox('getValue') == '') {
                        xAlert(msgNotSlocID);
                        return;
                    };
                    break;
                case "EXCEL":
                    if (rows == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }  
                    break;
                default:
            }

            return result;
        }

        function fnSearch() {
            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.OPENNINGYRMN = $('#dtMonth').val().replace(/-/gi, '');
            items.SLOCID = $('#cboStockLocation').combobox('getValue');
            items.ISNOW = $('#chkNOW').is(":checked") ? "NOW" : "MONTH";
            items.USERID = $("[id$=hidUserID]").val();
            items.POSTDATE = $('#dtPostDate').val().replace(/-/gi, '');
            
            var param = {};
            param.bizID = "BR_PRD_GET_INV_STOCK_MNTH";
            param.items = items;
            param.inTableNames = 'INDATA'; 
            param.outTableNames = 'RSLTDT';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";
            RealGrid1.CallRequest(url, param);
            RealGrid1.Refresh();            
        };

        function RealGrid1_LoadDataCompleted(rtn) {

            /* v1.2_투입실적이 없을경우 색상표시  */
            var crRowidxArray1 = [];
            var curRows;
            for (var intX = 0; intX < RealGrid1.GetRowCount() ; intX++) {
                curRows = RealGrid1_gridView.getDataSource().getJsonRow(intX);
                if (curRows.AVAINVQTY == undefined || curRows.AVAINVQTY == null || curRows.AVAINVQTY == 0) {
                    crRowidxArray1.push(intX);
                }
            }
            RealGrid1_gridView.setCellStyles(crRowidxArray1, ["AVAINVQTY"], "zeroCellStyle", true);
            //RealGrid1_gridView.setCellStyles(crRowidxArray, ["RELSTCKQTY"], "editCellStyle", true);
            
            fnCheckCloseStat();

            <%--$("#totalConunt").html("<%=lang.word["Search results"]%> ( Total <span class='red01'>" + RealGrid1.GetRowCount() + "</span> Found )");--%>
            if (RealGrid1.GetRowCount() == 0) {
                xAlert(msgNotFoundList);
            }
        }

        function DelRow() {
            /// <summary>기말재고가 없는것은 나타나지 않게 함</summary>
            var curRows;
            var intCnt = RealGrid1.GetRowCount();
            if (intCnt == 0) return false;

            for (var intX = intCnt - 1; intX >= 0; intX--) {

                curRows = RealGrid1_gridView.getDataSource().getJsonRow(intX);

                if (curRows.STOCKQTY_ERP == undefined || curRows.STOCKQTY_ERP == null || curRows.STOCKQTY_ERP == "") {
                    RealGrid1_dataProvider.setOptions({ softDeleting: false });
                    RealGrid1_dataProvider.removeRow(intX);
                }
            }

        }

        
        function fnSave(CnfmFlag) {
            /// <summary>입력값 저장</summary>            
            var items = [];
            var subItems = [];
            var param = {};
            var url;
            RealGrid1_gridView.commit();

            var subBasic = [];
            var curRows;
            var idx = 0;
            var vCnfmFlag = CnfmFlag;

            subBasic[0] = [
                  { name: "LANGID", value: $("[id$=hidLangID]").val(), dataType: _DataType.String }
                , { name: "USERID", value: $("[id$=hidUserID]").val(), dataType: _DataType.String }
                , { name: "CNFMFLAG", value: CnfmFlag, dataType: _DataType.String }
            ];

            for (var intX = 0; intX < RealGrid1.GetRowCount(); intX++) { 

                curRows = RealGrid1_gridView.getDataSource().getJsonRow(intX); 
                subItems[intX] = [
                      { name: "STCKCNTMNTH", value: curRows.STCKCNTMNTH.replace(/-/gi,''), dataType: _DataType.String }
                    , { name: "SHOPID", value: curRows.SHOPID, dataType: _DataType.String }
                    , { name: "MTRLID", value: curRows.MTRLID, dataType: _DataType.String }
                    , { name: "SLOCID", value: curRows.SLOCID, dataType: _DataType.String }
                    , { name: "BTCHNAME", value: curRows.BTCHNAME, dataType: _DataType.String }
                    , { name: "RELSTCKQTY", value: curRows.RELSTCKQTY, dataType: _DataType.Decimal }
                    , { name: "GAPSTCKQTY", value: curRows.GAPSTCKQTY, dataType: _DataType.Decimal }
                    , { name: "DSTSTCKQTY", value: curRows.DSTSTCKQTY, dataType: _DataType.Decimal }
                    , { name: "UNIT", value: curRows.UNIT, dataType: _DataType.String }
                    , { name: "GUBUN", value: curRows.GUBUN, dataType: _DataType.String }
                ];
            }

            items[0] = subBasic;
            items[1] = subItems;

            url = "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";
            param.bizID = "BR_PRD_UPD_CLOSE_RSLT";
            param.items = items;
            param.inTableNames = "INDATA,INDATA_LIST";
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

        function fnExcel(obj) {
            var vToday = "StockResultInput_" + new Date().format("yyyyMMddhhmmss") + ".xlsx";
            RealGrid1.ExcelExport(vToday);
        };

        function fnCheckCloseStat() {
            /// <summary>마감상태점검</summary>
            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.STCKCNTMNTH = $('#dtMonth').val().replace(/-/gi,'');
            items.SLOCID = $('#cboStockLocation').combobox('getValue');

            var param = {};
            param.bizID = "DA_PRD_SEL_CHK_CLOSE_STAT";
            param.items = items;
            param.inTableNames = 'RQSTDT';
            param.outTableNames = 'RSLTDT';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            sendRequestMethod(function (targetID, data, message, status) {
                chkCloseStat(data, 0, status, message);
            }, param, "POST", url);
        };


        function chkCloseStat(data, index, status, message) {
            var vStat = 'BEGIN';
            if (status == "FAIL") {
                if (message.split(":")[1] == null) {
                    xAlert(message);
                }
                else {
                    xAlert(message.split(":")[1]);
                }
                return;
            }
            else if (status == "OK") {                
                data.forEach(function (value, index, array) {
                    vStat = value.CLOSE_STAT;
                });                
            }
            SetButton(vStat);
        }

        function fnRunCheck(runCode) {
            /// <summary>저장,확정,취소시 마감상태점검</summary>
            var items = {};
            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.STCKCNTMNTH = $('#dtMonth').val().replace(/-/gi, '');
            items.SLOCID = $('#cboStockLocation').combobox('getValue');

            var param = {};
            param.bizID = "DA_PRD_SEL_CHK_CLOSE_STAT";
            param.items = items;
            param.inTableNames = 'RQSTDT';
            param.outTableNames = 'RSLTDT';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            sendRequestMethod(function (targetID, data, message, status) {
                chkRunStat(data, 0, status, message,runCode);
            }, param, "POST", url);
        };


        function chkRunStat(data, index, status, message, runCode) {
            if (status == "FAIL") {
                if (message.split(":")[1] == null) {
                    xAlert(message);
                } else {
                    xAlert(message.split(":")[1]);
                }
                return;
            }
            else if (status == "OK") {
                var vStat = '';
                data.forEach(function (value, index, array) {
                    vStat = value.CLOSE_STAT;
                });

                //저장 => 확정,완료 검사
                if(runCode=="" && (vStat=="CONFIRM" || vStat=="COMPLETE"))
                {
                    xAlert("<%=lang.message["38102"]%>");       //확정 및 완료 상태이므로 저장 할 수 없습니다");
                    SetButton(vStat);
                    return;
                }
                else if(runCode=="Y" && (vStat=="CONFIRM" || vStat=="COMPLETE"))
                {
                    xAlert("<%=lang.message["38103"]%>");       //확정 및 완료 상태이므로 확정 할 수 없습니다");
                    SetButton(vStat);
                    return;
                }
                else if (runCode == "N" && (vStat == "COMPLETE")) {
                    xAlert("<%=lang.message["38104"]%>");       //완료 상태이므로 확정취소 할 수 없습니다");
                    SetButton(vStat);
                    return;
                }

                fnSave(runCode);
            }
        }

        function ShowProductCodePopup(value) {
            ShowPopup("../GMES_COM/GMES_COM_0003.aspx?DVALUE=RAW&MTRLFLAG=" + "ES122" + "&SHOPID=" + $("[id$=hidShopID]").val() + "&MENU_ID=<%=ViewState["MENU_ID"].ToString()%>&PROD_SEARCH=" + value, 790, 500, "<%=lang.word["Inquiry Product"]%>", SetProductName);
        }

        function SetProductName(data) {
            if (data !== undefined && data.length > 2) {
                $("#txtMtrlId").textbox('setValue', data[2]);  //자재코드
                $("#txtMtrlName").textbox('setValue', data[1]); //자재명
                SetButtonEnable('#btnAddRow', true); //"품목추가"버튼 활성화

                fnMtrlUnit();
            }
        }

        function fnMtrlUnit() {
            var items = {};
            items.MTRLID = $('#txtMtrlId').textbox('getValue')

            var param = {};
            param.bizID = "COR_SEL_MATERIAL_TBL";
            param.items = items;
            param.inTableNames = 'RQSTDT';
            param.outTableNames = 'RSLTDT';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            sendRequestMethod(function (targetID, data, message, status) {
                fnRfnMtrlUnit(data, 0, status, message);
            }, param, "POST", url);
        }

        function fnRfnMtrlUnit(data, index, status, message) {
            var vCloseStat = '';
            if (status == "FAIL") {
                if (message.split(":")[1] == null) {
                    xAlert(message);
                } else {
                    xAlert(message.split(":")[1]);
                }
                return;
            }
            else if (status == "OK") {
                var vUNIT = '';
                data.forEach(function (value, index, array) {
                    vUNIT = value.MTRLUNIT;
                });

                $("#txtMtrlUnit").textbox('setValue', vUNIT);
            }
        }

        function AddRow() {
            values = {
                STCKCNTMNTH: $('#dtMonth').val(),
                SHOPID: $('[id$=hidShopID]').val(),
                SLOCID: $('#cboStockLocation').combobox('getValue'),
                SLOCNM: $('#cboStockLocation').combobox('getText'),
                MTRLID: $('#txtMtrlId').textbox('getValue'),
                MTRLNAME: $('#txtMtrlName').textbox('getValue'),
                BTCHNAME: $('#txtBTCHNAME').textbox('getValue').replace(/ /gi, ""),
                STOCKQTY_ERP: '0',
                RELSTCKQTY: '0',
                GAPSTCKQTY: '0',
                DSTSTCKQTY: '0',
                UNIT: $('#txtMtrlUnit').textbox('getValue').replace(/ /gi, ""),
                GUBUN: 'NEW'
            };

            RealGrid1_gridView.commit();

            // 중복데이터 체크
            for (var intX = 0 ; intX < RealGrid1.GetRowCount() ; intX++) {
                var jsonData = RealGrid1_dataProvider.getJsonRow(intX);
                if (jsonData.MTRLID == values.MTRLID && jsonData.BTCHNAME == values.BTCHNAME) {
                    xAlert("<%=lang.message["38120"]%>"); //해당 품목이 존재합니다
                    return;
                }
            };

            var rowNo = RealGrid1.GetRowCount();
            RealGrid1_dataProvider.insertRow(rowNo, values);
            RealGrid1_gridView.checkItem(rowNo, true);

            var crRowidxArray = [];
            crRowidxArray.push(rowNo);
            RealGrid1_gridView.setCellStyles(crRowidxArray, ["RELSTCKQTY"], "editCellStyle", true);
        }

        function SetDateShow() {
            /// <summary>전기일날짜선택시 보이기처리</summary>
            var IsChk = $('#chkNOW').is(":checked");

            if (IsChk) {
                $('#spPostDate').css("visibility", "visible");
            }
            else {
                $('#spPostDate').css("visibility", "hidden");
            }
        }


        function ExcelImport(e) {
            /// <summary>엑셀 파일을 읽어 들여 그리드에 표시한다.</summary>
            var rABS = typeof FileReader !== "undefined" && (FileReader.prototype || {}).readAsBinaryString;
            var f = e.target.files[0];
            var check = f.name.toString();
            var reader = new FileReader();
            ShowLoading();

            if (check.indexOf("CLS") != -1) {
                reader.onload = function (e) {
                    var count = 1;
                    var data = e.target.result;
                    if (!rABS) data = new Uint8Array(data);
                    var workbook = XLSX.read(data, { type: rABS ? 'binary' : 'array' });
                    var sheet_name_list = workbook.SheetNames;
                    var arrXData = XLSX.utils.sheet_to_json(workbook.Sheets[workbook.SheetNames[0]], { header: 1 });

                    if (count == 1) {

                        for (var intX = 1; intX < arrXData.length; intX++) {

                            if (arrXData[intX][0] == null || arrXData[intX][0] == "" || arrXData[intX][1] == null || arrXData[intX][1] == "") {
                                //입력이 제대로 안된 항목이 있습니다.
                                continue;
                            } 

                            values = {
                                MTRLID: arrXData[intX][0],
                                USEQTY: arrXData[intX][1] 
                            };

                            // 일치하는지 확인  
                            for (var intY = 0 ; intY < RealGrid1.GetRowCount() ; intY++) {
                                var jsonData = RealGrid1_dataProvider.getJsonRow(intY);

                                if (jsonData.MTRLID == values.MTRLID) {

                                    RealGrid1_gridView.setValue(intY, "RELSTCKQTY", values.USEQTY)

                                    var vErpQty = RealGrid1_gridView.getValue(intY, "STOCKQTY_ERP");
                                    var vMesQty = RealGrid1_gridView.getValue(intY, "RELSTCKQTY");
                                    var gap;

                                    vErpQty = (vErpQty == null ? 0 : vErpQty);
                                    vMesQty = (vMesQty == null ? 0 : vMesQty);

                                    if (vMesQty != null) {
                                        //gap = vErpQty - vMesQty;
                                        gap = parseFloat(vErpQty - vMesQty).toFixed(3);
                                        RealGrid1_gridView.setValue(intY, "GAPSTCKQTY", gap);
                                        RealGrid1_gridView.setValue(intY, "DSTSTCKQTY", gap * -1);
                                        RealGrid1_gridView.checkItem(intY, true);
                                    }
                                    else {
                                        RealGrid1_gridView.checkItem(intY, false);
                                    }
                                                 
                                    break;
                                }
                            };
                        }
                    }
                    count += 1;
                }
                // 엑셀 업로드 데이터 검증
                CloseLoading();
            } else {
                xAlert('<%=lang.message["38113"]%>');  //제공한 템플릿 파일이 아닙니다
                CloseLoading();
                return;
            }

            if (rABS) {
                reader.readAsBinaryString(f);
            } else {
                reader.readAsArrayBuffer(f);
            }

            RealGrid1_LoadDataCompleted();
            $('#uploadFile').val("");
        }

        //==============================================================


        //== Set Control ==============================
        function SetStorage() {
            /// <summary>저장위치</summary>
            //var AREAID = ($("#cboArea").val() == '') ? '' : '&AREAID=' + $("#cboArea").val();
            $('#cboStockLocation').combobox({
                //url: '../common/xml/CallBizJson.aspx?sp_name=CUS_SEL_STOCKLOCATION_AREAID_CBO&SHOPID=' + $("[id$=hidShopID]").val() + '&LANGID=' + $("[id$=hidLangID]").val() + '&CBOOPT=OPT|SLOCID|SLOCNAME'
                url: '../common/xml/CallBizJson.aspx?sp_name=CUS_SEL_STORAGELOCATION_RANGE_CBO&LANGID=' + $("[id$=hidLangID]").val() + '&SHOPID=' + $("[id$=hidShopID]").val() + '&USEFLAG=Y&CBOOPT=OPT|SLOCID|SLOCNAME'
                , valueField: 'SLOCID'
                , textField: 'SLOCNAME'
                , onLoadSuccess: function () {
                    var items = $(this).combobox("getData");
                    if (items.length > 0) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                }
            });
        }

        function SetMonth() {
            /// <summary>전월설정</summary>
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
                DelRow();
                var crRowidxArray = [];
                for (var intX = 0; intX < RealGrid1.GetRowCount() ; intX++)
                {
                    crRowidxArray.push(intX);
                }

                switch (id) {
                    case "BEGIN":
                        RealGrid1_gridView.setCellStyles(crRowidxArray, ["RELSTCKQTY"], "editCellStyle", true);
                        SetButtonEnable('#btnConfirm', true);
                        SetButtonEnable('#btnConfirmCancel', false);
                        SetButtonEnable('#btnSave', true);        
                        //SetButtonEnable('#btnUploadExcel', true);
                        /* 2022-08-23, 엑셀 업로드 버튼 DISABLE 처리 */
                        SetButtonEnable('#btnUploadExcel', false)
                        break;
                    case "CONFIRM":
                        RealGrid1_gridView.setCellStyles(crRowidxArray, ["RELSTCKQTY"], "lockCellStyle", true);
                        SetButtonEnable('#btnConfirm', false);
                        SetButtonEnable('#btnConfirmCancel', true);
                        SetButtonEnable('#btnSave', false);
                        SetButtonEnable('#btnUploadExcel', false);
                        break;
                    case "COMPLETE":
                        RealGrid1_gridView.setCellStyles(crRowidxArray, ["RELSTCKQTY"], "lockCellStyle", true);
                        SetButtonEnable('#btnConfirm', false);
                        SetButtonEnable('#btnConfirmCancel', false);
                        SetButtonEnable('#btnSave', false);
                        SetButtonEnable('#btnUploadExcel', false);
                        break;
                    default:
                        RealGrid1_gridView.setCellStyles(crRowidxArray, ["RELSTCKQTY"], "editCellStyle", true);
                }
            } catch (e) {
                xAlert(e.message);
            }
        }

        //==============================================================

        //== Layout Framework ============================== 
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
        //==============================================================
    </script>

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
                            <th>
                                <label><!--전일재고사용--> 
                                    <input type="checkbox" id="chkNOW" onchange="javascript:SetDateShow();" /><%=lang.word["BEF_INV_USE"]%>
                                </label>
                            </th><!--기준일--> <!-- 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용 -->
                            <td><span id="spPostDate"><label><%=lang.word["BaseDttm"]%><input id="dtPostDate" class="easyui-datebox" style="width: 100px;" /></label></span></td>                         
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
                <!-- div id="totalConunt" class="floatLeft01"><%=lang.word["Search results"]%> ( Total <span class='red01'>0</span> Found )<div -->
                <ul id="ulBttomButton" runat="server" class="btn_crud">
                     
                    <li><a class="red"  id ="btnConfirm" onclick="onButtonClick(this.id)"><span><%=lang.word["Confirmation"]%></span></a></li>               <!-- 확정 -->
                    <li><a class="red"  id ="btnConfirmCancel" onclick="onButtonClick(this.id)"><span><%=lang.word["ConfirmCancel"]%></span></a></li>        <!-- 확정취소 -->
                    <li><a class="red"  id ="btnSave" onclick="onButtonClick(this.id)"><span><%=lang.word["TEMPSAVE"]%></span></a></li>                      <!-- 임시저장 --> 
                    <li><a class="red"  id ="btnUploadExcel" onclick="onButtonClick(this.id)"><span><%=lang.word["Excel Down"]%> <%=lang.word["Upload"]%></span></a></li> <!-- 엑셀 Upload -->                  
                    <li><a class="excel" id ="btnExcel" onclick="onButtonClick(this.id)"></a></li>
                    <li><input name="uploadFileTab1" id="uploadFile" type="file" style="display:none;"/></li>
                </ul>

                <div style="float:Right;">
                    <%=lang.word["Material Code."]%>
                <input id="txtMtrlId" class="easyui-searchbox" style="width: 200px; " data-options="searcher:ShowProductCodePopup, inputEvents: $.extend({}, $.fn.searchbox.defaults.inputEvents, { keyup: function(e){ $('#txtMtrlName').textbox('setText', ''); } })" />
                <span style="display:none;"><input id="txtMtrlName" class="easyui-textbox" style="width: 100px; " disabled="disabled"/><input id="txtMtrlUnit" class="easyui-textbox" style="width:1px;"/></span> 
                &nbsp;<%=lang.word["Batch No."]%><input id="txtBTCHNAME" class="easyui-textbox" style="width: 100px"/>
                    <ul id="ulBttomButton1" runat="server" class="btn_crud">                        
                        <li><a class="red" id ="btnAddRow" onclick="onButtonClick(this.id)"><span><%=lang.word["ITEM_ADD"]%></span></a></li> 
                        <li><a class="table_bar"></a></li> 
                    </ul>
                </div>

            </div>
            <div id="divMasterGrid" class="table">
                <uc:Realgrid ID="RealGrid1" CALLID="RealGrid1" runat="server" HEIGHT="200" LAYOUTSAVING="Y" />
            </div>
        </div>
    </form>
</asp:Content>


