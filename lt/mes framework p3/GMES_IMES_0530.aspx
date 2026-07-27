<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0530.aspx.cs" Inherits="GMES_IMS_0480" %>

<%--/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMS_0480.aspx
* @desc    : 재고관리 - ERP I/F - 인터페이스 이력조회[생산/투입 실적]
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2017/12/21   조상국              INIT
* 1.1  2018/02/05   한유진              조회조건 - 투입실적LOT 추가 
* 1.2  2021/01/04   김경용              투입실적 Biz 변경(우시)
* 1.3  2021/01/07   김경용              투입실적 Biz 변경(청주, 우시)
*************************************************************************************************
*/--%>
<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>
<%--<%@ Register Src="~/GMES_POM/Controls/UCGrid.ascx" TagName="Realgrid" TagPrefix="uc" %>--%>

<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js"></script>
    <script>
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
    <script type="text/javascript" language="javascript">        
        // 공장/동을 선택하여 주십시요.
        var msgAreaRequired = "<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["Shop/Area"]%>");
        // 단위공정을 선택하여 주십시요.
        var msgProcessRequired = "<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["Process"]%>");
        // 라인/실을 선택하여 주십시요.
        var msgLineRequired = "<%=lang.message["10012"]%>".replace("%1", "<%=lang.word["Line/Equipment Seg."]%>");
        // 조회내역이 존재하지 않습니다.
        var msgNotFoundList = "<%=lang.message["20051"]%>";
        //처리 되었습니다. 
        var msgProcessComplete = "<%=lang.message["20006"]%>";
        // 저장 하시겠습니까?
        var msgSaveConfrim = "<%=lang.message["20022"]%>";

        // 선택된 데이터가 없습니다. 
        var msgNotSelectedList = "<%=lang.message["900"]%>";

        //전송하시겠습니까? 
        var msgSendToERPConfrim = "<%=lang.message["20148"]%>";

        //#region resize
        $(window).resize(function () {
            AutoHeightSpread();
        });
        //#endregion        

        //#region onSlideResize
        function onSlideResize() {
            AutoHeightSpread();
        };
        //#endregion

        //#region xInitPage
        function xInitPage() {
            AutoHeightSpread();
        }
        //#endregion

        //#region AutoHeightSpread - RealGrid의 높이를 재설정한다
        function AutoHeightSpread() {
            var gridMaster = document.getElementById("UCRealGrid");

            var masterHeight = document.getElementById("tbContents").offsetTop;
            var pageHeight = document.documentElement.clientHeight;
            var dockh = 0;

            if (IsDock()) {
                dockh = DockHeight();

                if (dockh > 0) {
                    dockh = dockh;
                }
            }

            var i = 0;
            i = pageHeight - masterHeight - dockh - 40;

            gridMaster.style.height = String(i) + 'px';

            UCRealGrid.ResetSize();
        }
        //#endregion        

        //#region ready
        $(document).ready(function () {            
            InitGrid("init");
            InitControls();            
            //LotSearchCheck();
        });
        //#endregion        

        function LotSearchCheck() {
//            return;
//            $('#sbLotId').textbox('textbox').bind('keyup', function (e) {
//
//                var schStatus = ($('#sbLotId').textbox("getText").length > 0) ? "disable" : "enable";
//
//                //$("#cbo_ProcessingState").combobox(schStatus);
//                $("#sbProductCode").textbox(schStatus);
//            });
        }

        //#region InitControls - 컨트롤을 초기 셋팅한다
        function InitControls() {
            /// <summary>컨트롤을 초기 셋팅한다.</summary>     
            SetShopArea();
            SetDateTime();
            SetProcessingState();
            SetEAITransFlag();

            SetButtonEnable("#btnPostingDateResend", false);
            $('#chkPostingDateResend').attr("checked", false);
            $('#dtPostingDate').datebox('disable');

            if ("<%=SSUser.ShopID%>" != "30D0") { // RO 아니면 숨김
                SetPostingDateResendControl(false);
            } else {
                SetPostingDateResendControl(true);
                GetWipCloseMonth();
            }
            
        };

        function SetPostingDateResendControl(flag) {            
            $('[id$=btnPostingDateResend]').toggle(flag);
            $('[id$=btnTableBar]').toggle(flag);
            //$('[id$=chkPostingDateResend]').toggle(flag);

            if (flag == true) {
                $('#spanPostingDate').css("display", "block");
                var toDay = $.fn.datebox.defaults.formatter(new Date());
                $('#dtPostingDate').datebox('setValue', toDay);
            } else {
                $('#spanPostingDate').css("display", "none");
            }
        }


        function SetEquipment(item, AREAID, PDGRID) {            
            $('#cbo_Equipment').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_EQUIPMENT_CBO&LANGID=<%=SSUser.LangID%>&SHOPID=<%=SSUser.ShopID%>&AREAID=' + AREAID + '&PDGRID=' + PDGRID + '&EQSGID=' + item.EQSGID + '&CBOOPT=ALL|EQPTID|EQPTNAME'
                , valueField: 'EQPTID'
                , textField: 'EQPTNAME'
                , onLoadSuccess: function () {
                    var items = $(this).combobox("getData");
                    if (items.length === 2) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                }
            });
        };

        function SetEqsg(item, AREAID) {
            $('#cbo_Line').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=DA_PRD_SEL_EQSGID_PROD_RST&LANGID=<%=SSUser.LangID%>&AREAID=' + AREAID + '&PDGRID=' + item.PDGRID + '&CBOOPT=ALL|EQSGID|EQSGNAME'
                , valueField: 'EQSGID'
                , textField: 'EQSGNAME'
                , onSelect: function (row) {
                    $.ajaxSettings.async = false;
                    SetEquipment(row, AREAID, item.PDGRID);
                    $.ajaxSettings.async = true;
                }, onLoadSuccess: function () {
                    var items = $(this).combobox("getData");
                    if (items.length === 2) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                }
            });

        };

