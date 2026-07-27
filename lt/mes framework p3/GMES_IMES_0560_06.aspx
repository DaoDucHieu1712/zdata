<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPopup.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0560_06.aspx.cs" Inherits="GMES_IMES_0560_06" %>
<%--/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0560_06.aspx
* @desc    : 생산실적 - 이상품 추적 - 확정 취소 팝업
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2025/08/14   오정균              INIT
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
        //#region 변수
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
            GetData();
        }
        //#endregion

        //#region realGrid
        //#region Main Realgrid Field, Column 설정
        var vMasterRealgridFieldColumn = [
            { fieldName: "PRODTYPE", columnSetting: { type: "logic", header: "PRODTYPE" } },

            { fieldName: "PRODID", columnSetting: { type: "main_id", header: "<%=lang.word["PRODID"]%>" } },
            { fieldName: "PRODNAME", columnSetting: { type: "main_name", header: "<%=lang.word["Drawing No. Name"]%>" } },
            { fieldName: "PLOTID", columnSetting: { type: "logic", header: "PLOTID" } },
            { fieldName: "PLOTID_USER", columnSetting: { type: "main_lotid", header: "<%=lang.word["BATCH"]%>" } },
            {
                type: "group",
                name: "Confirm",
                header: "<%=lang.word["Action plan"]%>" + "( " + "<%=lang.word["production team"]%>" + " )",
                columns: [
                    { fieldName: "PROC_PLAN_A_CONFIRM", columnSetting: { type: "logic", header: "PROC_PLAN_A_CONFIRM" } },
                    { fieldName: "PROC_PLAN_A_CONFIRM_NM", columnSetting: { type: "main_inputYN", header: "<%=lang.word["Confirm"]%>" } },
                    { fieldName: "PROC_PLAN_A", columnSetting: { type: "main_plan", header: "<%=lang.word["Action plan"]%>" } }
                ]
            },
            {
                type: "group",
                name: "Confirm",
                header: "<%=lang.word["Action plan"]%>" + "(" + "<%=lang.word["technical team"]%>" + ")",
                columns: [
                    { fieldName: "PROC_PLAN_B_CONFIRM", columnSetting: { type: "logic", header: "PROC_PLAN_B_CONFIRM" } },
                    { fieldName: "PROC_PLAN_B_CONFIRM_NM", columnSetting: { type: "main_inputYN", header: "<%=lang.word["Confirm"]%>" } },
                    { fieldName: "SINGLE_INPUT_YN", columnSetting: { type: "logic", header: "SINGLE_INPUT_YN" } },
                    { fieldName: "SINGLE_INPUT_NM", columnSetting: { type: "main_inputYN", header: "<%=lang.word["Independent input or not"]%>" } },
                    { fieldName: "PROC_PLAN_B", columnSetting: { type: "main_plan", header: "<%=lang.word["Action plan"]%>" } }
                ]
            }
        ];
        //#endregion
 
        //#region 컬럼 타입 별 기준 정보 변경
        var setTypeColumn = function (vType, vColumn) {
            switch (vType) {
                case "logic":
                    vColumn.visible = false;
                    vColumn.width = 0;
                    break
                case "main_id":
                case "main_lotid":
                    vColumn.width = 200;
                    break
                case "main_name":
                    vColumn.width = 250;
                    break
                case "main_plan":
                    vColumn.width = 300;
                    vColumn.styles.textWrap = "normal";
                    break
                case "main_inputYN":
                    vColumn.width = 120;
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

        //#region column / field 
        function setColumnSetting(fieldColumns, fields, columns) {
            fieldColumns.forEach(function (a) {
                var vGroupWidth = 0;
                var masterColumns = [];

                if (a.type == "group") {
                    a.columns.forEach(function (b) {
                        fields.push({ fieldName: b.fieldName, dataType: onNullCheck(b.dataType) ? 'text' : b.dataType });
                        var column = setColumn(b.columnSetting.type, b.fieldName, b.columnSetting.header, { type: true });
                        vGroupWidth += (column.visible) ? column.width : 0;

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
                    fields.push({ fieldName: a.fieldName, dataType: onNullCheck(a.dataType) ? 'text' : a.dataType });
                    columns.push(setColumn(a.columnSetting.type, a.fieldName, a.columnSetting.header, { type: false }));
                }
            });
        }
        //#endregion

        //#region realGrid Init
        function InitMainRealgrid() {
            var fields = [];
            var columns = [];

            setColumnSetting(vMasterRealgridFieldColumn, fields, columns);

            /*메뉴 ID 에 null을 등록하면 컬럼별 빼고 안빼고를 설정 할 수 없다. 일단은 NULL로 */
            ucMasterRealgrid.Init(null, fields, columns, true, true, true);
 
            realGridSet(ucMasterRealgrid_gridView, true);
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
                fitStyle: "even", // 컬럼 채우기 "none" 이면 설정한 넓이 기준
                eachRowResizable: true // 개별 행 높이 설정
            });
 
            if (isGroup) {
                gridView.setHeader(
                    { height: 50 } // 헤더 높이 +10
                );
            }
        }
        //#endregion
        //#endregion
 
        //#region 조회
        function GetData() {
            var items = {};
            items.LANGID = XSSReplace($("[id$=hidLangID]").val(), 1); 
            items.SHOPID = XSSReplace($("[id$=hidShopID]").val(), 1);
            items.AREAID = XSSReplace($("[id$=hidAREAID]").val(), 1);
            items.PRODID_LIST = $("[id$=hidPRODIDLIST]").val();

            var param = {};
            param.bizID = "DA_IM_STK_SEL_RACK_ABNORMAL_CONFIRM";
            param.items = items;
            param.inTableNames = 'RQSTDT';
            param.outTableNames = 'RSLTDT';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            ucMasterRealgrid.CallRequest(url, param, function () {
                setTotalCount([$("#ucMasterTotalConunt"), ucMasterRealgrid.GetRowCount()]);
                ucMasterRealgrid_gridView.checkAll(true, false);
                ucMasterRealgrid_gridView.fitRowHeightAll(0, true);
            });
        }
        //#endregion

        // #region validation
        var validation = function (type) {
            var vReturn = false;

            switch (type) {
                case "checkRows":  // 선택 된 데이터 여부 확인
                    if (ucMasterRealgrid_gridView.getCheckedRows().length <= 0) {
                        xAlert('<%=lang.message["10008"]%>');
                        vReturn = true;
                    }
                    break
            }

            return vReturn;
        }
        //#endregion


        /* NOTETYPE 정의
        NT58 처리방안(생산팀)
        NT59 처리방안(기술팀)
        NT60 처리방안(생산팀) 확정
        NT61 처리방안(기술팀) 확정
        NT62 단독투입 여부*/

        //#region 저장
        var save = function () {
            let chkRows = ucMasterRealgrid_gridView.getCheckedRows();
            var subItems = [];

            var funSubItems = function (subItems, items) {
                subItems.push([
                    { name: "LOTID", value: items.LOTID, dataType: _DataType.String }
                    , { name: "NOTETYPE", value: items.NOTETYPE, dataType: _DataType.String }
                    , { name: "LOTNOTE", value: items.NOTEVALUE, dataType: _DataType.String }
                    , { name: "MTRLTYPE", value: items.MTRLTYPE, dataType: _DataType.String }
                    , { name: "USERID", value: '<%=SSUser.UserID%>', dataType: _DataType.String }
                ]);
            }

            for (var i = 0; i < chkRows.length; i++) {
                let dataRow = ucMasterRealgrid_dataProvider.getJsonRow(chkRows[i]);
                var mtrltype = (dataRow.PRODTYPE != 'RAW' ? 'PROD' : dataRow.PRODTYPE);

                if (dataRow.PROC_PLAN_A_CONFIRM == 'Y') {
                    funSubItems(subItems, { LOTID: dataRow.PLOTID, NOTETYPE: "NT60", NOTEVALUE: 'N', MTRLTYPE: mtrltype });
                }

                if (dataRow.PROC_PLAN_B_CONFIRM == 'Y') {
                    funSubItems(subItems, { LOTID: dataRow.PLOTID, NOTETYPE: "NT61", NOTEVALUE: 'N', MTRLTYPE: mtrltype });
                }

                if (!onNullCheck(dataRow.SINGLE_INPUT_YN)) {
                    funSubItems(subItems, { LOTID: dataRow.PLOTID, NOTETYPE: "NT62", NOTEVALUE: '', MTRLTYPE: mtrltype });
                }
            }

            var param = {};
            var items = [];

            param.bizID = "BR_IM_BAS_REG_ABNORMAL_PROD_LOTNOTE";
            items[0] = subItems;
            
            var url = "/GMES_IM_POM/GMES_IMES_0560.aspx/ExecuteData";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = '';

            GridShowLoading();
            sendRequestMethod(function (id, data) {
                if (data.length > 0) {
                    if (data[0].RETURN === 'OK') {
                        // 20250819
                        CallBackCloseDialog(true);
                        // 20250819
                    }
                }
            }, param, "POST", url);
        }
        //#endregion

        //#region 버튼클릭
        function buttonCheck(id) {
            try {
                switch (id) {
                    case "btnSave"://확정 취소
                        ucMasterRealgrid_gridView.commit(true);

                        if (!validation("checkRows")) {
                            xConfirm('<%=lang.message["IMS0011"]%>', function (parm) { if (parm) { save(); } });
                        }
                        break;

                    case "btnClose"://닫기
                        CallBackCloseDialog(false);
                        break;

                    default:
                }
            } catch (e) {
                xAlert(e.message);
            }
        }
        //#endregion

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
    <form id="form1" runat="server">
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidMenuID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidAREAID" runat="server" />
        <asp:HiddenField ID="hidPRODIDLIST" runat="server" />
        
        <div id="divMasterContent">
            <div id="div_ButtonArea" class="buttonArea" style="padding:0px 10px 0px 10px;">
                <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> (Total <span id="ucMasterTotalConunt" class='red01'>0</span> Found )</div>
                <ul runat="server" class="btn_crud">
                    <li><a class="save" id="btnSave" onclick="buttonCheck(this.id)"><span><%=lang.word["Cancel Confirmation"]%></span></a></li> <!--확정 취소 -->
                    <li><a class="close" id="btnClose" onclick="buttonCheck(this.id)"><span><%=lang.word["Close"]%></span></a></li>
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