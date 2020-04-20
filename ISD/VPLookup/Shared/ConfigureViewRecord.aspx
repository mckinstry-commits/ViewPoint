<%@ Page Language="vb" AutoEventWireup="false" Inherits="VPLookup.UI.BaseApplicationPage" MasterPageFile="~/Master Pages/Blank.master"%>
<script runat="server" language="VB">

    Public Sub Page_PreInit(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.PreInit
    

        Dim selectedTheme As String = Me.GetSelectedTheme()
        If Not String.IsNullOrEmpty(selectedTheme) Then Me.Page.Theme = selectedTheme
        
        If DirectCast(Me.Page, BaseApplicationPage).GetDecryptedURLParameter("RedirectStyle")  = "Popup" Then
            Dim masterPage As String = "../Master Pages/Popup.master"      
            Me.Page.MasterPageFile = masterPage
        End If

        If DirectCast(Me.Page, BaseApplicationPage).GetDecryptedURLParameter("RedirectStyle")  = "NewWindow" Then
            Dim masterPage As String = "../Master Pages/Blank.master"      
            Me.Page.MasterPageFile = masterPage
        End If

        If Me.Page.Request("MasterPage") <> "" Then
            Dim masterPage As String = DirectCast(Me.Page, BaseApplicationPage).GetDecryptedURLParameter("MasterPage")          
            Me.Page.MasterPageFile = masterPage
        End If              
    End Sub
    Public Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not IsPostBack) Then

            AjaxControlToolkit.ToolkitScriptManager.RegisterStartupScript(Me, Me.GetType(), "PopupScript", "openPopupPage('QPageSize');", True)               
        End If
    End Sub    
</script>



<asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
    <table cellspacing="0" cellpadding="0" border="0" class="pWrapper">
        <tr>
            <td class="panelTL">
                <img src="../Images/space.gif" class="panelTLSpace" alt="" /></td>
            <td class="panelT">
                <img src="../Images/space.gif" class="panelTSpace" alt="" /></td>
            <td class="panelTR">
                <img src="../Images/space.gif" class="panelTRSpace" alt="" /></td>
        </tr>
        <tr>
            <td class="panelL">
                <img src="../Images/space.gif" class="panelLSpace" alt="" /></td>
            <td class="panelC">
                <table cellspacing="0" cellpadding="0" border="0" class="pContent">
                    <tr>
                        <td>
                            <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse"
                                width="100%" id="AutoNumber1">
                                <tr>
                                    <td class="dialog_header" colspan="3">
                                        <table cellpadding="0" cellspacing="0" border="0" width="100%">
                                            <tr>
                                                <td class="dialogHeaderEdgeL">
                                                    <img src="../Images/space.gif" alt="" /></td>
                                                <td class="dhb">
                                                    <table border="0" cellpadding="0" cellspacing="0">
                                                        <tr>
                                                            <td class="dialog_header_text">
                                                                Configuring a View Record Page</td>
                                                        </tr>
                                                    </table>
                                                </td>
                                                <td class="dialogHeaderEdgeR">
                                                    <img src="../Images/space.gif" alt="" /></td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="width: 20px;">
                                    </td>
                                    <td class="configureErrorPagesText">
                                        <br />
                                        You cannot view the selected record because the underlying View button or icon is
                                        not yet bound to a View Record page.<br />
                                        <br />
                                        To bind the View button or icon to a View Record page:<br />
                                        <br />
                                        <ol>
                                            <li>If you have not yet created a View Record page, use the Application Wizard to create
                                                one.<br />
                                                <br />
                                            </li>
                                            <li>Go to the Application Explorer tab, navigate in the tree to the page that contains
                                                the View button or icon.<br />
                                                <br />
                                                <ul style="list-style-type: disc">
                                                    <li>Select the name of the View button or icon on the page. Then click the 'Button actions' on the Properties sheet.</li>
                                                    <li>In the Properties dialog, select the Redirect option and click on the Edit button.</li>
						    <li>Now modify the Redirect URL to point to your View Record page.<br />
                                                        Example: ../MyPages/MyViewRecordPage.aspx?QueryStringParam={0}<br />
                                                        <br />
                                                    </li>
                                                    <li>Make sure the Redirect parameter is "ID".<br />
                                                        <br />
                                                    </li>
                                                </ul>
                                            </li>
                                            <li>Save changes and rebuild the application.</li>
                                        </ol>
                                    </td>
                                    <td style="width: 20px;">
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
            <td class="panelR">
                <img src="../Images/space.gif" class="panelRSpace" alt="" /></td>
        </tr>
        <tr>
            <td class="panelBL">
                <img src="../Images/space.gif" class="panelBLSpace" alt="" /></td>
            <td class="panelB">
                <img src="../Images/space.gif" class="panelBSpace" alt="" /></td>
            <td class="panelBR">
                <img src="../Images/space.gif" class="panelBRSpace" alt="" /></td>
        </tr>
    </table>
</asp:Content>