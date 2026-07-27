 <%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0312.aspx.cs" Inherits="GMES_IMES_0312" %>

<%--/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0312.aspx
* @desc    : 생산실적 - 정보조회 - 재처리투입실적조회 [관리자]
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2023/03/29   황유라              C20230214-000081 세척용Lot 투입관리 메뉴 개선 件
* 1.1  2023/07/19   정다운              C20230630-000166 조회 조건 시 Param 추가
* 1.2  2023/08/08   황유라              생산LOT 조회 조건 추가
*************************************************************************************************
*/--%>
<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %> 

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
                        <col class="col_7p" />
                        <col class="col_13p" />
                        <col class="col_7p" />
                        <col class="col_13p" />
                        <col class="col_7p" />
                        <col class="col_13p" />
                        <col class="col_7p" />
                        <col class="col_13p" />
                        <col class="col_7p" />
                        <col class="col_13p" />
                    </colgroup>
                    <tbody>
                        <tr>
                            <th><%=lang.word["Shop/Area"]%></th>
                            <td>
                                <table class="tableShopArea">
                                    <tr>
                                        <td><input id="cboArea" class="easyui-combobox" style="width: 200px;" /></td>
                                    </tr>
                                    <tr class="ProdGR">
                                        <td><input id="cboGrade" class="easyui-combobox" style="width: 200px;" /></td>
                                    </tr> 
                                </table>
                            </td>

                            <th style="display:normal";><%=lang.word["PROC_GROUP"]%></th>
                            <td style="display:normal";>                                
                                <select id="cboProcessSegment" class="easyui-combobox" style="width: 100%; max-width: 200px; "/>
                            </td>

                            <th style="display:normal";><%=lang.word["Line/Equipment Seg."]%></th>
                            <td style="display:normal";>
                                <select id="cboLine" class="easyui-combobox" style="width: 100%; max-width: 200px; "/>
                            </td>  
                        

                            <th style="display:normal";><%=lang.word["Operation"]%></th>
                            <td style="display:normal";>                                
                                <select id="cboProcess" class="easyui-combobox" style="width: 100%; max-width: 200px; "/>
                            </td>
                        </tr>
                        <tr>
                            <th><span class="textPink">*</span><%=lang.word["Search Period"]%></th> <!-- 조회기간 -->
                            <td>
                                <input id="dtDateRange" class="easyui-daterangebox" style="width: 200px; " />
                            </td>
                            <th><%=lang.word["Product Code"]%></th> <!--제품코드-->
                            <td >
                                <div style="width: 100%; max-width: 250px;">
                                     <div style="float: left; width: 100%; ">
                                        <input id="txtProduct" class="easyui-searchbox" style="width: 100%;" data-options="searcher:ShowProductPopup, inputEvents: $.extend({}, $.fn.searchbox.defaults.inputEvents, { keyup: function(e){} })" />

                                    </div>
                                    <div style="display:none; float: left; width: 30%; padding-left: 5px;">
                                        <input id="txtProductName" class="easyui-textbox" style="width: 100%;" disabled="disabled" />
                                    </div>
                                </div>
                            </td>
                            <th id="thProductTypeName"><%=lang.word["Consume"]%> <%=lang.word["Type"]%></th> <!--투입 유형-->
                            <td id="tdProductTypeName">
                                <input id="cboInputType" class="easyui-combobox" style="width: 100%; max-width: 200px;" />
                            </td>
                            <th><!--LOTNO, 2023.08.08 황유라 투입, 생산 선택 옵션으로 변경-->
                                <fieldset style="display: inline-block; width: 100%;">
                                    <label for="rdo_lot1" style="width: 100%;text-align:left;">
                                        <input type="radio" id="rdo_lot1" name="SearchLot" value="I"checked="checked"/><%=lang.word["Consume"]%> <%=lang.word["LOT"]%>
                                    </label> <!-- 투입LOT -->
                                    <label for="rdo_lot2" style="width: 100%;text-align:left; ">
                                        <input type="radio" id="rdo_lot2" name="SearchLot" value="P" /><%=lang.word["Production"]%> <%=lang.word["LOT"]%>
                                    </label> <!-- 생산LOT -->
                                </fieldset>
                            </th> 
                            <td>
                                <!--LOTNO, 2023.08.08 황유라 다중 입력으로 변경-->
                                <%--<input id="txtMLOTNO" class="easyui-textbox" style="width: 100%; max-width: 200px;" />--%>
                                <input id="txtLOTID" class="easyui-textbox" style="height: 100%; width: 100%; max-width: 200px; max-height:50px" data-options="multiple:true, multiline:true" />
                            </td>
                        </tr>
                        <tr>
                            <th><label for="input_text01" style="width: 100%;"><%=lang.word["Query Condition"]%></label></th>
                            <td>
                                    <fieldset style="display: inline-block; width: 300px;">
                                        <label for="rdoAll" >
                                            <input type="radio" id="rdoAll" name="SearchSelType" value="A" checked="checked" onclick="RadioClick();"/><%=lang.word["ALL"]%>
                                        </label>
                                        <label for="rdoBasic">
                                            <input type="radio" id="rdoBasic" name="SearchSelType" value="M" "/><%=lang.word["Mass-Production"]%>
                                        </label>
                                        <label for="rdoCleaning">
                                            <input type="radio" id="rdoCleaning" name="SearchSelType" value="C" "/><%=lang.word["Cleaning"]%>
                                        </label>
                                    </fieldset>
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
        <!-- 검색조건 영역 끝 -->

        <div class="buttonArea" id="divMidButton">
            <div> 
                <div id="totalCount"  class="floatLeft01" style="float:left;"><%=lang.word["Search results"]%> ( Total <span class='red01'>0</span> Found ) </div>
            </div>            

            <ul id="ulBttomButton" runat="server" class="btn_crud" style="margin-right:5px;">  
                <li><a id="btnEditProdLotNo" class="red" onclick="onButtonClick(this.id)"><span><%=lang.word["Production"]%> <%=lang.word["LOT-NO"]%> <%=lang.word["MODIFY"]%></span></a></li> <!--생산 LOT-NO 수정-->
                <li><a class="excel" id="btnExcel" onclick="onButtonClick(this.id)"></a></li>
            </ul>
        </div>
        <div id="divMasterGrid" class="table" > 
            <div id="divLayout" class="easyui-layout" style="width:100%;height:100%;">

                <div id="divGrid" data-options="region:'center',border:false" style="width:100%;height:100%;margin-bottom: 15px;">
                    <uc:Realgrid ID="UCRealgrid" CALLID="UCRealgrid" LAYOUTSAVING="Y" runat="server" />
                </div> 
            </div> 
        </div>
        <!-- Contents 종료 -->        
        <input type="hidden" id="hidProdMat" />  
        <input type="hidden" id="hidProdMatGroup" />  
        <input type="hidden" id="hidAreaId" />  
        <input type="hidden" id="hidTargetMonth" />  
        <input type="hidden" id="hidOutputFormat" />  
        <input type="hidden" id="hidNonMgtExclude" />  
        <input type="hidden" id="hidLiquidExclude" />          
    </form>
