<%--/* 
*************************************************************************************************
* @source  : GMES_POM/GMES_IMS_0585.aspx
* @desc    : 재고관리 - ERP I/F - ERP 시점재고I/F 이력조회
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2022/08/08   문창완              INIT
* 1.1  2022/11/29   S.Y.H               차수 DEFAULT 1로 설정하도록 수정.
* 1.2  2023/02/21   전찬혁              C20230223-000041 구미 양극재 PJT 요청 다국어 적용
*************************************************************************************************
*/--%>

<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPage.Master" AutoEventWireup="true" CodeFile="GMES_IMS_0585.aspx.cs" Inherits="GMES_IMS_0585" %>

<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>

<%-- Fucntion --%>
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
    <script language="javascript" type="text/javascript">               
        var bSearch = false;

        //▼▼ Event ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼

        $(window).resize(function () {
            AutoHeightSpread(true);
        });

        $(document).ready(function () {
            
            InitData();

            InitGrid2();

            // 통문증 체크 이벤트
            $("#chkExistsLoc").click(function () {
                if ($("#chkExistsLoc").prop("checked")) {
                    $("#cboSlocId").combobox('setValue', '');
                }
            });

        });        

        // xInitPage => 필수!! 상위에서 호출됨??
        function xInitPage() {
            AutoHeightSpread(true);
        }

        function AutoHeightSpread(cSize) {
            var gridMaster = document.getElementById("UCRealgrid");

            var masterSchHeight = document.getElementById("divSearchPart").clientHeight;
            var masterTitHeight = document.getElementById("divMidButton").clientHeight;
            var pageHeight = document.documentElement.clientHeight;

            var i = 0;
            i = pageHeight - (masterSchHeight + masterTitHeight) - 100;

            gridMaster.style.height = String(i) + 'px';

            UCRealgrid.ResetSize();

            if (cSize) {
                
            }
        }

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

        function colSize(colName, size) {

            var column = UCRealgrid_gridView.columnByName(colName);
            if (column) {
                UCRealgrid_gridView.setColumnProperty(column, "width", size);
            }
        }

        // #region ExcelExport - 그리드 데이터를 엑셀 파일로 출력한다.
        function ExcelExport() {
            /// <summary>그리드 데이터를 엑셀 파일로 출력한다</summary>
            var fNameToday = $("[id$=hidMenuName]").val() + new Date().format("yyyyMMdd_hhmmss") + "_export.xlsx";
            UCRealgrid.ExcelExport(fNameToday);
        }

        function ExcelExportAll() {
            var items = {};            

            var _ifNo = $('#txtIfNo').numberbox('getValue');

            if (_ifNo == undefined || _ifNo == null || _ifNo == "") {
                xAlert("<%=lang.message["20058"]%>".replace("%1", "<%=lang.word["Sequence Number"]%>")); // 20058 : [%1]을 입력하세요. Sequence Number : 차수
                return false; 
            }            

            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.DATUM = $('#dtDate').datebox('GetDateString');
            items.TRANSFLAG = $("#cboProcessingFlag").combobox("getValue");
            items.LOCATION = $("#cboSlocId").combobox("getValue");            
            items.LOCNOTNULL = $("#chkExistsLoc").prop("checked") ? "Y" : "";
            items.MTRLID = $("#txtMtrlId").textbox("getValue");
            items.LOTLIST = getLotList();
            items.IFNO = $('#txtIfNo').numberbox('getValue');            
                        
            var param = {};
            param.bizID = "DA_PRD_SEL_ERP_IF_HISTORY_TOTAL";
            param.items = items;
            param.inTableNames = "INDATA";
            param.outTableNames = "OUTDATA";

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            ShowLoading();                        
            sendRequestMethod(function () {
                CloseLoading();                
                if (data != null) {
                    UCRealgrid2.SetGridData(data);
                    ShowLoading();
                    UCRealgrid2_LoadDataCompleted();
                    CloseLoading();
                }
            }, param, "POST", url);
            
        }
        
        // #endregion 

        function onButtonClick(id) {

            try {

                switch (id) {
                    case "btnExcel":
                        ExcelExport();
                        break;
                    case "btnExcelAll":
                        ExcelExportAll();
                        break;
                    default:
                        break;
                }

            } catch (e) {
                xAlert(e.message);
            }

        }

        function InitData() {


            // GRID 셋팅
            InitGrid();            
                        
            // Set Controls
            // 2022.11.29 S.Y.H 차수 1 DEFAULT 설정 START
            $('#txtIfNo').numberbox('setValue', 1);
            // 2022.11.29 S.Y.H 차수 1 DEFAULT 설정 END

            SetProcessingFlag() // 처리상태
            SetStorage(); // 저장위치            
            SetRowCountPerPage() // 페이지당 조회건수
            
            // 조회일자 셋팅
            SetDateTime();

            jQuery('#ulPaging').empty();                        
        }
        
        // 페이지 컨트롤 (총건수, 페이지당 Row 건수, 현재페이지)
        function makePageNavigation(totalRowCount, countPerPage, currentPage) {
            jQuery('#ulPaging').empty();

            var _viewPageCount = 10;
            var _totalPages = (totalRowCount % countPerPage) == 0 ? Math.floor(totalRowCount / countPerPage) : Math.floor(totalRowCount / countPerPage) + 1;                                    

            var _currFirstPageNum = currentPage <= _viewPageCount ? 1 : 
                             ((currentPage % _viewPageCount) == 0 ? ((Math.floor(currentPage / _viewPageCount) - 1) * _viewPageCount + 1) : (Math.floor(currentPage / _viewPageCount) * _viewPageCount + 1));                

            var _currLastPageNum = (currentPage % _viewPageCount) == 0 ? currentPage : (Math.floor(currentPage / _viewPageCount) + 1) * _viewPageCount;
            _currLastPageNum = _currLastPageNum > _totalPages ? _totalPages : _currLastPageNum;

            var _prevPageNum = (currentPage % _viewPageCount) == 0 ? (currentPage - _viewPageCount) : Math.floor(currentPage / _viewPageCount) * _viewPageCount;

            var _nextPageNum = (_prevPageNum + _viewPageCount + 1);
            _nextPageNum = _nextPageNum > _totalPages ? _totalPages : _nextPageNum;            

            var _firstPage = '<li><a style="border: 1px solid #808080; color:#db3461;" onclick="searchByPage(' + countPerPage + ',1);">처음</a></li>';
            var _prevPage = '<li><a style="border: 1px solid #808080; color:#db3461;" onclick="searchByPage(' + countPerPage + ',' + _prevPageNum + ');">&lt;&lt;</a></li>';
            var _nextPage = '<li><a style="border: 1px solid #808080; color:#db3461;" onclick="searchByPage(' + countPerPage + ',' + _nextPageNum + ');">&gt;&gt;</a></li>';
            var _lastPage = '<li><a style="border: 1px solid #808080; color:#db3461;" onclick="searchByPage(' + countPerPage + ',' + _totalPages + ');" >끝</a></li>';
            var _currPage = '<li><a style="background:#db3461; border: 1px solid #808080; color:#ffffff;" >' + currentPage + '</a></li>';

            //console.log("currentPage " + currentPage);
            //console.log("_totalPages " + _totalPages);
            //console.log("_currFirstPageNum " + _currFirstPageNum);
            //console.log("_currLastPageNum " + _currLastPageNum);
            //console.log("_prevPageNum " + _prevPageNum);
            //console.log("_nextPageNum " + _nextPageNum);

            if (_totalPages <= 10) {
                for (var idx = 0; idx < _totalPages; idx++) {
                    var _pageNum = idx + 1;
                    if (currentPage == _pageNum)
                        jQuery('#ulPaging').append(_currPage);
                    else
                        jQuery('#ulPaging').append('<li><a style="border: 1px solid #808080; color:#db3461;" onclick="searchByPage(' + countPerPage + ',' + _pageNum + ')" >' + _pageNum + '</a></li> ');
                }
            } else {
                // 처음페이지와 이전페이지 진행
                if (_currFirstPageNum > _viewPageCount) {
                    jQuery('#ulPaging').append(_firstPage);
                    jQuery('#ulPaging').append(_prevPage);
                }

                for (var idx = _currFirstPageNum; idx <= _currLastPageNum; idx++) {
                    var _pageNum = idx;
                    if (currentPage == _pageNum)
                        jQuery('#ulPaging').append(_currPage);
                    else
                        jQuery('#ulPaging').append('<li><a style="border: 1px solid #808080; color:#db3461;" onclick="searchByPage(' + countPerPage + ',' + _pageNum + ')" >' + _pageNum + '</a></li> ');
                }

                // 다음페이지와 끝페이지 진행
                if (_currLastPageNum < _totalPages) {
                    jQuery('#ulPaging').append(_nextPage);
                    jQuery('#ulPaging').append(_lastPage);
                }
            }
        }

        function getLotList() {
            var attrText = $("#txtLotIds").textbox('getText');
            var attrMultiline = $("#txtLotIds").textbox('options').multiline;


            var uniqueItems = [];
            if (attrText != '') {
                var splitItems = attrText.split('\n');
                splitItems.forEach(function (value, index, array) {
                    var trimValue = $.trim(value);
                    if (value.length > 0) {
                        uniqueItems[index] = trimValue;
                    };
                });
            }

            uniqueItems = CallUniqueArray(uniqueItems);

            return uniqueItems.length > 0 ? uniqueItems.join() : null;
        }

        // 페이지를 통한 조회 (페이지당 Row 건수, 현재페이지)
        function searchByPage(countPerPage, currentPage) {
            
            for (var i = 0; i < vFilters.length; i++) {
                UCRealgrid_gridView.activateAllColumnFilters(vFilters[i], false);
            }

            var items = {};                      

            items.LANGID = $("[id$=hidLangID]").val();
            items.SHOPID = $("[id$=hidShopID]").val();
            items.DATUM = $('#dtDate').datebox('GetDateString');
            items.TRANSFLAG = $("#cboProcessingFlag").combobox("getValue");
            items.LOCATION = $("#cboSlocId").combobox("getValue");            
            items.LOCNOTNULL = $("#chkExistsLoc").prop("checked") ? "Y" : "";
            items.MTRLID = $("#txtMtrlId").textbox("getValue");
            items.LOTLIST = getLotList();
            items.IFNO = $('#txtIfNo').numberbox('getValue');
            items.PAGE_NO = currentPage;
            items.COUNT_PER_PAGE = $("#cboRowCount").combobox("getValue");
            
            if (items.IFNO == undefined || items.IFNO == null || items.IFNO == "") {
                xAlert("<%=lang.message["20058"]%>".replace("%1", "<%=lang.word["Sequence Number"]%>")); // 20058 : [%1]을 입력하세요. Sequence Number : 차수
                return false; 
            }


            var param1 = {};
            param1.bizID = "DA_PRD_SEL_ERP_IF_HISTORY_TOTAL_COUNT";
            param1.items = items;
            param1.inTableNames = "INDATA";
            param1.outTableNames = "OUTDATA";

            var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";

            ShowLoading();
            sendRequestMethod(function () {
                CloseLoading();
                if (data != null) {                    
                    var _totalRowCount = data[0].COUNT;
                    $("#totalConunt").html("&nbsp;&nbsp;&nbsp;&nbsp;<%=lang.word["Search results"]%> ( Total <span class='red01'>" + _totalRowCount + "</span> Found ) ");
                    {
                        var _countPerPage = countPerPage == undefined || countPerPage == null || countPerPage == "" ? $("#cboRowCount").combobox("getValue") : countPerPage;
                        if (_totalRowCount > 0) {
                            makePageNavigation(_totalRowCount, _countPerPage, currentPage);
                        } else {
                            jQuery('#ulPaging').empty();
                        }
                        
                        var param = {};
                        param.bizID = "DA_PRD_SEL_ERP_IF_HISTORY";
                        param.items = items;
                        param.inTableNames = "INDATA";
                        param.outTableNames = "OUTDATA";

                        var url = "/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary";
                        UCRealgrid.CallRequest(url, param);
                        UCRealgrid.Refresh();
                    }                    
                }
            }, param1, "POST", url);

            //makePageNavigation(_totalRowCount, countPerPage, currentPage);
        }

        //==================================================================================================================================
        // # "Search"(조회) 버튼 클릭 시
        function searchData()
        {
            var _countPerPage = $("#cboRowCount").combobox("getValue");

            searchByPage(_countPerPage, 1);

                       
        }   

        // 페이지당 로우갯수
        function SetRowCountPerPage() {
            $('#cboRowCount').combobox({
                valueField: 'VALUE',
                textField: 'TEXT',
                onLoadSuccess: function () {
                    //
                }
            });
            var rowCount = [];
            rowCount.push({ VALUE: '100', TEXT: '100 건' });
            rowCount.push({ VALUE: '200', TEXT: '200 건' });
            rowCount.push({ VALUE: '500', TEXT: '500 건' });
            rowCount.push({ VALUE: '1000', TEXT: '1000 건' });
            rowCount.push({ VALUE: '5000', TEXT: '5000 건' });
            rowCount.push({ VALUE: '10000', TEXT: '10000 건' });
            $('#cboRowCount').combobox('loadData', rowCount);

            $('#cboRowCount').combobox('setValue', '1000');
        }

        // 처리상태
        function SetProcessingFlag() { 
            /// <summary>처리상태여부 콤보박스에 데이터를 설정한다. Y:처리 N:미처리 </summary> 
            $('#cboProcessingFlag').combobox({
                url: '../common/xml/CallBizJson.aspx?sp_name=BR_COM_GET_COMMONCODE_CBO&LANGID=' + $("[id$=hidLangID]").val() + '&CMCDTYPE=PROCESSING_STATUS&CBOOPT=ALL|CMCODE|CMCDNAME',
                valueField: 'CMCODE',
                textField: 'CMCDNAME',
            });
            //$('#cboProcessingFlag').combobox("select", ""); //전체
        }
        
       function SetStorage() {
           //저장위치
           $('#cboSlocId').combobox({
               url: '../common/xml/CallBizJson.aspx?sp_name=CUS_SEL_STORAGELOCATION_RANGE_CBO&LANGID=' + $("[id$=hidLangID]").val() + '&SHOPID=' + $("[id$=hidShopID]").val()
                     + '&USEFLAG=Y&CBOOPT=ALL|SLOCID|SLOCNAME',
               valueField: 'SLOCID',
               textField: 'SLOCNAME',
               onSelect: function () { 

               },
            });
       }       

        function SetDateTime() {            
            var toDay = $.fn.datebox.defaults.formatter(new Date());
            $('#dtDate').datebox('setValue', toDay);
        }

            
        
        var vFilters = ["LOCATION", "MTRLID", "MESLOT"];
        //▼▼ RealGrid Column & Filed Info ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼        
        function InitGrid() {

            var aLabel = [];
            var aValue = [];
           
            UCRealgrid.ColumnsClear();            

            UCRealgrid.AddColumn("ROWNUM", "<%=lang.word["NO"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("DATUM", "<%=lang.word["Registration Date"]%>", 100, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("IFNO", "<%=lang.word["Sequence Number"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("TOTAL_CNT", "<%=lang.word["KCOUNT"]%>", 80, "#,##0", 1, false, true, null, null);
            UCRealgrid.AddColumn("SHOPID", "<%=lang.word["SHOPID"].Replace("ID","")%>", 60, "center", 0, false, true, null, null);//플랜트 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            UCRealgrid.AddColumn("LOCATION", "<%=lang.word["Storage Location"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("MTRLID", "<%=lang.word["PRODCODE"]%>", 150, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("MESLOT", "<%=lang.word["LOT ID"]%>", 130, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("LOTDATE", "<%=lang.word["LOT Create"]%><%=lang.word["Day"]%>", 150, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("LOTUOM", "<%=lang.word["Unit"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("LOTQTY", "<%=lang.word["Work In Progress Inventory"]%>", 80, "#,##0.000", 1, false, true, null, null);
            UCRealgrid.AddColumn("POSSQTY", "<%=lang.word["Available Inventory"]%>", 80, "#,##0.000", 1, false, true, null, null);//가용재고 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            UCRealgrid.AddColumn("FAILQTY", "<%=lang.word["Defect"]%><%=lang.word["Cur. Stock"]%>", 80, "#,##0.000", 1, false, true, null, null);
            UCRealgrid.AddColumn("HOLDQTY", "<%=lang.word["Holding Stock"]%>", 80, "#,##0.000", 1, false, true, null, null);
            //UCRealgrid.AddColumn("MOVEQTY", "<%=lang.word["TRANSITSTOCK"]%>", 80, "#,##0.000", 1, false, true, null, null);//운송중재고 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            UCRealgrid.AddColumn("SCANQTY", "<%=lang.word["Physical Count"]%>" + "<%=lang.word["Cur. Stock"]%>", 80, "#,##0.000", 1, false, true, null, null);//실사재고 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            UCRealgrid.AddColumn("EAI_CREATEDTTM", "EAI <%=lang.word["Created Datetime"]%>", 150, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("EAI_TRANSFFLAG", "EAI <%=lang.word["TRANSFLAG"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("EAI_TRANSFDTTM", "EAI <%=lang.word["TRANSDTTM"]%>", 150, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("TXNFLAG", "<%=lang.word["Processing State"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("ERRCODE", "<%=lang.word["Remain Results"]%> <%=lang.word["Code"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("ERRDESC", "<%=lang.word["Remain Results"]%> <%=lang.word["Message"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("CLOSEMONTH", "<%=lang.word["Closing"]%> <%=lang.word["Month"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("EAI_ROWID", "EAI <%=lang.word["ROWID"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("EAI_SRCSYSID", "EAI <%=lang.word["SRCSYSID"]%>", 120, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("ZSYSID", "<%=lang.word["Legacy System ID"]%>", 130, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("ZDEPT", "<%=lang.word["ENTERPRISE"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("ZSYSCD", "<%=lang.word["System Code"]%>", 120, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("ZSYSDB", "<%=lang.word["System DB"]%>", 120, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("IFSEQ", "I/F <%=lang.word["Sequence"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("LOCNO", "<%=lang.word["Sub System"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("LOCNO_NM", "<%=lang.word["Sub System Name"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("EAI_ENTID", "EAI <%=lang.word["ENTERPRISE"]%> ID", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("EAI_SITEID", "EAI <%=lang.word["Site ID"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid.AddColumn("EAI_SHOPID", "EAI <%=lang.word["Shop ID"]%>", 60, "center", 0, false, true, null, null);

            UCRealgrid.InitGrid("<%=ViewState["MENU_ID"].ToString()%>", false, false, true);                
                        
            UCRealgrid.SetColsFilter(vFilters);
        }

        function InitGrid2() {

            var aLabel = [];
            var aValue = [];
           
            UCRealgrid2.ColumnsClear();            

            UCRealgrid2.AddColumn("ROWNUM", "<%=lang.word["NO"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("DATUM", "<%=lang.word["Registration Date"]%>", 100, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("IFNO", "<%=lang.word["Sequence Number"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("TOTAL_CNT", "<%=lang.word["KCOUNT"]%>", 80, "#,##0", 1, false, true, null, null);
            UCRealgrid2.AddColumn("SHOPID", "<%=lang.word["SHOPID"].Replace("ID","")%>", 60, "center", 0, false, true, null, null);//플랜트 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            UCRealgrid2.AddColumn("LOCATION", "<%=lang.word["Storage Location"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("MTRLID", "<%=lang.word["PRODCODE"]%>", 150, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("MESLOT", "<%=lang.word["LOT ID"]%>", 130, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("LOTDATE", "<%=lang.word["LOT Create"]%><%=lang.word["Day"]%>", 150, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("LOTUOM", "<%=lang.word["Unit"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("LOTQTY", "<%=lang.word["Work In Progress Inventory"]%>", 80, "#,##0.000", 1, false, true, null, null);
            UCRealgrid2.AddColumn("POSSQTY", "<%=lang.word["Available Inventory"]%>", 80, "#,##0.000", 1, false, true, null, null);//가용재고 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            UCRealgrid2.AddColumn("FAILQTY", "<%=lang.word["Defect"]%><%=lang.word["Cur. Stock"]%>", 80, "#,##0.000", 1, false, true, null, null);
            UCRealgrid2.AddColumn("HOLDQTY", "<%=lang.word["Holding Stock"]%>", 80, "#,##0.000", 1, false, true, null, null);
            //UCRealgrid2.AddColumn("MOVEQTY", "<%=lang.word["TRANSITSTOCK"]%>", 80, "#,##0.000", 1, false, true, null, null);//운송중재고 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            UCRealgrid2.AddColumn("SCANQTY", "<%=lang.word["Physical Count"]%>" + "<%=lang.word["Cur. Stock"]%>", 80, "#,##0.000", 1, false, true, null, null);//실사재고 2023-02-21 전찬혁 C20230223-000041 구미 양극재 PJT 요청 다국어 적용
            UCRealgrid2.AddColumn("EAI_CREATEDTTM", "EAI <%=lang.word["Created Datetime"]%>", 150, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("EAI_TRANSFFLAG", "EAI <%=lang.word["TRANSFLAG"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("EAI_TRANSFDTTM", "EAI <%=lang.word["TRANSDTTM"]%>", 150, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("TXNFLAG", "<%=lang.word["Processing State"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("ERRCODE", "<%=lang.word["Remain Results"]%> <%=lang.word["Code"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("ERRDESC", "<%=lang.word["Remain Results"]%> <%=lang.word["Message"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("CLOSEMONTH", "<%=lang.word["Closing"]%> <%=lang.word["Month"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("EAI_ROWID", "EAI <%=lang.word["ROWID"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("EAI_SRCSYSID", "EAI <%=lang.word["SRCSYSID"]%>", 120, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("ZSYSID", "<%=lang.word["Legacy System ID"]%>", 130, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("ZDEPT", "<%=lang.word["ENTERPRISE"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("ZSYSCD", "<%=lang.word["System Code"]%>", 120, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("ZSYSDB", "<%=lang.word["System DB"]%>", 120, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("IFSEQ", "I/F <%=lang.word["Sequence"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("LOCNO", "<%=lang.word["Sub System"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("LOCNO_NM", "<%=lang.word["Sub System Name"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("EAI_ENTID", "EAI <%=lang.word["ENTERPRISE"]%> ID", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("EAI_SITEID", "EAI <%=lang.word["Site ID"]%>", 60, "center", 0, false, true, null, null);
            UCRealgrid2.AddColumn("EAI_SHOPID", "EAI <%=lang.word["Shop ID"]%>", 60, "center", 0, false, true, null, null);

            UCRealgrid2.InitGrid("<%=ViewState["MENU_ID"].ToString()%>", false, false, true);                                                   
       }

        function CallBottomSlideSet(currentRow, tabIdx) {

            if (tabIdx == 3) {
                // 품질비고 Popup    
                //ShowPopup("../GMES_POM/GMES_IMS_1520.aspx?LOTID=" + UCRealgrid_dataProvider.getValue(currentRow.dataRow, 'LOTID'), 1200, 800, "<=lang.word["Quality Information"]>", null);
                OpenQuality(UCRealgrid_dataProvider.getValue(currentRow.dataRow, 'LOTID'), '<%=lang.word["Quality Information"]%>');
            } else {

                ExpandCommonSlideArea();
                SendDataToCommonSlideArea(tabIdx + ",LOTID=" + UCRealgrid_dataProvider.getValue(currentRow.dataRow, "LOTID"));
            }
        }

        function ShowProductPopup()
        {
            ShowPopup("../GMES_COM/GMES_COM_0003.aspx?PROD_SEARCH=" + $("#txtMtrlId").textbox("getValue"), 790, 500, '<%=lang.word["Drawing No."]%>' + '<%=lang.word["Search"]%>', SetProductName);
        };

        function SetProductName(data) {

            if (data == undefined) return;
            if (data.length != 3) return;

            //data[0];//Part No
            //data[1];//제품명
            //data[2];//제품코드

            $("#txtMtrlId").textbox("setValue", data[2]);
        };

        // Event setting
        function UCRealgrid_DblClicked(grid, index) {
            // event define
        }

        function UCRealgrid_CellClicked(grid, index) {
            // event define
        }

        function UCRealgrid_RowChanged(grid, oldRow, newRow) {
            // event define
        }

        function UCRealgrid_DataChanged(provider) {
            // event define
        }

        function UCRealgrid_CellEdited(grid, itemIndex, dataRow, field) {
            // event define
        }

        function UCRealgrid_LoadDataCompleted() {
            <%--$("#totalConunt").html("&nbsp;&nbsp;&nbsp;&nbsp;<%=lang.word["Search results"]%> ( Total <span class='red01'>" + UCRealgrid.GetRowCount() + "</span> Found ) ");--%>
        }

        function UCRealgrid_ImageButtonClicked(grid, itemIndex, column, buttonIndex, name) {
            
        }

        function UCRealgrid2_LoadDataCompleted() {
            var fNameToday = $("[id$=hidMenuName]").val() + new Date().format("yyyyMMdd_hhmmss") + "_ALL_export.xlsx";
            UCRealgrid2.ExcelExport(fNameToday);
        }

    </script>

</asp:Content>


<asp:Content ID="UISlideContent" ContentPlaceHolderID="slideHolder" runat="server">

    <div id="divSlidePopup">
        <div id="divUnStoringInfo" style="margin-top: 5px"></div>
    </div>

</asp:Content>

<%-- View --%>
<asp:Content ID="UIContent" ContentPlaceHolderID="bodyHolder" runat="server">

    <form id="form1" runat="server">
        <asp:ScriptManager runat="server" ID="ScriptManager1"></asp:ScriptManager>
        <asp:HiddenField ID="hidHeight" runat="server" />
        <asp:HiddenField ID="hidUserID" runat="server" />
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidLoginuser" runat="server" />
        <asp:HiddenField ID="hidAccessFlag" runat="server" />
        <asp:HiddenField ID="hidMenuName" runat="server" />    

        <div class="tableInquiry searchBox" id="divSearchPart">
            <div class="itemBox">
                <table>
                    <colgroup>
                        <col class="col_10p" />
                        <col class="col_25p" />
                        <col class="col_10p" />
                        <col class="col_20p" />
                        <col class="col_10p" />
                        <col class="col_20p" /> 
                        <col class="col_10p" />
                        <col class="col_20p" />
                        <col class="col_10p" />
                    </colgroup>
                    <tbody>
                        <tr>
                            <th><span class="textPink">*</span><%=lang.word["Registration Date"]%></th> <!-- 수행일 -->
                            <td>				                
                                <input id="dtDate" class="easyui-datebox" style="width:200px" />
                            </td>
                            <th><span class="textPink">*</span><%=lang.word["Sequence Number"]%></th> <!-- 차수 -->
                            <td>
				                <input id="txtIfNo" class="easyui-numberbox" style="width: 50px; max-width: 50px" data-options="precision:0" />                                                         
                            </td>
                            <th><%=lang.word["PRODCODE"]%></th> <!-- 제품코드 -->
                            <td >
                                <input id="txtMtrlId" class="easyui-searchbox" style="width: 100%; max-width: 200px" data-options="searcher:ShowProductPopup"/>
                            </td>
                            <th rowspan="2"><%=lang.word["LOTID"]%></th>
                            <td rowspan="2"><input id="txtLotIds" class="easyui-textbox" style="width: 200px; height: 100%; max-height: 80px;" data-options="multiple:true, multiline:true"  /></td>                                                                                 
                        </tr>
                        <tr>                            
                            <th><%=lang.word["Storage"]%></th> <!-- 저장위치 -->
                            <td>
                                <input id="cboSlocId" class="easyui-combobox" style="width: 100%; max-width: 200px" />
                                <label for="chkExistsLoc">
                                    <input type="checkbox" id="chkExistsLoc" name="chkExistsLoc"/><%=lang.word["Storage"]%> <%=lang.word["Flag"]%>
                                </label>
                            </td>                                                                                     
                            <th><%=lang.word["Processing State"]%></th>  <!--처리 상태 -->
                            <td>
                                <input id="cboProcessingFlag" class="easyui-combobox" style="width: 100%; max-width: 200px" />
                            </td> 
                            <td></td>
                                                      
                        </tr>
                    </tbody>
                </table>
            </div>
            <div id="divButtonArea" class="tableBtnSearch">
                <button type="button" id="btnSearch" onclick="javascript:searchData();"><span><%=lang.word["Search"]%></span></button><!-- 조회 -->
            </div>
            <uc:SearchToggleContent ID="SearchToggleContent2" runat="server" />
            <div class="clear"></div>
        </div>
        <div class="buttonArea" id="divMidButton">            
            <div id="totalConunt" class="floatLeft01">&nbsp;&nbsp;&nbsp;&nbsp;<%=lang.word["Search results"]%> ( Total <span class='red01'>0</span> Found ) </div>
            <div class="floatLeft01" style="margin-left:5px;margin-top:1px;">
                <input id="cboRowCount" class="easyui-combobox" style="width:80px; height:25px; max-width: 80px;" />
            </div>
            <div id="divBtnGatePass" style="margin: 0px 0px 0px 0px;float:right;padding-top: 0px;">
                <ul class="btn_crud">
                    <li><a class="table_bar"></a></li>
                    <li><a class="save" id="btnExcelAll" onclick="onButtonClick(this.id)"><%=lang.word["All"]%> <%=lang.word["Excel Down"]%></a></li>                
                </ul>
            </div>
            <ul id="ulBttomButton" runat="server" class="btn_crud">
                <li><a class="excel" id="btnExcel" onclick="onButtonClick(this.id)"></a></li>                
            </ul>
        </div>
        
        <div id="divMasterGrid" class="table">
            <uc:Realgrid ID="UCRealgrid" CALLID="UCRealgrid" HEIGHT="690" LAYOUTSAVING="Y" runat="server" />
            <span style="display:none;">
                <uc:Realgrid ID="UCRealgrid2" CALLID="UCRealgrid2" HEIGHT="690" LAYOUTSAVING="Y" runat="server" />
            </span>
        </div>        
        <div class="clear"></div>
        <div id="divPaging" class="buttonArea" style="width:100%; height:50px; display:flex; justify-content:center; text-align:center;">            
            <ul id="ulPaging" class="btn_crud" style="margin: 0px 0px 0px 0px;">             
                <li><a style="border: 1px solid #808080; color:#db3461;">&lt;처음</a></li>                                       
                <li><a style="border: 1px solid #808080; color:#db3461;" >1</a></li>
                <li><a style="border: 1px solid #808080; color:#db3461;" >2</a></li>  
                <li><a style="border: 1px solid #808080; color:#db3461;" >3</a></li>
                <li><a style="background:#db3461; border: 1px solid #808080; color:#ffffff;" >4</a></li>  
                <li><a style="border: 1px solid #808080; color:#db3461;" >5</a></li>
                <li><a style="border: 1px solid #808080; color:#db3461;" >6</a></li>  
                <li><a style="border: 1px solid #808080; color:#db3461;" >7</a></li>
                <li><a style="border: 1px solid #808080; color:#db3461;" >8</a></li>  
                <li><a style="border: 1px solid #808080; color:#db3461;" >9</a></li>  
                <li><a style="border: 1px solid #808080; color:#db3461;" >10</a></li>  
                <li><a style="border: 1px solid #808080; color:#db3461;" >다음&gt;</a></li>  
            </ul>  
             
        </div>  
                            
    </form>
</asp:Content>