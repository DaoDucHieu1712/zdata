<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPopup.master" AutoEventWireup="true" CodeFile="GMES_IMES_0560_05.aspx.cs" Inherits="GMES_IMES_0560_05" %>

<%--/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMES_0560_05.aspx
* @desc    : 분산 투입 계산 팝업
************************************************************************************************* 
* VER     DATE                          AUTHOR        DESCRIPTION
*************************************************************************************************
* 1.0     2025-07-09                    오정균        신규 (분산 투입 계산 팝업)
*************************************************************************************************
*/--%>
<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>

<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <style>
        .th_fix {
            width : 130px;
            max-width: 130px;
        }
        .td_number_fix {
            width: 200px;
            max-width: 200px;
        }
        .custom-li {
            height: 27px;
            display: flex; /* Flexbox 사용 */
            align-items: center; /* 수직 가운데 정렬 */
            justify-content: center; /* 수평 가운데 정렬 */
            list-style-type: none; /* 기본 리스트 스타일 제거 */
        }
    </style>

    <%--<script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js"></script>--%>
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js?v=<%=DateTime.Now.ToString("yyyyMMddHHmmss")%>"></script>
    <%--<script type="text/javascript" src="common/js/JsCommon.js"></script>--%>
    <script type="text/javascript" language="javascript">
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

        //#region 변수
        // grid
        const cQtyFormat = "#,##0.00";  /*수량 소수점 3자리X*/
        const defaultBorder = "#808080, 1";
        // grid

        const newDate = new Date();
        const today = '' + newDate.getFullYear() + (newDate.getMonth() + 1).toString().padStart(2, '0') + newDate.getDate().toString().padStart(2, '0') + '';
        //#endregion

        $(document).ready(function () {
            InitData();
        });

        function xInitPage() {
            AutoHeightSpread();
        }

        //#region AutoHeightSpread - RealGrid의 높이를 재설정한다.
        function AutoHeightSpread() {
            var gridMaster = document.getElementById("ucMasterRealgrid");

            var InputBoxHeight = document.getElementById("div_InputContent").clientHeight;
            var AddButtonHeight = document.getElementById("div_AddButtonArea").clientHeight;
            var pageHeight = document.documentElement.clientHeight;

            var i = 0;
            i = pageHeight - (InputBoxHeight + AddButtonHeight + 33);

            gridMaster.style.height = String(i) + 'px';

            ucMasterRealgrid.ResetSize();
        }
        //#endregion


        // #region InitData
        function InitData() {
            setSelectCom(); // 콤보박스 설정
            InitMainRealgrid(); // realGrid
            GetData();
        }
        //#endregion

        //#region 콤보박스 설정
        function setSelectCom() {
            $('#com_InspectionItem').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=DA_IM_BAS_SEL_PROD_CLCTITEM&LANGID=' + XSSReplace($("[id$=hidLangID]").val(), 1) + '&TYPE=' + XSSReplace($("[id$=hidTYPE]").val(), 1) + '&CMCDTYPE=CM_QUALITEM&ATTRIBUTE2=Y&CBOOPT=OPT|CLCTITEM|CLCTNAME',
                valueField: 'CLCTITEM',
                textField: 'CLCTNAME'
            });
        }
        //#endregion

        //#region realGrid
        //#region Main Realgrid Field, Column 설정

        var vMasterRealgridFieldColumn = [
            { fieldName: "index", columnSetting: { type: "logic", mergeRule: {}, filterType: false, header: "index" } },
            { fieldName: "LOTID_USER_BATCH", columnSetting: { type: "main_lotid", mergeRule: { criteria: "values['LOTID_USER_BATCH']+value" }, mergeType: true, filterType: false, header: "<%=lang.word["Batch"]%>" } },
            { fieldName: "CLCTNAME", columnSetting: { type: "main_name", mergeRule: { criteria: "values['LOTID_USER_BATCH']+value" }, mergeType: true, filterType: false, header: "<%=lang.word["Inspection Item"]%>" } },
            { fieldName: "LSL", dataType: "number", columnSetting: { type: "main_clc", mergeRule: { criteria: "values['LOTID_USER_BATCH']+value" }, mergeType: true, filterType: false, header: "<%=lang.word["Lower Limit"]%>" } },
            { fieldName: "USL", dataType: "number", columnSetting: { type: "main_clc", mergeRule: { criteria: "values['LOTID_USER_BATCH']+value" }, mergeType: true, filterType: false, header: "<%=lang.word["Upper Limit"]%>" } },
            { fieldName: "CLCTVAL", dataType: "number", columnSetting: { type: "main_clctval", mergeRule: { criteria: "values['LOTID_USER_BATCH']+value" }, mergeType: true, filterType: false, header: "<%=lang.word["Measure Value"]%>" } },
            { fieldName: "LOTID_USER", columnSetting: { type: "main_lotid", mergeRule: {}, mergeType: false, filterType: false, header: "<%=lang.word["LOTID_USER"]%>" } },
            { fieldName: "INRATIO", columnSetting: { type: "main_data", mergeRule: {}, mergeType: false, filterType: false, header: "<%=lang.word["DistributedInjection"]%> <%=lang.word["Ratio"]%>" } },
            { fieldName: "INQTY_CALC", dataType: "number", columnSetting: { type: "main_qty", mergeRule: {}, mergeType: false, filterType: false, header: "<%=lang.word["DistributedInjection"]%> <%=lang.word["BeakerWeight"]%>(<%=lang.word["conversion"]%>)" } },
        ];
        var vMasterRealgridFields = []
        var vMasterRealgridColumns = [];
        //#endregion

        //#region 컬럼 타입 별 기준 정보 변경
        const dynamicStyles = [
            {
                criteria: "((values['LSL'] <> null) AND (values['LSL'] <> '') AND (values['LSL'] > values['CLCTVAL']))",
                styles: {
                    "fontBold": true,
                    "foreground": "#0019F4"
                }
            },
            {
                criteria: "((values['USL'] <> null) AND (values['USL'] <> '') AND (values['USL'] < values['CLCTVAL']))",
                styles: {
                    "fontBold": true,
                    "foreground": "#ff0000"
                }
            },
            {
                criteria: "(((values['LSL'] = null) OR (values['LSL'] = '')) AND (((values['USL'] = null) OR (values['USL'] = '')))",
                styles: {
                    "fontBold": false
                }
            }
        ];

        var setTypeColumn = function (vType, vColumn) {
            switch (vType) {
                case "logic":
                    vColumn.visible = false;
                    break
                case "main_clc":
                    vColumn.styles.numberFormat = cQtyFormat;
                    vColumn.width = 90;
                    break
                case "main_qty":
                    vColumn.styles.numberFormat = cQtyFormat;
                    vColumn.width = 130;
                    break
                case "main_clctval":
                    vColumn.styles.numberFormat = cQtyFormat;
                    vColumn.width = 90;
                    vColumn.dynamicStyles = dynamicStyles;
                    vColumn.styles.fontBold = true;
                    break
                case "main_data":
                    vColumn.width = 130;
                    break
                case "main_name":
                case "main_id":
                case "main_lotid":
                    vColumn.width = 200;
                    break
            }

            return vColumn;
        }
        //#endregion

        //#region 컬럼 설정
        var setColumn = function (vType, vFieldName, vHeader, vMergeRule, mergeType, isGroup) {
            // 해당 Detailgrid 공통 컬럼 설정
            var column = {
                name: vFieldName,
                fieldName: vFieldName,
                header: { text: vHeader },
                styles: { textAlignment: "center" },
                mergeRule: vMergeRule,
                sortable: false, /*ORDER BY 사용 여부*/
                visible: true,
                editable: false,
                width: 150
            };
            // 해당 Detailgrid 공통 컬럼 설정

            if (mergeType) {
                column.styles.borderBottom = defaultBorder;
                column.sortable = true;
            }

            if (isGroup.type) {
                column.movable = false; // 그룹 안에서는 컬럼 이동 못하도록 설정
            }

            return setTypeColumn(vType, column);
        };
        //#endregion

        //#region realGrid Init
        function InitMainRealgrid() {
            vMasterRealgridFieldColumn.forEach(function (a) {
                var vGroupWidth = 0;
                var masterColumns = [];

                if (a.type == "group") {
                    a.columns.forEach(function (b) {
                        vMasterRealgridFields.push({ fieldName: b.fieldName, dataType: onNullCheck(b.dataType) ? 'text' : b.dataType });
                        var column = setColumn(b.columnSetting.type, b.fieldName, b.columnSetting.header, b.columnSetting.mergeRule, b.columnSetting.mergeType, { type: true });
                        masterColumns.push(column);
                        vGroupWidth += (column.visible) ? column.width : 0;

                        if (b.columnSetting.filterType) {
                            vRealgridFilterColumns.push(a.fieldName);
                        }
                    });

                    vMasterRealgridColumns.push({
                        type: a.type,
                        name: a.name,
                        header: a.header,
                        width: vGroupWidth,
                        columns: masterColumns
                    });
                } else {
                    if (a.columnSetting.filterType) {
                        vRealgridFilterColumns.push(a.fieldName);
                    }
                    vMasterRealgridFields.push({ fieldName: a.fieldName, dataType: onNullCheck(a.dataType) ? 'text' : a.dataType });
                    vMasterRealgridColumns.push(setColumn(a.columnSetting.type, a.fieldName, a.columnSetting.header, a.columnSetting.mergeRule, a.columnSetting.mergeType, { type: false }));
                }
            });

            /*메뉴 ID 에 null을 등록하면 컬럼별 빼고 안빼고를 설정 할 수 없다. 일단은 NULL로 */
            ucMasterRealgrid.Init(null, vMasterRealgridFields, vMasterRealgridColumns, true, true, true);

            realGridSet(ucMasterRealgrid_gridView, false);

            ucMasterRealgrid_gridView.setStyles({
                body: {
                    cellDynamicStyles: [{
                        criteria: "values['index'] % 2 = 1",
                        styles: {
                            background: "#F9F9F9"
                        }
                    }, {
                        criteria: "values['index'] % 2 = 0",
                        styles: {
                            background: "#ffffff"
                        }
                    }]
                }
            });

            ucMasterRealgrid_gridView.addCellStyle("defaultBorderCellStyle", {
                "borderBottom": defaultBorder,
            }, true);
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
                editable: false,
                commitByCell: true,
                showInnerFocus: false
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
        //#endregion
        //#endregion

        //#region 버튼클릭
        function buttonCheck(id) {
            try {
                switch (id) {
                    case "btnSelect"://계산
                        GetMasterData();
                        break;

                    case "btnClose"://닫기
                        parent.CallBackCloseDialog();
                        break;

                    default:
                }
            } catch (e) {
                xAlert(e.message);
            }
        }
        //#endregion

        //#region 계산
        function GetMasterData() {
            var validation = function (type, value, label) {
                var msg = "<%=lang.message["25062"]%>";
                var vReturn = false;

                switch (type) {
                    case "text":
                        if (onNullCheck(value)) {
                            msg = msg.replace("%1", label);
                            xAlert(msg);

                            vReturn = true;
                        }
                        break
                    case "number":
                        if (onZeroCheck(value)) {
                            msg = msg.replace("%1", label);
                            xAlert(msg);

                            vReturn = true;
                        }
                        break
                }

                return vReturn;
            }

            if (validation("text", $('#com_InspectionItem').combobox('getValue'), "<%=lang.word["Inspection Item"]%>")) {
                return
            }
            if (validation("number", $('#num_GoodQty').val(), "<%=lang.word["Mass-Production"]%> <%=lang.word["Criterion"]%>")) {
                return
            }
            if (validation("number", $('#num_MixBatchWeight').val(), "<%=lang.word["MIXED"]%> <%=lang.word["Batch"]%> <%=lang.word["BeakerWeight"]%>")) {
                return
            }

            GetData();
        }

        function GetData() {
            ucMasterRealgrid_gridView.orderBy([], []); /*순서 초기화*/

            var items = [
                 { name: "LANGID", value: XSSReplace($("[id$=hidLangID]").val(), 1), dataType: _DataType.String },
                 { name: "LOTID_LIST", value: XSSReplace($("[id$=hidLOTLIST]").val(), 1), dataType: _DataType.String },
                 { name: "CLCTITEM", value: $('#com_InspectionItem').combobox('getValue'), dataType: _DataType.String },
                 { name: "PRDSTD", value: $('#num_GoodQty').val(), dataType: _DataType.Decimal },
                 { name: "MIXQTY", value: $('#num_MixBatchWeight').val(), dataType: _DataType.Decimal }
            ];

            var url = "/GMES_IM_POM/GMES_IMES_0560_05.aspx/GetData";
            var param = {};
            param.bizID = "BR_IM_PRD_SEL_LOT_ABNORMAL_CALC";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = 'OUTDATA';

            ucMasterRealgrid.CallRequest(url, param, function () {
                var defaultBorderCellStyleDataRow = [];
                var index = 0;

                for (var idx = 0; idx < ucMasterRealgrid.GetRowCount(); idx++) {
                    var item = ucMasterRealgrid_dataProvider.getJsonRow(idx);

                    if (idx != 0) {
                        var fromBATCH = ""
                        var lotBATCH = ""
                        var fromItem = ucMasterRealgrid_dataProvider.getJsonRow(idx - 1);

                        fromBATCH = fromItem.LOTID_USER_BATCH;
                        lotBATCH = item.LOTID_USER_BATCH;

                        if (fromBATCH != lotBATCH) {
                            index += 1;
                            defaultBorderCellStyleDataRow.push(idx - 1);
                        }

                        ucMasterRealgrid_gridView.setValue(idx, "index", index);
                    }
                }

                // 그룹 체크
                var defaultBorderCellStyleFieldName = [];

                vMasterRealgridFieldColumn.forEach(function (v) {
                    if (v.type == "group") {
                        v.columns.forEach(function (f) {
                            if (!(f.columnSetting.mergeType)) {
                                defaultBorderCellStyleFieldName.push(f.fieldName);
                            }
                        });
                    } else {
                        if (v.columnSetting.type != "logic" && !(v.columnSetting.mergeType)) {
                            defaultBorderCellStyleFieldName.push(v.fieldName);
                        }
                    }
                });

                if (defaultBorderCellStyleDataRow.length > 0) {
                    ucMasterRealgrid_gridView.setCellStyles(defaultBorderCellStyleDataRow, defaultBorderCellStyleFieldName, "defaultBorderCellStyle");
                }
                if (ucMasterRealgrid.GetRowCount() > 0) {
                    ucMasterRealgrid_gridView.setCellStyles(ucMasterRealgrid.GetRowCount() - 1, defaultBorderCellStyleFieldName, "defaultBorderCellStyle");
                }
                // 그룹 체크

                setTotalCount([$("#ucMasterTotalConunt"), ucMasterRealgrid.GetRowCount()]);
            });
        }
        //#endregion

        // #region Excel
        function onExcelButtonClick(grid, gridView) {
            try {
                GridToExcel(grid, gridView);
            } catch (e) {
                xAlert(e.message);
            }
        }

        function GridToExcel(grid, gridView) {
            if (grid.GetRowCount() == 0) {
                xAlert('<%=lang.message["20051"]%>');
                return;
            }

            var title = XSSReplace($("[id$=hidTITLE]").val(), 1); // title 명

            gridView.exportGrid({
                target: "local",
                fileName: '(' + today + ')' + title + ".xlsx",
                indicator: "hidden",
                footer: "hidden",
                lookupDisplay: true,
                compatibility: true, // false면 엑셀에서 그룹 접기 출력
                showProgress: true,
                progressMessage: "Excel Exporting....",
                applyDynamicStyles: true
            });
        }
        // #endregion

        // #region 카운트
        function setTotalCount(count) {
            if (!onNullCheck(count)) {
                count[0].text(count[1]);
            }
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

        //#region 빈 값 체크
        function onNullCheck(value) {
            if (value === null || value === undefined || valueIsNaN(value) || value.toString().trim() === '') {
                //if (Object.is(value, null) || Object.is(value, undefined) || Object.is(value, NaN) || Object.is(value.toString().trim(), '')) {
                return true;
            } else {
                return false;
            }
        }
        function valueIsNaN(v) {
            return v !== v;
        }
        //#endregion
    </script>

</asp:Content>

<asp:Content ID="UIContent" ContentPlaceHolderID="bodyHolder" runat="server">
    <form id="form1" runat="server" onkeypress="if(event.keyCode == 13) { var target = event.target || event.srcElement; if(target.nodeName != 'TEXTAREA') { self.focus(); return false; } }">
        <!-- hidden Field Start-->
        <asp:HiddenField ID="hidLOTLIST" runat="server" />
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidTYPE" runat="server" />
        <asp:HiddenField ID="hidTITLE" runat="server" />
        <!-- hidden Field End-->

        <asp:ScriptManager runat="server" EnablePageMethods="True" ID="ScriptManager1"></asp:ScriptManager>
        <div id="div_Content" runat="server">
            <div id="div_InputContent" style="margin-left: 10px; margin-right: 10px; margin-top: 4px;">
                <table class="tableGeneral">
                    <tbody>
                        <tr>
                            <td colspan="6"></td>
                        </tr>           
                        <tr>
                            <!-- 검사항목 -->
                            <th class="th_fix">
                                <span class='textPink'>*</span><label for="input_text01"><%=lang.word["Inspection Item"]%></label>
                            </th>
                            <td align="left">
                                <input id="com_InspectionItem" class="easyui-combobox" style="width: 100%; border: none;" />
                            </td>
                            <!-- 검사항목 -->
                            <!-- 양산기준 -->
                            <th class="th_fix">
                                <span class='textPink'>*</span><label for="input_text01"><%=lang.word["Mass-Production"]%> <%=lang.word["Criterion"]%></label>
                            </th>
                            <td align="left" class="td_number_fix">
                                <input id="num_GoodQty" class="easyui-numberbox" data-options="precision:3,groupSeparator:','" style="width: 100%;" />
                            </td>
                            <!-- 양산기준 -->
                            <!-- 혼합배치중량 -->
                            <th class="th_fix">
                                <span class='textPink'>*</span><label for="input_text01"><%=lang.word["MIXED"]%> <%=lang.word["Batch"]%> <%=lang.word["BeakerWeight"]%></label>
                            </th>
                            <td align="left" class="td_number_fix">
                                <input id="num_MixBatchWeight" class="easyui-numberbox" data-options="precision:3,groupSeparator:','" style="width: 100%;" />
                            </td>
                            <!-- 혼합배치중량 -->
                        </tr>
                    </tbody>
                </table>
            </div>

            <div id="div_AddButtonArea" class="buttonArea" style="padding:10px 10px 0px 10px;">
                <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucMasterTotalConunt" class='red01'>0</span> Found )</div>
                <ul runat="server" class="btn_crud">
                    <li class="custom-li">
                       <span><%=lang.word["Inspection Result"]%> <%=lang.word["Status"]%> : </span>
                    </li>
                    <li class="custom-li" style="padding: 0 3px;">
                       <span style="color:#0019F4; font-weight: bold;"><%=lang.word["LessThan"]%></span>
                    </li>
                    <li class="custom-li">
                       <span>/</span>
                    </li>
                    <li class="custom-li" style="padding: 0 3px;">
                       <span style="color:#ff0000; font-weight: bold;"><%=lang.word["Excess"]%></span>
                    </li>
                    <li class="custom-li">
                       <span>/</span>
                    </li>
                    <li class="custom-li" style="padding: 0 0 0 3px;">
                       <span style="font-weight: bold;"><%=lang.word["Normal"]%></span>
                    </li>
                    <li><a class="table_bar"></a></li>
                    <li><a class="save" id="btnSelect" onclick="buttonCheck(this.id);"><span><%=lang.word["Calculation"]%></span></a></li>
                    <li><a class="close" id="btnClose" onclick="buttonCheck(this.id);"><span><%=lang.word["Close"]%></span></a></li>
                    <li><a class="table_bar"></a></li>
                    <li><a class="excel" onclick="onExcelButtonClick(ucMasterRealgrid, ucMasterRealgrid_gridView)"></a></li>
                </ul>
            </div>
            <div id="div_InputLotContent">
                <div id="divMasterGrid" class="table">
                    <uc:Realgrid ID="ucMasterRealgrid" CALLID="ucMasterRealgrid" runat="server" HEIGHT="200" />
                </div>
            </div>
        </div>
    </form>
</asp:Content>
