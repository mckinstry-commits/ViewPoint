<%@ Register Tagprefix="ViewpointXRef" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="ImportData.aspx.cs" Inherits="ViewpointXRef.UI.ImportData" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" %>
<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head id="Head1" runat="server">
    <title>ImportData</title>
     <base target="_self" />
    </head>
    <body id="Body1" runat="server" class="importWizardpBack">
    <form id="Form1" method="post" runat="server"><BaseClasses:ScrollCoordinates id="ScrollCoordinates" runat="server"></BaseClasses:ScrollCoordinates>
        <BaseClasses:BasePageSettings id="PageSettings" runat="server"></BaseClasses:BasePageSettings>
        <script language="JavaScript" type="text/javascript">clearRTL()</script>
        <script language='javascript' type='text/javascript'>function CloseWindow(msg,msg2){ alert(msg.concat("\r\n",msg2));window.opener.__doPostBack('ChildWindowPostBack', ''); window.opener.focus();window.close();}</script>
		<asp:ToolkitScriptManager ID="scriptManager1" runat="server" EnablePartialRendering="True" EnablePageMethods="True" />
		
        <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
		  <table  cellpadding="0" cellspacing="0" border="0"><tr>
			<td class="importWizardmarginTL"></td>
			<td class="importWizardpcT"></td>
			<td class="importWizardmarginTR"></td>
		  </tr>
		  <tr>
			<td class="importWizardmarginL"></td>
			<td class="importWizardpcC">
				<table class="importWizarddv" cellpadding="0" cellspacing="0" border="0">
					<tr>
						<td class="importWizarddBody" style="width:100%; height:100%">			
							<table>
							<tr>
							<td class="tableCellValue"><asp:Literal id="ImportSelectColumns" runat="server" Text='<%# GetResourceValue("Txt:ImportSelectColumns") %>'/>
							<%-- Select and assign the data columns you wish to import.--%>
							</td>
							</tr>
							    <tr>
									<td class="tableCellValue"><asp:checkbox id="ImportFirstRowCheckBox" runat="server" Text=""/>&nbsp;&nbsp;
									
									
								</td></tr>
								 <tr>
									<td class="tableCellValue"><asp:checkbox id="ImportResolveForeignKeys" runat="server" Text=""/>&nbsp;&nbsp;
									
									
								</td></tr>
								<tr><td class="tableCellValue">
										<asp:Table id="DisplayTable" runat="server" CellSpacing="0" CellPadding="3"	GridLines="Both" BorderStyle="Solid" BorderWidth="1" CssClass="ttc">
										</asp:Table>
									</td>
								</tr>
								
								
							</table>
							<table>
								<tr>
									<td><ViewpointXRef:ThemeButton runat="server" id="PreviousButton" Button-Text="&lt;%# GetResourceValue(&quot;Import:Previous&quot;) %>" Button-ToolTip="&lt;%# GetResourceValue(&quot;Import:Previous&quot;, &quot;ViewpointXRef&quot;) %>">
		</ViewpointXRef:ThemeButton></td>
									<td><ViewpointXRef:ThemeButton runat="server" id="ImportButton" Button-Text="&lt;%# GetResourceValue(&quot;Import:Import&quot;) %>" Button-ToolTip="&lt;%# GetResourceValue(&quot;Import:Import&quot;, &quot;ViewpointXRef&quot;) %>">
		</ViewpointXRef:ThemeButton></td>
								</tr>
							</table>
						</td>
					</tr>
				</table>
			</td>
		  	<td class="importWizardmarginR"></td>
		  </tr>
		  <tr>
		  	<td class="importWizardmarginBL"></td>
		  	<td class="importWizardpcB"></td>
		  	<td class="importWizardmarginBR"></td>
		  </tr>
		  </table>
        <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary></form>
    </body>
</html>
