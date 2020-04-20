<%@ Page Language="C#" AutoEventWireup="true" Inherits="POViewer.UI.BaseApplicationPage" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">

<script runat="server" language="C#">
    public void Page_PreInit(object sender, System.EventArgs e)
    {
        string selectedTheme = this.GetSelectedTheme();
        if (!string.IsNullOrEmpty(selectedTheme)) this.Page.Theme = selectedTheme;
    }
</script>
    <title>Configure Special View Record Page</title>
</head>
<body class="pBack">
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
                                                                Configuring a Special View Record Page</td>
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
                                        not yet bound to a View Record page. The table that contains the record you are
                                        trying to view is either a non-physical table (i.e. a View or a Query), or has no
                                        primary key. However, you can still create a View button for it by binding the View
                                        Icon and providing a Primary Key from a referenced physical table.<br />
                                        <br />
                                        This will enable you to view a record from one of the referenced physical tables.
                                        For example, you could bind the View Icon for the 'Alphabetical list of products'
                                        view from the Northwind database so that it displayes a Products record for viewing.<br />
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
                                                    <li>Select the name of the View button or icon on the page. Then click the 'Button actions' in the Properties sheet.</li>
                                                    <li>In the Properties dialog, select the Redirect option and click on the Edit button.</li>
					            <li>Now modify the Redirect URL to point to your View Record page.<br />
                                                        Example: ../MyPages/MyViewRecordPage.aspx?QueryStringParam={0}<br />
                                                        <br />
                                                    </li>
                                                    <li>The Redirect parameter should reference the field that is a Primary Key for an associated
                                                        physical table.<br />
                                                        Example: "FV:ProductID"<br />
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
</body>
</html>
