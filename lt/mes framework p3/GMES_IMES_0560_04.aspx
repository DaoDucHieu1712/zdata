<%@ Page Language="C#" MasterPageFile="~/Master/MasterApiPopup.Master" AutoEventWireup="true" CodeFile="GMES_IMES_0560_04.aspx.cs" Inherits="GMES_IMES_0560_04" %>

<%--/* 
*************************************************************************************************
* @source  : GMES_IM_POM/GMES_IMES_0560_04.aspx
* @desc    : 생산실적 - 이상품 추적 - 검사항목 관리
************************************************************************************************* 
* VER  DATE         AUTHOR      		DESCRIPTION
*************************************************************************************************
* 1.0  2024/10/13   송상호              INIT
*************************************************************************************************
*/--%>



<%@ Register Src="../common/UserControl/UCUpdatePanelContent.ascx" TagName="UpdatePanelContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCSearchToggle.ascx" TagName="SearchToggleContent" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCpopCalendar.ascx" TagName="UCpopCalendar" TagPrefix="uc" %>
<%@ Register Src="../common/UserControl/UCRealgrid.ascx" TagName="Realgrid" TagPrefix="uc" %>
<%@ Register Assembly="System.Web.DataVisualization, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" Namespace="System.Web.UI.DataVisualization.Charting" TagPrefix="asp" %>
<%-- Fucntion --%>
<asp:Content ID="HeaderContent" ContentPlaceHolderID="headHolder" runat="server">
    <style>
        .checkbox-dn input[type="checkbox"] {
            display: none !important;
        }
    </style>
    <script type="text/javascript" src="/GMES_COM/Scripts/IMSCommon.js?v=20240130"></script>
    <script language="javascript" type="text/javascript">

        $(window).resize(function () {

        });

        $(document).ready(function () {

        });
        function xInitPage() { }

    </script>
</asp:Content>

<asp:Content ID="UIContent" ContentPlaceHolderID="bodyHolder" runat="server">

    <form id="form1" runat="server">
        <asp:HiddenField ID="hidLangID" runat="server" />
        <asp:HiddenField ID="hidMenuID" runat="server" />
        <asp:HiddenField ID="hidShopID" runat="server" />
        <asp:HiddenField ID="hidAreaID" runat="server" />
        <asp:HiddenField ID="hidProdID" runat="server" />
        <asp:HiddenField ID="hidWhID" runat="server" />
        <asp:HiddenField ID="hidMTRLTYPE" runat="server" />
        <asp:HiddenField ID="hidINLOTID" runat="server" />
        <asp:ScriptManager runat="server" EnablePageMethods="True" ID="ScriptManager1" />

        <div id="capture_All" style="margin-left: 20px;">
            <asp:UpdatePanel ID="UpdatePanel1" runat="server" UpdateMode="Conditional">
                <ContentTemplate>
                    <asp:Chart ID="Chart1" runat="server" Width="1400" Height="600">
                        <Legends>
                            <asp:Legend Name="Legend1" IsTextAutoFit="False" LegendStyle="Row" Font="맑은 고딕, 12pt">
                            </asp:Legend>
                        </Legends>
                        <Titles>
                            <asp:Title Font="맑은 고딕, 12pt, style=Bold" Name="Title1">
                            </asp:Title>
                        </Titles>
                        
                        <Series>
                            <asp:Series Name="Series1" Font="맑은 고딕, 10pt, style=Bold" ChartType="StackedBar" Color="#70AD47"></asp:Series>
                            <asp:Series Name="Series2" Font="맑은 고딕, 10pt, style=Bold" ChartType="StackedBar" Color="#5B9AD5"></asp:Series>
                            <asp:Series Name="Series3" Font="맑은 고딕, 10pt, style=Bold" ChartType="StackedBar" Color="#FF0000"></asp:Series>
                        </Series>
                        <ChartAreas>
                            <asp:ChartArea Name="Default">
                            </asp:ChartArea>
                        </ChartAreas>
                        
                    </asp:Chart>
                </ContentTemplate>

            </asp:UpdatePanel>
        </div>
    </form>
</asp:Content>
