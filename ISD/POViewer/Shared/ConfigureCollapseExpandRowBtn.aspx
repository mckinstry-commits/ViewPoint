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
    <title>Configuring an Expand / Collapse Row Button</title>
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
                                        <table cellpadding="0" cellspacing="0" border="0">
                                            <tr>
                                                <td class="dialogHeaderEdgeL">
                                                    <img src="../Images/space.gif" alt="" /></td>
                                                <td class="dhb">
                                                    <table border="0" cellpadding="0" cellspacing="0" width="100%">
                                                        <tr>
                                                            <td class="dialog_header_text">
                                                                Configuring an Expand / Collapse Row Button</td>
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
                                        The Expand / Collapse Row button you clicked on is not yet configured.<br />
                                        <br />
                                        To configure the Expand / Collapse button:<br />
                                        <br />
                                        <ol>
                                            <li>In the Layout editor, select the second row you wish to expand and collapse
                                                when the button is clicked.<br />
                                                <br />
                                            </li>
                                            <li>Open the Row Attributes… dialog by (Right-click on the row you want to collapse
                                                or expand, Styles -> Row ...) and set these attributes:<br />
                                                <br />
                                                <ul style="list-style-type: disc">
                                                    <li>Id=&lt;Table Control Name&gt;AltRow</li>
                                                    <li>runat=server<br />
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
