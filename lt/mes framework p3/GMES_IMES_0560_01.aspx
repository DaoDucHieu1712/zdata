<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPopup.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0560_01.aspx.cs" Inherits="GMES_IMES_0560_01" %>
<%--/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0560_01.aspx
* @desc    : 생산실적 - 이상품 추적 - 투입List 작성
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2024/10/13   송상호              INIT
* 1.1  2025/07/14   오정균              위,아래 버튼 추가("20250714" 날짜 표기)
* 1.2  2025/07/31   오정균              요구 사항으로 인한 전체 수정
*************************************************************************************************
*/--%>

<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>

<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <style>
        .th_fix {
            width : 100px;
            max-width: 100px;
        }
        .td_fix {
            width: 200px;
            max-width: 200px;
        }
        .displayBlock{
            display:block;
        }
        .custom-li {
            height: 27px;
            display: flex; /* Flexbox 사용 */
            align-items: center; /* 수직 가운데 정렬 */
            justify-content: center; /* 수평 가운데 정렬 */
            list-style-type: none; /* 기본 리스트 스타일 제거 */
        }
        .hidden {
            display: none;
        }
    </style>

    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js?v=<%=DateTime.Now.ToString("yyyyMMddHHmmss")%>"></script>
    <script type="text/javascript" language="javascript">
        //#region 변수
        // grid
        const cQtyFormat = "#,##0.000";  /*수량 소수점 3자리X*/
        const defaultBorder = "#808080, 1";
        // grid

        /*
         1) S : 단독
         2) D : 분산
         3) ETC : 그 외

         - data: 배치, CALDATE
         - sortBatchType: 정렬 중심 여부
         - sortBatchData: 정렬한 데이터
         - sortBatchNumberID: number ID
         - sortBatchNumber: number
         - cellDynamicStyles: realGrid cellDynamicStyles
         */
        var batchList = {
            "S": {
                data: [],
                sortBatchType: [true, "D"],
                sortBatchData: [],
                sortBatchNumberID: "num_single",
                sortBatchNumber: 1,
                cellDynamicStyles: {
                    criteria: "values['SINGLE_INPUT_YN'] = 'S'",
                    styles: {
                        background: "#D2EAAE"
                    }
                }
            },
            "D": {
                data: [],
                sortBatchType: [false, ""],
                sortBatchData: [],
                sortBatchNumberID: "num_dispersion",
                sortBatchNumber: 1,
                cellDynamicStyles: {
                    criteria: "values['SINGLE_INPUT_YN'] = 'D'",
                    styles: {
                        background: "#FFE8BE"
                    }
                }
            },
            "ETC": []
        };
        var cellDynamicStyles = [];
        var isSortBatch = false; // 배치정렬 처리 여부
        let legacyEqutID = "";
        //#endregion

        $(document).ready(function () {
            GridShowLoading();
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
            InitSetting();
            setInitSelectCom();/*조회조건 콤보박스 초기화*/
            setSelectCom("AREA", null, XSSReplace($("[id$=hidAreaId]").val(), 1)); /*조회 조건 설정*/
            InitMainRealgrid(); // realGrid
            GetMasterData();
        }
        //#endregion

        // #region 조건에 따른 setting
        function InitSetting() {
            if (JSON.parse($("[id$=hidSingleInputYNType]").val())) { // 단독 투입 사용 여부
                $('#li_explanation').removeClass('hidden');

                cellDynamicStyles = [
                    batchList["S"]["cellDynamicStyles"],
                    batchList["D"]["cellDynamicStyles"]
                ];

                if (JSON.parse($("[id$=hidSingleDispersionType]").val())) { // 혼합 여부
                    $('#li_sortBatch').removeClass('hidden');
                } else {
                    $('#li_sortBatch').addClass('hidden');
                }
            } else {
                $('#li_explanation').addClass('hidden');
            }
        }
        //#endregion

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
            var formatter = undefined;
            var vSuccess = undefined;

            switch (vType) {
                case "AREA":
                    bizID = 'BR_IM_SEL_AREA_CBO';
                    bizInData = '&AREAID=' + vSelectValue + '&AREAIUSE=Y' + '&SHOPID=' + XSSReplace($("[id$=hidShopID]").val(), 1) + '&SHOPIUSE=Y&EQSGTYPE=LINE&USERID=' + XSSReplace($("[id$=hidUserID]").val(), 1);
                    vCbo = $('#cboArea');
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
                    bizInData = '&AREAID=' + vRecord.areaId + '&SHOPID=' + XSSReplace($("[id$=hidShopID]").val(), 1) + '&PDGRID=' + vSelectValue + '&EQSGTYPE=LINE';
                    vCbo = $('#cboLine');
                    onSelect = function (row) {
                        setSelectCom("PROCESSSEGMENT", { areaId: vRecord.areaId }, row.EQSGID);
                    };
                    break
                case "PROCESSSEGMENT":
                    bizID = 'DA_IM_BAS_SEL_PCSGID_BY_EQSGID';
                    bizInData = '&AREAID=' + vRecord.areaId + '&EQSGID=' + vSelectValue + '&SHOPID=' + XSSReplace($("[id$=hidShopID]").val(), 1) + '&EQSGIUSE=Y&PROCIUSE=Y&AREAIUSE=Y&SHOPIUSE=Y&PCSGIUSE=Y';
                    vCbo = $('#cboProcessSegment');
                    vSuccess = function (data) {
                        data.forEach(function (v) {
                            if (!onNullCheck(v.CODE)) {
                                if (String(v.NAME).indexOf("[") === -1 && String(v.NAME).indexOf("]") === -1) {
                                    v.NAME = "[" + v.CODE + "]" + v.NAME;
                                }
                            }
                        });
                    }
                    onSelect = function (row) {
                        setSelectCom("PROC", { areaId: vRecord.areaId, eqsgid: vSelectValue }, row.CODE);
                    };
                    break
                case "PROC":
                    bizID = 'BR_IM_SEL_PROCESS_BY_PCSGID_CBO';
                    bizInData = '&AREAID=' + vRecord.areaId + '&EQSGID=' + vRecord.eqsgid + '&SHOPID=' + XSSReplace($("[id$=hidShopID]").val(), 1) + '&EQSGIUSE=Y&PCSGID=' + vSelectValue + '&PROCIUSE=Y&AREAIUSE=Y&SHOPIUSE=Y&PCSGIUSE=Y';
                    vCbo = $('#cboProcess');
                    onSelect = function (row) {
                        setSelectCom("EQPT", { areaId: vRecord.areaId, eqsgId: vRecord.eqsgid }, row.PROCID);
                    };
                    break
                case "EQPT":
                    bizID = 'DA_IM_BAS_SEL_EQPT_HOPPER';
                    bizInData = '&SHOPID=' + XSSReplace($("[id$=hidShopID]").val(), 1) + '&EQSGID=' + vRecord.eqsgId + '&AREAID=' + vRecord.areaId + '&PROCID=' + vSelectValue + '&MULTI_S29=' + "'INPUT','REWORK'" + '&NOT_IN_EQPTTYPE=' + "'A'";
                    vCbo = $('#cboEquipment');
                    onSelect = function (row) {
                        GET_EQUIPMENTATTR(row.CODE);
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
                                    if (!onNullCheck(vSuccess)) {
                                        vSuccess(data); // [코드] 처리.
                                    }
                                    success(data);
                                },
                                error: function () {
                                    error.apply(this, arguments);
                                }
                            });
                        },
                        url: vUrl + bizID + '&LANGID=' + XSSReplace($("[id$=hidLangID]").val(), 1) + bizInData + '&CBOOPT=' + cboOptions.cBoopt + '|' + cboOptions.valueField + '|' + cboOptions.textField,
                        onLoadSuccess: onLoadSuccess,
                        onSelect: function (row) {
                            if (!onNullCheck(onSelect)) {
                                onSelect(row);
                            }
                        },
                        formatter: formatter
                    });
                } else {
                    setInitCom(vCbo, cboOptions);
                }
            }
        }

        var GET_EQUIPMENTATTR = function (eqptid) {
            var items = {};
            items.EQPTID = eqptid;
            var param = {};
            param.bizID = "DA_IM_BAS_SEL_EQUIPMENTATTR_TBL";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = 'OUTDATA';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";
            sendRequestMethod(function callback(id, dataItems, message, status) {
                legacyEqutID = "";
                if (dataItems.length > 0) {
                    legacyEqutID = dataItems[0].S33;
                }
            }, param, "GET", url);
        }
        // #endregion

        //#region realGrid
        //#region Main Realgrid Field, Column 설정
        const dynamicStyles = [
            {
                criteria: "values['WHTYPE'] = 'L20'",
                styles: {
                    "foreground": "#ff0000"
                }
            }
        ];

        var ucMainRealgridFields = [
            { fieldName: "WHTYPE", columnSetting: { type: "logic", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "WHTYPE" } },
            { fieldName: "PRODTYPE_CD", columnSetting: { type: "logic", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "PRODTYPE_CD" } },
            { fieldName: "SINGLE_INPUT_YN", columnSetting: { type: "logic", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "SINGLE_INPUT_YN" } },
            { fieldName: "MLOTDTTM", columnSetting: { type: "logic", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "MLOTDTTM" } },

            { fieldName: "PLOTID_USER", columnSetting: { type: "main_lotid", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["Batch"]%>" } },
            { fieldName: "BAGNO", columnSetting: { type: "main_data", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["BAG NO"]%>" } },
            { fieldName: "LOTIDUSER", columnSetting: { type: "main_lotid", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["LOTIDUSER"]%>" } },
            { fieldName: "WHNAME_PV", columnSetting: { type: "main_name", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["WHNAME"]%>" } },
            { fieldName: "WHNAME", columnSetting: { type: "main_name", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["RACK NO"]%>" } },
            { fieldName: "PRODID", columnSetting: { type: "main_id", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["PRODID"]%>" } },
            { fieldName: "PRODNAME", columnSetting: { type: "logic", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["PRODNAME"]%>" } },
            { fieldName: "WIPQTY", columnSetting: { type: "main_qty", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["WIPQTY"]%>" } },
            { fieldName: "POSS_INPUT", columnSetting: { type: "main", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["Available Input"]%>" } },
            {
                type: "group",
                name: "Confirm",
                header: "<%=lang.word["SinglePrimaryBurning_P"]%>",
                columns: [
                    { fieldName: "LINE_LINE", columnSetting: { type: "main_data", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["LINE"]%>", endColumn: false } },
                    { fieldName: "LINE_MAKER_LI", columnSetting: { type: "main_data", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["PRECURSOR"]%>", endColumn: false } },
                    { fieldName: "LINE_MAKER_MOOH", columnSetting: { type: "main_data", mergeRule: {}, mergeType: false, dynamicStyles: [], header: "<%=lang.word["Lithium"]%>", endColumn: true } }
                ]
            },
            {
                type: "group",
                name: "Confirm",
                header: "<%=lang.word["Manufacturer"]%>",
                columns: [
                    { fieldName: "MOOH_MAKERID", columnSetting: { type: "main_data", mergeRule: {}, mergeType: false, dynamicStyles: [],  header: "<%=lang.word["PRECURSOR"]%>", endColumn: false } },
                    { fieldName: "LI_MAKERID", columnSetting: { type: "main_data", mergeRule: {}, mergeType: false, dynamicStyles: [],  header: "<%=lang.word["Lithium"]%>", endColumn: true } }
                ]
            },
            { fieldName: "WHTYPE_OUTGOING", columnSetting: { type: "main", mergeRule: {}, mergeType: false, dynamicStyles: dynamicStyles,  header: "<%=lang.word["Waiting warehouse for input"]%>" + "\n" + "<%=lang.word["exists or not"]%>" } }
        ];
        //#endregion

        //#region 컬럼 타입 별 기준 정보 변경
        var setTypeColumn = function (vType, vColumn) {
            switch (vType) {
                case "logic":
                    vColumn.visible = false;
                    break
                case "main_name":
                    vColumn.width = 200;
                    break
                case "main_qty":
                    vColumn.numberFormat = cQtyFormat;
                    vColumn.width = 100;
                    break
                case "main_data":
                    vColumn.width = 100;
                    break
                case "main_id":
                case "main_lotid":
                    vColumn.width = 200;
                    break
            }

            return vColumn;
        }
        //#endregion

        //#region 컬럼 설정
        var setColumn = function (vType, vFieldName, vHeader, vMergeRule, mergeType, isGroup, dynamicStyle) {
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
                width: 150,
                dynamicStyles: dynamicStyle
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
            var fields = [];
            var columns = [];

            ucMainRealgridFields.forEach(function (a) {
                var vGroupWidth = 0;
                var masterColumns = [];

                if (a.type == "group") {
                    a.columns.forEach(function (b) {
                        fields.push({ fieldName: b.fieldName, dataType: onNullCheck(b.dataType) ? 'text' : b.dataType });
                        var column = setColumn(b.columnSetting.type, b.fieldName, b.columnSetting.header, b.columnSetting.mergeRule, b.columnSetting.mergeType, { type: true }, b.columnSetting.dynamicStyles);
                        masterColumns.push(column);
                        vGroupWidth += (column.visible) ? column.width : 0;
                    });

                    columns.push({
                        type: a.type,
                        name: a.name,
                        header: a.header,
                        width: vGroupWidth,
                        columns: masterColumns
                    });
                } else {
                    fields.push({ fieldName: a.fieldName, dataType: onNullCheck(a.dataType) ? 'text' : a.dataType });
                    columns.push(setColumn(a.columnSetting.type, a.fieldName, a.columnSetting.header, a.columnSetting.mergeRule, a.columnSetting.mergeType, { type: false }, a.columnSetting.dynamicStyles));
                }
            });

            /*메뉴 ID 에 null을 등록하면 컬럼별 빼고 안빼고를 설정 할 수 없다. 일단은 NULL로 */
            ucMasterRealgrid.Init(null, fields, columns, true, true, true);
            realGridSet(ucMasterRealgrid_gridView, true);

            ucMasterRealgrid_gridView.setStyles({
                body: {
                    cellDynamicStyles: cellDynamicStyles
                }
            });

            ucMasterRealgrid_dataProvider.onRowMoved = function (provider, row, newRow) {
                ucMasterRealgrid_gridView.checkRow(row, false, false);
                ucMasterRealgrid_gridView.checkRow(newRow, true, false);
            };
        }

        function realGridSet(gridView, isGroup) {
            gridView.setOptions({
                edit: { insertable: true, appendable: true }
                , softDeleting: true
                , deleteCreated: true
                , hideDeletedRows: true
            });

            gridView.setSortingOptions({ enabled: false });

            gridView.setEditOptions({
                editable: false,
                commitByCell: true,
                showInnerFocus: false
            });

            gridView.setStateBar({
                visible: false
            });

            gridView.setCheckBar({
                showAll: false,
                visible: true
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

        // #region validation
        var validation = function (type, value, label) {
            var msg = "<%=lang.message["25062"]%>";
            var vReturn = false;

            switch (type) {
                case "number":
                    if (onZeroCheck(value)) {
                        msg = msg.replace("%1", label);
                        xAlert(msg);

                        vReturn = true;
                    }
                    break
                case "checkRows":  // 선택 된 데이터 여부 확인
                    if (ucMasterRealgrid_gridView.getCheckedRows().length <= 0) {
                        xAlert('<%=lang.message["10008"]%>');

                        vReturn = true;
                    }
                    break
                case "checkSortBatch":  // 배치 정렬 사용 여부
                    if (!value) {
                        msg = "<%=lang.message["20029"]%>";
                        msg = msg.replace("%1", label);

                        xAlert(msg);

                        vReturn = true;
                    }
                    break
            }

            return vReturn;
        }
        //#endregion

        // #region BagNo 처리
        var SetBagNo = function (array, BAGNO) {
            if (array == undefined) { return; }

            switch (BAGNO) {
                case "1":
                    array.BAGNO_01 = BAGNO;
                    break;
                case "2":
                    array.BAGNO_02 = BAGNO;
                    break;
                case "3":
                    array.BAGNO_03 = BAGNO;
                    break;
                case "4":
                    array.BAGNO_04 = BAGNO;
                    break;
                case "5":
                    array.BAGNO_05 = BAGNO;
                    break;
                case "6":
                    array.BAGNO_06 = BAGNO;
                    break;
                case "7":
                    array.BAGNO_07 = BAGNO;
                    break;
                case "8":
                    array.BAGNO_08 = BAGNO;
                    break;

                default:
            }

            return array;
        }
        //#endregion

        //#region Report
        var GetReport = function () {
            var param = {};
            var items = [];
            var schitems = [];
            var reportNm = "AbnormalInputReport";
            var reportfileNm = "AbnormalInputReport.xml";

            let PLOTID_USER_LIST = [];
            var dataArray = ucMasterRealgrid_dataProvider.getJsonRows(0, -1);

            dataArray.forEach(function (item, idx, array) {
                let PLOTID_USER = ucMasterRealgrid_gridView.getValue(idx, 'PLOTID_USER');
                // 20250813
                let SINGLE_INPUT_YN = ucMasterRealgrid_gridView.getValue(idx, 'SINGLE_INPUT_YN');
                // 20250813
                let BAGNO = ucMasterRealgrid_gridView.getValue(idx, 'BAGNO');
                if (PLOTID_USER_LIST.length <= 0) {
                    PLOTID_USER_LIST.push({ LOTID: PLOTID_USER, BAGNO_01: null, BAGNO_02: null, BAGNO_03: null, BAGNO_04: null, BAGNO_05: null, BAGNO_06: null, BAGNO_07: null, BAGNO_08: null, BAGNO_09: null, BAGNO_10: null, INOUT: null, SINGLE_INPUT_YN: SINGLE_INPUT_YN });
                    SetBagNo(PLOTID_USER_LIST[0], BAGNO);
                } else {
                    if (PLOTID_USER_LIST[PLOTID_USER_LIST.length - 1].LOTID != PLOTID_USER) {
                        PLOTID_USER_LIST.push({ LOTID: PLOTID_USER, BAGNO_01: null, BAGNO_02: null, BAGNO_03: null, BAGNO_04: null, BAGNO_05: null, BAGNO_06: null, BAGNO_07: null, BAGNO_08: null, BAGNO_09: null, BAGNO_10: null, INOUT: null, SINGLE_INPUT_YN: SINGLE_INPUT_YN });
                    }
                    SetBagNo(PLOTID_USER_LIST[PLOTID_USER_LIST.length - 1], BAGNO);
                }
            });

            PLOTID_USER_LIST.forEach(function (value, idx, array) {
                items[idx] = [
                    { name: "LOTID", value: PLOTID_USER_LIST[idx].LOTID }
                    , { name: "BAGNO_01", value: PLOTID_USER_LIST[idx].BAGNO_01 }
                    , { name: "BAGNO_02", value: PLOTID_USER_LIST[idx].BAGNO_02 }
                    , { name: "BAGNO_03", value: PLOTID_USER_LIST[idx].BAGNO_03 }
                    , { name: "BAGNO_04", value: PLOTID_USER_LIST[idx].BAGNO_04 }
                    , { name: "BAGNO_05", value: PLOTID_USER_LIST[idx].BAGNO_05 }
                    , { name: "BAGNO_06", value: PLOTID_USER_LIST[idx].BAGNO_06 }
                    , { name: "BAGNO_07", value: PLOTID_USER_LIST[idx].BAGNO_07 }
                    , { name: "BAGNO_08", value: PLOTID_USER_LIST[idx].BAGNO_08 }
                    , { name: "BAGNO_09", value: PLOTID_USER_LIST[idx].BAGNO_09 }
                    , { name: "BAGNO_10", value: PLOTID_USER_LIST[idx].BAGNO_10 }
                    , { name: "INOUT", value: PLOTID_USER_LIST[idx].INOUT }
                    // 20250813
                    , { name: "SINGLE_INPUT_YN", value: PLOTID_USER_LIST[idx].SINGLE_INPUT_YN }
                    // 20250813
                ];
            });

            let PRODTYPE_CD = ucMasterRealgrid_gridView.getValue(0, 'PRODTYPE_CD');

            switch (PRODTYPE_CD) {
                case "ASSY":
                    PRODTYPE_CD = "<%=lang.word["Half-Finished Goods"]%>";
                    break;
                case "GOOD":
                    PRODTYPE_CD = "<%=lang.word["Finished Goods"]%>";
                    break;
                case "RAW":
                    PRODTYPE_CD = "<%=lang.word["Raw Material"]%>";
                    break;
                default:
            }

            var EqptName = '';
            if ($('#cboEquipment').combobox('getValue') != '') {
                EqptName = $('#cboEquipment').combobox('getText');
                EqptName = legacyEqutID + "(" + EqptName.substring(EqptName.indexOf(']') + 1, EqptName.length) + ")";
            }

            var Line = '';
            if ($('#cboLine').combobox('getValue') != '') {
                Line = $('#cboLine').combobox('getText');
                Line = Line.substring(Line.indexOf(']') + 1, Line.length);
            }

            var TITLE = Line + " " + PRODTYPE_CD + " " + "<%=lang.word["input list"]%>";
            let PRODID = ucMasterRealgrid_gridView.getValue(0, 'PRODID');

            var dataArray = ucMasterRealgrid_dataProvider.getJsonRows(0, -1);
            let MOOH_MAKERID_LIST = $.grep(dataArray, function (el, l) { return el.MOOH_MAKERID != ''; });
            let LI_MAKERID_LIST = $.grep(dataArray, function (el, l) { return el.LI_MAKERID != ''; });

            var MOOH_MAKERID = '';
            var LI_MAKERID = '';
            var SUB_PRODID = '';
            var CAUTION_REMARK = $('#txtCaution').textbox('getValue');

            if (MOOH_MAKERID_LIST.length > 0) {
                MOOH_MAKERID = MOOH_MAKERID_LIST[0].MOOH_MAKERID;
            }

            if (LI_MAKERID_LIST.length > 0) {
                LI_MAKERID = LI_MAKERID_LIST[0].LI_MAKERID;
            }

            if (MOOH_MAKERID != '' && LI_MAKERID != '') {
                SUB_PRODID = "(" + MOOH_MAKERID + "/" + LI_MAKERID + ")";
            } else {
                if (MOOH_MAKERID != '') {
                    SUB_PRODID = "(" + MOOH_MAKERID + ")";
                }

                if (LI_MAKERID != '') {
                    SUB_PRODID = "(" + LI_MAKERID + ")";
                }
            }

            schitems[0] = [
                { name: "TITLE", value: TITLE }
                , { name: "PRODID", value: PRODID + SUB_PRODID }
                , { name: "CAUTION", value: "<%=lang.word["Caution Item"]%>" }
                , { name: "CAUTION_REMARK", value: CAUTION_REMARK }
                , { name: "EQPTNAME", value: EqptName }
                // 20250819 신규 추가
                , { name: "SINGLE", value: (JSON.parse($("[id$=hidSingleInputYNType]").val()) ? "<%=lang.word["single"]%>" : "") }
                , { name: "GUBN", value: (JSON.parse($("[id$=hidSingleInputYNType]").val()) ? "/" : "") }
                , { name: "DISPERSION", value: (JSON.parse($("[id$=hidSingleInputYNType]").val()) ? "<%=lang.word["dispersion"]%>" : "") }
                , { name: "TYPE", value: "" }
                // 20250819
            ];

            param.fileName = reportfileNm;
            param.reportName = reportNm;
            param.schitems = schitems;
            param.bizID = '';
            param.items = items;
            param.inTableNames = '';
            param.outTableNames = '';

            var url = "/ReportService.asmx/GetReport";

            sendRequestMethod(function (data) {
                ShowWinPopup_Center('/ReportDownloadHandler.ashx?tmpFileNM=' + data[0].data, "Report View", '800', '600');
            }, param, "POST", url);
        };
        //#endregion

        //#region 버튼클릭
        function buttonCheck(id) {
            try {
                switch (id) {
                    case "btnPrint"://출력
                        var validation_type = true;

                        if (JSON.parse($("[id$=hidSingleDispersionType]").val())) { // 혼합 여부
                            if (validation("checkSortBatch", isSortBatch, "<%=lang.word["Sort by Batch"]%>")) { // 홉합일 경우에만 배치정렬을 한번이라도 처리 후에 출력 가능.
                                validation_type = false;
                            }
                        }

                        if (validation_type) {
                            GetReport();
                        }
                        break;
                    case "btnSortBatch"://배치정렬
                        var validation_type = true;

                        if (validation("number", $('#num_single').val(), "<%=lang.word["single"]%>")) {
                            validation_type = false;
                        }

                        if (validation("number", $('#num_dispersion').val(), "<%=lang.word["dispersion"]%>")) {
                            validation_type = false;
                        }

                        if (validation_type) {
                            GridShowLoading();
                            isSortBatch = true; // 배치 정렬 처리 여부

                            var sortBatchStartSingleInputYN = "";

                            for (const key in batchList) {
                                if (key != "ETC") { // ETC는 그 외
                                    var list = ucMasterRealgrid_dataProvider.getJsonRows(0, -1).filter(function (itemValue, index, array) {
                                        return key == itemValue.SINGLE_INPUT_YN;
                                    });

                                    batchList[key]["sortBatchData"] = [];

                                    batchList[key]["data"].forEach(function (v) {
                                        list.filter(function (value) {
                                            return v.batch == value.PLOTID_USER;
                                        }).sort(function (a, b) {
                                            return (a.BAGNO - b.BAGNO);
                                        }).forEach(function (item) {
                                            batchList[key]["sortBatchData"].push(item);
                                        });
                                    });

                                    batchList[key]["sortBatchNumber"] = $('#' + batchList[key]["sortBatchNumberID"]).val();

                                    if (batchList[key]["sortBatchType"][0]) {
                                        sortBatchStartSingleInputYN = key;
                                    }
                                }
                            }

                            var realGridList = [];
                            var sortBatchStartData = batchList[sortBatchStartSingleInputYN];
                            var sortBatchEndData = batchList[batchList[sortBatchStartSingleInputYN]["sortBatchType"][1]];

                            var sortBatchStartNumber = parseInt(sortBatchStartData["sortBatchNumber"]);
                            var endBatchStartNumber = 0;

                            for (var i = 0; i < sortBatchStartData["sortBatchData"].length; i++) {
                                if (i == sortBatchStartNumber) {
                                    if (sortBatchEndData["sortBatchData"].length > 0) {
                                        for (var j = endBatchStartNumber; j < (endBatchStartNumber + parseInt(sortBatchEndData["sortBatchNumber"])); j++) {
                                            if (!onNullCheck(sortBatchEndData["sortBatchData"][j])) {
                                                realGridList.push(sortBatchEndData["sortBatchData"][j]);
                                            }
                                        }
                                        endBatchStartNumber += parseInt(sortBatchEndData["sortBatchNumber"]);
                                    }
                                    sortBatchStartNumber += parseInt(sortBatchStartData["sortBatchNumber"]);
                                }

                                realGridList.push(sortBatchStartData["sortBatchData"][i]);

                                if (i == (sortBatchStartData["sortBatchData"].length - 1)) {
                                    if (endBatchStartNumber < sortBatchEndData["sortBatchData"].length) {
                                        for (var j = endBatchStartNumber; j < sortBatchEndData["sortBatchData"].length; j++) {
                                            realGridList.push(sortBatchEndData["sortBatchData"][j]);
                                        }
                                    }
                                    if (batchList["ETC"].length > 0) {
                                        batchList["ETC"].forEach(function (v) {
                                            realGridList.push(v);
                                        });
                                    }
                                }
                            }

                            if (realGridList.length > 0) {
                                ucMasterRealgrid_dataProvider.clearRows();
                                ucMasterRealgrid_dataProvider.fillJsonData(realGridList, { fillMode: "set" });
                            }

                            GridCloseLoading();
                        }

                        break;
                    case "btnClose"://닫기
                        parent.CallBackCloseDialog();
                        break;
                    case "btnUp":
                        if (!validation("checkRows", null, null)) {
                            let chkRows = ucMasterRealgrid_gridView.getCheckedRows();

                            for (var i = 0; i < chkRows.length; i++) {
                                if (i < chkRows[i]) {
                                    ucMasterRealgrid_dataProvider.moveRow(chkRows[i], (chkRows[i] - 1));
                                }
                            }
                        }
                        break;
                    case "btnDown":
                        if (!validation("checkRows", null, null)) {
                            let chkRows = ucMasterRealgrid_gridView.getCheckedRows();

                            var count = ucMasterRealgrid.GetRowCount() - 1;
                            var index = 0;
                            for (var i = (chkRows.length - 1); i >= 0; i--) {
                                if ((count - index) > chkRows[i]) {
                                    ucMasterRealgrid_dataProvider.moveRow(chkRows[i], (chkRows[i] + 1));
                                }
                                index++;
                            }
                        }
                        break;
                }
            } catch (e) {
                xAlert(e.message);
            }
        }
        //#endregion

        //#region 조회
        function GetMasterData() {
            var param = {};
            var items = [];

            items = [
                { name: "LANGID", value: XSSReplace($("[id$=hidLangID]").val(), 1), dataType: _DataType.String },
                { name: "SHOPID", value: XSSReplace($("[id$=hidShopID]").val(), 1), dataType: _DataType.String },
                { name: "INLOTID", value: $("[id$=hidLOTID]").val(), dataType: _DataType.String }
            ];

            param.items = items;
            param.bizID = "BR_IM_STK_GET_RACK_ABNORMAL";
            param.inTableNames = 'INDATA';
            param.outTableNames = 'OUTDATA';

            var url = "/GMES_IM_POM/GMES_IMES_0560_01.aspx/GetData";

            ucMasterRealgrid.CallRequest(url, param, function () {
                setTotalCount([$("#ucMasterTotalConunt"), ucMasterRealgrid.GetRowCount()]);
                <%--CallBackMaster();--%>

                for (var idx = 0; idx < ucMasterRealgrid.GetRowCount(); idx++) {
                    var item = ucMasterRealgrid_dataProvider.getJsonRow(idx);

                    if (item.SINGLE_INPUT_YN in batchList) {
                        if (batchList[item.SINGLE_INPUT_YN]["data"].filter(function (v) { return v.batch == item.PLOTID_USER }).length === 0) {
                            batchList[item.SINGLE_INPUT_YN]["data"].push({
                                batch: item.PLOTID_USER,
                                caldate: item.MLOTDTTM
                            });
                        }
                    } else {
                        batchList["ETC"].push(item);
                    }

                    if (item.WHTYPE === 'L20') { //대기창고
                        ucMasterRealgrid_gridView.setValue(idx, "WHTYPE_OUTGOING", "<%=lang.word["Not shipped"]%>");
                    } else {
                        ucMasterRealgrid_gridView.setValue(idx, "WHTYPE_OUTGOING", "<%=lang.word["Outgoing"]%>");
                    }
                }
                for (const key in batchList) {
                    if (key != "ETC") { // ETC는 그 외
                        batchList[key]["data"].sort(function (a, b) {
                            return (new Date(a.caldate) - new Date(b.caldate))
                        });
                    }
                }

                ucMasterRealgrid_gridView.commit(true);
                GridCloseLoading();
            });
        }
        //#endregion

        // #region Loading
        function GridShowLoading() {
            $("#LoadingPanel").show();
        }

        function GridCloseLoading() {
            $("#LoadingPanel").hide();
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
        
        <asp:HiddenField ID="hidSingleInputYNType" runat="server" />
        <asp:HiddenField ID="hidSingleDispersionType" runat="server" />
        <asp:HiddenField ID="hidMenuID" runat="server" />
        <asp:HiddenField ID="hidAreaId" runat="server" />
        <asp:HiddenField ID="hidLOTID" runat="server" />
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
                            <!-- 공장동 -->
                            <th class="th_fix">
                                <label for="input_text01"><%=lang.word["Shop/Area"]%></label>
                            </th>
                            <td align="left" class="td_fix" name="cboSelect">
                                <input id="cboArea" data-options="valueField: 'AREAID',textField: 'AREANAME_ML', cBoopt: 'OPT'" class="easyui-combobox" style="width: 100%;" disabled="disabled"/>
                            </td>
                            <!-- 공장동 -->
                            <!-- 제품군 -->
                            <th class="th_fix">
                                <label for="input_text01"><%=lang.word["PROD_GROUP"]%></label>
                            </th>
                            <td align="left" class="td_fix" name="cboSelect">
                                <input id="cboGrade" data-options="valueField: 'PDGRID',textField: 'PDGRNAME', cBoopt: 'OPT'" class="easyui-combobox" style="width: 100%;" />
                            </td>
                            <!-- 제품군 -->
                            <!-- 라인실 -->
                            <th class="th_fix">
                                <label for="input_text01"><%=lang.word["Line/Equipment Seg."]%></label>
                            </th>
                            <td align="left" class="td_fix" name="cboSelect">
                                <input id="cboLine" data-options="valueField: 'EQSGID',textField: 'EQSGNAME', cBoopt: 'OPT'" class="easyui-combobox" style="width: 100%;" />
                            </td>
                            <!-- 라인실 -->
                        </tr>      
                        <tr>
                            <!-- 공정군 -->
                            <th class="th_fix">
                                <label for="input_text01"><%=lang.word["PROC_GROUP"]%></label>
                            </th>
                            <td align="left" class="td_fix" name="cboSelect">
                                <input id="cboProcessSegment" data-options="valueField: 'CODE',textField: 'NAME', cBoopt: 'OPT'" class="easyui-combobox" style="width: 100%;" />
                            </td>
                            <!-- 공정군 -->
                            <!-- 공정 -->
                            <th class="th_fix">
                                <label for="input_text01"><%=lang.word["Operation"]%></label>
                            </th>
                            <td align="left" class="td_fix" name="cboSelect">
                                <input id="cboProcess" data-options="valueField: 'PROCID',textField: 'PROCNAME', cBoopt: 'OPT'" class="easyui-combobox" style="width: 100%;" />
                            </td>
                            <!-- 공정 -->
                            <!-- 설비 -->
                            <th class="th_fix">
                                <label for="input_text01"><%=lang.word["Equipment"]%></label>
                            </th>
                            <td align="left" class="td_fix" name="cboSelect">
                                <input id="cboEquipment" data-options="valueField: 'CODE',textField: 'EQPTCODENAME', cBoopt: 'OPT'" class="easyui-combobox" style="width: 100%;" />
                            </td>
                            <!-- 설비 -->
                        </tr>      
                        <tr>
                            <!-- 주의 사항 -->
                            <th class="th_fix">
                                <label for="input_text01"><%=lang.word["Caution Item"]%></label><spen class="displayBlock" style="font-size:10px;">(<%=lang.word["Max Length"]%>(60))</spen>
                            </th>
                            <td align="left" class="td_fix" colspan="5">
                                <input id="txtCaution" class="easyui-textbox" style="width: 100%; height: 40px;" />
                            </td>
                            <!-- 주의 사항 -->
                        </tr>
                    </tbody>
                </table>
            </div>
            
            <div id="div_AddButtonArea" class="buttonArea" style="padding:10px 10px 0px 10px;">
                <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucMasterTotalConunt" class='red01'>0</span> Found )</div>
                <ul runat="server" class="btn_crud">
                    <li class="custom-li hidden" id="li_explanation">
                        <span style="color:#86C02E; font-weight: bold; padding-right: 5px;"><%=lang.word["single"]%></span>
                        <span>/</span>
                        <span style="color:#FF772A; font-weight: bold; padding-left: 5px;"><%=lang.word["dispersion"]%></span>
                        <a class="table_bar"></a>
                    </li>
                    <li class="custom-li hidden" id="li_sortBatch">
                        <span style="font-weight: bold; margin-right: 5px;"><%=lang.word["single"]%> : </span>
                        <input id="num_single" class="easyui-numberbox" value="1" style="width: 30px;" />
                        <span style="font-weight: bold; margin: 0px 5px;"><%=lang.word["dispersion"]%> : </span>
                        <input id="num_dispersion" class="easyui-numberbox" style="width: 30px;" />
                        <a class="save" id="btnSortBatch" onclick="buttonCheck(this.id)" style="margin-left: 5px;"><span><%=lang.word["Sort by Batch"]%></span></a>
                        <a class="table_bar"></a>
                    </li>
                    <li><a class="save" id="btnUp" onclick="buttonCheck(this.id)"><span>UP</span></a></li>
                    <li><a class="save" id="btnDown" onclick="buttonCheck(this.id)"><span>DOWN</span></a></li>
                    <li><a class="table_bar"></a></li>
                    <li><a id="btnPrint" onclick="buttonCheck(this.id)"><img src="/common/crosseditor/images/icon/print.gif" /><span><%=lang.word["Printed Y/N"]%></span></a></li> <!--출력 -->
                    <li><a class="close" id="btnClose" onclick="buttonCheck(this.id);"><span><%=lang.word["Close"]%></span></a></li>
                </ul>
            </div>
            <div id="div_InputLotContent">
                <div id="divMasterGrid" class="table">
                    <uc:Realgrid ID="ucMasterRealgrid" CALLID="ucMasterRealgrid" runat="server" HEIGHT="200" />
                    <div id="LoadingPanel" class="modal"></div>       
                </div>
            </div>
        </div>
    </form>
</asp:Content>