<%--        function SetEqsg(pdgrRow, AREAID) {
            $('#cbo_Line').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=DA_PRD_SEL_EQSGID_PROD_RST&LANGID=<%=SSUser.LangID%>&AREAID=' + AREAID + '&PDGRID=' + pdgrRow.PDGRID + '&CBOOPT=ALL|EQSGID|EQSGNAME',
                valueField: 'EQSGID',
                textField: 'EQSGNAME',
                onSelect: function (record) {
                    $.ajaxSettings.async = false;
                    //SetEqptData(areaRow, pdgrRow, record);
                    $.ajaxSettings.async = true;
                }
                , onLoadSuccess: function () {
                    var items = $(this).combobox("getData");
                    if (items.length === 2) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                }
            });
        }--%>

        <%--function SetGrade(item) {

            $('#cbo_Grade').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_PRODUCTGROUP_AREA_CBO&LANGID=<%=SSUser.LangID%>&SHOPID=<%=SSUser.ShopID%>&AREAID=' + item.AREAID + '&USERID=<%=SSUser.UserID%>&CBOOPT=OPT|PDGRID|PDGRNAME'
                , valueField: 'PDGRID'
                , textField: 'PDGRNAME'
                , onSelect: function (row) {
                    $.ajaxSettings.async = false;
                    SetEqsg(row, item.AREAID);
                    $.ajaxSettings.async = true;

                }, onLoadSuccess: function () {

                    var items = $(this).combobox("getData");
                    if (items.length === 2) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
               }
            });
        }--%>

        function SetPdgr(areaRow) {
            $('#cbo_Grade').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_PRODUCTGROUP_AREA_CBO&LANGID=<%=SSUser.LangID%>' + '&AREAID=' + areaRow.AREAID + '&CBOOPT=OPT|PDGRID|PDGRNAME',
                valueField: 'PDGRID',
                textField: 'PDGRNAME',
                onSelect: function (record) {
                    $.ajaxSettings.async = false;
                    SetEqsg(record, areaRow.AREAID);
                    $.ajaxSettings.async = true;
                }
                , onLoadSuccess: function () {

                    var items = $(this).combobox("getData");
                    if (items.length === 2) {
                        var opts = $(this).combobox("options");
                        $(this).combobox("select", items[1][opts.valueField]);
                    }
                }
            });
        }

        function SetShopArea() {
            $('#cbo_Area').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=DA_BAS_SEL_AREA_CBO&LANGID=<%=SSUser.LangID%>&SHOPID=<%=SSUser.ShopID%>&AREAIUSE=Y&SHOPIUSE=Y&USERID=<%=SSUser.UserID%>&CBOOPT=OPT|AREAID|AREANAME_ML'
                , valueField: 'AREAID'
                , textField: 'AREANAME_ML'
                , onSelect: function (record) {
                    $.ajaxSettings.async = false;
                    SetPdgr(record);
                    $.ajaxSettings.async = true;

                }, onLoadSuccess: function () {
                   var items = $(this).combobox("getData");
                   if ($('#cbo_Area').combobox('getData').length == 2) {
                       $('#cbo_Area').combobox('setValue', $('#cboArea').combobox('getData')[1].AREAID);
                   }
                   else if (items.length > 2) {
                       var opts = $(this).combobox("options");
                       var userArea = '<%=SSUser.AreaID%>';
                       var b = false;
                       for(var i = 0; i < items.length; i++) {
                           if(items[i][opts.valueField] == userArea) {
                               $(this).combobox("select", userArea);
                               b = true;
                               break;
                           }
                       }
                       if(!b) $(this).combobox("select", items[0][opts.valueField]);
                   }
               }
            });
        };
        //#endregion

        //#region SetDateTime - 날짜를 설정한다.
        function SetDateTime() {
            /// <summary>날짜를 설정한다.</summary>  
            var fromday = new Date();
            var today = new Date();

            fromday.setDate(fromday.getDate() - 7);
            $('#dtDateRange').daterangebox('SetFromDate', fromday);
            $('#dtDateRange').daterangebox('SetToDate', today);
        }
        //#endregion

        // 전기일자 체크
        function validResendDate() {
            var _closeDate = $("#txtWipCloseDate").textbox("getText");

            if (_closeDate != undefined && _closeDate != null && _closeDate != "") {
                try {
                    _closeDate = convertDate(_closeDate);
                } catch (e) {
                    _closeDate = "";
                }
            } else {
                _closeDate = "";
            }

            var _today = new Date();
            var _resendDate = $("#dtPostingDate").datebox("getValue");
            var _select = new Date(_resendDate);
            var _fromDate = new Date(_today.getFullYear(), _today.getMonth(), 1);
            var _toLast = new Date(_today.getFullYear(), _today.getMonth() + 1, 0);

            var _pre = new Date(_today.getFullYear(), _today.getMonth() - 1, 1);
            var _preYear = _pre.getFullYear();          // 전달 년도
            var _preMonth = _pre.getMonth() + 1;            // 전달 월
            var _preDay = _pre.getDate();                // 전달 일
            var _last = new Date(_today.getFullYear(), _today.getMonth(), 0); // 전월 마지막날

            if (_closeDate == "") { // 마감일이 없다면.
                if (_fromDate <= _select && _today >= _select) { // 당월 값으로만 세팅
                    return 1;
                } else {
                    return 2; // 10012 : [%1](을)를 선택하여 주십시오.
                }
            } else {
                if (_today <= _closeDate) { //마감일자가 오늘 이거나 뒷날이면 전달 1일 ~ 오늘까지 선택가능
                    if (_pre <= _select && _today >= _select) {
                        return 1;
                    } else {
                        return 3; // 전달 1 ~ 오늘 날짜안에서 선택하십시요.
                    }
                } else if (_today > _closeDate) { // 마감일자가 오늘 보다 이전 이면 당월
                    if (_fromDate <= _select && (new Date(_today.getFullYear(), _today.getMonth(), _today.getDate(), 0, 0, 0) >= new Date(_select.getFullYear(), _select.getMonth(), _select.getDate(), 0, 0, 0))) {
                        return 1;
                    } else {
                        return 4; // 당월 1일 부터 오늘 날짜내에서 선택하십시요.
                    }
                }
            }

            

            return 0;
        }
        //#region SetProcessingState - 처리 상태 콤보박스에 데이터를 설정한다
        function SetProcessingState() {
            /// <summary>처리 상태 콤보박스에 데이터를 설정한다.</summary> 
            //$('#cbo_ProcessingState').combobox({
            //    url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_COMMONCODE_CBO&LANGID=' + XSSReplace( $("[id$=hidLangID]").val()  , 1) + '&CMCDTYPE=PROCESSING_STATUS&CBOOPT=ALL|CMCODE|CMCDNAME',
            //    valueField: 'CMCODE',
            //    textField: 'CMCDNAME',
            //    onLoadSuccess: function () {
            //        var items = $(this).combobox("getData");
            //        if (items.length === 2) {
            //            var opts = $(this).combobox("options");
            //            $(this).combobox("select", items[1][opts.valueField]);
            //        }
            //    }
            //});

            $('#cbo_TXNSTAT').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_COMMONCODE_CBO&CMCDTYPE=ERP_TXNSTAT&LANGID=<%=SSUser.LangID%>&CBOOPT=ALL|CMCODE|CMCDNAME',
                valueField: 'CMCODE',
                textField: 'CMCDNAME',
            });
        }
        //#endregion

        //#region SetEAITransFlag - 전송결과 콤보박스에 데이터를 설정한다
        function SetEAITransFlag() {
            /// <summary>전송결과 콤보박스에 데이터를 설정한다.</summary> 

            $('#cbo_TRANSFLAG').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_COMMONCODE_CBO&CMCDTYPE=EAI_TRANSFFLAG&LANGID=<%=SSUser.LangID%>&CBOOPT=ALL|CMCODE|CMCDNAME',
                valueField: 'CMCODE',
                textField: 'CMCDNAME',
            });
        }
        //#endregion
        function dateConvert(date) {
            // YYYYMMDD 로 리턴한다.
            var tmpDate = date.split(" ");
            var strDate = tmpDate[0].split("-");
            var rtnDate = "";

            for (var i = 0; i <= strDate.length - 1; i++) {
                rtnDate = rtnDate + strDate[i];
            }

            return rtnDate
        }



        //#region InquiryData - 검색 조건에 해당하는 데이터를 조회한다.
        function InquiryData() {

            var deferred = CallCheckLots($('#sbLotId'));

            deferred.done(function (strLots, arrLots) {

                //var fromdate = dateConvert($.fn.datebox.defaults.formatter($('#dtDateRange').daterangebox('GetFromDate')));
                //var todate = dateConvert($.fn.datebox.defaults.formatter($('#dtDateRange').daterangebox('GetToDate')));
                var fromdate = $('#dtDateRange').daterangebox('GetFromDate');
                var todate = $('#dtDateRange').daterangebox('GetToDate');
                var items = {};                
                
                items.LANGID = XSSReplace( $("[id$=hidLangID]").val()  , 1);

                if (strLots != '') { // $('#sbLotId').textbox('getValue').length > 0) {
                    
                    // 사용자 LOT
                    items.LOTID = strLots; // $('#sbLotId').textbox('getValue');

                } else {
                    var msg = '<%=lang.message["25068"]%>'; //[%1]의 선택 항목이 없습니다.
                    var _areaId = $('#cbo_Area').combobox('getValue');
                    var _pdgrId = $('#cbo_Grade').combobox('getValue');
                    // 공장/동 validation
                    if (_areaId == undefined || _areaId == "") {
                        msg = msg.replace("%1", '<%=lang.word["Shop/Area"]%>');
                        xAlert(msg);
                        return;
                    }
                    // 제품군 validation                    
                    if (_pdgrId == undefined || _pdgrId == "") {
                        msg = msg.replace("%1", '<%=lang.word["PRODGROUP"]%>');
                        xAlert(msg);
                        return;
                    }

                    items.AREAID = $('#cbo_Area').combobox('getValue');
                    items.PDGRID = $('#cbo_Grade').combobox('getValue');
                    items.EQSGID = $('#cbo_Line').combobox('getValue');
                    items.EQPTID = $('#cbo_Equipment').combobox('getValue');
                    items.MTRLID = $("#sbProductCode").textbox('getText');
                    //items.TXNSTAT = $('#cbo_ProcessingState').combobox('getValue');
                    items.TXNSTAT = $('#cbo_TXNSTAT').combobox('getValue');
                    items.EAI_TRANSFFLAG = $('#cbo_TRANSFLAG').combobox('getValue');

                    if ($('input:radio[id=rdoTRANS]').is(':checked')) {
                        items.DATE_FROM = fromdate;
                        items.DATE_TO = todate;
                    } else {
                        items.DATE_BU_FROM = fromdate.format("yyyyMMdd");
                        items.DATE_BU_TO = todate.format("yyyyMMdd");
                    }
                }                


                var param = {};
                if ($('input:radio[id=rdoProd]').is(':checked')) {
                    param.bizID = "DA_PRD_SEL_ERP_IF_PROD";
                } else {
                    param.bizID = "DA_IM_PRD_SEL_ERP_IF_MATERIAL_INPUT";
                    //if (XSSReplace(XSSReplace($("[id$=hidShopID]").val()   , 1)   , 1) == "G621") {
                    //    param.bizID = "DA_IM_PRD_SEL_ERP_IF_MATERIAL_INPUT";
                    //} else {
                    //    param.bizID = "DA_PRD_SEL_ERP_IF_MATERIAL_INPUT";
                    //}
                }

                param.items = items;
                param.inTableNames = "RQSTDT";
                param.outTableNames = "RSLTDT";

                var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";


                UCRealGrid.CallRequest(url, param);
            });
        }

        //#endregion

        function DoPostingDateResend() {
            var _resendDate = GetDateDash($("#dtPostingDate").datebox("getValue"), true, '-');
            var chkRows = UCRealGrid_gridView.getCheckedRows();
            var checkItems = [];
            for (var i = chkRows.length - 1; i >= 0; i--) {
                var curRows = UCRealGrid_dataProvider.getJsonRow(chkRows[i]);
                if (curRows.EAI_ROWID != "") {
                    checkItems.push(curRows.EAI_ROWID);
                }
            }

            checkItems = returnUniqData(checkItems);
            var _eaiRowIdList = "";
           
            for (var idx = 0; idx < checkItems.length; idx++) if (checkItems[idx].trim().length > 0) _eaiRowIdList = _eaiRowIdList.concat("'", checkItems[idx].trim(), "',");

            if (_eaiRowIdList.length > 0) _eaiRowIdList = _eaiRowIdList.substring(0, _eaiRowIdList.length - 1);
           

            var items = [];
            var subItems = [];
            
            subItems[0] = [
                          { name: 'EAI_ROWID_LIST', value: _eaiRowIdList, dataType: _DataType.String }
                        , { name: 'BUDAT', value: _resendDate, dataType: _DataType.String }
                        
            ];
            
            items[0] = subItems;

            var url = "/GMES_POM/GMES_IMS_0480.aspx/ExecuteData";
            var param = {};
            param.bizID = "BR_INF_REG_ERP_PRODRESULT_BUDAT";
            param.items = items;
            param.inTableNames = 'INDATA';
            param.outTableNames = '';

            ShowLoading();
            sendRequestMethod(function (id, data, message, status) {
                CloseLoading();
                if (status != "OK") {
                    xAlert(message);
                    return;
                } else {
                    xAlert(msgProcessComplete);//처리 되었습니다. 
                    InquiryData();
                }
            }, param, "POST", url);
        }

        function convertDate(str) {
            var _date = str.replace("-", "").replace("-", "");
            var _year = _date.substring(0, 4);
            var _month = _date.substring(4, 6);
            var _day = _date.substring(6, 8);
            return new Date(_year, _month - 1, _day);
        }

        function validCloseDate(pCheckDate) {
            var _closeDate = $("#txtWipCloseDate").textbox("getText");
            
            if (_closeDate != undefined && _closeDate != null && _closeDate != ""){
                try{
                    _closeDate = convertDate(_closeDate);
                }catch(e){
                    _closeDate = "";
                }
            } else {
                _closeDate = "";
            }

            try{
                var _today = new Date();
                var _todayYear = _today.getFullYear();      // 오늘짜 년도
                var _todayMonth = _today.getMonth() + 1;         // 오늘짜 월
                var _todayDay = _today.getDate();            // 오늘짜 일

                var _pre = new Date(_todayYear, _today.getMonth() - 1, 1);
                var _preYear = _pre.getFullYear();          // 전달 년도
                var _preMonth = _pre.getMonth() + 1;            // 전달 월
                var _preDay = _pre.getDate();                // 전달 일

                var _last = new Date(_preYear, _pre.getMonth() + 1, 0); // 전월 마지막날

                var _chkDate = new Date(pCheckDate);
                var _chkDateYear = _chkDate.getFullYear();  // 선택한 데이터의 년도
                var _chkDateMonth = _chkDate.getMonth() + 1    // 선택한 데이터의 월
                var _chkDateDay = _chkDate.getDate();        // 선택한 데이터의 일

                // 0. 오늘을 기준으로 전달 마감일자 조회
                // 1. 마감일자가 없다면 해당월에 대해서만 전기일자 재전송 가능
                // 2. 마감일자가 오늘이거나 뒷날이면 전달의 1일 부터 오늘 날짜까지만 전기일자 재전송 가능
                // 3. 마감일자가 오늘자보다 이전날이면 해당월의 전기일자 재전송 가능
                if (_closeDate == "") { // 마감일자가 없다면 전월건 처리
                    if (_todayYear == _chkDateYear && _todayMonth == _chkDateMonth) { // 당월건 체크
                        return true;
                    } else {
                        return false;
                    }
                } else {
                    if (_today <= _closeDate) { // 마감일자가 오늘 이거나 뒷날이면 전월 및 당일까지건 처리
                        if (_pre <= _chkDate && _closeDate >= _chkDate) { // 전월 1일 부터 당일까지건 체크
                            return true;
                        } else {
                            return true;
                        }
                    } else if (_today > _closeDate) { // 마감일자가 오늘 보다 이전 이면 당월 건 처리
                        if (_todayYear = _chkDateYear && _todayMonth == _chkDateMonth) { // 당월건 체크
                            return true;
                        } else {
                            return false;
                        }
                    }
                }
            } catch (e) {
                return false;
            }            
        }

        // 월마감 일자 수집
        function GetWipCloseMonth() {
            var _today = new Date();
            var _year = _today.getFullYear();
            var _month = _today.getMonth() + 1;
            var _day = _today.getDate();

            var _pre = new Date(_year, _today.getMonth() - 1, 1);
            var _preYear = _pre.getFullYear();
            var _preMonth = _pre.getMonth() + 1;           

            var items = {};
            items.WIPCLOSEMONTH = _preYear + "" + (_preMonth > 9 ? _preMonth : "0" + _preMonth);
            items.SHOPID = "<%=SSUser.ShopID%>";
            items.USEFLAG = "Y";

            var param = {};
            var param = {};
            param.bizID = "DA_BAS_SEL_TB_SFC_WIPCLOSEMONTH";
            param.items = items;
            param.inTableName = "RQSTDT";
            param.outTableName = "RSLTDT";

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonDataSetByDictionary";

            sendRequestMethod(function (id, data) {
                if (data != null) {
                    if (data[0].RSLTDT.length > 0) {
                        // WIPCLOSEMONTH가 설정되어 있을 때
                        var wipCloseDate = data[0].RSLTDT[0].WIPCLOSEDATE;

                        $("#txtWipCloseDate").textbox("setText", wipCloseDate);
                    } else {
                        //
                    }
                }                                
            }, param, "POST", url);
        }

        // #region SetWaitToSend - ERP전송 트랜잭션  
        function SetWaitToSend(useFlag) {


            var chkRows = UCRealGrid_gridView.getCheckedRows();
            var cntVal = 0;
            var items = [];
            var subItems = [];

            var checkItems = [];
            for (var i = chkRows.length - 1; i >= 0; i--) {
                var curRows = UCRealGrid_dataProvider.getJsonRow(chkRows[i]);
                if (curRows.EAI_ROWID != "") {
                    checkItems.push(curRows.EAI_ROWID);
                }
            }
            //중복키 제거
            checkItems = returnUniqData(checkItems);

            items = [];
            subItems = [];
            for (var i = 0; i < checkItems.length; i++) {
                var EAI_ROWID = checkItems[i];

                subItems[i] = [
                       { name: "EAI_ROWID", value: EAI_ROWID, dataType: _DataType.String }
                       , { name: "EAI_TRANSFFLAG", value: useFlag, dataType: _DataType.String }
                ];
            }
            items[0] = subItems;

            var url = "/GMES_COM/Service/CallBizJson.aspx/ExecuteData";
            var param = {};
            if ($('input:radio[id=rdoProd]').is(':checked')) {
                param.bizID = "DA_PRD_UPD_ERP_IF_PROD_TRANSFLAG";
            } else {
                param.bizID = "DA_PRD_UPD_ERP_IF_MATERIAL_INPUT_TRANSFLAG";
            }
            param.items = items;
            param.inTableNames = "RQSTDT";
            param.outTableNames = "";

            sendRequestMethod(CallBackSave, param, "POST", url);
            
        }
        // #endregion

        // #region CallBackSave - 트랜잭션 콜백 처리 후 메시지 
        function CallBackSave(id, data) {
            if (data === null) return;
            if (data[0].RETURN === "FAIL") {
                xAlert(data[0].MESSAGE);
                return;
            }
            else if (data[0].RETURN === "OK") {
                xAlert(msgProcessComplete);//처리 되었습니다. 
                InquiryData();
                return;
            }
        }
        // #endregion
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
                        
                    case "btnSetWaitToSend":    //ERP전송
                        if (UCRealGrid.GetRowCount() == 0) return false;

                        var selRows = UCRealGrid_gridView.getCheckedRows();
                        if (selRows.length == 0) {
                            //선택된 데이터가 없습니다. 
                            xAlert(msgNotSelectedList);
                            return false;
                        }
                        xConfirm(msgSendToERPConfrim, function (parm) { if (parm) SetWaitToSend("N"); });
                        break;

                        Validate("EXCEL");
                        break;
                    case "btnPostingDateResend": // 전기일자 재전송
                        var _resendDate = GetDateDash($("#dtPostingDate").datebox("getValue"), false, '-');
                        var chkRows = UCRealGrid_gridView.getCheckedRows();
                        if (chkRows.length == 0) {
                            var _msg = "<%=lang.message["10008"]%>";//10008 선택된 데이터가 없습니다.
                            xAlert(_msg);
                            return;
                        }
                        var _validResendDate = validResendDate();
                        if (_validResendDate != 1) {
                            if (_validResendDate == 2 || _validResendDate == 4) {
                                var _msg = "<%=lang.message["20334"]%>"; // 20334 당월 [%]일부터 오늘 날짜까지만 선택하세요.
                                _msg = _msg.replace("%1", "1");
                                xAlert(_msg);
                                return;
                            } else if(_validResendDate == 3) {
                                var _msg = "<%=lang.message["20333"]%>"; // 20333 [%]월1일 부터 오늘 날짜까지만 선택하세요.
                                var _today = new Date();
                                var _pre = new Date(_today.getFullYear(), _today.getMonth() - 1, 1);
                                var _preMonth = _pre.getMonth() + 1;
                                _msg = _msg.replace("%1", _preMonth);
                                xAlert(_msg);
                                return;
                            } else {
                                var _msg = "<%=lang.message["20043"]%>" + "\\n[<%=lang.word["STODOCDATE"]%>]"; // 20043 날짜설정이 잘못되었습니다.
                                xAlert(_msg);
                                return;
                            }                           
                        }                        
                        xConfirm(msgSendToERPConfrim + "\\n[<%=lang.word["STODOCDATE"]%>: " + _resendDate + " ]", function (parm) { if (parm) DoPostingDateResend(); });
                        break;
                    default:
                }
            } catch (e) {
                xAlert(e.message);
            }
        }
        //#endregion

        function GetDateDash(pDate, flag, dash) {
            var t = pDate;
            if (!isNaN(t)) {
                var date = new Date(t);
                if (dash != undefined) {
                    return date.getFullYear() + dash + ((date.getMonth() < 9 ? "0" : "") + Number(date.getMonth() + 1)) + dash + ((date.getDate() < 10 ? "0" : "") + date.getDate());
                }
                return date.getFullYear() + ((date.getMonth() < 9 ? "0" : "") + Number(date.getMonth() + 1)) + ((date.getDate() < 10 ? "0" : "") + date.getDate());
            }
            if (flag) {
                return t.replace(dash, "").replace(dash, "");
            } else {
                return t;
            }
            
            return t;
        }

        function onReSendCheckedClick(id) {
            var isChecked = $("#chkPostingDateResend").is(":checked");

            SetButtonEnable("#btnPostingDateResend", isChecked);//btnReSend
            SetButtonEnable("#dtPostingDate", isChecked);//dtPostingDate
            SetButtonEnable("#btnSetWaitToSend", !isChecked);//btnSetWaitToSend

            if (isChecked == true) {
                $('#dtPostingDate').datebox('enable');
            } else {
                $('#dtPostingDate').datebox('disable');
            }
            


            UCRealGrid_gridView.checkAll(false, false);

        }
        // #region onRadioClick - 라디오 버튼 클릭 이벤트 후 처리
        /// <summary>라디오 버튼 클릭 이벤트 후 처리</summary>  
        /// <param name="id" type="string">라디오 버튼 ID</param> 
        function onRadioClick(id) {
            var isChecked = $("input:radio[id=" + id + "]").is(':checked');
            $("#hidSearchID").val($("input:radio[id=" + id + "]").val());

            SetButtonEnable("#btnSetWaitToSend", true);
            SetButtonEnable("#btnPostingDateResend", false);
            $('#chkPostingDateResend').attr("checked", false);            

            if (id === "rdoProd") {
                if (isChecked) {
                    InitGrid("ProdLot");
                    if ("<%=SSUser.ShopID%>" == "30D0") { // RO
                        SetPostingDateResendControl(true);
                    }
                }
            }
            else if (id === "rdoInput") {
                if (isChecked) {
                    $("#hidReference").val($("input:radio[id=" + id + "]").val());
                    InitGrid("InputLot");
                    SetPostingDateResendControl(false);
                }
            }
        }
        // #endregion 

        // #region ExcelExport - 그리드 데이터를 엑셀 파일로 출력한다.
        function ExcelExport() {
            /// <summary>그리드 데이터를 엑셀 파일로 출력한다</summary>       
            var fNameToday = "ErpInterfaceInfo_" + new Date().format("yyyyMMdd_hhmmss") + "_export.xlsx";
            UCRealGrid.ExcelExport(fNameToday, true);
        }
        // #endregion

        // #region ShowProductCodePopup - 제품코드명 팝업창을 Open한다.
        function ShowProductCodePopup(value) {
            ///// <summary>제품코드명 팝업창을 Open한다.</summary>    
            // 제품검색 팝업창을 오픈하여 제품코드 / 코드명을 리턴받는다.
            var PDGRID = $('#cbo_Grade').combobox('getValue');
            ShowPopup("../GMES_COM/GMES_COM_0003.aspx?MENU_ID=<%=ViewState["MENU_ID"].ToString()%>&PROD_SEARCH=" + value + "&PDGRID=" + PDGRID, 790, 500, '<%=lang.word["Drawing No."]%>' + '<%=lang.word["Search"]%>', SetProductName);
        }
        // #endregion
        
        // #region SetProductName - 제품코드 검색 팝업 후 선택 제품 정보 제품코드 text box에 적용
        function SetProductName(data) {
            if (data !== undefined && data.length > 0) {
                $("#sbProductCode").textbox('setValue', data[2]);
                $("#txtProductName").textbox('setValue', data[1]);
            }
        }
        // #endregion        

        // #region Validate - 함수 실행 전 유효성 체크
        function Validate(type) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            var result = false;

            switch (type) {
                case "SEARCH":
                    if($('#sbLotId').textbox('getValue').trim().length == 0) {
                        if ($('#cbo_Area').combobox('getValue') == '') {
                            xAlert('<%=lang.message["20059"]%>'.replace('%1', '<%=lang.word["Shop/Area"]%>'));
                            return;
                        }

                        if ('<%=HttpContext.Current.Session["multiProdGr"]%>' == 'Y') {
                            if ($('#cbo_Grade').combobox('getValue') == '') {
                                xAlert('<%=lang.message["20059"]%>'.replace('%1', '<%=lang.word["Product Group"]%>'));
                                return;
                            }
                        }

                    }
                    break;
                case "EXCEL":
                    if (UCRealGrid.GetRowCount() == 0) {
                        xAlert(msgNotFoundList);
                        return;
                    }
                    ExcelExport();
                    break;
                default:
            }
            result = true;
            return result;
        }
        // #endregion

        function InitGrid(code) {
            /// <summary>RealGrid를 초기화한다.</summary> 
            var aLabel = [];
            var aValue = [];
            //sFieldName, sCaption, nWidth, sFormat, nDataType, bEdit, bVisible, aLabels, aValues
            UCRealGrid.ColumnsClear();
            if (code === "init" || code === "ProdLot") { 
                UCRealGrid.AddColumn("ERPTRANSDATE", "<%=lang.word["ERP Send"]%> <%=lang.word["DATETIME"]%>", 150, getLocaleDateFormat('<%=SSUser.LangID%>') + " HH:mm:ss", ColumnType.DATETIME, false, true, null, null); // ERP 전송 일시
                UCRealGrid.AddColumn("BUDAT", "<%=lang.word["Electric"]%><%=lang.word["Day"]%>", 100, getLocaleDateFormat('<%=SSUser.LangID%>'), ColumnType.DATETIME, false, true, null, null); // 작업일
                UCRealGrid.AddColumn("LOTID", "<%=lang.word["LOTID"]%>", 130, "center", ColumnType.TEXT, false, true, null, null); // LOT ID
                UCRealGrid.AddColumn("LOTID_USER", "<%=lang.word["LOTID_USER"]%>", 130, "center", ColumnType.TEXT, false, true, null, null); // LOT ID
                UCRealGrid.AddColumn("WOID", "<%=lang.word["Work Order No."]%>", 120, "center", ColumnType.TEXT, false, true, null, null); // 작업지시 번호
                UCRealGrid.AddColumn("MTRLID", "<%=lang.word["Product Code"]%>", 130, "near", ColumnType.TEXT, false, true, null, null); // 제품코드
                UCRealGrid.AddColumn("MTRLNAME", "<%=lang.word["Product Name"]%>", 200, "near", ColumnType.TEXT, false, true, null, null); // 제품 명
                UCRealGrid.AddColumn("PCSGID", "<%=lang.word["W/C"]%>", 100, "center", ColumnType.TEXT, false, true, null, null); // W/C 
                UCRealGrid.AddColumn("PLANQTY", "<%=lang.word["Plan Qty"]%>", 80, "#,##0.00", ColumnType.NUMBER, false, true, null, null); // 지시량
                UCRealGrid.AddColumn("PRODQTY", "<%=lang.word["Product QTY"]%>", 80, "#,##0.00", ColumnType.NUMBER, false, true, null, null); // 생산량
                UCRealGrid.AddColumn("OUTQTY", "<%=lang.word["Defect Qty2"]%>", 80, "#,##0.00", ColumnType.NUMBER, false, true, null, null); // 불량
                UCRealGrid.AddColumn("STORAGELOCATION", "<%=lang.word["Sloc. ID"]%>", 90, "center", ColumnType.TEXT, false, true, null, null); // 저장위치 ID
                UCRealGrid.AddColumn("STORAGELOCATION_NAME", "<%=lang.word["Sloc. Name"]%>", 150, "center", ColumnType.TEXT, false, true, null, null); // 저장위치 명
                UCRealGrid.AddColumn("ERPTRANSFFLAG", "<%=lang.word["TRANSFLAG"]%>", 0, "center", ColumnType.TEXT, false, false, null, null); // 전송 여부
                UCRealGrid.AddColumn("ERPTRANSFFLAGNAME", "<%=lang.word["TRANSFLAG"]%>", 70, "center", ColumnType.TEXT, false, true, null, null); // 전송 여부
                UCRealGrid.AddColumn("ERPRESULTCD", "<%=lang.word["Transfer Result"]%>", 70, "center", ColumnType.TEXT, false, false, null, null); // 전송 결과
                UCRealGrid.AddColumn("ERPRESULTCDNM", "<%=lang.word["Transfer Result"]%>", 70, "center", ColumnType.TEXT, false, true, null, null); // 전송 결과명
                UCRealGrid.AddColumn("ERPRESULTDATE", "<%=lang.word["ERP Result Date"]%>", 150, getLocaleDateFormat('<%=SSUser.LangID%>') + " HH:mm:ss", ColumnType.DATETIME, false, true, null, null); // ERP 처리 일시
                UCRealGrid.AddColumn("ERPRESULTDESC", "<%=lang.word["Message"]%>", 180, "near", ColumnType.TEXT, false, true, null, null); // 메세지
                UCRealGrid.AddColumn("EAI_ROWID", "<%=lang.word["EAI_ROWID"]%>", 0, "near", ColumnType.TEXT, false, true, null, null); // KEY
            } else if (code === "InputLot") {
                UCRealGrid.AddColumn("ERPTRANSDATE", "<%=lang.word["ERP Send"]%> <%=lang.word["DATETIME"]%>", 150, getLocaleDateFormat('<%=SSUser.LangID%>') + " HH:mm:ss", ColumnType.DATETIME, false, true, null, null); // ERP 전송 일시
                UCRealGrid.AddColumn("BUDAT", "<%=lang.word["Electric"]%><%=lang.word["Day"]%>", 100, getLocaleDateFormat('<%=SSUser.LangID%>'), ColumnType.DATETIME, false, true, null, null); // 작업일
                UCRealGrid.AddColumn("LOTID", "<%=lang.word["Input LOTID"]%>", 130, "near", ColumnType.TEXT, false, true, null, null); // 투입 LOT ID
                UCRealGrid.AddColumn("LOTID_USER", "<%=lang.word["LOTID_USER"]%>", 130, "near", ColumnType.TEXT, false, true, null, null); // 투입 LOT ID
                
                UCRealGrid.AddColumn("WOID", "<%=lang.word["Work Order No."]%>", 120, "center", ColumnType.TEXT, false, true, null, null); // 작업지시 번호
                UCRealGrid.AddColumn("MTRLID", "<%=lang.word["Product Code"]%>", 130, "near", ColumnType.TEXT, false, true, null, null); // 제품코드
                UCRealGrid.AddColumn("MTRLNAME", "<%=lang.word["Product Name"]%>", 190, "near", ColumnType.TEXT, false, true, null, null); // 제품 명
                UCRealGrid.AddColumn("PLANQTY", "<%=lang.word["Plan Qty"]%>", 80, "#,##0.00", ColumnType.NUMBER, false, true, null, null); // 지시량
                UCRealGrid.AddColumn("PRODQTY", "<%=lang.word["Input Quantity"]%>", 80, "#,##0.00", ColumnType.NUMBER, false, true, null, null); // 투입량
                UCRealGrid.AddColumn("PCSGID", "<%=lang.word["W/C"]%>", 100, "center", ColumnType.TEXT, false, true, null, null); // W/C
                UCRealGrid.AddColumn("PRODUCT_LOTID", "<%=lang.word["Product LOTID"]%>", 130, "near", ColumnType.TEXT, false, true, null, null); // 생산 LOT ID
                UCRealGrid.AddColumn("STORAGELOCATION", "<%=lang.word["Sloc. ID"]%>", 90, "center", ColumnType.TEXT, false, true, null, null); // 저장위치 ID
                UCRealGrid.AddColumn("STORAGELOCATION_NAME", "<%=lang.word["Sloc. Name"]%>", 150, "center", ColumnType.TEXT, false, true, null, null); // 저장위치 명
                UCRealGrid.AddColumn("ERPTRANSFFLAG", "<%=lang.word["TRANSFLAG"]%>", 0, "center", ColumnType.TEXT, false, false, null, null); // 전송 여부
                UCRealGrid.AddColumn("ERPTRANSFFLAGNAME", "<%=lang.word["TRANSFLAG"]%>", 70, "center", ColumnType.TEXT, false, true, null, null); // 전송 여부
                UCRealGrid.AddColumn("ERPRESULTCD", "<%=lang.word["Transfer Result"]%>", 70, "center", ColumnType.TEXT, false, false, null, null); // 전송 결과
                UCRealGrid.AddColumn("ERPRESULTCDNM", "<%=lang.word["Transfer Result"]%>", 70, "center", ColumnType.TEXT, false, true, null, null); // 전송 결과명
                UCRealGrid.AddColumn("ERPRESULTDATE", "<%=lang.word["ERP Result Date"]%>", 150, getLocaleDateFormat('<%=SSUser.LangID%>') + " HH:mm:ss", ColumnType.DATETIME, false, true, null, null); // ERP 처리 일시
                UCRealGrid.AddColumn("ERPRESULTDESC", "<%=lang.word["Message"]%>", 180, "near", ColumnType.TEXT, false, true, null, null); // 메세지
                UCRealGrid.AddColumn("EAI_ROWID", "<%=lang.word["EAI_ROWID"]%>", 0, "near", ColumnType.TEXT, false, true, null, null); // KEY
            }
            
            if (code === "init")
                UCRealGrid.InitGrid("<%=ViewState["MENU_ID"].ToString()%>", false, true, true);
            else {
                UCRealGrid.InitGridControl(false, true, true);
            }

            var menuLabels = [
                "<%=lang.word["Product Lot Info"]%>"
                , "<%=lang.word["Input Lot Info"]%>"
                , "<%=lang.word["Defect Information"]%>"
                , "<%=lang.word["Quality Information"]%>"
                , "<%=lang.word["Remark Info"]%>"
                , "<%=lang.word["Process Report Print"]%>"];

            SetCommonContextMenu(UCRealGrid, menuLabels, "LOTID");

            UCRealGrid_gridView.setCheckBar({ showAll: true }); // 전체 선택 기능 Disable            

            UCRealGrid_gridView.onItemChecked = function (grid, itemIndex, checked) {
                if (typeof UCRealGrid_ItemChecked != "undefined") {
                    UCRealGrid_ItemChecked(grid, itemIndex, checked);
                }
            };

            //UCRealGrid_gridView.setSelectOptions({
            //    style: 'rows'
            //});

            <%--UCRealGrid_gridView.setContextMenu([
                { label: "<%=lang.word["Product Lot Info"]%>", tag: ContextMenuID.ProductLotInfo }   // 생산Lot정보
                , { label: "<%=lang.word["Input Lot Info"]%>", tag: ContextMenuID.InputLotInfo }         // 투입Lot정보
                , { label: "<%=lang.word["Defect Information"]%>", tag: ContextMenuID.DefectInfo }    // 불량정보
                , { label: "<%=lang.word["Quality Information"]%>", tag: ContextMenuID.QualityInfo }  // 품질비고
                , { label: "<%=lang.word["Remark Info"]%>", tag: ContextMenuID.Remark }  // 품질비고
                , { label: "<%=lang.word["Process Report Print"]%>", tag: ContextMenuID.Print }  // 공정지 발행
            ]);

            UCRealGrid_gridView.onContextMenuPopup = function (grid, x, y, elementName) {

                // 선택 필드 "LOTID" 미포함 및 elementName이 "HeaderCell" : 클릭 무시
                return ((UCRealGrid.GetCurrent().fieldName.match("LOTID")) && (elementName != "HeaderCell")) ? true : false;
            };

            UCRealGrid_gridView.onContextMenuItemClicked = function (grid, menuid, index) {
                var currentRow = UCRealGrid.GetCurrent();
                if (currentRow.fieldName.match("LOTID"))
                    {
                    if (currentRow.dataRow > -1) {
                        if (menuid.tag == 0) {
                            //생산Lot정보 Popup
                            CollapseSlideArea();
                            ExpandCommonSlideArea();
                            SendDataToCommonSlideArea('0,LOTID=' + UCRealGrid_dataProvider.getValue(currentRow.dataRow, currentRow.fieldName));
                        }
                        else if (menuid.tag == 1) {
                            //투입Lot정보 Popup
                            CollapseSlideArea();
                            ExpandCommonSlideArea();
                            SendDataToCommonSlideArea('1,LOTID=' + UCRealGrid_dataProvider.getValue(currentRow.dataRow, currentRow.fieldName));
                        }
                        else if (menuid.tag == 2) {
                            //물량정보 Popup
                            CollapseSlideArea();
                            ExpandCommonSlideArea();
                            SendDataToCommonSlideArea('2,LOTID=' + UCRealGrid_dataProvider.getValue(currentRow.dataRow, currentRow.fieldName));
                        }
                        else if (menuid.tag == 3) {
                            // 품질비고 Popup    
                            CollapseSlideArea();
                            //ShowPopup("../GMES_POM/GMES_IMS_1520.aspx?LOTID=" + UCRealGrid_dataProvider.getValue(currentRow.dataRow, currentRow.fieldName), 1200, 800, "<=lang.word["Quality Information"]>", null);
                            OpenQuality(UCRealGrid_dataProvider.getValue(currentRow.dataRow, currentRow.fieldName), '<%=lang.word["Quality Information"]%>');
                        }
                        else if (menuid.tag == 4) {
                            // 비고정보 Popup    
                            CollapseSlideArea();
                            ShowPopup("../GMES_POM/GMES_IMS_1530.aspx?LOTID=" + UCRealGrid_dataProvider.getValue(currentRow.dataRow, currentRow.fieldName), 650, 420, "<%=lang.word["Remark Info"]%>", null);
                        }
                        else if (menuid.tag == 5) {
                            //공정지 출력   
                            printRun(UCRealGrid_dataProvider.getValue(currentRow.dataRow, currentRow.fieldName));
                        };
                    };
                };
            };--%>
        }
        //배열에서 중복 제거
        function returnUniqData(a) {
            var unique = a.filter(function (item, i, a) {
                return i == a.indexOf(item);
            }
            );
            return unique;
        }

        function UCRealGrid_ItemChecked(grid, itemIndex, checked) {
            //if (checked == true) {
            //    UCRealGrid_gridView.checkAll(false, false);
            //    UCRealGrid_gridView.checkItem(itemIndex, checked, false, false);                    
            //}
            var selSTAT = UCRealGrid_dataProvider.getValue(itemIndex, "ERPTRANSFFLAG");
            var selRESULT = UCRealGrid_dataProvider.getValue(itemIndex, "ERPRESULTCD");
            var selBUDAT = UCRealGrid_dataProvider.getValue(itemIndex, "BUDAT");
            var isChecked = $("#chkPostingDateResend").is(":checked");
            //전송차단만 체크되도록
            if (selSTAT == undefined || (selSTAT != undefined && selSTAT != "W" && isChecked == false)) {
                UCRealGrid.SetCheckBarValue(itemIndex, false);
            }

            if (isChecked == true && (selRESULT != "E" || validCloseDate(selBUDAT) == false)) {
                UCRealGrid.SetCheckBarValue(itemIndex, false);
            }
        }
        function UCRealGrid_LoadDataCompleted(rtn) {
            /// <summary>함수 실행 전 유효성 체크</summary> 
            $("#totalConunt").html("<%=lang.word["Search results"]%> ( Total <span class='red01'>" + UCRealGrid.GetRowCount() + "</span> Found )");
            if (UCRealGrid.GetRowCount() == 0) {
                xAlert(msgNotFoundList);
            }
        
            var expressFields = [
                      { fieldName: "MTRLNAME", style: { styles: { textAlignment: "far" }, text: "<%=lang.word["Grand Total"]%> :", groupText: "<%=lang.word["Sub Total"]%> :" } }
                    , { fieldName: "PRODQTY", style: { styles: { textAlignment: "far", numberFormat: "#,##0" }, expression: "sum", groupExpression: "sum" } }
                    , { fieldName: "OUTQTY", style: { styles: { textAlignment: "far", numberFormat: "#,##0" }, expression: "sum", groupExpression: "sum" } }
            ];
            var groupByFields = ["GRADE"];
            UCRealGrid.SetGroup(groupByFields, expressFields);
        }
        
    </script>
