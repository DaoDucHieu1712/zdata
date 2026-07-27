<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0560.aspx.cs" Inherits="GMES_IMES_0560" %>

<%--/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0560.aspx
* @desc    : 생산실적 - 실적조정관리 - 이상품 추적
************************************************************************************************* 
* VER     DATE            AUTHOR      DESCRIPTION
*************************************************************************************************
* 1.0                                 init
* 1.1     2025-06-26      오정균      수정
* 1.2     2025-07-31      오정균      요구사항으로 인한 2차 전체 수정
*************************************************************************************************
*/--%> 
<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc2" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>

<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <style>
        .th_auto {
            width : auto;
            min-width: 100px;
        }
        .th_fix {
            width : 100px;
            min-width: 100px;
        }
        .td_fix {
            width: 210px;
            max-width: 210px;
        }
        .td_fix_rdo {
            width: 280px;
            max-width: 280px;
        }
        .td_fixEnd {
            width: 250px;
            max-width: 250px;
        }
        .search_width {
            width: 210px;
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
        /* NOTETYPE 정의
        NT58 처리방안(생산팀)
        NT59 처리방안(기술팀)
        NT60 처리방안(생산팀) 확정
        NT61 처리방안(기술팀) 확정
        NT62 단독투입 여부
        */
        /*
         1) sampleType : sample LOT 사용 여부
         2) planBType : PlanB 컬럼 사용여부
         3) ncrType : ncr 컬럼 사용여부
         4) PLotIDType : PLOTID(배치) 기준 여부 사용 (X 원재료도 PLOTID로 변경)
         5) ParticlexType : [PARTICLEX 사용여부, PARTICLEX 컬럼]
         6) LOTWORKTYPENAME : 컬럼 LOTWORKTYPENAME 사용여부
         7) SETFIXEDCOLUMN : 컬럼 고정 수
         7) HoldType : 보류 정보(LOT, BAG) 컬럽 출력 여부
         */
        const classification = {
            "GOOD": {
                "sampleType": false,
                "planBType": false,
                "ncrType": true,
                //"PLotIDType": true,
                "ParticlexType": [true, []],
                "LOTWORKTYPENAME": true,
                "SETFIXEDCOLUMN": 4,
                "HoldType": true
            },
            "ASSY": {
                "sampleType": true,
                "planBType": true,
                "ncrType": false,
                //"PLotIDType": true,
                "ParticlexType": [false, []],
                "LOTWORKTYPENAME": true,
                "SETFIXEDCOLUMN": 5,
                "HoldType": false
            },
            "RAW": {
                "sampleType": false,
                "planBType": false,
                "ncrType": false,
                //"PLotIDType": false,
                "ParticlexType": [false, []],
                "LOTWORKTYPENAME": false,
                "SETFIXEDCOLUMN": 3,
                "HoldType": false
            }
        };

        /*
         1) SINGLE_INPUT_YN : 단독투입 사용여부
         2) NAME : 기준 컬럼 명
         */
        const dblClickedColumns = {
            "PROC_PLAN_A": {
                "SINGLE_INPUT_YN": false,
                "NAME": "PROC_PLAN_A"
            },
            "PROC_PLAN_B": {
                "SINGLE_INPUT_YN": true,
                "NAME": "PROC_PLAN_B"
            },
            "SINGLE_INPUT_YN": {
                "SINGLE_INPUT_YN": true,
                "NAME": "PROC_PLAN_B"
            }
        }
        //20250714

        // grid
        const cNumberFormat = "#,##0";  /*기본 숫자 소수점 X*/
        const cQtyFormat = "#,##0.000";  /*수량 소수점 3자리X*/
        const defaultBorder = "#808080, 1";
        const noGroupBorderBottom = " #ffcccccc, 1";
        var autoFilter = {};
        // grid

        const newDate = new Date();
        const today = '' + newDate.getFullYear() + (newDate.getMonth() + 1).toString().padStart(2, '0') + newDate.getDate().toString().padStart(2, '0') + '';
        const delay = 300;
        const maxCheckCount = 90;
        const panelPopupClass = '.panel.window.panel-htop';
        var timer = null;
        let _DataInfo = null;
        var RegCallBack = function () { };
        //#endregion

        $(document).ready(function () {
            InitData();
        });

        $(window).resize(function () {
            CollapseSlideArea(); // 슬라이드 닫기

            clearTimeout(timer); // 높이 가지고 오는 시점으로 인한 Timout 처리
            timer = setTimeout(function () {
                gridResetSize("main", "ucMasterRealgrid", ucMasterRealgrid, null);

                if (onNullCheck(window.top.$(panelPopupClass)[1]) && !onNullCheck(window.top.$(panelPopupClass)[0])) {
                    centerDialog(window.top.$(panelPopupClass));
                }
            }, delay);
        });

        function onSlideResize() {
            AutoHeightSpread();
        }

        function xInitPage() {
            AutoHeightSpread();
        }

        //#region AutoHeightSpread - RealGrid의 높이를 재설정한다.
        function AutoHeightSpread() {
            gridResetSize("main", "ucMasterRealgrid", ucMasterRealgrid);
            gridResetSize("subTab", null, null);
        }

        function gridResetSize(type, realGridElementById, realGrid) {
            const bottomFixHeight = 10; // 하단 그리드 공백
            const tabFixHeight = 35; // TAB 높이
            const mainLayout = parent.$('#MainLayout'); // 화면 (영역은 TAB 포함)
            const mainTabsHeight = mainLayout.find('.tabs-wrap').height(); // 화면 TAB 높이
            var gridHeight = 0; // 높이

            var divSlideTap = document.getElementById('SlidePanel'); // sub TAP
            var divSlideTapHeight = onZeroCheck(divSlideTap.offsetHeight) ? 0 : (divSlideTap.offsetHeight - (mainTabsHeight - tabFixHeight)); // sub TAP 높이 (공통으로 기본 한줄의 TAB 높이만 제외 두줄 이상은 TAB 높이 계산해서 처리)

            var funCss = function (id, style) {
                var value = id.css(style);
                return (onNullCheck(value) ? 0 : parseInt(value.replace(/[^0-9]/g, "")));
            }

            switch (type) {
                case "main":
                    const mainLayoutHeight = mainLayout.height(); // 화면 높이 (영역은 TAB 포함) > 사용 가능 : parent.window.document.getElementById('MainLayout').offsetHeight

                    var minTitleHeight = document.getElementById("div_mainTitle").offsetHeight; // 화면 타이틀 높이
                    var divSearchArea = $("#divSearchArea"); // 화면 조회조건
                    var divSearchAreaHeight = divSearchArea.height() + funCss(divSearchArea, 'margin-bottom'); // 화면 조회조건 높이 (margin 포함)
                    var divButton = $("#divButton"); // 화면 버튼
                    var divButtonHeight = divButton.height() + funCss(divButton, 'margin-bottom'); // 화면 버튼(엑셀) 높이 (margin 포함)

                    gridHeight = mainLayoutHeight - mainTabsHeight - minTitleHeight - divSearchAreaHeight - divButtonHeight - bottomFixHeight - divSlideTapHeight;

                    gridMaster = document.getElementById(realGridElementById);
                    gridMaster.style.height = gridHeight + 'px';
                    realGrid.ResetSize();
                    break
                case "subTab":
                    var subFixHeight = 47;

                    if (classification[$("input[name='Classification']:checked").val()].planBType) {
                        subFixHeight += 33;
                    }

                    var divSlideTapHeader = $("#SlidePanel").find('.tabs-header'); // subTab의 Tab
                    var divSlideTapHeaderHeight = Math.ceil(divSlideTapHeader.height() + funCss(divSlideTapHeader, 'padding-top')); // subTab의 Tab 높이(padding 포함)

                    var divButton = $("#divButtonInsert"); // 화면 버튼
                    var divButtonHeight = divButton.height() + funCss(divButton, 'margin-bottom'); // 화면 버튼(엑셀) 높이 (margin 포함)

                    const fixWidth = 190; // th + margin
                    var divIncInsertContentWidth = $("#SlidePanel").width();

                    gridHeight = divSlideTapHeight - divSlideTapHeaderHeight - divButtonHeight - subFixHeight - bottomFixHeight;
                    $('#txtPROC_PLAN').textbox('resize', { width: (divIncInsertContentWidth - fixWidth), height: gridHeight });
                    break
            }
        }
        //#endregion

        // #region InitData
        function InitData() {
            setInitSelectCom();/*조회조건 콤보박스 초기화*/
            setSelectCom("AREA", null, $("[id$=hidShopID]").val()); /*조회 조건 설정*/
            setEvent();

            InitMainRealgrid(); // main
            setColumnLayout();
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

            switch (vType) {
                case "AREA":
                    bizID = 'BR_IM_SEL_AREA_CBO';
                    bizInData = '&AREAIUSE=Y' + '&SHOPID=' + vSelectValue + '&SHOPIUSE=Y&USERID=' + $("[id$=hidUserID]").val();
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
                        setSelectCom("WAREHOUSE", { shopid: vSelectValue }, row.AREAID);
                    };
                    break
                case "WAREHOUSE":
                    bizID = 'DA_IM_COM_SEL_WAREHOUSE_CBO';
                    bizInData = '&WITH_CHILD=N&USEFLAG=Y&AREAID=' + vSelectValue + '&SHOPID=' + vRecord.shopid;
                    vCbo = $('#cbo_Warehouse');
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
                            setClear();
                        }
                    });
                } else {
                    setInitCom(vCbo, cboOptions);
                }
            }
        }
        // #endregion

        // #region Event 설정
        function setEvent() {
            $('#divClassification label').click(function (event) { // 라벨 클릭 시 해당 라디오 버튼 체크
                var radioButton = $(this).find('input[type="radio"]');
                if (!radioButton.prop('checked')) {
                    radioButton.prop('checked', true); // 라벨 클릭 시 라디오 버튼 체크
                    clearColumnLayout(true); // 라디오 버튼 값이 변경되었을 때 clearColumnLayout 호출
                }
            });

            $("input:radio[name='Classification']:radio[value='ASSY']").prop("checked", true);
            $("input[name='Classification']").change(function () {
                clearColumnLayout(true);
            });

            $('#comSINGLE_INPUT_YN').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_CommonCode&LANGID=<%=SSUser.LangID%>&CMCDTYPE=ABNORMAL_INPUT_TYPE&CBOOPT=OPT|CMCODE|CMCDNAME',
                valueField: 'CMCODE',
                textField: 'CMCDNAME'
            });
        }
        //#endregion

        //#region realGrid
        //#region Main Realgrid Field, Column 설정
        /*
         dynamicStyles1 : 같은 그룹 구분선 추가
         dynamicStyles2,3 : 확정 여부에 따른 스타일지정
         */
        var dynamicStyles1 = [
            {
                criteria: "(values['ENDSEQ'] = 'END')",
                styles: {
                    borderBottom: defaultBorder
                }
            },
            {
                criteria: "(values['ENDSEQ'] <> 'END')",
                styles: {
                    borderBottom: noGroupBorderBottom
                }
            }
        ];
        var dynamicStyles2 = [
            {
                criteria: "(values['PROC_PLAN_A_CONFIRM'] = 'Y')",
                styles: {
                    background: "#d3d3d3"
                }
            },
            {
                criteria: "(values['PROC_PLAN_A_CONFIRM'] <> 'Y')",
                styles: {
                    background: "#ffffe6"
                }
            }
        ];
        var dynamicStyles3 = [
            {
                criteria: "(values['PROC_PLAN_B_CONFIRM'] = 'Y')",
                styles: {
                    background: "#d3d3d3"
                }
            },
            {
                criteria: "(values['PROC_PLAN_B_CONFIRM'] <> 'Y')",
                styles: {
                    background: "#ffffe6"
                }
            }
        ];

        var vMasterRealgridFieldColumn = [
            { fieldName: "index", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "index" } },
            { fieldName: "RN_BG", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "RN_BG" } },
            { fieldName: "WHID_PV", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "WHID_PV" } },
            { fieldName: "WHNAME_PV", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "WHNAME_PV" } },
            { fieldName: "WHID", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "<%=lang.word["WHID"]%>" } },
            { fieldName: "WHNAME_SHORT", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "WHNAME_SHORT" } },
            { fieldName: "LOTWORKTYPESEQ", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "LOTWORKTYPESEQ" } },
            { fieldName: "BOXSCAN_YN", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "BOXSCAN_YN" } },
            { fieldName: "SUPPLIERNAME", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "SUPPLIERNAME" } },
            { fieldName: "PRODTYPE", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "PRODTYPE" } },
            { fieldName: "PRODTYPENM", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "PRODTYPENM" } },
            { fieldName: "MTRLTYPE", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "MTRLTYPE" } },
            { fieldName: "LINE", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "LINE" } },
            { fieldName: "TEMP_HOLDYN", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "TEMP_HOLDYN" } },
            { fieldName: "HOLDMNGTTYPE", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "TEMP_HOLDYN" } },
            //{ fieldName: "HOLDCODE", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "TEMP_HOLDYN" } },
            //{ fieldName: "HOLDCODENAME", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "TEMP_HOLDYN" } },
            //{ fieldName: "HOLDNOTE", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "TEMP_HOLDYN" } },
            { fieldName: "PROC_PLAN_A_CONFIRM", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "PROC_PLAN_A_CONFIRM" } },
            { fieldName: "PROC_PLAN_B_CONFIRM", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "PROC_PLAN_B_CONFIRM" } },
            { fieldName: "SINGLE_INPUT_YN_ORG", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "SINGLE_INPUT_YN_ORG" } },
            { fieldName: "LOADED_UPDATED", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "LOADED_UPDATED" } },
            { fieldName: "PLOTID", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "<%=lang.word["BATCH"]%>" } },
            { fieldName: "PLOTID_USER", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "PLOTID_USER" } },
            // 20250717
            { fieldName: "INSP_RESULT", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "INSP_RESULT" } },
            // 20250717
            // 20250718
            { fieldName: "ENDSEQ", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "ENDSEQ" } },
            // 20250718
            { fieldName: "LOTID", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "<%=lang.word["LOTID"]%>" } },
            { fieldName: "LOTWORKTYPE", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: [], filterType: false, header: "LOTWORKTYPE" } },

            { fieldName: "LOTID_USER", columnSetting: { type: "main_lotid", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["LOTID_USER"]%>" }, group: true },
            { fieldName: "LOTWORKTYPENAME", columnSetting: { type: "main", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Work Category"]%>" } },
            { fieldName: "WHNAME", columnSetting: { type: "main", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["WHNAME"]%>" } },
            { fieldName: "BAGNO", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["BAG NO"]%>" } },
            { fieldName: "SMP_LOTID_USER", columnSetting: { type: "main_lotid", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "L-T sample ID" } },
            { fieldName: "WIPQTY", dataType: "number", columnSetting: { type: "main_qty", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["WIPQTY"]%>" } },
            { fieldName: "MLOTDTTM", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Date"]%>(<%=lang.word["Incoming"]%>/<%=lang.word["Production"]%>)" } },
            { fieldName: "PRODID", columnSetting: { type: "main_id", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Product Code"]%>" } },
            { fieldName: "PRODNAME", columnSetting: { type: "main_name", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Drawing No. Name"]%>" } },
            { fieldName: "MTRLTYPENM", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Product Type"]%>" } },
            { fieldName: "POSS_INPUT", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Available Input"]%>" } },
            { fieldName: "INSPRESULT", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["INSP_GB"]%>" } },
            { fieldName: "LINENAME", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["LINE"]%>" } },
            {
                type: "group",
                name: "Confirm",
                header: "<%=lang.word["SinglePrimaryBurning_P"]%>",
                columns: [
                    { fieldName: "LINE_LINE", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["LINE"]%>" } },
                    { fieldName: "LINE_MAKER_LI", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["PRECURSOR"]%>" } },
                    { fieldName: "LINE_MAKER_MOOH", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Lithium"]%>" } }
                ]
            },
            {
                type: "group",
                name: "Confirm",
                header: "<%=lang.word["Manufacturer"]%>",
                columns: [
                    { fieldName: "MOOH_MAKERID", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["PRECURSOR"]%>" } },
                    { fieldName: "LI_MAKERID", columnSetting: { type: "main_data", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Lithium"]%>" } }
                ]
            }
        ];
        var vMasterRealgridPlanAddFieldColumn = [
            { fieldName: "PROC_PLAN_A", columnSetting: { type: "main_plan", mergeRule: { criteria: "values['PLOTID']+value" }, dynamicStyles: dynamicStyles2, filterType: true, header: "<%=lang.word["Action plan"]%>" + "\n" + "( " + "<%=lang.word["production team"]%>" + " )" } }
        ];

        var vMasterRealgridNCRAddFieldColumn = [
            { fieldName: "NCRSTEP", columnSetting: { type: "main_name", mergeRule: { criteria: "values['PLOTID']+value" }, dynamicStyles: [], filterType: true, header: "NCR <%=lang.word["Progressing Status"]%>" } }
        ];
        var vMasterRealgridHoldAddFieldColumn = [
            {
                type: "group",
                name: "Confirm",
                header: "<%=lang.word["LOT"]%>",
                columns: [
                    { fieldName: "HOLDCODE", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: false, header: "HOLDCODE" } },
                    { fieldName: "HOLDCODENAME", columnSetting: { type: "main_id", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Hold"]%><%=lang.word["Code Name"]%>" } },
                    { fieldName: "HOLDNOTE", columnSetting: { type: "main_name", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Nonconformance Classification"]%>" } }
                ]
            },
            {
                type: "group",
                name: "Confirm",
                header: "<%=lang.word["LOT"]%>(Bag)",
                columns: [
                    { fieldName: "BAGLOT_HOLDCODE", columnSetting: { type: "logic", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: false, header: "HOLDCODE" } },
                    { fieldName: "BAGLOT_HOLDCODENAME", columnSetting: { type: "main_id", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Hold"]%><%=lang.word["Code Name"]%>" } },
                    { fieldName: "BAGLOT_HOLDNOTE", columnSetting: { type: "main_name", mergeRule: {}, dynamicStyles: dynamicStyles1, filterType: true, header: "<%=lang.word["Nonconformance Classification"]%>" } }
                ]
            }
        ];
        var vMasterRealgridPlanBAddFieldColumn = [
            {
                type: "group",
                name: "Confirm",
                header: "<%=lang.word["Action plan"]%>" + "(" + "<%=lang.word["technical team"]%>" + ")",
                columns: [
                    { fieldName: "SINGLE_INPUT_YN", columnSetting: { type: "main_inputYN", mergeRule: { criteria: "values['PLOTID']+value" }, dynamicStyles: dynamicStyles3, filterType: true, header: "<%=lang.word["Independent input or not"]%>" } },
                    { fieldName: "PROC_PLAN_B", columnSetting: { type: "main_plan", mergeRule: { criteria: "values['PLOTID']+value" }, dynamicStyles: dynamicStyles3, filterType: true, header: "<%=lang.word["Action plan"]%>" } }
                ]
            }
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
                    break
                case "main_name":
                    vColumn.width = 250;
                    break
                case "main_qty":
                    vColumn.styles.numberFormat = cQtyFormat;
                    vColumn.width = 120;
                    break
                case "main_number":
                    vColumn.styles.numberFormat = cNumberFormat;
                    vColumn.width = 120;
                    break
                case "main_data":
                    vColumn.width = 120;
                    break
                case "main_id":
                case "main_lotid":
                    vColumn.width = 200;
                    break
                case "main_plan":
                    vColumn.width = 300;
                    vColumn.styles.background = "#ffffe6";
                    vColumn.styles.textWrap = "normal";
                    vColumn.styles.borderBottom = defaultBorder;
                    break
                case "main_inputYN":
                    vColumn.width = 120;
                    vColumn.styles.background = "#ffffe6";
                    vColumn.lookupDisplay = true;
                    vColumn.mergeEdit = true;
                    vColumn.editor = { type: "dropDown", domainOnly: true };
                    break
            }

            return vColumn;
        }
        //#endregion

        //#region 컬럼 설정
        var setColumn = function (vType, vFieldName, vHeader, vMergeRule, isGroup, dynamicStyle, defaultBorderType) {
            // 해당 Detailgrid 공통 컬럼 설정
            var column = {
                name: vFieldName,
                fieldName: vFieldName,
                header: { text: vHeader },
                styles: { textAlignment: "center", borderBottom: noGroupBorderBottom },
                mergeRule: vMergeRule,
                visible: true,
                editable: false,
                width: 150,
                // 20250718
                dynamicStyles: dynamicStyle
                // 20250718
            };
            // 해당 Detailgrid 공통 컬럼 설정

            if (isGroup.type) {
                column.movable = false; // 그룹 안에서는 컬럼 이동 못하도록 설정
            }

            if (defaultBorderType) {
                column.styles.borderBottom = defaultBorder;
            }

            return setTypeColumn(vType, column);
        };
        //#endregion

        //#region column / field 
        function setColumnSetting(fieldColumns, fields, columns, filter, defaultBorderType) {
            fieldColumns.forEach(function (a) {
                var vGroupWidth = 0;
                var masterColumns = [];

                if (a.type == "group") {
                    a.columns.forEach(function (b) {
                        fields.push({ fieldName: b.fieldName, dataType: onNullCheck(b.dataType) ? 'text' : b.dataType });
                        var column = setColumn(b.columnSetting.type, b.fieldName, b.columnSetting.header, b.columnSetting.mergeRule, { type: true }, b.columnSetting.dynamicStyles, defaultBorderType);
                        vGroupWidth += (column.visible) ? column.width : 0;

                        if (b.columnSetting.filterType) {
                            filter.push(b.fieldName);
                        }

                        masterColumns.push(column);
                    });

                    columns.push({
                        type: a.type,
                        name: a.name,
                        header: a.header,
                        width: vGroupWidth,
                        columns: masterColumns
                    });
                } else {
                    if (a.columnSetting.filterType) {
                        filter.push(a.fieldName);
                    }

                    fields.push({ fieldName: a.fieldName, dataType: onNullCheck(a.dataType) ? 'text' : a.dataType });
                    columns.push(setColumn(a.columnSetting.type, a.fieldName, a.columnSetting.header, a.columnSetting.mergeRule, { type: false }, a.columnSetting.dynamicStyles, defaultBorderType));
                }
            });
        }
        //#endregion

        //#region realGrid Init
        function InitMainRealgrid() {
            setColumnSetting(vMasterRealgridFieldColumn, vMasterRealgridFields, vMasterRealgridColumns, vRealgridFilterColumns, false);

            /*메뉴 ID 에 null을 등록하면 컬럼별 빼고 안빼고를 설정 할 수 없다. 일단은 NULL로 */
            ucMasterRealgrid.Init(null, vMasterRealgridFields, vMasterRealgridColumns, true, true, true);

            realGridSet(ucMasterRealgrid_gridView, true);

            ucMasterRealgrid.SetFixedColumn(4);

            ucMasterRealgrid_gridView.addCellStyle("NG_UNDER_CellStyle", {
                "fontBold": true,
                "foreground": "#0019F4"
            }, true);
            ucMasterRealgrid_gridView.addCellStyle("NG_OVER_CellStyle", {
                "fontBold": true,
                "foreground": "#ff0000"
            }, true);
            ucMasterRealgrid_gridView.addCellStyle("OK_CellStyle", {
                "fontBold": true,
            }, true);

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

            ucMasterRealgrid_DblClicked = function (grid, row) {
                CollapseSlideArea();
                _DataInfo = null;

                if (!onNullCheck(dblClickedColumns[row.column])) {
                    var datarow = ucMasterRealgrid_dataProvider.getJsonRow(row.dataRow);

                    _DataInfo = {
                        DataRow: datarow
                        , SelectColumn: row.column
                    };

                    setDataInfo(row.column, datarow, ucMasterRealgrid_gridView.getDisplayValues(row.dataRow));
                    ExpandSlideArea();
                }
            }
            // 20250731
            ucMasterRealgrid_gridView.onFiltering = function (grid) {
                CollapseSlideArea(); // 슬라이드 닫기
            }
            // 20250731
            // 20250718
            ucMasterRealgrid_gridView.onFilteringChanged = function (grid, column) {
                setTotalCount([$("#ucMasterTotalConunt"), ucMasterRealgrid_gridView.getItemCount()]);

                GridShowLoading();
                dataProviderSetData(null, true, null);
            }
            // 20250718
        }

        var setFilterColumns = function (filterColumns) {
            if (filterColumns.length > 0) {
                ucMasterRealgrid.SetColsFilter(filterColumns);

                autoFilter["ucMasterRealgrid"] = {
                    "realGrid_autoFilterItemsKey": [],
                    "realGrid_autoFilterColumns": filterColumns
                };

                ucMasterRealgrid_LoadDataCompleted = function () {
                    ucMasterRealgrid_gridView.onFilterActionClicked = function (grid, column, action, x, y) {
                        if (action == "autoFilter") {
                            var offset = $("#ucMasterRealgrid").position();

                            showAutoFiltering("ucMasterRealgrid", ucMasterRealgrid_gridView, ucMasterRealgrid_dataProvider, column, x + offset.left, y + offset.top);
                        }
                    };
                };

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

            gridView.setSortingOptions({ enabled: false });

            gridView.setEditOptions({
                //editable: false
                //commitByCell: true,
                //showInnerFocus: false
                insertable: false,
                appendable: false
            });

            gridView.setStateBar({
                // 20250707
                visible: false
                //visible: true
                // 20250707
            });

            gridView.setCheckBar({
                // 20250707
                //visible: false
                showAll: false,
                visible: true
                // 20250707
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
                fitStyle: "even", // 컬럼 채우기 "none" 이면 설정한 넓이 기준
                eachRowResizable: true // 개별 행 높이 설정
            });

            if (isGroup) {
                gridView.setHeader(
                    { height: 50 } // 헤더 높이 +10
                );
            }
        }

        // #region 더블 클릭 시 이벤트 
        var setDataInfo = function (colName, info, displayValue) {
            // 초기화
            $("#txtLOTIDUSER").val('');
            $("#txtPROC_PLAN").textbox('setValue', '');
            $("#txtSINGLE_INPUT_YN").val('');
            $('#comSINGLE_INPUT_YN').combobox('setValue', '');

            SetButtonEnable('#btnSave', true);
            SetButtonEnable('#btnConfirm', true);
            SetButtonEnable('#btnCancel', false);

            document.getElementById("divTxtSINGLE_INPUT_YN").style.display = "inherit";
            document.getElementById("divComSINGLE_INPUT_YN").style.display = "none";
            $('#txtPROC_PLAN').textbox('readonly', false);

            if (classification[$("input[name='Classification']:checked").val()].planBType) {
                $('#trSINGLE_INPUT_YN').removeClass('hidden');
            } else {
                $('#trSINGLE_INPUT_YN').addClass('hidden');
            }
            // 초기화

            if (info !== null) {
                var CONFIRMTYPE = false;

                $("#txtLOTIDUSER").val(info.LOTID_USER);
                $('#txtSINGLE_INPUT_YN').val(displayValue.SINGLE_INPUT_YN);
                $("#txtPROC_PLAN").textbox('setValue', info[dblClickedColumns[colName].NAME]);

                if (dblClickedColumns[colName].SINGLE_INPUT_YN) {
                    $("#txtTitle").text('<%=lang.word["technical team"]%>');

                    if (info[dblClickedColumns[colName].NAME + "_CONFIRM"] == "Y") {
                        CONFIRMTYPE = true;
                    } else {
                        $('#comSINGLE_INPUT_YN').combobox('setValue', info.SINGLE_INPUT_YN);

                        document.getElementById("divTxtSINGLE_INPUT_YN").style.display = "none";
                        document.getElementById("divComSINGLE_INPUT_YN").style.display = "inherit";
                    }
                } else {
                    $("#txtTitle").text('<%=lang.word["production team"]%>');

                    if (info[dblClickedColumns[colName].NAME + "_CONFIRM"] == "Y") {
                        CONFIRMTYPE = true;
                    }
                }

                if (CONFIRMTYPE) {
                    $('#txtPROC_PLAN').textbox('readonly', true);

                    SetButtonEnable('#btnSave', false);
                    SetButtonEnable('#btnConfirm', false);
                    SetButtonEnable('#btnCancel', true);
                }
            }
        }
        //#endregion
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
        //#endregion
        //#endregion
        //#endregion

        // #region 동적 컬럼 Clear
        var clearColumnLayout = function (data) {
            if (data) {
                setClear();
                setColumnLayout();
            } else if (data == undefined) {
                setClear();
                setColumnLayout();
            }
        }
        //#endregion

        // #region 동적 컬럼 생성
        var setColumnLayout = function () {
            var items = {};
            items.LANGID = XSSReplace($("[id$=hidLangID]").val(), 1); // 언어
            items.CMCDTYPE = "CM_QUALITEM";
            items.USEYN = 'Y';//사용여부

            var ITEMTYPE = $('input:radio[name="Classification"]:checked').val();
            items.TYPE = ITEMTYPE;

            var param = {};
            param.bizID = "BR_IM_COM_GET_PROD_CLCTITEM";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = 'OUTDATA';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            GridShowLoading();
            sendRequestMethod(function callback(id, data, message, status) {
                var fields = JSON.parse(JSON.stringify(vMasterRealgridFields));
                var columns = JSON.parse(JSON.stringify(vMasterRealgridColumns));
                var filterColumns = JSON.parse(JSON.stringify(vRealgridFilterColumns));

                // 20250731 HoldType
                if (classification[$("input[name='Classification']:checked").val()].HoldType) {
                    setColumnSetting(vMasterRealgridHoldAddFieldColumn, fields, columns, filterColumns, false);
                }
                // 20250731

                setColumnSetting(vMasterRealgridPlanAddFieldColumn, fields, columns, filterColumns, true);

                if (classification[$("input[name='Classification']:checked").val()].ncrType) {
                    setColumnSetting(vMasterRealgridNCRAddFieldColumn, fields, columns, filterColumns, true);
                }

                if (classification[$("input[name='Classification']:checked").val()].planBType) {
                    setColumnSetting(vMasterRealgridPlanBAddFieldColumn, fields, columns, filterColumns, true);
                }

                if (data != undefined || data != null) {
                    let ProdList = $.grep(data, function (el, l) {
                        return el.ITEMTYPE === 'PROD';
                    });

                    if (ProdList.length > 0) {
                        if (classification[$("input[name='Classification']:checked").val()].sampleType) {
                            ProdList.forEach(function (value, index, array) {
                                var vGroupWidth = 0;
                                var masterColumns = [];

                                if (value[$("input[name='Classification']:checked").val()] == $("input[name='Classification']:checked").val()) {
                                    fields.push({ fieldName: value.CLCTITEM + "_1", dataType: "number" });
                                    fields.push({ fieldName: value.CLCTITEM + "_2", dataType: "number" });

                                    var column1 = setColumn("main_qty", value.CLCTITEM + "_1", "Origin", { criteria: "values['PLOTID']+value" }, { type: true }, []);
                                    var column2 = setColumn("main_qty", value.CLCTITEM + "_2", "Sample", { criteria: "values['PLOTID']+value" }, { type: true }, []);

                                    column1.styles.borderBottom = defaultBorder;
                                    column2.styles.borderBottom = defaultBorder;

                                    vGroupWidth += column1.width;
                                    vGroupWidth += column2.width;

                                    masterColumns.push(column1);
                                    masterColumns.push(column2);
                                }

                                columns.push({
                                    type: "group",
                                    name: value.CLCTITEM,
                                    header: value.CLCTNAME,
                                    width: vGroupWidth,
                                    columns: masterColumns
                                });
                            });
                        } else {
                            var vGroupWidth = 0;
                            var masterColumns = [];

                            ProdList.forEach(function (value, index, array) {
                                if (value[$("input[name='Classification']:checked").val()] == $("input[name='Classification']:checked").val()) {
                                    fields.push({ fieldName: value.CLCTITEM + "_1", dataType: "number" });
                                    var column = setColumn("main_qty", value.CLCTITEM + "_1", value.CLCTNAME, { criteria: "values['PLOTID']+value" }, { type: true }, []);

                                    column.styles.borderBottom = defaultBorder;

                                    vGroupWidth += column.width;

                                    masterColumns.push(column);
                                }
                            });

                            columns.push({
                                type: "group",
                                name: "Inspection",
                                header: "<%=lang.word["Line Inspection"]%>" + "<%=lang.word["Result"]%>" + " <%=lang.word["Query"]%>",
                                width: vGroupWidth,
                                columns: masterColumns
                            });
                        }
                    }

                    if (classification[$("input[name='Classification']:checked").val()].ParticlexType[0]) {
                        classification[$("input[name='Classification']:checked").val()].ParticlexType[1] = [];

                        let ParticleXList = $.grep(data, function (el, l) {
                            return el.ITEMTYPE === 'PARTICLEX';
                        });

                        if (ParticleXList.length > 0) {
                            var vGroupWidth = 0;
                            var masterColumns = [];

                            ParticleXList.forEach(function (value, index, array) {
                                if (value.CLCTITEM != "SUM") {
                                    classification[$("input[name='Classification']:checked").val()].ParticlexType[1].push(value.CLCTITEM);
                                }

                                fields.push({ fieldName: (value.CLCTITEM == "SUM" ? "PARTICLEX_TOTAL" : value.CLCTITEM), dataType: "number" });
                                var column = setColumn("main_number", (value.CLCTITEM == "SUM" ? "PARTICLEX_TOTAL" : value.CLCTITEM), (value.CLCTITEM == "SUM" ? "<%=lang.word["D_SUM"]%>" : value.CLCTNAME), { criteria: "values['PLOTID']+value" }, { type: true } , []);

                                column.styles.borderBottom = defaultBorder;
                                column.styles.fontBold = true;

                                vGroupWidth += column.width;
                                masterColumns.push(column);
                            });

                            columns.push({
                                type: "group",
                                name: "PARTICLEX",
                                header: "particle X " + "<%=lang.word["Data"]%>",
                                width: vGroupWidth,
                                columns: masterColumns
                            });
                        }
                    }
                }

                ucMasterRealgrid_dataProvider.setFields(fields);
                ucMasterRealgrid_gridView.setColumns(columns);
                ucMasterRealgrid_gridView.commit(true);

                setFilterColumns(filterColumns);

                if (classification[$("input[name='Classification']:checked").val()].planBType) {
                    GridCombobox();
                }

                // 샘플 LOT 여부
                if (classification[$("input[name='Classification']:checked").val()].sampleType) {
                    ucMasterRealgrid_gridView.setColumnProperty("SMP_LOTID_USER", "visible", true);
                } else {
                    ucMasterRealgrid_gridView.setColumnProperty("SMP_LOTID_USER", "visible", false);
                }
                // 샘플 LOT 여부

                // 작업구분 사용여부
                if (classification[$("input[name='Classification']:checked").val()].LOTWORKTYPENAME) {
                    ucMasterRealgrid_gridView.setColumnProperty("LOTWORKTYPENAME", "visible", true);
                } else {
                    ucMasterRealgrid_gridView.setColumnProperty("LOTWORKTYPENAME", "visible", false);
                }
                // 작업구분 사용여부

                // SetFixedColumn 
                ucMasterRealgrid.SetFixedColumn(classification[$("input[name='Classification']:checked").val()].SETFIXEDCOLUMN);
                // SetFixedColumn 

                GridCloseLoading();
            }, param, "GET", url);
        };

        // #region SINGLE_INPUT_YN 콤보박스 설정
        var GridCombobox = function () {
            var items = [
                { name: 'LANGID', value: '<%=SSUser.LangID%>', dataType: _DataType.String }
                , { name: 'CMCDTYPE', value: 'ABNORMAL_INPUT_TYPE', dataType: _DataType.String }
            ];

            var url = "/GMES_IM_POM/GMES_IMES_0560.aspx/GetData";
            var param = {};
            param.bizID = 'BR_IM_SEL_CommonCode';
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = 'OUTDATA';

            sendRequestMethod(function () {
                if (data != null) {
                    var vLabelItems = [];
                    var vValuesItems = [];

                    data.forEach(function (value, index, array) {

                        vValuesItems.push(value.CMCODE);
                        vLabelItems.push(value.CMCDNAME);
                    });

                    var column = ucMasterRealgrid_gridView.columnByName('SINGLE_INPUT_YN');

                    if (column != null) {
                        column.values = vValuesItems;
                        column.labels = vLabelItems;

                        ucMasterRealgrid_gridView.setColumn(column);
                    };
                };
            }, param, "POST", url);
        };
        //#endregion

        //#endregion

        // #region Data 처리
        var dataProviderSetData = function (uniqueLotIDs, closeLoadingType, uniqueUserLotIDs) {
            var index = 0;

            for (var idx = 0; idx < ucMasterRealgrid_gridView.getItemCount(); idx++) {
                var item = ucMasterRealgrid_gridView.getValues(idx);

                if (!onNullCheck(uniqueLotIDs)) {
                    uniqueLotIDs.add(item.PLOTID);
                }

                if (!onNullCheck(uniqueUserLotIDs)) {
                    uniqueUserLotIDs.add(item.PLOTID_USER);
                }

                if (idx != 0) {
                    var fromLotid = ""
                    var lotid = ""
                    var fromItem = ucMasterRealgrid_gridView.getValues(idx - 1);

                    fromLotid = fromItem.PLOTID;
                    lotid = item.PLOTID;

                    if (fromLotid != lotid) {
                        index += 1;
                        ucMasterRealgrid_gridView.setValue((idx - 1), "ENDSEQ", "END");
                    } else {
                        ucMasterRealgrid_gridView.setValue((idx - 1), "ENDSEQ", "");
                    }

                    ucMasterRealgrid_gridView.setValue(idx, "index", index);
                } else {
                    ucMasterRealgrid_gridView.setValue(idx, "index", index);
                }
            }

            if (ucMasterRealgrid_gridView.getItemCount() > 0) {
                ucMasterRealgrid_gridView.setValue((ucMasterRealgrid_gridView.getItemCount() - 1), "ENDSEQ", "END");
            }

            if (closeLoadingType) {
                GridCloseLoading();
            }
        }
        //#endregion

        // #region 조회
        function GetMasterData() {
            if (validation("areaID", $("#cboArea").val())) {
                return
            }
            // 20250715
            setClear();
            // 20250715

            //setDataInfo(null, null); 
            CollapseSlideArea(); // 슬라이드 닫기
            _DataInfo = null;

            var param = {};
            var items = [];
            var subItems = [];
            var MtrlType = $('input:radio[name="Classification"]:checked').val();
            var prodid = $("#txtProductCode").textbox("getText").trim();
            var SearchKeyword = $("#txt_LotID").textbox("getText").trim().split(/[\r\n]/);
            var inputLots = '';
            var oneLot = '';

            if (SearchKeyword.length > 1) {
                for (var i = 0; i < SearchKeyword.length; i++) {
                    inputLots = inputLots.concat("'", SearchKeyword[i].trim(), "',");
                }

                inputLots = inputLots.concat("''");
            }
            else {
                oneLot = SearchKeyword[0];
            }

            subItems[0] = [
                { name: "LANGID", value: XSSReplace($("[id$=hidLangID]").val(), 1), dataType: _DataType.String },
                { name: "SHOPID", value: XSSReplace(XSSReplace($("[id$=hidShopID]").val(), 1), 1), dataType: _DataType.String },
                { name: "AREAID", value: $('#cboArea').combobox('getValue'), dataType: _DataType.String },
                { name: "WHID", value: $('#cbo_Warehouse').combobox('getValue'), dataType: _DataType.String },
                { name: "MTRLTYPE", value: MtrlType, dataType: _DataType.String },
                { name: "PRODID", value: prodid, dataType: _DataType.String },
                { name: "USERID", value: XSSReplace($("[id$=hidUserID]").val(), 1), dataType: _DataType.String },
                { name: "INLOTID", value: inputLots, dataType: _DataType.String },
                { name: "ONELOTID", value: oneLot, dataType: _DataType.String }
            ];

            items[0] = subItems;
            param.items = items;

            param.bizID = "BR_IM_STK_GET_RACK_ABNORMAL";
            param.inTableNames = 'INDATA,';
            param.outTableNames = 'OUTDATA';

            var url = "/GMES_IM_POM/GMES_IMES_0560.aspx/GetData";

            ucMasterRealgrid.CallRequest(url, param, function () {
                let LotID_List = '';
                let UserLotID_List = '';
                let uniqueLotIDs = new Set(); // 중복 제거
                let uniqueUserLotIDs = new Set(); // 중복 제거

                dataProviderSetData(uniqueLotIDs, false, uniqueUserLotIDs);

                LotID_List = Array.from(uniqueLotIDs).join(',');
                UserLotID_List = Array.from(uniqueUserLotIDs).join(',');

                if (LotID_List.endsWith(',')) {// 마지막 쉼표 제거 
                    LotID_List = LotID_List.slice(0, -1);
                }

                if (UserLotID_List.endsWith(',')) {// 마지막 쉼표 제거
                    UserLotID_List = UserLotID_List.slice(0, -1);
                }


                if (LotID_List === '' || UserLotID_List === '') {
                    return;
                }

                var InspItems = {};
                InspItems.LANGID = XSSReplace($("[id$=hidLangID]").val(), 1); // 언어
                InspItems.LOTID_LIST = LotID_List;
                InspItems.LOTID_USER_LIST = UserLotID_List;
                InspItems.SHOPID = $("[id$=hidShopID]").val();
                InspItems.MTRLTYPE = $("input[name='Classification']:checked").val();

                var InspParam = {};
                InspParam.bizID = "BR_IM_PRD_SEL_LOT_ABNORMAL_INSPRESULT"; // 공정검사 결과값
                InspParam.items = InspItems;
                InspParam.inTableNames = 'INDATA';
                InspParam.outTableNames = 'OUTDATA';

                var InspUrl = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

                GridShowLoading();
                sendRequestMethod(function callback(id, data, message, status) {
                    if (data != undefined || data != null) {

                        for (var idx = 0; idx < ucMasterRealgrid.GetRowCount(); idx++) {
                            var item = ucMasterRealgrid_dataProvider.getJsonRow(idx);

                            var dataList = data.filter(function (v) { return v.LOTID == item.PLOTID })[0];

                            if (!onNullCheck(dataList)) {
                                if (classification[$("input[name='Classification']:checked").val()].sampleType) {
                                    if (ucMasterRealgrid_gridView.columnByField("SMP_LOTID_USER")) {
                                        ucMasterRealgrid_gridView.setValue(idx, "SMP_LOTID_USER", dataList.SMP_LOTID_USER);
                                    }
                                }

                                if (classification[$("input[name='Classification']:checked").val()].ncrType) {
                                    if (ucMasterRealgrid_gridView.columnByField("NCRSTEP")) {
                                        ucMasterRealgrid_gridView.setValue(idx, "NCRSTEP", dataList.NCRSTEP);
                                    }
                                }

                                let InspresultArray = dataList.INSPRESULT.split(',');

                                let INSP_RESULT = ""

                                for (var j = 0; j < InspresultArray.length; j++) {
                                    let Inspresult = InspresultArray[j].split(':');
                                    let ItemID = Inspresult[0]; // 검사 항목
                                    let ItemValue = Inspresult[1]; // 검사 항목값
                                    let ItemResult = Inspresult[2]; // 검사 결과값

                                    if (!onNullCheck(ItemValue)) {
                                        if (ucMasterRealgrid_gridView.columnByField(ItemID)) {
                                            ucMasterRealgrid_gridView.setValue(idx, ItemID, ItemValue);

                                            if (ItemResult == "NG_UNDER") {
                                                ucMasterRealgrid_gridView.setCellStyle(idx, ItemID, "NG_UNDER_CellStyle", true);
                                            } else if (ItemResult == "NG_OVER") {
                                                ucMasterRealgrid_gridView.setCellStyle(idx, ItemID, "NG_OVER_CellStyle", true);
                                            } else if (ItemResult == "OK") {
                                                ucMasterRealgrid_gridView.setCellStyle(idx, ItemID, "OK_CellStyle", true);
                                            }

                                            // 20250716
                                            if (ItemResult == "NG_UNDER" || ItemResult == "NG_OVER") {
                                                INSP_RESULT = "D";
                                            } else if ((INSP_RESULT != "D") && (onNullCheck(ItemResult))) {
                                                INSP_RESULT = "SELECT";
                                            } else if (INSP_RESULT != "SELECT" && INSP_RESULT != "D" && ItemResult == "OK") {
                                                INSP_RESULT = "S";
                                            }
                                            // 20250716
                                        }
                                    }
                                }

                                if (classification[$("input[name='Classification']:checked").val()].planBType) {
                                    // 20250717
                                    if (onNullCheck(item.SINGLE_INPUT_YN)) {
                                        ucMasterRealgrid_gridView.setValue(idx, "SINGLE_INPUT_YN", (INSP_RESULT == "SELECT" ? "" : INSP_RESULT));
                                    }
                                    ucMasterRealgrid_gridView.setValue(idx, "INSP_RESULT", (INSP_RESULT == "SELECT" ? "" : INSP_RESULT));
                                    // 20250717
                                }
                            }

                            if (classification[$("input[name='Classification']:checked").val()].ParticlexType[0]) {
                                let PARTICLEX_TOTAL; // PARTICLEX 합계

                                classification[$("input[name='Classification']:checked").val()].ParticlexType[1].forEach(function (v) {
                                    let ParticleXValue = ucMasterRealgrid_gridView.getValue(idx, v);
                                    if (!onNullCheck(ParticleXValue)) {
                                        PARTICLEX_TOTAL = (onNullCheck(PARTICLEX_TOTAL) ? 0 : PARTICLEX_TOTAL) + parseInt(ParticleXValue);
                                    }
                                });

                                if (!onNullCheck(PARTICLEX_TOTAL)) {
                                    ucMasterRealgrid_gridView.setValue(idx, "PARTICLEX_TOTAL", PARTICLEX_TOTAL);
                                }
                            }

                            ucMasterRealgrid_dataProvider.setRowState(idx, "none", true);
                        }

                    }
                    ucMasterRealgrid_gridView.commit(true);
                    GridCloseLoading();
                }, InspParam, "GET", InspUrl);

                setTotalCount([$("#ucMasterTotalConunt"), ucMasterRealgrid.GetRowCount()]);
            });
        }
        //#endregion

        // #region 버튼 이벤트
        // #region 저장
        var Save = function (type) {
            let message = '';
            var planNoteType = "";
            var confirmNoteType = "";
            var comSINGLE_INPUT_YN = $('#comSINGLE_INPUT_YN').combobox('getValue');

            if (dblClickedColumns[_DataInfo.SelectColumn].SINGLE_INPUT_YN) {
                planNoteType = "NT59";
                confirmNoteType = "NT61";
            } else {
                planNoteType = "NT58";
                confirmNoteType = "NT60";
            }

            var plan = { type: false, notetype: planNoteType, notevalue: $("#txtPROC_PLAN").textbox('getValue') };    // 처리방안
            var inputYN = { type: false, notetype: "NT62", notevalue: comSINGLE_INPUT_YN }; // 단독투입 여부
            var confirm = { type: false, notetype: confirmNoteType, notevalue: "" }; // 확정

            switch (type) {
                //확정
                case "CONFIRM":
                    plan.type = true;

                    confirm.type = true;
                    confirm.notevalue = "Y";

                    if (dblClickedColumns[_DataInfo.SelectColumn].SINGLE_INPUT_YN) {
                        inputYN.type = true;
                    }

                    message = '<%=lang.message["SFU1246"]%>';
                    break;
                //취소
                case "CANCEL":
                    confirm.type = true;
                    confirm.notevalue = "N";

                    message = '<%=lang.message["20014"]%>';

                    break;
                //저장
                case "SAVE":
                    plan.type = true;

                    if (dblClickedColumns[_DataInfo.SelectColumn].SINGLE_INPUT_YN) {
                        inputYN.type = true;
                    }

                    message = '<%=lang.message["10004"]%>';
                    break;
                default:
            }

            var param = {};
            var items = [];
            var subItems0 = [];

            var dataArray = ucMasterRealgrid_dataProvider.getJsonRows(0, -1);
            var dataProviderIdx = [];

            var subItems = function (subItems, items) {
                subItems.push([
                    { name: "LOTID", value: items.LOTID, dataType: _DataType.String }
                    , { name: "NOTETYPE", value: items.NOTETYPE, dataType: _DataType.String }
                    , { name: "LOTNOTE", value: items.NOTEVALUE, dataType: _DataType.String }
                    , { name: "MTRLTYPE", value: items.MTRLTYPE, dataType: _DataType.String }
                    , { name: "USERID", value: '<%=SSUser.UserID%>', dataType: _DataType.String }
                ]);
            }

            $.grep(dataArray, function (el, l) { if (el.PLOTID === _DataInfo.DataRow.PLOTID) { dataProviderIdx.push(l); } });

            let MTRLTYPE = "RAW";
            if ($("input[name='Classification']:checked").val() != "RAW") {
                MTRLTYPE = "PROD"
            }

            var lotid = '';

            //if (classification[$("input[name='Classification']:checked").val()].PLotIDType) {
                //lotid = _DataInfo.DataRow.PLOTID;
            //} else {
                //lotid = _DataInfo.DataRow.LOTID;
            //}
            lotid = _DataInfo.DataRow.PLOTID;

            if (plan.type) {
                subItems(subItems0, { LOTID: lotid, NOTETYPE: plan.notetype, NOTEVALUE: plan.notevalue, MTRLTYPE: MTRLTYPE });
            }
            if (inputYN.type) {
                subItems(subItems0, { LOTID: lotid, NOTETYPE: inputYN.notetype, NOTEVALUE: inputYN.notevalue, MTRLTYPE: MTRLTYPE });
            }
            if (confirm.type) {
                subItems(subItems0, { LOTID: lotid, NOTETYPE: confirm.notetype, NOTEVALUE: confirm.notevalue, MTRLTYPE: MTRLTYPE });
            }

            param.bizID = "BR_IM_BAS_REG_ABNORMAL_PROD_LOTNOTE";
            items[0] = subItems0;

            var url = "/GMES_IM_POM/GMES_IMES_0560.aspx/ExecuteData";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = '';

            sendRequestMethod(function (id, data) {
                if (data.length > 0) {
                    if (data[0].RETURN === 'OK') {
                        dataProviderIdx.forEach(function (v) {
                            if (plan.type) {
                                ucMasterRealgrid_dataProvider.setValue(v, dblClickedColumns[_DataInfo.SelectColumn].NAME, plan.notevalue);
                            }

                            if (inputYN.type) {
                                if (onNullCheck(comSINGLE_INPUT_YN)) { // 선택 일 경우 기본으로 단독인지 분산인지 확인 후에 데이터 출력 되도록 한다.(선택으로 저장 했는데 선택으로 안나오면 이 부분 때문(현업 요청))
                                    ucMasterRealgrid_dataProvider.setValue(v, "SINGLE_INPUT_YN", _DataInfo.DataRow.INSP_RESULT);
                                } else {
                                    ucMasterRealgrid_dataProvider.setValue(v, "SINGLE_INPUT_YN", comSINGLE_INPUT_YN);
                                }
                            }

                            if (confirm.type) {
                                ucMasterRealgrid_dataProvider.setValue(v, dblClickedColumns[_DataInfo.SelectColumn].NAME + "_CONFIRM", confirm.notevalue);
                            }
                        });

                        CollapseSlideArea();
                        setAlert(message);
                    }
                }
            }, param, "POST", url);
        }
        // #endregion

        // #region validation
        var validation = function (type, value) {
            var msg = "<%=lang.message["25062"]%>";
            var vReturn = false;

            switch (type) {
                case "areaID": // 공장동 선택여부
                    msg = '<%=lang.message["10012"]%>';

                    if (onNullCheck(value)) {
                        msg = msg.replace("%1", "<%=lang.word["Shop/Area"]%>");
                        setAlert(msg);

                        vReturn = true;
                    }
                    break
                case "singleInputYN": // 단독투입 여부 입력 확인
                    if (_DataInfo.SelectColumn != "PROC_PLAN_A") {
                        if (onNullCheck(value)) {
                            msg = msg.replace("%1", "<%=lang.word["Independent input or not"]%>");
                            setAlert(msg);

                            vReturn = true;
                        }
                    }
                    break
                case "procPlan": // 처리방안 입력 확인
                    if (onNullCheck(value)) {
                        msg = msg.replace("%1", "<%=lang.word["Action plan"]%>");
                        setAlert(msg);

                        vReturn = true;
                    }
                    break
                case "checkRows":  // 선택 된 데이터 여부 확인
                    if (ucMasterRealgrid_gridView.getCheckedRows().length <= 0) {
                        setAlert('<%=lang.message["10008"]%>');
                        vReturn = true;
                    }
                    break
                case "maxCheckRows": // 최대 가능 선택 ROW 수
                    if (ucMasterRealgrid_gridView.getCheckedRows().length > maxCheckCount) {
                        setAlert('MAX CHECK : ' + maxCheckCount);
                        vReturn = true;
                    }
                    break
                case "prodCheck": // 제품코드 다른지 체크
                    if (value.fromPRODID !== value.toPRODID) {
                        setAlert("<%=lang.message["255178"]%>".replace("%1", "<%=lang.word["Product ID/Name"]%>"));
                        vReturn = true;
                    }
                    break
                case "confirmCheck":  // 확정 여부 체크
                    if (value != "Y") {
                        setAlert("<%=lang.message["255432"]%>");
                        vReturn = true;
                    }
                    break
                case "single_input_ynCheck": // 단독투입여부 다른지 체크
                    if (value.fromSINGLE_INPUT_YN !== value.toSINGLE_INPUT_YN) {
                        setAlert("<%=lang.message["255178"]%>".replace("%1", "<%=lang.word["Independent input or not"]%>"));
                        vReturn = true;
                    }
                    break
                case "holdCheck": // 투입보류 체크
                    if (value === "H") {
                        setAlert("<%=lang.message["255178"]%>".replace("%1", "<%=lang.word["Input hold"]%>"));
                        vReturn = true;
                    }
                    break
            }
            
            return vReturn;
        }

        // #endregion

        // #region lotList
        var lotList = function () {
            let chkRows = ucMasterRealgrid_gridView.getCheckedRows();
            let lotItems = '';

            for (var i = 0; i < chkRows.length; i++) {

                let dataRow = ucMasterRealgrid_dataProvider.getJsonRow(chkRows[i]);
                lotItems += "'" + dataRow.LOTID + "',";

            }

            lotItems = lotItems.substring(0, lotItems.length - 1);

            return lotItems;
        }
        // #endregion

        function buttonCheck(id) {
            try {
                switch (id) {
                    case "btnSave":
                        if (!validation("procPlan", $("#txtPROC_PLAN").textbox('getValue'))) {
                            setConfirm('<%=lang.message["10073"]%>', function (parm) { if (parm) { Save('SAVE'); } });
                        }
                        break;
                    case "btnConfirm":
                        var type = true;

                        if (validation("procPlan", $("#txtPROC_PLAN").textbox('getValue'))) {
                            type = false;
                        }

                        if (classification[$("input[name='Classification']:checked").val()].planBType) {
                            if (validation("singleInputYN", $('#comSINGLE_INPUT_YN').combobox('getValue'))) {
                                type = false;
                            }
                        }

                        if (type) {
                            setConfirm('<%=lang.message["20023"]%>', function (parm) { if (parm) { Save('CONFIRM'); } });
                        }
                        break;
                    case "btnCancel":
                        setConfirm('<%=lang.message["25051"]%>', function (parm) { if (parm) { Save('CANCEL'); } });
                        break;
                    case "btnAbnormalCalc": // 분산투입계산
                        var type = true;

                        if (validation("checkRows", null)) {
                            type = false;
                        }

                        if (validation("maxCheckRows", null)) {
                            type = false;
                        }

                        if (type) {
                            CollapseSlideArea(); // 팝업 닫기
                            var title = '<%=lang.word["DistributedInjection"]%> <%=lang.word["Calculation"]%>';

                            var data = {};
                            data["LOTLIST"] = lotList();

                            const queryString = Object.keys(data).map(function (key) { return (key + "=" + encodeURIComponent(data[key])) }).join('&');
                            const encodedData = btoa(queryString);

                            ShowPopup("../GMES_IM_POM/GMES_IMES_0560_05.aspx?MENU_ID=" + XSSReplace($("[id$=hidMenuID]").val(), 1) + "&TYPE=" + $('input:radio[name="Classification"]:checked').val() + "&TITLE=" + title + "&LOTLIST=" + encodedData, "1300", Math.floor(window.innerHeight * 0.8), title, RegCallBack);
                        }
                        break;
                    case "btnInputList": //투입 List 작성
                        var single_dispersion_type = false; // 혼합 여부

                        var InputListValidation = function () {
                            if (validation("checkRows", null)) {
                                return false;
                            }

                            let chkRows = ucMasterRealgrid_gridView.getCheckedRows();
                            let conData = ucMasterRealgrid_dataProvider.getJsonRow(chkRows[0]);//체크된 첫번째 DataItem

                            for (var i = 0; i < chkRows.length; i++) {

                                let dataRow = ucMasterRealgrid_dataProvider.getJsonRow(chkRows[i]);

                                if (validation("prodCheck", { fromPRODID: conData.PRODID, toPRODID: dataRow.PRODID })) {
                                    return false;
                                }

                                if (validation("confirmCheck", dataRow.PROC_PLAN_A_CONFIRM)) {
                                    setAlert("<%=lang.message["255432"]%>");
                                    return false;
                                }

                                if (classification[$("input[name='Classification']:checked").val()].planBType) {
                                    if (validation("confirmCheck", dataRow.PROC_PLAN_B_CONFIRM)) {
                                        return false;
                                    }

                                    // 20250731 요청 사항으로 단독, 분산 혼합 허용
                                    //if (validation("single_input_ynCheck", { fromSINGLE_INPUT_YN: conData.SINGLE_INPUT_YN, toSINGLE_INPUT_YN: dataRow.SINGLE_INPUT_YN })) {
                                    //    return false;
                                    //}
                                    // 20250731

                                    if (validation("holdCheck", dataRow.SINGLE_INPUT_YN)) {
                                        return false;
                                    }

                                    // 20250812 혼합 여부 확인
                                    if (dataRow.SINGLE_INPUT_YN != conData.SINGLE_INPUT_YN) {
                                        single_dispersion_type = true;
                                    }
                                    // 20250812
                                }
                            }
                            return true;
                        }

                        if (InputListValidation() == true) {
                            CollapseSlideArea(); // 팝업 닫기

                            var title = '<%=lang.word["Input List"]%>';
                            var param = "";

                            param += "&AREAID=" + $('#cboArea').combobox('getValue');
                            param += "&LOTID=" + lotList();
                            param += "&SINGLEINPUTYNTYPE=" + classification[$("input[name='Classification']:checked").val()].planBType;
                            param += "&SINGLE_DISPERSION_TYPE=" + single_dispersion_type;

                            ShowPopup("../GMES_IM_POM/GMES_IMES_0560_01.aspx?MENU_ID=" + XSSReplace($("[id$=hidMenuID]").val(), 1) + param, "1200", Math.floor(window.innerHeight * 0.9), title, RegCallBack);
                        }
                        break;
                    case "btnManagement": //관리 기준
                        CollapseSlideArea(); // 팝업 닫기
                        var title = "<%=lang.word["관리기준"]%>";

                        var param = "";

                        param += "&AREAID=" + $('#cboArea').combobox('getValue');

                        var MtrlType = $('input:radio[name="Classification"]:checked').val();
                        ShowPopup("../GMES_IM_POM/GMES_IMES_0560_02.aspx?MENU_ID=" + XSSReplace($("[id$=hidMenuID]").val(), 1) + "&MTRLTYPE=" + MtrlType + "&TITLE=" + title + param, "P_95", "P_80", title, clearColumnLayout);
                        break;
                    case "btnSpecManagement": //검사항목 지정 정보
                        CollapseSlideArea(); // 팝업 닫기
                        ShowPopup("../GMES_IM_POM/GMES_IMES_0560_03.aspx?MENU_ID=" + XSSReplace($("[id$=hidMenuID]").val(), 1) + "", "900", Math.floor(window.innerHeight * 0.9), "<%=lang.word["Specify Inspection Item"]%>", clearColumnLayout);
                        break;
                    case "btnClose":
                        CollapseSlideArea();
                        _DataInfo = null;
                        break;
                    case "btnChart":
                        CollapseSlideArea(); // 팝업 닫기

                        // 기존
                        var Param = "";
                        var LANGID = XSSReplace($("[id$=hidLangID]").val(), 1);
                        var SHOPID = XSSReplace(XSSReplace($("[id$=hidShopID]").val(), 1), 1);
                        var AREAID = $('#cboArea').combobox('getValue');
                        var WHID = $('#cbo_Warehouse').combobox('getValue');
                        var MTRLTYPE = $('input:radio[name="Classification"]:checked').val();
                        var PRODID = $("#txtProductCode").textbox("getText").trim();
                        var INLOTID = $('#txt_LotID').textbox('getValue');
                        var varLots = ""; //다중LOT 검색
                        if (INLOTID != '') {


                            var items = [];
                            var subItems = [];

                            var arrLotItems = [];
                            var splitItems = $('#txt_LotID').textbox('getText').split('\n');

                            splitItems.forEach(function (value, index, array) {
                                var trimValue = $.trim(value);
                                if (trimValue.length > 0) {
                                    arrLotItems[index] = trimValue;
                                };
                            });

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

                            arrLotItems.unique();

                            if (arrLotItems.length > 0) {
                                if (arrLotItems.length < 2) {
                                    varLot = arrLotItems[0];
                                }
                                else {
                                    arrLotItems.forEach(function (value, index, array) {
                                        if (value.length > 0) {
                                            varLots += (varLots.length > 0 ? "," : "") + "'" + value + "'";
                                        }
                                    });
                                }

                            }
                        }

                        Param += "&AREAID=" + AREAID + "&WHID=" + WHID;
                        Param += "&MTRLTYPE=" + MTRLTYPE + "&PRODID=" + PRODID;
                        Param += "&INLOTID=" + varLots;

                        ShowPopup("../GMES_IM_POM/GMES_IMES_0560_04.aspx?MENU_ID=" + XSSReplace($("[id$=hidMenuID]").val(), 1) + Param, "P_80", "P_80", "<%=lang.word["WareHouse_List_Tab"]%>", function () { });
                        // 기존
                        break;
                    default:
                        break;
                }

            } catch (e) {
                setAlert(e.message);
            }
        }
        // #endregion

        // #region Excel
        function onExcelButtonClick(grid, gridView) {
            try {
                GridToExcel(grid, gridView);
            } catch (e) {
                setAlert(e.message);
            }
        }

        function GridToExcel(grid, gridView) {
            if (grid.GetRowCount() == 0) {
                setAlert('<%=lang.message["20051"]%>');
                return;
            }

            var title = parent.$('#tt').tabs('getSelected').panel('options').title; // 선택한 화면의 title 명

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

        // #region ShowProductCodePopup - 제품코드명 팝업창을 Open한다.
        function ShowProductCodePopup(value) {
            ShowPopup("../GMES_COM/GMES_COM_0003.aspx?DVALUE=PROD&MENU_ID=" + $("[id$=hidMenuID]").val() + "&PROD_SEARCH=" + value, 790, 500, "<%=lang.word["Inquiry Product"]%>", SetProductName);
        }

        function SetProductName(data) {
            if (data !== undefined && data.length > 0) {
                $("#txtProductCode").textbox('setValue', data[2]);
                $("#txtProductName").textbox('setValue', data[1]);
            }
        }
        // #endregion

        // #region 카운트
        function setTotalCount(count) {
            if (!onNullCheck(count)) {
                count[0].text(count[1]);
            }
        }
        // #endregion

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

            CollapseSlideArea();

            setTotalCount([$("#ucMasterTotalConunt"), 0]);
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

        // #region Loading
        function GridShowLoading() {
            $("#LoadingPanel").show();
        }

        function GridCloseLoading() {
            $("#LoadingPanel").hide();
        }
        // #endregion

        // #region 정보창 호출
        function setAlert(msg) {
            xAlert(msg);
            centerDialog(window.top.$(panelPopupClass));
        }

        function setConfirm(msg, callback) {
            xConfirm(msg, callback);
            centerDialog(window.top.$(panelPopupClass));
        }
        // #endregion

        // #region 다이얼로그를 화면의 가운데로 위치시키는 함수
        function centerDialog($dialog) {
            const windowHeight = $(window).height();
            const windowWidth = $(window).width();
            const dialogHeight = $dialog.outerHeight();
            const dialogWidth = $dialog.outerWidth();

            const top = (windowHeight - dialogHeight) / 2 + $(window).scrollTop();
            const left = (windowWidth - dialogWidth) / 2 + $(window).scrollLeft();

            $dialog.css({
                top: top,
                left: left
            });
        }
        // #endregion


    </script>
</asp:Content>

<asp:Content ID="Content1" ContentPlaceHolderID="bodyHolder" runat="server">
    <form id="form2" runat="server">
        <!-- hidden Field Start-->
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidMenuID" runat="server" />
        <!-- hidden Field End-->
        <asp:ScriptManager runat="server" ID="ScriptManager2"></asp:ScriptManager>

        <!-- 검색조건 영역 시작  -->
        <div class="tableInquiry searchBox" id="divSearchArea">
            <div class="itemBox">
                <table>
                    <tbody>
                        <tr>
                            <th rowspan="2" class="th_auto"><span class="textPink">*</span><%=lang.word["Classification"]%></th>
                            <td rowspan="2" class="td_fix_rdo">
                                <div id="divClassification" >
                                    <label><input type="radio" id="rdoFGoods" name="Classification" value="GOOD" /><%=lang.word["Finished Goods"]%></label>
                                    <label><input type="radio" id="rdoHGoods" checked="checked" name="Classification" value="ASSY" /><%=lang.word["Half-Finished Goods"]%></label>
                                    <label><input type="radio" id="rdoRawMaterial" name="Classification" value="RAW" /><%=lang.word["Raw Material"]%></label>
                                </div>
                            </td>
                            
                            <th class="th_auto"><span class="textPink">*</span><%=lang.word["Shop/Area"]%></th> <!-- 공장/동 -->
                            <td class="td_fix" name="cboSelect">
                                <input id="cboArea" data-options="valueField: 'AREAID',textField: 'AREANAME_ML', cBoopt: 'OPT'" class="easyui-combobox search_width"  />
                            </td>

                            <th class="th_fix"><span class="textPink" id="textStorageLocationPink" style ="display:none">*</span><%=lang.word["StorageLocation"]%></th> <!-- 창고 -->
                            <td class="td_fix" name="cboSelect">
                                <input id="cbo_Warehouse" data-options="valueField: 'WHID',textField: 'WHNAME', cBoopt: 'ALL'" class="easyui-combobox search_width" />
                            </td> 

                            <th class="th_auto"><%=lang.word["LOT ID"]%></th> 
                            <td class="td_fixEnd" rowspan="2">
                                <input id="txt_LotID" class="easyui-textbox  search_width" style="height:100%; max-height:60px" data-options="multiline:true"/>
                            </td>
                        </tr>
                        <tr>
                            <!-- 제품코드 -->
                            <th><%=lang.word["Product Code"]%></th>
                            <td colspan="3">
                                <div style="width: 100%; display: flex;">
                                    <div class="td_fix">
                                        <input id="txtProductCode" class="easyui-searchbox" style="display: inline-block; width: 100%;" data-options="searcher:ShowProductCodePopup, inputEvents: $.extend({}, $.fn.searchbox.defaults.inputEvents, { keyup: function(e){ $('#txtProductName').textbox('setText', ''); } })" />
                                    </div>
                                    <div style="width: 330.5px; padding-left: 5px;">
                                        <input id="txtProductName" class="easyui-textbox" style="display: inline-block; width: 100%;" disabled="disabled" readonly="readonly" />
                                    </div>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <div id="divButtonArea" class="tableBtnSearch" >
                <button type="button" id="btnSearch" onclick="javascript:GetMasterData();"><span><%=lang.word["Search"]%></span></button><!-- 조회 -->
            </div>
            <uc:SearchToggleContent ID="SearchToggleContent1" runat="server" />
            <div class="clear"></div>
        </div>
        <!-- 검색조건 영역 끝 -->

        <div id="divDetailContent">
            <div class="buttonArea" id="divButton">
                <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucMasterTotalConunt" class='red01'>0</span> Found )</div>
                <ul runat="server" class="btn_crud">
                    <li class="custom-li">
                       <span style="margin-right:5px;"><%=lang.word["Inspection Result"]%> <%=lang.word["Status"]%> : </span>
                       <span style="color:#0019F4; font-weight: bold; margin-right:5px;"><%=lang.word["LessThan"]%></span>
                       <span style="margin-right:5px;">/</span>
                       <span style="color:#ff0000; font-weight: bold; margin-right:5px;"><%=lang.word["Excess"]%></span>
                       <span style="margin-right:5px;">/</span>
                       <span style="font-weight: bold;"><%=lang.word["Normal"]%></span>
                    </li>
                    <li><a class="table_bar"></a></li>
                    <li><a class="save" id="btnChart" onclick="buttonCheck(this.id)"><span><%=lang.word["COM_NCR"]%> <%=lang.word["WareHouse_List_Tab"]%></span></a></li>
                    <li><a class="save" id="btnAbnormalCalc" onclick="buttonCheck(this.id)"><span><%=lang.word["DistributedInjection"]%> <%=lang.word["Calculation"]%></span></a></li>
                    <li><a class="table_bar"></a></li>
                    <li><a class="save" id="btnInputList" onclick="buttonCheck(this.id)"><span><%=lang.word["Input List"]%> <%=lang.word["Write"]%> </span></a></li>
                    <li><a class="save" id="btnManagement" onclick="buttonCheck(this.id)"><span><%=lang.word["InternalManagementStandards"]%></span></a></li>
                    <li><a class="save" id="btnSpecManagement" onclick="buttonCheck(this.id)"><span><%=lang.word["Management Inspection Item"]%></span></a></li>
                    <li><a class="table_bar"></a></li>
                    <li><a class="excel" onclick="onExcelButtonClick(ucMasterRealgrid, ucMasterRealgrid_gridView)"></a></li>
                </ul>
            </div>
            <div name="realGrid" id="ucMaster" data-options='{"group":true}' class="table">
                <uc:Realgrid ID="ucMasterRealgrid" CALLID="ucMasterRealgrid" HEIGHT="200" runat="server" LAYOUTSAVING="Y" />
                <div id="LoadingPanel" class="modal"></div>         
            </div>
        </div>
        <div id="div_disabled" class="parentDisable" style="display: none"></div>
        <div id="div_popup" class="winPop dvMinheight" style="width: 400px; height: 350px; display: none"></div>
    </form>
</asp:Content>

<asp:Content ID="UISlideContent" ContentPlaceHolderID="slideHolder" runat="server">
    <div id="divSlideTap" class="easyui-tabs" data-options="fit:true" style="height: 300px">
         <div id="divIncInsert" title="<%=lang.word["Action plan"]%>" style="margin-top: 5px;"> 
                <div id="divIncInsertContent" style="padding-left: 10px; padding-right: 10px">
                    <div id="divButtonInsert" class="buttonArea">
                        <ul id="ulInsertButton" runat="server" class="btn_crud" style="margin: 5px 0px 0px 0px;">
                            <li><a class="save" id="btnSave"     onclick="buttonCheck(this.id)"><span><%=lang.word["Save"]%></span></a></li>
                            <li><a class="save" id="btnConfirm"    onclick="buttonCheck(this.id)"><span><%=lang.word["Confirm"]%></span></a></li>
                            <li><a class="save" id="btnCancel"      onclick="buttonCheck(this.id)"><span><%=lang.word["Cancel"]%></span></a></li>
                            <li><a class="table_bar"></a></li>
                            <li><a  id="btnClose" onclick="buttonCheck(this.id)" ><span><%=lang.word["Close"]%></span></a></li>
				        </ul>
                    </div>
                    <table id="tblInsertContent" class="tableGeneral" >
                        <tbody>
                            <tr>
					            <td colspan="4" style="padding-top: 0px; padding-bottom: 0px; height: 2px; background-color: brown; "></td>                                                           
				            </tr>
				            <tr style="height: 32px;">
                                <th align="right" style="min-width: 150px; max-width: 150px;"><%=lang.word["LOTIDUSER"]%></th>
                                <td colspan="3" >
                                    <input id="txtLOTIDUSER" class="easyui-textbox-border" style="width: 100%; border: none; " readonly="readonly" />
                                </td>
                            </tr>
                            <tr id="trSINGLE_INPUT_YN" style="height: 32px;">
                                <th align="right" style="min-width: 150px; max-width: 150px;"><%=lang.word["Independent input or not"]%></th>
                                <td colspan="3" >
                                    <div id="divTxtSINGLE_INPUT_YN" style="width: 100%">
                                        <input id="txtSINGLE_INPUT_YN" class="easyui-textbox-border" style="width: 100%; border: none; " readonly="readonly" />
                                    </div>
                                    <div id="divComSINGLE_INPUT_YN" style="width: 100%">
                                        <input id="comSINGLE_INPUT_YN" class="easyui-combobox" style="min-width: 100px; max-width: 100px;  border: none; " />
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <th align="right" style="min-width: 150px; max-width: 150px;" id="txtTitle" rowspan="3"> </th><%--<%=lang.word["생산팀"]%>--%>
                                <td colspan="3" rowspan="3">
                                    <input id="txtPROC_PLAN" class="easyui-textbox" style="width: 100%; height: 120px;" data-options="multiline:true" />
                                </td>
                            </tr>
                            </tbody>
                        </table>
                </div>
           </div>
     </div>               
</asp:Content>