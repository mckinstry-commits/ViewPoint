<%@ Register TagPrefix="POViewer" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register TagPrefix="Selectors" Namespace="POViewer" %>
<%@ Register TagPrefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="SelectFileToImport.aspx.cs"
    Inherits="POViewer.UI.SelectFileToImport" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title>SelectFileToImport</title>
    <base target="_self" />
</head>
<body id="Body1" runat="server" class="importWizardpBack">
    <form id="Form1" method="post" runat="server">
        <BaseClasses:ScrollCoordinates id="ScrollCoordinates" runat="server">
        </BaseClasses:ScrollCoordinates>
        <BaseClasses:BasePageSettings id="PageSettings" runat="server">
        </BaseClasses:BasePageSettings>

        <script language="JavaScript" type="text/javascript">clearRTL()</script>

        <asp:ToolkitScriptManager ID="scriptManager1" runat="server" EnablePartialRendering="True"
            EnablePageMethods="True" />
        <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();"
            onmouseover="clearTimeout(gPopupTimer);">
        </div>
        <table cellpadding="0" cellspacing="0" border="0">
            <tr>
                <td class="importWizardmarginTL">
                </td>
                <td class="importWizardpcT">
                </td>
                <td class="importWizardmarginTR">
                </td>
            </tr>
            <tr>
                <td class="importWizardmarginL">
                </td>
                <td class="importWizardpcC">
                    <table class="importWizarddv" cellpadding="0" cellspacing="0" border="0">
                        <tr>
                            <td class="importWizarddBody" style="width: 100%; height: 100%">
                                <table>
                                    <tr>
                                        <td class="tableCellValue">
                                            <asp:Label runat="server" ID="InfoLabel"></asp:Label></td>
                                    </tr>
                                    <tr>
                                        <td class="tableCellValue">
                                            <input type="file" id="InputFile" name="InputFile" runat="server" size="80" /></td>
                                        <td>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="tableCellValue">
                                            <br />
                                            <asp:Label runat="server" ID="fileInfo"></asp:Label></td>
                                    </tr>
                                </table>
                               <asp:UpdatePanel ID="FileSelectionPanel" runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <table>
                                        <tr>
                                            <td class="tableCellValue" colspan="4">
                                                <asp:RadioButton ID="rbtnCSV" runat="server" AutoPostBack="true" Checked="true" GroupName="ImportGroup"
                                                    OnCheckedChanged="rbtnCSV_CheckedChanged" />
                                                <%--<asp:Panel ID="pnlCSV" runat="server" Enabled="true">
                                                </asp:Panel>--%>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td class="tableCellValue" colspan="4">
                                                <asp:RadioButton ID="rbtnTAB" runat="server" AutoPostBack="true" Checked="false" GroupName="ImportGroup"
                                                    OnCheckedChanged="rbtnTAB_CheckedChanged" />
                                                <%--<asp:Panel ID="pnlTAB" runat="server" Enabled="true">
                                                </asp:Panel>--%>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td class="tableCellValue" colspan="4">
                                                <asp:RadioButton ID="rbtnExcel" runat="server" AutoPostBack="true" GroupName="ImportGroup"
                                                    OnCheckedChanged="rbtnExcel_CheckedChanged" />
                                            </td>
                                        </tr>
                                        <%--<asp:Panel ID="pnlExcel" runat="server" Enabled="false">--%>
                                            <tr>
                                                <td style="width: 28px">
                                                </td>
                                                <td class="tableCellValue">
                                                    <asp:Label ID="ExcelSheetname" runat="server">
                                                    </asp:Label>
                                                </td>
                                                <td class="tableCellValue">
                                                    <asp:TextBox ID="txtExcelSheetname" runat="server" CssClass="field_input" Text="Sheet1"></asp:TextBox>
                                                </td>
                                                <td>
                                                </td>
                                            </tr>
                                        <%--</asp:Panel>--%>
                                        <tr>
                                            <td class="tableCellValue" colspan="4">
                                                <asp:RadioButton ID="rbtnAccess" runat="server" AutoPostBack="true" GroupName="ImportGroup"
                                                    OnCheckedChanged="rbtnAccess_CheckedChanged" />
                                            </td>
                                        </tr>
                                        <%--<asp:Panel ID="pnlAccess" runat="server" Enabled="false">--%>
                                            <tr>
                                                <td>
                                                </td>
                                                <td class="tableCellValue">
                                                    <asp:Label ID="AccessTableName" runat="server">
                                                    </asp:Label>
                                                </td>
                                                <td class="tableCellValue">
                                                    <asp:TextBox ID="txtAccessTableName" runat="server" CssClass="field_input" Text="Table1"></asp:TextBox><br />
                                                </td>
                                                <td>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td>
                                                </td>
                                                <td class="tableCellValue">
                                                    <asp:Label ID="AccessPassword" runat="server">
                                                    </asp:Label>
                                                </td>
                                                <td class="tableCellValue">
                                                    <asp:TextBox ID="txtAccessPassword" runat="server" CssClass="field_input" TextMode="Password"></asp:TextBox>
                                                </td>
                                                <td class="tableCellValue">
                                                    <asp:Label ID="AccessPasswordOptional" runat="server">
                                                    </asp:Label>
                                                </td>
                                            </tr>
                                        <%--</asp:Panel>--%>
                                    </table>
                                </ContentTemplate>
                            </asp:UpdatePanel>
                                <table>
                                    <tr>
                                        <td>
                                            <br />
                                            <POViewer:Themebutton runat="server" id="NextButton" button-text="&lt;%# GetResourceValue(&quot;Import:Next&quot;) %>"
                                                button-tooltip="&lt;%# GetResourceValue(&quot;Import:Next&quot;) %>">
		</POViewer:Themebutton>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </table>
                </td>
                <td class="importWizardmarginR">
                </td>
            </tr>
            <tr>
                <td class="importWizardmarginBL">
                </td>
                <td class="importWizardpcB">
                </td>
                <td class="importWizardmarginBR">
                </td>
            </tr>
        </table>
        <asp:ValidationSummary ID="ValidationSummary1" ShowMessageBox="true" ShowSummary="false"
            runat="server"></asp:ValidationSummary>
    </form>
</body>
</html>
