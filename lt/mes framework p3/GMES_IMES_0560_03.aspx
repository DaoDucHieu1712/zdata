<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPopup.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0560_03.aspx.cs" Inherits="GMES_IMES_0560_03" %>
<%--/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0560_03.aspx
* @desc    : 생산실적 - 이상품 추적 - 검사항목 관리
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2024/10/13   송상호              INIT
* 1.1  2025/06/27   오정균              수정(검사항목 크기 변경)
*************************************************************************************************
*/--%>

<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>

<%-- Fucntion --%>
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
            width: 200px;
            max-width: 200px;
        }
        .td_fix_rdo {
            width: 280px;
            max-width: 280px;
        }
        .td_fixEnd {
            width: 200px;
            max-width: 200px;
        }
        .search_width {
            width: 210px;
        }

        .checkbox-dn input[type="checkbox"] {
            display: none !important;
        }
    </style>
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js?v=20240130"></script>
    <script language="javascript" type="text/javascript">
        let IS_SAVE = false; // 저장여부

        $(document).ready(function () {
            InitMasterGrid();
            InitControl();
        });

        $(window).resize(function () {
            AutoHeightSpread(true);
        });

        function xInitPage() {
            AutoHeightSpread();
        };

        function AutoHeightSpread() {
            var gridMaster = document.getElementById("ucMasterRealgrid");
            var pageHeight = document.documentElement.clientHeight;
            var gridHeight = 0; // 높이
            var fixHeight = 25;

            var funCss = function (id, style) {
                var value = id.css(style);
                return (onNullCheck(value) ? 0 : parseInt(value.replace(/[^0-9]/g, "")));
            }

            var divSearchArea = $("#divSearchArea"); // 화면 조회조건
            var divSearchAreaHeight = divSearchArea.height() + funCss(divSearchArea, 'margin-bottom'); // 화면 조회조건 높이 (margin 포함)
            var divButton = $("#divButton"); // 화면 버튼
            var divButtonHeight = divButton.height() + funCss(divButton, 'margin-bottom'); // 화면 버튼(엑셀) 높이 (margin 포함)

            gridHeight = pageHeight - divSearchAreaHeight - divButtonHeight - fixHeight;

            gridMaster.style.height = String(gridHeight) + 'px';
            ucMasterRealgrid.ResetSize();
        };

        function InitControl() {
            SetComboYN();
        }

        // 마스터 그리드 생성
        function InitMasterGrid() {
            ucMasterRealgrid.Init("<%=ViewState["MENU_ID"].ToString()%>", vRealgridMasterFields, vRealgridMasterColumns, true, true, true);
            ucMasterRealgrid_gridView.setDisplayOptions({ fitStyle: "even" });
            ucMasterRealgrid_gridView.setCheckBar({ visible: false });
            ucMasterRealgrid_gridView.setStateBar({ visible: true });
            var options = ucMasterRealgrid_gridView.getSortingOptions();
            options.enabled = false;
            ucMasterRealgrid_gridView.setSortingOptions(options);
            ucMasterRealgrid_gridView.setEditOptions({ enterToNextRow: true });
            ucMasterRealgrid_gridView.setEditOptions({
                insertable: false,
                appendable: false
            });
            //var vFilters = ["CLCTNAME"];
            //ucMasterRealgrid.SetColsFilter(vFilters);

            ucMasterRealgrid_gridView.addCellStyle("EditCellStyle", {
                "editable": true,
                "background": "#ffffe6"
            }, true);

            // 20250708
            ucMasterRealgrid_gridView.onCellEdited = function (grid, itemIndex, dataRow, field) {
                var good = grid.getValue(itemIndex, "GOOD");
                var assy = grid.getValue(itemIndex, "ASSY");
                var raw = grid.getValue(itemIndex, "RAW");

                if (good == "GOOD" || assy == "ASSY" || raw == "RAW") {
                    grid.setValue(itemIndex, "USEYN", "Y");
                } else {
                    grid.setValue(itemIndex, "USEYN", "N");
                }
            };
            // 20250708
        }

        function Search_MainData() {
            ucMasterRealgrid_gridView.commit(true);

            var cbo_use = $('#cbo_use').combobox('getValue');
            var Inspection = $("#txt_Inspection").textbox('getValue');

            var items = {};
            items.LANGID = XSSReplace($("[id$=hidLangID]").val(), 1); // 언어
            items.CMCDTYPE = "CM_QUALITEM";
            items.ITEMTYPE = "'PROD'";
            if (Inspection.length > 0) {
                items.CLCTITEM = Inspection;//검사항목
            }

            items.USEYN = cbo_use;//사용여부

            var param = {};
            param.bizID = "BR_IM_COM_GET_PROD_CLCTITEM";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = 'OUTDATA';

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";
            ucMasterRealgrid.CallRequest(url, param, function () {
                setTotalCount(ucMasterRealgrid.GetRowCount());

                for (var idx = 0; idx < ucMasterRealgrid.GetRowCount(); idx++) {
                    ucMasterRealgrid_gridView.setCellStyle(idx, "CLCTSEQ", "EditCellStyle", true);
                }
            });
        }

        function SetComboYN() {
            $('#cbo_use').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_CommonCode&LANGID=' + '<%=SSUser.LangID%>' + '&CMCDTYPE=COUNTERPLANFLAG&CBOOPT=ALL|CMCODE|CMCDNAME',
               valueField: 'CMCODE',
               textField: 'CMCDNAME',
               onLoadSuccess: function () {

                   var items = $(this).combobox("getData");
                   if (items.length === 3) {
                       var opts = $(this).combobox("options");
                       /*$(this).combobox("select", items[1][opts.valueField]);*/
                       $(this).combobox("select", "Y");
                       Search_MainData();
                   }
               }
           });
        }

        function buttonCheck(id) {
            try {
                switch (id) {
                    case "btnSave"://저장
                        if (saveValidation() === true) {
                            xConfirm('<%=lang.message["10073"]%>', function (parm) { if (parm) { save(); } });
                        }

                        break;

                    case "btnClose"://저장
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

        var saveValidation = function () {
            ucMasterRealgrid_gridView.commit(true);

            var updateList = ucMasterRealgrid_dataProvider.getStateRows('updated');

            if (updateList.length <= 0) {
                xAlert('<%=lang.message["9019"]%>');
                return false;
            }

            return true;
        }

        var searchValidation = function () {
            ucMasterRealgrid_gridView.commit(true);

            var updateList = ucMasterRealgrid_dataProvider.getStateRows('updated');

            if (updateList.length > 0) {
                xAlert('<%=lang.message["9019"]%>');
                return false;
            }

            return true;
        }

        var save = function () {
            var param = {};
            var items = [];
            var subItems = [];

            ucMasterRealgrid_gridView.commit(true);

            for (var i = 0; i < ucMasterRealgrid_dataProvider.getStateRows('updated').length; i++) {
                var index = ucMasterRealgrid_dataProvider.getStateRows('updated')[i];
                var CLCTITEM = ucMasterRealgrid_dataProvider.getValue(index, "CLCTITEM");
                var P_CLCTNAME = ucMasterRealgrid_dataProvider.getValue(index, "P_CLCTNAME");
                var CLCTSEQ = ucMasterRealgrid_dataProvider.getValue(index, "CLCTSEQ");
                var USEYN = ucMasterRealgrid_dataProvider.getValue(index, "USEYN");

                // 20250704
                var GOOD = ucMasterRealgrid_dataProvider.getValue(index, "GOOD");
                var ASSY = ucMasterRealgrid_dataProvider.getValue(index, "ASSY");
                var RAW = ucMasterRealgrid_dataProvider.getValue(index, "RAW");
                var attribute3 = "";

                attribute3 = (GOOD === "GOOD" ? (GOOD + ",") : ",");
                attribute3 += (ASSY === "ASSY" ? (ASSY + ",") : ",");
                attribute3 += (RAW === "RAW" ? RAW : "");
                // 20250704

                subItems[i] = [
                    { name: "CMCDTYPE", value: 'CM_QUALITEM', dataType: _DataType.String }
                    , { name: "CMCODE", value: CLCTITEM, dataType: _DataType.String } // 검사항목
                    , { name: "CMCDNAME", value: P_CLCTNAME, dataType: _DataType.String } // 검사항목 명
                    , { name: "ATTRIBUTE1", value: CLCTSEQ, dataType: _DataType.String } // 검사항목 표시순서
                    , { name: "ATTRIBUTE2", value: USEYN, dataType: _DataType.String } // 검사항목 표시여부
                    // 20250704
                    , { name: "ATTRIBUTE3", value: attribute3, dataType: _DataType.String } // 해당 검사항목이 완제품, 반제품, 원재료 인지 중복 가능
                    // 20250704
                    , { name: "USERID", value: '<%=SSUser.UserID%>', dataType: _DataType.String } // USERID
               ];
           }

           param.bizID = "BR_IM_REG_ABNORMAL_CLCTITEM_COMMONCODE";
           items[0] = subItems;

           var url = "/GMES_IM_POM/GMES_IMES_0560_03.aspx/ExecuteData";
           param.items = items;
           param.inTableNames = 'INDATA';
           param.outTableNames = '';

           sendRequestMethod(function (id, data) {

               if (data.length > 0) {

                   if (data[0].RETURN === 'OK') {
                       IS_SAVE = true;

                       //parent.CallBackCloseDialog(true);

                       xAlert('<%=lang.message["10004"]%>');
                       Search_MainData();
                   }

               }
           }, param, "POST", url);
       }
        
       var vRealgridMasterFields =
           [
                 { fieldName: "CLCTSEQ", dataType: "number" }
               , { fieldName: "CLCTITEM", dataType: "text" }
               , { fieldName: "CLCTNAME", dataType: "text" }
               , { fieldName: "P_CLCTNAME", dataType: "text" } // 언어별 NAME
               , { fieldName: "USEYN", dataType: "text" }
               // 20250704
               , { fieldName: "GOOD", dataType: "text" }
               , { fieldName: "ASSY", dataType: "text" }
               , { fieldName: "RAW", dataType: "text" }
               // 20250704
           ];

       var vRealgridMasterColumns =
           [
               { name: "CLCTSEQ", fieldName: "CLCTSEQ", header: { text: "<%=lang.word["CLCTITEM_SEQ"]%>" }, styles: { textAlignment: "far", numberFormat: "###0", background: "#ffffe6" }, editor: { type: 'number', positiveOnly: true, editFormat: "###0" }, editable: true, width: 80 }
               , { name: "CLCTITEM", fieldName: "CLCTITEM", header: { text: "<%=lang.word["Inspection Item ID"]%>" }, styles: { textAlignment: "center" }, editable: false, width: 80}
               , { name: "CLCTNAME", fieldName: "CLCTNAME", header: { text: "<%=lang.word["Inspection Item Name"]%>" }, styles: { textAlignment: "near" }, editable: false, width: 200 }
               // 20250724
               , { name: "GOOD", fieldName: "GOOD", header: { text: "<%=lang.word["Finished Goods"]%>" }, styles: { textAlignment: "center" }, editable: false, width: 80, renderer: { type: "check", editable: true, startEditOnClick: true, trueValues: "GOOD", falseValues: "N", labelPosition: "center" } }
               , { name: "ASSY", fieldName: "ASSY", header: { text: "<%=lang.word["AutoHold Setting"]%>" }, styles: { textAlignment: "center" }, editable: false, width: 80, renderer: { type: "check", editable: true, startEditOnClick: true, trueValues: "ASSY", falseValues: "N", labelPosition: "center" } }
               , { name: "RAW", fieldName: "RAW", header: { text: "<%=lang.word["Raw material spc"]%>" }, styles: { textAlignment: "center" }, editable: false, width: 80, renderer: { type: "check", editable: true, startEditOnClick: true, trueValues: "RAW", falseValues: "N", labelPosition: "center" } }
               // 20250724
               , { name: "USEYN", fieldName: "USEYN", header: { text: "<%=lang.word["USEFLAG"]%>" }, styles: { textAlignment: "center" }, editable: false, width: 80, lookupDisplay: true, editor: { type: "dropDown", labels: ["Y", "N"], values: ["Y", "N"] }, mergeEdit: true }
            ];

        // #region 카운트
        function setTotalCount(count) {
            $("#ucMasterTotalConunt").text(count);
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
    </script>
</asp:Content>

<asp:Content ID="Content1" ContentPlaceHolderID="bodyHolder" runat="server">
    <form id="form2" runat="server">
        <!-- hidden Field Start-->
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidMenuID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidMTRLTYPE" runat="server" />
        <!-- hidden Field End-->
        <asp:ScriptManager runat="server" ID="ScriptManager2"></asp:ScriptManager>

        <!-- 검색조건 영역 시작  -->
        <div class="tableInquiry searchBox" id="divSearchArea" style="margin-bottom:10px;">
            <div class="itemBox" style="height:37px">
                <table>
                    <tbody>
                        <tr>
                            <th class="th_auto"><%=lang.word["Inspection items"]%></th> <!-- 검사항목-->
                            <td class="td_fix">
                                <input id="txt_Inspection" class="easyui-textbox" style="width: 100%; max-width: 200px; "/>
                            </td>
                            <th class="th_auto"><%=lang.word["USEFLAG"]%></th> <!-- 사용여부-->
                            <td class="td_fixEnd"><input id="cbo_use" class="easyui-combobox" style="width: 100%; max-width: 80px;" /></td> 
                                
                            <td> 
                                <div class="tableBtnSearch">
                                    <button type="button" id="" onclick="javascript:Search_MainData();"><span><%=lang.word["SEARCH"]%></span></button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <div id="divButtonArea" class="tableBtnSearch" >
                <button type="button" id="btnSearch" onclick="javascript:Search_MainData();"><span><%=lang.word["Search"]%></span></button><!-- 조회 -->
            </div>
        </div>
        <!-- 검색조건 영역 끝 -->

        <div id="divDetailContent">
            <div class="buttonArea" id="divButton">
                <div class="floatLeft01" style="margin-top: 10px;"><%=lang.word["Search results"]%> ( Total <span id="ucMasterTotalConunt" class='red01'>0</span> Found )</div>
                <ul runat="server" class="btn_crud">
                    <li><a class="save" id="btnSave" onclick="buttonCheck(this.id)"><span><%=lang.word["Save"]%></span></a></li>
                    <li><a class="close" id="btnClose" onclick="buttonCheck(this.id)"><span><%=lang.word["Close"]%></span></a></li>
                </ul>
            </div>
            <div name="realGrid" id="ucMaster" class="table">
                <uc:Realgrid ID="ucMasterRealgrid" CALLID="ucMasterRealgrid" HEIGHT="200" runat="server" LAYOUTSAVING="Y" />
            </div>
        </div>
    </form>
</asp:Content>