</asp:Content>

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
                <table class="tableShopArea">
                    <colgroup>
                        <col class="col_10p" />
                        <col class="col_16p" />
                        <col class="col_5p" />
                        <col class="col_16p" />
                        <col class="col_5p" />
                        <col class="col_16p" />
                        <col class="col_5p" />
                        <col class="col_10p" />
                        <col class="col_15p" />
                        <col />
                    </colgroup>
                    <tbody>
                        <tr>
                            <th><span class="textPink">*</span><%=lang.word["Shop/Area"]%></th>
                            <td>
                                <div style="float: left">

                                    <table class="tableShopArea">
                                       <tr>
                                          <td><input id="cbo_Area" class="easyui-combobox" style="width: 200px;" /></td>
                                       </tr>
                                       <tr class="ProdGR">
                                          <td><input id="cbo_Grade" class="easyui-combobox" style="width: 200px;" /></td>
                                       </tr>
                                    </table>


                                </div>
                            </td>
                            <th><%=lang.word["Line/Equipment Seg."]%></th>
                            <td>
                                <div style="float: left">
                                    <input id="cbo_Line" class="easyui-combobox" style="width: 200px; " />
                                </div>
                            </td>

                            <th><%=lang.word["Equipment"]%></th>
                            <td>
                                <div style="float: left">
                                    <input id="cbo_Equipment" class="easyui-combobox" style="width: 200px; " />
                                </div>
                            </td>




                        </tr>
                        <tr>
                            <!-- 조회 조건 -->
                            <th >
                                <span class="textPink">*</span><%=lang.word["Reference Criteria"]%>
                            </th>
                            <td >
                                <fieldset style="display: inline-block;">
                                    <label for="rdoProd">
                                        <input type="radio" name="rdo_01" value="LOTID" id="rdoProd" onclick="onRadioClick(this.id);" checked /><%=lang.word["Production Result"]%></label>
                                    <label for="rdoInput">
                                        <input type="radio" name="rdo_01" value="PC" id="rdoInput" onclick="onRadioClick(this.id);" /><%=lang.word["Input Result"]%></label>
                                </fieldset>
                            </td>
                            <!-- 전송여부 -->
                            <th><%=lang.word["TRANSFLAG"]%></th>
                            <td>
                                <input id="cbo_TRANSFLAG" class="easyui-combobox" style="width: 100%; max-width: 200px; "/>
                            </td>
                            <!-- 제품코드명-->
                            <th><%=lang.word["Product Code/Name"]%></th> 
                            <td colspan="2">
                                <div style="width: 100%; ">
                                    <div style="float: left;  ">
                                        <input id="sbProductCode" class="easyui-searchbox" style="display: inline-block; width: 30%;" data-options="searcher:ShowProductCodePopup , inputEvents: $.extend({}, $.fn.searchbox.defaults.inputEvents, { keyup: function(e){ $('#txtProductName').textbox('setText', ''); } })"/>

                                        <input id="txtProductName" class="easyui-textbox" style="display: inline-block; width: 70%; " disabled="disabled" readonly="readonly" />
                                    </div>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <!-- 처리 상태 -->
                            <!-- <th><%=lang.word["Processing State"]%></th>
                            <td>
                                <select id="cbo_ProcessingState" class="easyui-combobox" style="width: 100%; max-width: 200px; "/>
                            </td> -->
                            <!-- 조회 기간 -->
                            <th  > <!-- <span class="textPink">*</span><=lang.word["Search Period"]> -->
                                <fieldset style="display: inline-block; ">
                                    <label for="rdoTRANS">
                                        <input type="radio" name="rdo_02" value="TRANS" id="rdoTRANS" checked /><%=lang.word["ERP Send"]%><%=lang.word["Date"]%></label>
                                    <label for="rdoBUDAT">
                                        <input type="radio" name="rdo_02" value="BUDAT" id="rdoBUDAT" /><%=lang.word["STODOCDATE"]%></label>
                                </fieldset>
                            </th>
                            <td >
                                <input id="dtDateRange" class="easyui-daterangebox" style="width: 100%; max-width: 200px; " />
                            </td>
                            <!-- 전송결과 -->
                            <th><%=lang.word["SEND_RESULT"]%></th>
                            <td>
                                <input id="cbo_TXNSTAT" class="easyui-combobox" style="width: 100%; max-width: 200px; "/>
                            </td>
                            <!-- LOT ID -->
                            <th id="thLotId"><%=lang.word["LOTID"]%></th>
                            <td id="tdLotId">
                                <input id="sbLotId" class="easyui-textbox" style="float: left; width: 100%; max-width: 200px;"/>
                                <%--<input id="sbLotId" class="easyui-textbox" style="width: 200px; height: 100%; max-height: 60px" data-options="multiline:true" />--%>
                                <span style="display:none;"><input id="txtWipCloseDate" class="easyui-textbox" style="float: left; width: 100%; max-width: 200px;"/></span>
                            </td>
                            <td>&nbsp;</td>
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

        <!--  CRUD Button Area start -->
        <div class="buttonArea" id="tbContents">
            <div id="totalConunt" class="floatLeft01"><%=lang.word["Search results"]%> ( Total <span class="red01">0</span> Found )</div>            


            <ul id="ulButton" runat="server" class="btn_crud">
                <li><a class="red" id="btnPostingDateResend" onclick="onButtonClick(this.id)"><%=lang.word["STODOCDATE"]%> <%=lang.word["ReSend"]%></a></li> <!-- 전기일자 재전송 -->
                <li><a class="table_bar" id="btnTableBar"></a></li>
                <li><a class="red" id="btnSetWaitToSend" onclick="onButtonClick(this.id)"><%=lang.word["ERP Send"]%></a></li> <!-- ERP 전송 -->
                <li><a class="table_bar"></a></li>
                <li><a class="excel" id="btnExcel" onclick="onButtonClick(this.id)"></a></li>
            </ul>
            <div style="margin: 0px 0px 0px 0px;float:right;padding-top: 0px;">
                <span id="spanPostingDate">
                <input type="checkbox" id="chkPostingDateResend" onclick="onReSendCheckedClick(this.id);"/>    
                <input id="dtPostingDate" class="easyui-datebox" style="width:100px;" />
                </span>                              
            </div>
        </div>
        <!-- CRUD Button Area end -->

        <!-- Contents 시작  -->
        <div id="dvContents_Mid" class="table">
            <uc:Realgrid ID="UCRealGrid" CALLID="UCRealGrid" HEIGHT="200" runat="server"/>
        </div>
        <!-- Contents 종료 -->        
        <input type="hidden" id="hidReference" />
        <input type="hidden" id="hidSelectedValue" />
        <input type="hidden" id="hidPartNoValue" />
        <input type="hidden" id="hidProdNameValue" />
        <input type="hidden" id="hidProdIdValue" />
    </form>
</asp:Content>