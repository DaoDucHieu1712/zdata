<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPopup.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0560_02.aspx.cs" Inherits="GMES_IMES_0560_02" %>
<%--/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0560_02.aspx
* @desc    : 생산실적 - 이상품 추적 - 관리기준
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2024/10/13   송상호              INIT
* 1.1  2025/08/14   오정균              요구사항으로 인한 전체 수정
*************************************************************************************************
*/--%>

<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>

<%-- Fucntion --%>
<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js?v=20240130"></script>
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

        //#region 변수
        // grid
        const cQtyFormat = "#,##0.000";  /*수량 소수점 3자리X*/
        // grid

        const newDate = new Date();
        const today = '' + newDate.getFullYear() + (newDate.getMonth() + 1).toString().padStart(2, '0') + newDate.getDate().toString().padStart(2, '0') + '';
        let IS_SAVE = false; // 저장여부
        var autoFilter = {};
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

            var AddButtonHeight = document.getElementById("div_ButtonArea").clientHeight;
            var pageHeight = document.documentElement.clientHeight;

            var i = 0;
            i = pageHeight - (AddButtonHeight + 28);

            gridMaster.style.height = String(i) + 'px';

            ucMasterRealgrid.ResetSize();
        }
        //#endregion

        // #region InitData
        function InitData() {
            InitMainRealgrid(); // realGrid
            setColumnLayout();
            //GetData();
        }
        //#endregion

        //#region realGrid
        //#region Main Realgrid Field, Column 설정
        var vMasterRealgridFieldColumn = [
            { fieldName: "PRODNAME", columnSetting: { type: "logic", filterType: false, header: "PRODNAME" } },
            { fieldName: "PRODID", columnSetting: { type: "main_id", filterType: true, header: "<%=lang.word["PRODID"]%>" } }
        ];
        var vMasterRealgridFields = []
        var vMasterRealgridColumns = [];
        var vRealgridFilterColumns = [];
        //#endregion

        //#region 컬럼 타입 별 기준 정보 변경
        var setTypeColumn = function (vType, vColumn) {
            switch (vType) {
                case "logic":
                    vColumn.visible = false;
                    vColumn.width = 0;
                    break
                case "main_id":
                    vColumn.width = 200;
                    break
                case "number_editable":
                    vColumn.width = 100;
                    vColumn.editable = true;
                    vColumn.styles.numberFormat = cQtyFormat;
                    break
            }

            return vColumn;
        }
        //#endregion

        //#region 컬럼 설정
        var setColumn = function (vType, vFieldName, vHeader, isGroup) {
            // 해당 Detailgrid 공통 컬럼 설정
            var column = {
                name: vFieldName,
                fieldName: vFieldName,
                header: { text: vHeader },
                styles: { textAlignment: "center" },
                sortable: false, /*ORDER BY 사용 여부*/
                visible: true,
                editable: false,
                width: 150
            };
            // 해당 Detailgrid 공통 컬럼 설정

            if (isGroup.type) {
                column.movable = false; // 그룹 안에서는 컬럼 이동 못하도록 설정
            }

            return setTypeColumn(vType, column);
        };
        //#endregion

        //#region realGrid Init
        function InitMainRealgrid() {
            vMasterRealgridFieldColumn.forEach(function (a) {
                if (a.columnSetting.filterType) {
                    vRealgridFilterColumns.push(a.fieldName);
                }

                vMasterRealgridFields.push({ fieldName: a.fieldName, dataType: onNullCheck(a.dataType) ? 'text' : a.dataType });
                vMasterRealgridColumns.push(setColumn(a.columnSetting.type, a.fieldName, a.columnSetting.header, { type: false }));
            });

            /*메뉴 ID 에 null을 등록하면 컬럼별 빼고 안빼고를 설정 할 수 없다. 일단은 NULL로 */
            ucMasterRealgrid.Init(null, vMasterRealgridFields, vMasterRealgridColumns, true, true, true);

            realGridSet(ucMasterRealgrid_gridView, true);

            ucMasterRealgrid.SetFixedColumn(1);
            ucMasterRealgrid_gridView.addCellStyle("EditCellStyle", {
                "editable": true,
                "background": "#ffffe6"
            }, true);

            ucMasterRealgrid_gridView.onFilteringChanged = function (grid, column) {
                setTotalCount([$("#ucMasterTotalConunt"), ucMasterRealgrid_gridView.getItemCount()]);
            }
        }

        var setFilterActionClicked = function () {
            ucMasterRealgrid_gridView.onFilterActionClicked = function (grid, column, action, x, y) {
                if (action == "autoFilter") {
                    var offset = $("#ucMasterRealgrid").position();

                    showAutoFiltering("ucMasterRealgrid", ucMasterRealgrid_gridView, ucMasterRealgrid_dataProvider, column, x + offset.left, y + offset.top);
                }
            };
        }

        var setFilterColumns = function (filterColumns) {
            if (filterColumns.length > 0) {
                ucMasterRealgrid.SetColsFilter(filterColumns);

                autoFilter["ucMasterRealgrid"] = {
                    "realGrid_autoFilterItemsKey": [],
                    "realGrid_autoFilterColumns": filterColumns
                };

                // 직접 그리드에 INSERT 조회 후 실행
                //ucMasterRealgrid_LoadDataCompleted = function () {
                //    ucMasterRealgrid_gridView.onFilterActionClicked = function (grid, column, action, x, y) {
                //        if (action == "autoFilter") {
                //            var offset = $("#ucMasterRealgrid").position();

                //            showAutoFiltering("ucMasterRealgrid", ucMasterRealgrid_gridView, ucMasterRealgrid_dataProvider, column, x + offset.left, y + offset.top);
                //        }
                //    };
                //};
                // 

                ucMasterRealgrid.FilterCheck = function () {
                    filterCheck("ucMasterRealgrid", ucMasterRealgrid_gridView, ucMasterRealgrid_dataProvider);
                };

                ucMasterRealgrid.applyAutoFilter = function () {
                    applyAutoFilter("ucMasterRealgrid", ucMasterRealgrid_gridView);
                };

                ucMasterRealgrid.closeAutoFilter = function () {
                    closeAutoFilter("ucMasterRealgrid", ucMasterRealgrid_gridView);
                };
            }
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
                editable: true,
                commitByCell: true,
                showInnerFocus: false
            });

            gridView.setStateBar({
                visible: true
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

            if (autoFilter[grid]["realGrid_autoFilterItemsKey"][column] != undefined) {
                autoFilterItems = autoFilter[grid]["realGrid_autoFilterItemsKey"][column];
            }

            var inputvalue = document.getElementById(grid + "_filterValue").value;
            var filtervalues = null;
            if (inputvalue != '') {
                if (Array.isArray(values)) {
                    var filtervalues;
                    if (columnObj.lookupDisplay == true && columnObj.values != []) {
                        var tmpfiltervalues = columnObj.labels.filter(function (val) { return val.indexOf(inputvalue) >= 0; });

                        for (i = 0; i < tmpfiltervalues.length; i++) {
                            filtervalues.push(columnObj.valuse[columnObj.labels.indexOf(tmpfiltervalues[i])]);
                        }
                    } else {
                        filtervalues = values.filter(function (val) { return val.indexOf(inputvalue) >= 0; });
                    }
                }

                if (filtervalues != null && filtervalues.length > 0) {
                    values = filtervalues;
                }
            }

            values.forEach(function (v) {
                var label = $("<label />").appendTo(span);

                var existsFilter = autoFilterItems.indexOf(v) >= 0;

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
                hidden: true
            };

            gridView.addColumnFilters(autoFilter[grid]["autoFiltercolumn"], filters, true);

            if (autoFilter[grid]["realGrid_autoFilterItemsKey"][autoFilter[grid]["autoFiltercolumn"]].length == 0) {
                gridView.activateAllColumnFilters(autoFilter[grid]["autoFiltercolumn"], false);
            }

            $("#ucMasterRealgrid_divAutoFilter").hide();
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

        // #region 필터 체크
        function filterCheck(grid, gridView, dataProvider) {
            if (autoFilter[grid]["realGrid_autoFiltercolumn"] != null) {

                if (autoFilter[grid]["realGrid_autoFilterItemsKey"][autoFilter[grid]["realGrid_autoFiltercolumn"]] != undefined) {
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
        //#endregion
        //#endregion
        //#endregion

        //#region 컬럼 설정
        var setColumnLayout = function () {
            var items = {};
            items.LANGID = XSSReplace($("[id$=hidLangID]").val(), 1); // 언어
            items.CMCDTYPE = "CM_QUALITEM";
            items.USEYN = "Y";
            items.ITEMTYPE = "'PROD'";

            var param = {};
            param.bizID = "BR_IM_COM_GET_PROD_CLCTITEM";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = 'OUTDATA';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            GridShowLoading();
            sendRequestMethod(function callback(id, data, message, status) {
                if (data != undefined || data != null) {
                    var fields = JSON.parse(JSON.stringify(vMasterRealgridFields));
                    var columns = JSON.parse(JSON.stringify(vMasterRealgridColumns));

                    data.forEach(function (value, index, array) {
                        var vGroupWidth = 0;
                        var masterColumns = [];

                        fields.push({ fieldName: value.CLCTITEM });
                        fields.push({ fieldName: value.CLCTITEM + "#" + "ROW", dataType: "number" });
                        fields.push({ fieldName: value.CLCTITEM + "#" + "UPPER", dataType: "number" });

                        masterColumns.push(setColumn("logic", value.CLCTITEM, value.CLCTITEM, { type: true }));
                        masterColumns.push(setColumn("number_editable", value.CLCTITEM + "#" + "ROW", "<%=lang.word["Lower Limit"]%>", { type: true }));
                        masterColumns.push(setColumn("number_editable", value.CLCTITEM + "#" + "UPPER", "<%=lang.word["Upper Limit"]%>", { type: true }));

                        masterColumns.forEach(function (column) {
                            vGroupWidth += column.width;
                        });

                        columns.push({
                            type: "group",
                            name: "Confirm",
                            header: value.CLCTNAME,
                            width: vGroupWidth,
                            columns: masterColumns
                        });
                    });

                    ucMasterRealgrid_dataProvider.setFields(fields);
                    ucMasterRealgrid_gridView.setColumns(columns);
                    ucMasterRealgrid_gridView.commit(true);
                    setFilterColumns(vRealgridFilterColumns);

                    GetMasterData();
                }
            }, param, "GET", url);
        }
        //#endregion

        //#region 조회
        function GetMasterData() {
            setClear();

            var items = {};
            items.LANGID = XSSReplace($("[id$=hidLangID]").val(), 1); // 언어
            var MTRLTYPE = 'PROD';

            if ($("[id$=hidMTRLTYPE]").val() == 'RAW') {
                MTRLTYPE = $("[id$=hidMTRLTYPE]").val();
            }
            items.PRODTYPE = MTRLTYPE;

            var param = {};
            param.bizID = "BR_IM_GET_PROD_PRODUCTPROCESSQUALSPEC";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = 'OUTDATA';
            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            GridShowLoading();
            sendRequestMethod(function callback(id, dataItems, message, status) {
                if (dataItems.length > 0) {
                    ucMasterRealgrid_dataProvider.fillJsonData(dataItems, { fillMode: "set" });

                    setTotalCount([$("#ucMasterTotalConunt"), ucMasterRealgrid.GetRowCount()]);

                    var columnNames = ucMasterRealgrid_gridView.getColumnNames(false).filter(function (name) {
                        return vMasterRealgridFields.filter(function (field) { return field.fieldName == name }).length == 0;
                    });

                    for (var idx = 0; idx < ucMasterRealgrid.GetRowCount(); idx++) {
                        ucMasterRealgrid_gridView.setCellStyles(idx, columnNames, "EditCellStyle", true);
                    }

                    GetData();
                } else {
                    GridCloseLoading();
                }
            }, param, "GET", url);
        }

        function GetData() {
            var items = {};
            items.LANGID = XSSReplace($("[id$=hidLangID]").val(), 1); // 언어

            var param = {};
            param.bizID = "BR_IM_COM_GET_PROD_CLCTITEM_SPEC";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = 'OUTDATA';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";
            sendRequestMethod(function callback(id, dataItems, message, status) {
                if (dataItems.length > 0) {
                    var dataArray = ucMasterRealgrid_dataProvider.getJsonRows(0, -1);

                    for (var i = 0; i < dataArray.length; i++) {
                        var dataArrayData = $.grep(dataItems, function (el, l) {
                            return el.ATTRIBUTE4 == dataArray[i].PRODID;
                        });

                        for (var j = 0; j < dataArrayData.length; j++) {
                            var data = dataArrayData[j];
                            var RowValues = data.ATTRIBUTE1;
                            var UpperValue = data.ATTRIBUTE2;
                            var CLCITEM = data.ATTRIBUTE5;

                            ucMasterRealgrid_dataProvider.setValue(i, CLCITEM + '#' + 'ROW', RowValues);
                            ucMasterRealgrid_dataProvider.setValue(i, CLCITEM + '#' + 'UPPER', UpperValue);
                        }
                        ucMasterRealgrid_dataProvider.setRowState(i, "none", false);
                    }
                    ucMasterRealgrid_gridView.commit(true);

                    // 필터 설정
                    setFilterActionClicked();
                    // 
                }

                GridCloseLoading();
            }, param, "GET", url);
        }
        //#endregion

        // #region validation
        var validation = function (type) {
            var vReturn = false;

            switch (type) {
                case "updatedRows":  // 수정 된 데이터 여부 확인
                    if (ucMasterRealgrid_dataProvider.getStateRows('updated').length <= 0) {
                        xAlert('<%=lang.message["9019"]%>');

                        vReturn = true;
                    }
                    break
            }

            return vReturn;
        }
        //#endregion

        //#region 저장
        var save = function () {
            var param = {};
            var items = [];
            var NCRItems = [];
            var subItems = [];
            var prodList = "";

            var columnNames = $.grep(ucMasterRealgrid_gridView.getColumnNames(false), function (col) {
                return col.indexOf("#") > -1;
            });

            let cnt = 0;
            for (var i = 0; i < ucMasterRealgrid_dataProvider.getStateRows('updated').length; i++) {
                var index = ucMasterRealgrid_dataProvider.getStateRows('updated')[i];
                var PRODID = ucMasterRealgrid_dataProvider.getValue(index, "PRODID");

                prodList += ((i == 0 ? "'" : ",'") + PRODID + "'");

                for (var j = 0; j < columnNames.length; j++) {
                    if (columnNames[j].indexOf("#ROW") > -1) {

                        var CMCODE = PRODID + '#' + columnNames[j].split('#')[0];
                        var ColValue = ucMasterRealgrid_dataProvider.getValue(index, columnNames[j]);

                        NCRItems[cnt++] = [
                            { name: "CMCODE", value: CMCODE, dataType: _DataType.String }
                            , { name: "PRODID", value: PRODID, dataType: _DataType.String }
                            , { name: "CLCTITEM", value: columnNames[j].split('#')[0], dataType: _DataType.String }
                            , { name: "CMCODE_TYPE", value: 'ROW', dataType: _DataType.String }
                            , { name: "CMCODE_VALUE", value: ColValue, dataType: _DataType.String }

                        ];
                    } else if (columnNames[j].indexOf("#UPPER") > -1) {
                        var CMCODE = PRODID + '#' + columnNames[j].split('#')[0];
                        var ColValue = ucMasterRealgrid_dataProvider.getValue(index, columnNames[j]);
                        NCRItems[cnt++] = [
                            { name: "CMCODE", value: CMCODE, dataType: _DataType.String }
                            , { name: "PRODID", value: PRODID, dataType: _DataType.String }
                            , { name: "CLCTITEM", value: columnNames[j].split('#')[0], dataType: _DataType.String }
                            , { name: "CMCODE_TYPE", value: 'UPPER', dataType: _DataType.String }
                            , { name: "CMCODE_VALUE", value: ColValue, dataType: _DataType.String }
                        ];
                    }
                }
            }

            var Dataitems = [];

            for (var i = 0; i < NCRItems.length; i++) {

                if (Dataitems.length <= 0) {
                    Dataitems.push({
                        CMCODE: NCRItems[i][0].value
                        , PRODID: NCRItems[i][1].value
                        , CLCTITEM: NCRItems[i][2].value
                        , ATTRIBUTE1: NCRItems[i][4].value // 하한값
                        , ATTRIBUTE2: ''
                    });
                } else {
                    var dataArrayData = $.grep(Dataitems, function (el, l) {
                        return el.CMCODE == NCRItems[i][0].value;
                    });

                    if (dataArrayData.length <= 0) {
                        Dataitems.push({
                            CMCODE: NCRItems[i][0].value
                            , PRODID: NCRItems[i][1].value
                            , CLCTITEM: NCRItems[i][2].value
                            , ATTRIBUTE1: NCRItems[i][4].value
                            , ATTRIBUTE2: ''
                        });
                    } else {
                        dataArrayData[0].ATTRIBUTE2 = NCRItems[i][4].value;//상한값
                    }
                }
            }

            Dataitems.forEach(function (value, index, array) {

                subItems[index] = [
                    { name: "CMCDTYPE", value: 'CM_QUALITEM_SPEC', dataType: _DataType.String }
                    , { name: "CMCODE", value: value.CMCODE, dataType: _DataType.String } // 검사항목
                    , { name: "ATTRIBUTE1", value: value.ATTRIBUTE1, dataType: _DataType.String } // 하한값
                    , { name: "ATTRIBUTE2", value: value.ATTRIBUTE2, dataType: _DataType.String } // 상한값
                    , { name: "ATTRIBUTE4", value: value.PRODID, dataType: _DataType.String } // 제품코드
                    , { name: "ATTRIBUTE5", value: value.CLCTITEM, dataType: _DataType.String } // 검사항목
                    , { name: "USERID", value: '<%=SSUser.UserID%>', dataType: _DataType.String } // USERID
                   ];

               });

            //나눠서 저장한다.
            let divCnt = 500;
            let s = parseInt(subItems.length / divCnt);
            let r = subItems.length % divCnt;
            let saveItems = [];
            let saveCnt = 0;
            let loopCnt = 0;
            let saveCheck = false;
            if (s > 0) {
            
                let cnt = 1;
                if (r > 0) {
                    s = s + 1;
                }
            
                for (var i = 0; i < s; i++) {
                    saveItems.push(subItems.slice((divCnt * i), divCnt * cnt++));
                    saveCnt++;
                }
            
            } else {
                saveItems.push(subItems);
                saveCnt++;
            }
            
            GridShowLoading();

            for (var i = 0; i < saveItems.length; i++) {
                param.bizID = "BR_IM_REG_ABNORMAL_CLCTITEM_COMMONCODE";
                items[0] = saveItems[i];
            
                var url = "/GMES_IM_POM/GMES_IMES_0560_03.aspx/ExecuteData";
                param.items = items;
                param.inTableNames = 'INDATA';
                param.outTableNames = '';
                    
                sendRequestMethod(function (targetID, data, message, status) {
                    loopCnt++;
                    if (saveCnt === loopCnt && saveCheck === false) {
                        saveCheck = true;
                        if (data.length > 0) {
                            if (data[0].RETURN === 'OK') {
                                IS_SAVE = true;

                                var items = {};
                                items.LANGID = XSSReplace($("[id$=hidLangID]").val(), 1);
                                items.SHOPID = XSSReplace($("[id$=hidShopID]").val(), 1);
                                items.AREAID = XSSReplace($("[id$=hidAREAID]").val(), 1);
                                items.PRODID_LIST = prodList;

                                var param = {};
                                param.bizID = "DA_IM_STK_SEL_RACK_ABNORMAL_CONFIRM";
                                param.items = items;
                                param.inTableNames = 'RQSTDT';
                                param.outTableNames = 'RSLTDT';

                                var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

                                sendRequestMethod(function (targetID, data, message, status) {
                                    if (data.length > 0) {
                                        var prodList = "";

                                        for (var i = 0; i < data.length; i++) {
                                            prodList += ((i == 0 ? "'" : ",'") + data[i].PRODID + "'");
                                        }

                                        var title = "<%=lang.word["Action plan"]%>";
                                        var param = "";

                                        param += "&AREAID=" + XSSReplace($("[id$=hidAREAID]").val(), 1);
                                        param += "&PRODIDLIST=" + prodList;

                                        ShowPopup("../GMES_IM_POM/GMES_IMES_0560_06.aspx?MENU_ID=" + XSSReplace($("[id$=hidMenuID]").val(), 1) + param, "1000", Math.floor(window.innerHeight), title, function (v) {
                                            if (v) {
                                                xAlert('<%=lang.message["20014"]%>');
                                            }
                                            GetMasterData();
                                        });
                                    } else {
                                        xAlert('<%=lang.message["10004"]%>');
                                        GetMasterData();
                                    }
                                }, param, "POST", url);
                            }
                        }
                    }
            
                }, param, "POST", url);
            }
        }
        //#endregion

        //#region 버튼클릭
        function buttonCheck(id) {
            try {
                switch (id) {
                    case "btnSave"://저장
                        ucMasterRealgrid_gridView.commit(true);

                        if (!validation("updatedRows")) {
                            xConfirm('<%=lang.message["10073"]%>', function (parm) { if (parm) { save(); } });
                        }
                        break;
 
                    case "btnClose"://닫기
                        if (IS_SAVE == true) {
                            parent.CallBackCloseDialog(true);
                        } else {
                            parent.CallBackCloseDialog(false);
                        }
                        break;
 
                    default:
                }
            } catch (e) {
                xAlert(e.message);
            }
        }
        //#endregion

        // #region 데이터 초기화
        function setClear() {
            if (!onNullCheck(ucMasterRealgrid_dataProvider) && !onNullCheck(ucMasterRealgrid_gridView)) {
                ucMasterRealgrid_dataProvider.clearRows();
                ucMasterRealgrid_gridView.orderBy([], []); /*순서 초기화*/
                var ucMasterRealgridAutoFilter = autoFilter["ucMasterRealgrid"];

                if (!onNullCheck(ucMasterRealgridAutoFilter)) {
                    ucMasterRealgridAutoFilter["realGrid_autoFilterItemsKey"] = [];

                    ucMasterRealgridAutoFilter["realGrid_autoFilterColumns"].forEach(function (v) {
                        ucMasterRealgrid_gridView.activateAllColumnFilters(ucMasterRealgrid_gridView.columnByField(v), false);
                    });

                    $("#ucMasterRealgrid_divAutoFilter").hide();
                }
            }

            setTotalCount([$("#ucMasterTotalConunt"), 0]);
        }
        // #endregion

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

        // #region Loading
        function GridShowLoading() {
            $("#LoadingPanel").show();
        }

        function GridCloseLoading() {
            $("#LoadingPanel").hide();
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
    <form id="form1" runat="server">
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidMenuID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidMTRLTYPE" runat="server" />
        <asp:HiddenField ID="hidTITLE" runat="server" />
        <asp:HiddenField ID="hidAREAID" runat="server" />
        
        <div id="divMasterContent">
            <div id="div_ButtonArea" class="buttonArea" style="padding:0px 10px 0px 10px;">
                <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucMasterTotalConunt" class='red01'>0</span> Found )</div>
                <ul runat="server" class="btn_crud">
                    <li><a class="save" id="btnSave" onclick="buttonCheck(this.id)"><span><%=lang.word["Save"]%></span></a></li> <!--저장 -->
                    <li><a class="close" id="btnClose" onclick="buttonCheck(this.id)"><span><%=lang.word["Close"]%></span></a></li>
                    <li><a class="table_bar"></a></li>
                    <li><a class="excel" onclick="onExcelButtonClick(ucMasterRealgrid, ucMasterRealgrid_gridView)"></a></li>
                </ul>
            </div>

            <div>
                <div id="divMasterGrid" class="table">
                    <uc:Realgrid ID="ucMasterRealgrid" CALLID="ucMasterRealgrid" runat="server" HEIGHT="200" />
                    <div id="LoadingPanel" class="modal"></div>       
                </div>
            </div>
        </div>
    </form>
</asp:Content>