</asp:Content>

<asp:Content ID="UISlideContent" ContentPlaceHolderID="slideHolder" runat="server">
    <div id="divSlideTab" class="easyui-tabs" data-options="fit:true" style="width: 100%;height:250px">

    </div>
</asp:Content>


<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js"></script>
    
    <script type="text/javascript" language="javascript">      
        
        // 공장/동을 선택하여 주십시요.
        var msgAreaRequired = "<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["Shop/Area"]%>");
        // 실사 일시는 반드시 입력하십시오.
        var msgCNTDTTMRequired = "<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["CNTDTTM"]%>");     
        // 조회내역이 존재하지 않습니다.
        var msgNotFoundList = "<%=lang.message["20051"]%>";

        //#region Variables
        var vAreaID = '<%:SSUser.AreaID%>';
        var vFirst = true;
        var vSize = 0;

        var aLabel = [];
        var aValue = [];
        var vParm = {};
        //#endregion

        function AutoHeightSpread(cSize) {

            var gridMaster = document.getElementById("UCRealgrid");

            var masterHeight = document.getElementById("divMasterGrid").offsetTop;
            var pageHeight = document.documentElement.clientHeight;
            var dockh = 0;

            if (IsDock()) {
                dockh = DockHeight();

                if (dockh > 0) {
                    dockh = dockh;
                };
            };

            var i = 0;
            i = pageHeight - masterHeight - dockh - 20 ;

            gridMaster.style.height = String(i) + 'px';

            UCRealgrid.ResetSize();
        }
        //#region resize


        $(window).resize(function () {
            AutoHeightSpread(true);
        });
        //#endregion    


        //#region xInitPage
        function xInitPage() {
        }
        //#endregion

        //#region ready
        $(document).ready(function () {
            var today = new Date();
            var firstDate = new Date();
            firstDate = new Date(firstDate.getFullYear(), firstDate.getMonth(), 1);
            $('#dtDateRange').daterangebox('SetDate', firstDate, today);

            InitControls();             
            InitGrid();
            SetInputType();
        });

        function SetInputType() {
            /// <summary>생산유형 콤보박스에 데이터를 설정한다.</summary>  
            $('#cboInputType').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=DA_PRD_SEL_COMMONCODE_REPROC_SUM&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&CMCDTYPE=LOTWORKTYPE&CBOOPT=ALL|CMCODE|CMCDNAME',
                valueField: 'CMCODE',
                textField: 'CMCDNAME'
            });
        }

        // #region ShowProductCodePopup - 제품코드명 팝업창을 Open한다.
        function ShowProductPopup() {
            ShowPopup("../GMES_COM/GMES_COM_0003.aspx?PROD_SEARCH=" + $('#txtProduct').textbox('getText'), 790, 500, '<%=lang.word["Drawing No."]%>' + '<%=lang.word["Search"]%>', SetProductName);
        };
        // #endregion

        function SetProductName(data) {

            if (data == undefined) return;
            //if (data.length != 3) return;
            if (data.length < 3) return; //2022.05.26 황유라 txtProductGroup 객체 없음, 주석처리

            //data[0];//Part No
            //data[1];//제품명
            //data[2];//제품코드

            $("#txtProductName").textbox("setValue", data[1]);
            $("#txtProduct").textbox("setValue", data[2]);
        };

        //#region InitControls - 컨트롤을 초기 셋팅한다
        function InitControls() {
            /// <summary>컨트롤을 초기 셋팅한다.</summary>               
            SetDateTime();
            SetArea();
                       
            $("input:checkbox[id='chkNONMGT_EXCLUDE']").prop("checked", true); //진행실적 제외
            $("input:checkbox[id='chkLiquid']").prop("checked", true);         //액상자재 제외            
        };
        //#endregion

        //#region SetDateTime - 날짜를 설정한다.
        function SetDateTime() {
            /// <summary>날짜를 설정한다.</summary>  
            setCloseMonth('D');
        }

        function setCloseMonth(worktype) {
            // <summary>실사일자에 해당되는 마감월을 설정한다.</summary> 
            var items = {};

            items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1);
            items.SHOPID = XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1);
            items.WORKTYPE = worktype;

            var param = {};
            param.bizID = "DA_PRD_SEL_WIP_CLOSE_MONTH_OR_DATE";
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            sendRequestMethod(function (id, datas) {
                if (datas != null && datas.length > 0) {
                    $('#dtDate').datetimespinner('setValue', datas[0].CLOSEMONTH);
                }
                else {
                    var toDay = $.fn.datebox.defaults.formatter(new Date());
                    $('#dtDate').datetimespinner('setValue', toDay);
                }

                vFirst = false;

            }, param, "POST", url);

        }
        //#endregion 

        function SetArea() {
            /// <summary>공장/동 콤보박스에 데이터를 설정한다.</summary>  
            $('#cboArea').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_AREA_CBO&AREAIUSE=Y&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1)
                    + '&SHOPID=' + XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1) + '&SHOPIUSE=Y&EQSGTYPE=LINE&USERID=' + XSSReplace( $("[id$=hidUserID]").val()  , 1) + '&CBOOPT=OPT|AREAID|AREANAME_ML',
                valueField: 'AREAID',
                textField: 'AREANAME_ML',
                onSelect: function (row) {
                    SetGrade(row);
                },
                onLoadSuccess: function () {
                    var items = $(this).combobox("getData");
                    if (items.length === 2) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                },
                onLoadSuccess: function () {

                    var autoSelect = false;
                    var AREAIDValue = "<%=SSUser.AreaID%>";

                        if (AREAIDValue.length > 0) {
                            var items = $(this).combobox("getData");
                            var opts = $(this).combobox("options");
                            var strIn = false;
                            for (var i = 0; i < items.length; i++) {
                                if (items[i][opts.valueField] == AREAIDValue) { // 콤보박스 데이터가 있다면 있음 표시 하고 SELECT될 수 있도록 한다.
                                    strIn = true;
                                    break;
                                }
                            }
                            if (strIn) {
                                $(this).combobox("select", AREAIDValue);
                            } else {
                                autoSelect = true;
                            }
                        } else {
                            autoSelect = true;
                        }

                        if (autoSelect) {

                            var items = $(this).combobox("getData");
                            if (items.length === 2) {
                                var opts = $(this).combobox("options");
                                $(this).combobox("select", items[1][opts.valueField]);
                            }
                        }
                    }
                });
            }
            //#endregion

            function SetGrade(record) {
                /// <summary>제품군 콤보박스에 데이터를 설정한다.</summary>  
                $('#cboGrade').combobox({
                    url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_PRODUCTGROUP_BY_AREA_CBO&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&AREAID=' + record.AREAID
                        + '&CBOOPT=OPT|PDGRID|PDGRNAME',
                    valueField: 'PDGRID',
                    textField: 'PDGRNAME',
                    onSelect: function (row) {
                        //SetProcess(record.AREAID, row);
                        //SetLine(record.AREAID, row);
                        SetProcessSegment(record.AREAID, row);

                        var pdgrid = row.PDGRID;

                        //if (pdgrid == 'SD') {
                        //    $('[id$=btnDafMultiList]').toggle(true);
                        //} else {
                        //    $('[id$=btnDafMultiList]').toggle(false);
                        //};

                    },
                    onLoadSuccess: function () {
                        var items = $(this).combobox("getData");
                        if (items.length === 2) {
                            var opts = $(this).combobox("options");
                            $(this).combobox("select", items[1][opts.valueField]);
                        }
                    }
                });
            }

            //#region SetProcess - 단위공정 콤보박스에 데이터를 설정한다
            function SetProcess(Arearid, record, pcsgid) {
                /// <summary>단위공정 콤보박스에 데이터를 설정한다.</summary>   
                //PCSGID=PG0024

                $('#cboProcess').combobox({
                    url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_PROCESS_BY_PCSGID_CBO&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&AREAID=' + Arearid
                        + '&SHOPID=' + XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1) + '&EQSGIUSE=Y&EQSGID=' + record.EQSGID + '&PCSGID=' + pcsgid + '&PROCIUSE=Y&AREAIUSE=Y&SHOPIUSE=Y&PCSGIUSE=Y&CBOOPT=OPT|PROCID|PROCNAME',
                    valueField: 'PROCID',
                    textField: 'PROCNAME',
                    onSelect: function (row) {
                        //SetLine(Arearid, row);
                        //SetEquipment(Arearid, row.PROCID, record.EQSGID);
                    },
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

          //#region SetProcess - 단위공정 콤보박스에 데이터를 설정한다
            function SetProcessSegment(Arearid, record) {
                /// <summary>단위공정 콤보박스에 데이터를 설정한다.</summary>   
                //PCSGID=PG0024

                $('#cboProcessSegment').combobox({
                    url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_PROCESSSEGMENT_BY_PCSGID_CBO&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&AREAID=' + Arearid
                        + '&SHOPID=' + XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1) + '&EQSGIUSE=Y&PROCIUSE=Y&AREAIUSE=Y&SHOPIUSE=Y&PCSGIUSE=Y&CBOOPT=OPT|PCSGID|PCSGNAME',
                    valueField: 'PCSGID',
                    textField: 'PCSGNAME',
                    onSelect: function (row) {
                        SetLine(Arearid, record, row);
                        //SetEquipment(Arearid, row.PROCID, record);
                        //SetProcess(Arearid, record.EQSGID, row);
                    },
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

            //#region SetLine - 라인/실 콤보박스에 데이터를 설정한다
            function SetLine(areaId, record, pcsgid) {
                /// <summary>라인/실 콤보박스에 데이터를 설정한다.</summary>   

                $('#cboLine').combobox({
                    url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&AREAID=' + areaId
                        + '&SHOPID=' + XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1) + '&PDGRID=' + record.PDGRID + '&PCSGID=' + pcsgid.PCSGID + '&CBOOPT=OPT|EQSGID|EQSGNAME',
                    valueField: 'EQSGID',
                    textField: 'EQSGNAME', 
                    onSelect: function (row) {
                        SetProcess(areaId, row, pcsgid.PCSGID);
                    },
                    onLoadSuccess: function () {

                        var autoSelect = false;
                        var WorkTypeValue = "";
                        var tempProcess = ($("#cboLine").combobox("getValue").length > 0) ? $("#cboLine").combobox("getValue") : null  // 입고 라인/실

                        if ($(this)[0].id == "cboLine") // 이동구분 값 가져오기..
                        {
                            if (tempProcess != undefined) {
                                WorkTypeValue = tempProcess;
                            }
                        }

                        if (WorkTypeValue.length > 0) {
                            var items = $(this).combobox("getData");
                            var opts = $(this).combobox("options");
                            var strIn = false;
                            for (var i = 0; i < items.length; i++) {
                                if (items[i][opts.valueField] == WorkTypeValue) // 콤보박스 데이터가 있다면 있음 표시 하고 SELECT될 수 있도록 한다.
                                {
                                    strIn = true;
                                    break;
                                }
                            }

                            if (strIn) {
                                $(this).combobox("select", WorkTypeValue);
                            }
                        }
                        else {
                            autoSelect = true;
                        }

                        if (autoSelect) {
                            var items = $(this).combobox("getData");
                            if (items.length === 2) {
                                var opts = $(this).combobox("options");
                                $(this).combobox("select", items[1][opts.valueField]);
                            }
                        }


                    }
                });
            }
            //#endregion

            //#region SetEquipment - 설비 콤보박스에 데이터를 설정한다
            function SetEquipment(areaId, procid, EQSGID) {
                /// <summary>설비 콤보박스에 데이터를 설정한다.</summary>  
                //var eqsgId = record === undefined ? '' : record.EQSGID;

                $('#cboEquipment').combobox({
                    url: '../common/xml/CallBizJson.aspx?sp_name=BR_IM_SEL_EQUIPMENT_SHOP_CBO&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&SHOPID=' + XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1)
                        + '&AREAID=' + areaId + '&PROCID2=' + procid + '&EQSGID=' + EQSGID + '&CBOOPT=ALL|EQPTID|EQPTNAME',
                    valueField: 'EQPTID',
                    textField: 'EQPTNAME',
                    onLoadSuccess: function () {

                        var items = $(this).combobox("getData");
                        if (items.length === 2) {
                            var opts = $(this).combobox("options");
                            $(this).combobox("select", items[1][opts.valueField]);
                        }

                    }
                });
            }
        
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
                    case "btnEditProdLotNo":
                        EditProdLotNo();
                        break;
                    default: 
                }
            } catch (e) {
                xAlert(e.message);
            }
        }
        //#endregion             

        function EditProdLotNo() {

            var currentRow = UCRealgrid_dataProvider.getJsonRow(UCRealgrid_gridView.getCurrent().dataRow);
            
            var tempProdId = currentRow.LOT_PRODID;
            var tempRemark = currentRow.REMARK;

            var getLotID = "" //ucDetailRealGrid_dataProvider.getValue(0, "LOTID"); // 신규 시 새로 생성되므로 없어도 됨... 이광주 2018.01.16

            var tempAreaId = currentRow.LOT_AREAID; // 공장/동 ID
            var tempEqsgId = currentRow.LOT_EQSGID; // 라인/실
            var tempProcId = $('#cboProcess').combobox('getValue'); // 공정 ID
            var tempPdgrId = $('#cboGrade').combobox('getValue'); // 제품군 ID
            var tempPcgrId = $('#cboProcessSegment').combobox('getValue'); // 공정군 ID
            var tempMlotId = currentRow.MLOTID; // MLOT
            var tempLotId = currentRow.LOTID; // LOT
            var tempWipSeq = currentRow.WIPSEQ; // WIPSEQ

            ShowPopup("../GMES_IM_POM/GMES_IMES_0311_01.aspx?MENU_ID=<%=ViewState["MENU_ID"].ToString()%>>&tempAreaId=" + tempAreaId + "&tempEqsgId="
                + tempEqsgId + "&tempProcId=" + tempProcId + "&tempPdgrId=" + tempPdgrId + "&tempPcgrId=" + tempPcgrId + "&tempProdId="
                + tempProdId + "&tempRemark=" + tempRemark + "&tempMlotId=" + tempMlotId + "&tempLotId=" + tempLotId + "&tempWipSeq=" + tempWipSeq
                , 950, 750, "<%=lang.word["Production"]%> <%=lang.word["LOT-NO"]%> <%=lang.word["MODIFY"]%>", InquiryData);
            
        }

        function SetRemark() {

            var rowCount = UCRealgrid.GetRowCount();
            var remark = "";
            var tempRemark = "";

            var remarkList = new Array;


            for (var i = 0; i < rowCount; i++) {
                if (i > 0) {
                    if (UCRealgrid_dataProvider.getValue(i - 1, 'LOTID') == UCRealgrid_dataProvider.getValue(i, 'LOTID')) {
                        // 생산 LOT이 같을 때,
                        if (UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_LOTNO').split('#')[0] == UCRealgrid_dataProvider.getValue(i, 'MLOT_LOTNO').split('#')[0]) {
                            // 투입 LOT이 같을 때,
                            if (UCRealgrid_dataProvider.getValue(i - 1, 'INPUTQTY') == UCRealgrid_dataProvider.getValue(i, 'INPUTQTY')) {
                                // 투입량이 같을 때,
                                SumInputQty += parseInt(UCRealgrid_dataProvider.getValue(i, 'INPUTQTY'));
                                SameCount++;
                            } else {
                                // 투입량이 다를 때,
                                tempRemark = UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_LOTNO').split('#')[0] + " "
                                    + SumInputQty + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_UNIT') + " "
                                    + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_WORKTYPE') + " "
                                    + "(" + parseInt(UCRealgrid_dataProvider.getValue(i - 1, 'INPUTQTY')) + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_UNIT')
                                    + " " + SameCount + "bag)";

                                // List 추가
                                remarkList.push(tempRemark);

                                // 변수 값 재정의
                                reamrk = "";
                                SameCount = 1;
                                SumInputQty = parseInt(UCRealgrid_dataProvider.getValue(i, 'INPUTQTY'));
                            }

                            if (i == rowCount - 1) {
                                // 마지막 row일 때,
                                tempRemark = UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_LOTNO').split('#')[0] + " "
                                    + SumInputQty + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_UNIT') + " "
                                    + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_WORKTYPE') + " "
                                    + "(" + parseInt(UCRealgrid_dataProvider.getValue(i - 1, 'INPUTQTY')) + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_UNIT')
                                    + " " + SameCount + "bag)";

                                // List 추가
                                remarkList.push(tempRemark);
                                // Remark 정의
                                for (var r = 0; r < remarkList.length; r++) {
                                    if (r == 0) {
                                        remark += remarkList[r];
                                    } else {
                                        remark += ", " + remarkList[r];
                                    }
                                }

                                for (var i2 = startIndex; i2 <= i; i2++) {
                                    UCRealgrid_dataProvider.setValue(i2, 'REMARK', remark);
                                }
                            }
                        } else {
                            // 투입 LOT이 다를 때,
                            tempRemark = UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_LOTNO').split('#')[0] + " "
                                    + SumInputQty + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_UNIT') + " "
                                    + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_WORKTYPE') + " "
                                    + "(" + parseInt(UCRealgrid_dataProvider.getValue(i - 1, 'INPUTQTY')) + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_UNIT')
                                    + " " + SameCount + "bag)";

                            // List 추가
                            remarkList.push(tempRemark);

                            if (i == rowCount - 1) {
                                // 마지막 row일 때,
                                tempRemark = UCRealgrid_dataProvider.getValue(i, 'MLOT_LOTNO').split('#')[0] + " "
                                    + SumInputQty + UCRealgrid_dataProvider.getValue(i, 'MLOT_UNIT') + " "
                                    + UCRealgrid_dataProvider.getValue(i, 'MLOT_WORKTYPE') + " "
                                    + "(" + parseInt(UCRealgrid_dataProvider.getValue(i, 'INPUTQTY')) + UCRealgrid_dataProvider.getValue(i, 'MLOT_UNIT')
                                    + " " + SameCount + "bag)";

                                // List 추가
                                remarkList.push(tempRemark);
                                // Remark 정의
                                for (var r = 0; r < remarkList.length; r++) {
                                    if (r == 0) {
                                        remark += remarkList[r];
                                    } else {
                                        remark += ", " + remarkList[r];
                                    }
                                }

                                for (var i2 = startIndex; i2 <= i; i2++) {
                                    UCRealgrid_dataProvider.setValue(i2, 'REMARK', remark);
                                }
                            }

                            // 변수 값 재정의
                            reamrk = "";
                            SameCount = 1;
                            SumInputQty = parseInt(UCRealgrid_dataProvider.getValue(i, 'INPUTQTY'));
                        }
                    } else if (UCRealgrid_dataProvider.getValue(i - 1, 'LOTID') != UCRealgrid_dataProvider.getValue(i, 'LOTID')) {
                        // 생산 LOT이 다를 때,
                        tempRemark = UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_LOTNO').split('#')[0] + " "
                                    + SumInputQty + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_UNIT') + " "
                                    + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_WORKTYPE') + " "
                                    + "(" + parseInt(UCRealgrid_dataProvider.getValue(i - 1, 'INPUTQTY')) + UCRealgrid_dataProvider.getValue(i - 1, 'MLOT_UNIT')
                                    + " " + SameCount + "bag)";

                        // List 추가
                        remarkList.push(tempRemark);
                        // Remark 정의
                        for (var r = 0; r < remarkList.length; r++) {
                            if (r == 0) {
                                remark += remarkList[r];
                            } else {
                                remark += ", " + remarkList[r];
                            }
                        }

                        for (var i2 = startIndex; i2 < i; i2++) {
                            UCRealgrid_dataProvider.setValue(i2, 'REMARK', remark);
                        }

                        // 변수 값 재정의
                        startIndex = i;
                        SameCount = 1;
                        SumInputQty = parseInt(UCRealgrid_dataProvider.getValue(i, 'INPUTQTY'));
                        remark = "";
                        remarkList = new Array;

                        if (i == rowCount - 1) {
                            // 마지막 row일 때,
                            tempRemark = UCRealgrid_dataProvider.getValue(i, 'MLOT_LOTNO').split('#')[0] + " "
                                + SumInputQty + UCRealgrid_dataProvider.getValue(i, 'MLOT_UNIT') + " "
                                + UCRealgrid_dataProvider.getValue(i, 'MLOT_WORKTYPE') + " "
                                + "(" + parseInt(UCRealgrid_dataProvider.getValue(i, 'INPUTQTY')) + UCRealgrid_dataProvider.getValue(i, 'MLOT_UNIT')
                                + " " + SameCount + "bag)";

                            // List 추가
                            remarkList.push(tempRemark);
                            // Remark 정의
                            for (var r = 0; r < remarkList.length; r++) {
                                if (r == 0) {
                                    remark += remarkList[r];
                                } else {
                                    remark += ", " + remarkList[r];
                                }
                            }

                            for (var i2 = startIndex; i2 <= i; i2++) {
                                UCRealgrid_dataProvider.setValue(i2, 'REMARK', remark);
                            }
                        }
                    }
                } else {
                    // 변수 초기 정의
                    var startIndex = 0;
                    var SameCount = 1;
                    var SumInputQty = parseInt(UCRealgrid_dataProvider.getValue(i, 'INPUTQTY'));
                }
            }
        }

        // #region ExcelExport - 그리드 데이터를 엑셀 파일로 출력한다.
        function ExcelExport(gubun) {
            /// <summary>그리드 데이터를 엑셀 파일로 출력한다</summary>       
            var fNameToday = "DailyNegative_" + new Date().format("yyyyMMdd_hhmmss") + "_export.xlsx";
            if (gubun == "EXCEL") {
                UCRealgrid.ExcelExport(fNameToday, true);
            }
        }
        // #endregion

        // #region Validate - 함수 실행 전 유효성 체크
        function Validate(type) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            var result = true;

            switch (type) {
                case "SEARCH":
                    break;
                case "EXCEL":
                    if (UCRealgrid.GetRowCount() == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }
                    ExcelExport("EXCEL");
                    break;
                default:
            }

            return result;
        }
        // #endregion

        var bSearch = true;
        function Validation() {
            // message (10012) : [%1](을)를 선택하여 주십시오.
            var msg = '<%=lang.message["10012"]%>';
            if ($('#cboArea').combobox('getValue') == "" || $('#cboArea').combobox('getValue') == null) {
                msg = msg.replace("%1", "<%=lang.word["Shop/Area"]%>");
                bSearch = false;
                xAlert(msg);
                return;
            }
            if ($('#cboProcessSegment').combobox('getValue') == "" || $('#cboProcessSegment').combobox('getValue') == null) {
                msg = msg.replace("%1", "<%=lang.word["PROC_GROUP"]%>");
                bSearch = false;
                xAlert(msg);
                return;
            }
            if ($('#cboLine').combobox('getValue') == "" || $('#cboLine').combobox('getValue') == null) {
                msg = msg.replace("%1", "<%=lang.word["Line/Equipment Seg."]%>");
                bSearch = false;
                xAlert(msg);
                return;
            }
            if ($('#cboProcess').combobox('getValue') == "" || $('#cboProcess').combobox('getValue') == null) {
                msg = msg.replace("%1", "<%=lang.word["Operation"]%>");
                bSearch = false;
                xAlert(msg);
                return;
            }
        }
        
        //#region InquiryData - 검색 조건에 해당하는 데이터를 조회한다.  
        function InquiryData() {

            UCRealgrid_dataProvider.clearRows();

            var currentdate_from = $.fn.datebox.defaults.formatter($('#dtDateRange').daterangebox('GetFromDate'));
            var currentdate_to = $.fn.datebox.defaults.formatter($('#dtDateRange').daterangebox('GetToDate'));

            //투입목적 수정
            var search_SELTYPE = "";
            if ($('input:radio[name="SearchSelType"]:checked').val() == "A") {
                search_SELTYPE = "";
            } else if ($('input:radio[name="SearchSelType"]:checked').val() == "M") {
                search_SELTYPE = "SELTYPE_BASIC";
            } else if ($('input:radio[name="SearchSelType"]:checked').val() == "C") {
                search_SELTYPE = "SELTYPE_CLN";
            };


            //2023.08.08 황유라 투입, 생산lot 검색
            var searchLot = "INPUT";
            if ($('input:radio[name="SearchLot"]:checked').val() == "P") {
                searchLot = "PROD";
            }

            var lot_search_flag = "N";
            if ($('#txtLOTID').textbox('getValue') != '') {
                var arrLotItems = [];
                var splitItems = $('#txtLOTID').textbox('getText').split('\n');

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

                var varLot = "";  //단일LOT 검색
                var varLots = ""; //다중LOT 검색
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
                    lot_search_flag = "Y";
                }

            }

            var items = {};

            if (lot_search_flag=="Y") {
                items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1); // 언어
                items.SHOPID = XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1);
                items.SEARCHLOT = "Y";
                if (varLot.length > 0) {
                    items.SEARCHLOTID = varLot; // LOT ID
                }
                else if (varLots.length > 0) {
                    items.SEARCHLOTID_LIST = varLots // LOT ID 목록
                }

                if (searchLot == "INPUT") {
                    items.MLOTID = "Y"; //투입LOT 검색
                }
                else {
                    items.LOTID = "Y";  //생산LOT 검색
                }
                //2023.08.08 황유라 투입, 생산lot 검색 종료

            } else {
                //Validation();
                //if (bSearch == false) {
                //    bSearch = true;
                //    return;
                //}
                items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1); // 언어
                items.SHOPID = XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1);         // 2023.03.29 황유라 공장 작업시간으로 검색 목적
                items.AREAID = $('#cboArea').combobox('getValue'); // 공장동
                items.EQSGID = $('#cboLine').combobox('getValue'); // 라인실
                items.PROCID = $('#cboProcess').combobox('getValue'); // 공정
                //items.EQPTID = $('#cboEquipment').combobox('getValue'); // 설비
                items.PRODID = $('#txtProduct').searchbox('getValue'); // 제품코드
                items.WORKTYPE = $('#cboInputType').combobox('getValue'); // 제품코드

                items.DATE_FROM = currentdate_from; // DATE_FROM
                items.DATE_TO = currentdate_to; // DATE_TO 
                
                if (search_SELTYPE == "SELTYPE_BASIC") {
                    items.SELTYPE_BASIC = "Y";  //양산
                }
                else if (search_SELTYPE == "SELTYPE_CLN") {
                    items.SELTYPE_CLN = "Y";  //세척
                }

            }
            var param = {};
            param.bizID = "DA_PRD_SEL_MLOT_BY_EQPT_REPROC_SUM_NEW";
            param.items = items;

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            vParm = param;
            UCRealgrid.CallRequest(url, param);
        }
        //#endregion  

        function formatter2(date) {
            if (!date) { return ''; }
            var y = date.getFullYear();
            var m = date.getMonth() + 1;
            return y + '-' + (m < 10 ? ('0' + m) : m);
        }
        function parser2(s) {
            if (!s) { return null; }
            var ss = s.split('-');
            var y = parseInt(ss[0], 10);
            var m = parseInt(ss[1], 10);
            if (!isNaN(y) && !isNaN(m)) {
                return new Date(y, m - 1, 1);
            } else {
                return new Date();
            }
        }
       
        function InitGrid() {
            UCRealgrid.ColumnsClear();

            // 투입 LOT 컬럼
            UCRealgrid.AddColumn("INSDATE", "<%=lang.word["Input Date"]%>", 100, "center", 0, false, true, null, null); // 투입일자 
            UCRealgrid.AddColumn("INSDTTM", "<%=lang.word["Consumed Datetime"]%>", 140, "center", 0, false, true, null, null); // 투입일시 
            UCRealgrid.AddColumn("LOT_AREANAME", "<%=lang.word["Production"]%> <%=lang.word["AREANAME"]%>", 120, "center", 0, false, true, null, null); // 생산 공장/동
            UCRealgrid.AddColumn("LOT_EQSGNAME", "<%=lang.word["Line/Equipment Seg."]%>", 80, "center", 0, false, true, null, null); // 생산 라인/실
            UCRealgrid.AddColumn("INPUT_EQPTNAME", "<%=lang.word["Consume"]%> <%=lang.word["Equipment"]%>", 100, "center", 0, false, true, null, null); // 투입 설비
            UCRealgrid.AddColumn("MLOT_LOTNO", "<%=lang.word["Consume"]%> <%=lang.word["LOT No."]%>", 150, "center", 0, false, true, null, null); // 투입 LOTNO
            UCRealgrid.AddColumn("INPUTQTY", "<%=lang.word["INPUT_QTY"]%>", 80, "#,##0", 1, false, true, null, null); // 투입량
            UCRealgrid.AddColumn("MLOT_UNIT", "<%=lang.word["Unit"]%>", 40, "center", 0, false, true, null, null); // 투입 단위

            UCRealgrid.AddColumn("MLOT_WORKTYPE", "<%=lang.word["Consume"]%> <%=lang.word["Type"]%>", 70, "center", 0, false, true, null, null); // 투입유형
            UCRealgrid.AddColumn("MLOT_INPUTSTAT", "<%=lang.word["Consume"]%> <%=lang.word["Status"]%>", 70, "center", 0, false, true, null, null); // 투입 상태 (생산작업)

            UCRealgrid.AddColumn("LOT_LOTNO", "<%=lang.word["Production"]%> <%=lang.word["LOT No."]%>", 150, "center", 0, false, true, null, null); // 생산 LOT NO
            UCRealgrid.AddColumn("LOTQTY", "<%=lang.word["PROD_QTY"]%>", 80, "#,##0", 1, false, true, null, null); // 생산량

            UCRealgrid.AddColumn("WIPSEQ", "<%=lang.word["SEQ"]%>", 50, "#,##0", 1, false, false, null, null); // WIPSEQ  
            UCRealgrid.AddColumn("MLOT_EQPTNAME", "<%=lang.word["Consume"]%> <%=lang.word["Equipment"]%>", 150, "near", 0, false, false, null, null); // 투입 설비
            UCRealgrid.AddColumn("MLOT_PRODID", "<%=lang.word["Consume"]%> <%=lang.word["PRODID"]%>", 100, "near", 0, false, false, null, null); // 투입 제품코드
            UCRealgrid.AddColumn("MLOT_PRODNAME", "<%=lang.word["Consume"]%> <%=lang.word["PROD_NAME"]%>", 300, "near", 0, false, false, null, null); // 투입 제품명
            
            // 생산 LOT 컬럼
            UCRealgrid.AddColumn("MLOTID", "<%=lang.word["Consume"]%> <%=lang.word["LOTID"]%>", 100, "center", 0, false, true, null, null); // 투입 LOTID
            UCRealgrid.AddColumn("LOTID", "<%=lang.word["Product LOTID"]%>", 100, "center", 0, false, true, null, null); // 생산 LOT ID
            UCRealgrid.AddColumn("LOT_AREAID", "<%=lang.word["Production"]%> <%=lang.word["AREANAME"]%> <%=lang.word["ID"]%>", 150, "near", 0, false, false, null, null); // 생산 공장/동 ID

            UCRealgrid.AddColumn("LOT_EQSGID", "<%=lang.word["Production"]%> <%=lang.word["Line/Equipment Seg."]%> <%=lang.word["ID"]%>", 150, "near", 0, false, false, null, null); // 생산 라인/실 ID
            UCRealgrid.AddColumn("LOT_PRODID", "<%=lang.word["Production"]%> <%=lang.word["PROD_CODE"]%>", 100, "center", 0, false, true, null, null); // 생산 제품코드
            UCRealgrid.AddColumn("LOT_PRODNAME", "<%=lang.word["Production"]%> <%=lang.word["PROD"]%>", 300, "near", 0, false, true, null, null); // 생산 제품
            UCRealgrid.AddColumn("BOXSTAT", "<%=lang.word["Production"]%> <%=lang.word["Status"]%>", 100, "near", 0, false, false, null, null); // 생산 상태
            UCRealgrid.AddColumn("REMARK", "<%=lang.word["Remarks"]%>", 500, "near", 0, false, true, null, null); // 메모 비고
            UCRealgrid.AddColumn("INPUT_EQPTID", "EQPTID_INPUT", 100, "near", 0, false, false, null, null); // 투입설비

            
            UCRealgrid.InitGrid("<%=ViewState["MENU_ID"].ToString()%>", false, false, true);

            //UCRealgrid_gridView.setColumnProperty("AREANAME", "mergeRule", { criteria: "values['AREANAME']+value['EQSGNAME']+value['PROCNAME']+value['PRODID']+value['PRODNAME']+value['EQPTNAME']+value['LOTID']+value['PROD_QTY']+value['MTRLUNIT']+value['PRODDATE']+value['WIPDTTM_ST']+value['WIPDTTM_ED']" });
            //UCRealgrid_gridView.setColumnProperty("EQSGNAME", "mergeRule", { criteria: "values['AREANAME']+value['EQSGNAME']+value['PROCNAME']+value['PRODID']+value['PRODNAME']+value['EQPTNAME']+value['LOTID']+value['PROD_QTY']+value['MTRLUNIT']+value['PRODDATE']+value['WIPDTTM_ST']+value['WIPDTTM_ED']" });
            //UCRealgrid_gridView.setColumnProperty("PROCNAME", "mergeRule", { criteria: "values['AREANAME']+value['EQSGNAME']+value['PROCNAME']+value['PRODID']+value['PRODNAME']+value['EQPTNAME']+value['LOTID']+value['PROD_QTY']+value['MTRLUNIT']+value['PRODDATE']+value['WIPDTTM_ST']+value['WIPDTTM_ED']" });
            //UCRealgrid_gridView.setColumnProperty("PRODID", "mergeRule", { criteria: "values['AREANAME']+value['EQSGNAME']+value['PROCNAME']+value['PRODID']+value['PRODNAME']+value['EQPTNAME']+value['LOTID']+value['PROD_QTY']+value['MTRLUNIT']+value['PRODDATE']+value['WIPDTTM_ST']+value['WIPDTTM_ED']" });
            //UCRealgrid_gridView.setColumnProperty("PRODNAME", "mergeRule", { criteria: "values['AREANAME']+value['EQSGNAME']+value['PROCNAME']+value['PRODID']+value['PRODNAME']+value['EQPTNAME']+value['LOTID']+value['PROD_QTY']+value['MTRLUNIT']+value['PRODDATE']+value['WIPDTTM_ST']+value['WIPDTTM_ED']" });
            //UCRealgrid_gridView.setColumnProperty("EQPTNAME", "mergeRule", { criteria: "values['AREANAME']+value['EQSGNAME']+value['PROCNAME']+value['PRODID']+value['PRODNAME']+value['EQPTNAME']+value['LOTID']+value['PROD_QTY']+value['MTRLUNIT']+value['PRODDATE']+value['WIPDTTM_ST']+value['WIPDTTM_ED']" });

            UCRealgrid_gridView.setColumnProperty("INSDATE", "mergeRule", { criteria: "values['INSDATE']" }); //2023.08.08 황유라
            UCRealgrid_gridView.setColumnProperty("INSDTTM", "mergeRule", { criteria: "values['INSDTTM']" });
            UCRealgrid_gridView.setColumnProperty("LOT_AREANAME", "mergeRule", { criteria: "values['INSDTTM'] + values['LOT_AREAID']" });
            UCRealgrid_gridView.setColumnProperty("LOT_EQSGNAME", "mergeRule", { criteria: "values['INSDTTM'] + values['LOT_EQSGID']" });
            UCRealgrid_gridView.setColumnProperty("INPUT_EQPTNAME", "mergeRule", { criteria: "values['INSDTTM'] + values['LOT_EQSGID']+ values['INPUT_EQPTID']" });
            UCRealgrid_gridView.setColumnProperty("MLOT_LOTNO", "mergeRule", { criteria: "values['INSDTTM'] + values['LOT_EQSGID']+ values['INPUT_EQPTID'] + values['LOTID']" });

            //UCRealgrid_gridView.setColumnProperty("LOTID", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID']" });
            //UCRealgrid_gridView.setColumnProperty("LOT_LOTNO", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID'] + values['LOT_LOTNO']" });
            //UCRealgrid_gridView.setColumnProperty("LOT_AREAID", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID'] + values['LOT_LOTNO'] + values['LOT_AREAID']" });
            //UCRealgrid_gridView.setColumnProperty("LOT_AREANAME", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID'] + values['LOT_LOTNO'] + values['LOT_AREAID'] + values['LOT_AREANAME']" });
            //UCRealgrid_gridView.setColumnProperty("LOT_EQSGID", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID'] + values['LOT_LOTNO'] + values['LOT_AREAID'] + values['LOT_AREANAME'] + values['LOT_EQSGID']" });
            
            //UCRealgrid_gridView.setColumnProperty("LOT_PRODID", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID'] + values['LOT_LOTNO'] + values['LOT_AREAID'] + values['LOT_AREANAME'] + values['LOT_EQSGID'] + values['LOT_EQSGNAME'] + values['LOT_PRODID']" });
            //UCRealgrid_gridView.setColumnProperty("LOT_PRODNAME", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID'] + values['LOT_LOTNO'] + values['LOT_AREAID'] + values['LOT_AREANAME'] + values['LOT_EQSGID'] + values['LOT_EQSGNAME'] + values['LOT_PRODID'] + values['LOT_PRODNAME']" });
            //UCRealgrid_gridView.setColumnProperty("LOTQTY", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID'] + values['LOT_LOTNO'] + values['LOT_AREAID'] + values['LOT_AREANAME'] + values['LOT_EQSGID'] + values['LOT_EQSGNAME'] + values['LOT_PRODID'] + values['LOT_PRODNAME'] + values['LOTQTY']" });
            //UCRealgrid_gridView.setColumnProperty("BOXSTAT", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID'] + values['LOT_LOTNO'] + values['LOT_AREAID'] + values['LOT_AREANAME'] + values['LOT_EQSGID'] + values['LOT_EQSGNAME'] + values['LOT_PRODID'] + values['LOT_PRODNAME'] + values['LOTQTY'] + values['BOXSTAT']" });
            //UCRealgrid_gridView.setColumnProperty("REMARK", "mergeRule", { criteria: "values['INSDTTM'] + values['LOTID'] + values['LOT_LOTNO'] + values['LOT_AREAID'] + values['LOT_AREANAME'] + values['LOT_EQSGID'] + values['LOT_EQSGNAME'] + values['LOT_PRODID'] + values['LOT_PRODNAME'] + values['LOTQTY'] + values['BOXSTAT'] + values['REMARK']" });
            //UCRealgrid.SetFixedColumn(9);

        }

        function UCRealgrid_LoadDataCompleted() {
            $("#totalCount").html("&nbsp;<%=lang.word["Search results"]%> ( Total <span class='red01'>" + UCRealgrid.GetRowCount() + "</span> Found )"); 
            
            SetRemark();
        }
         
        function RadioClick() {

        }
    </script>
</asp:Content>