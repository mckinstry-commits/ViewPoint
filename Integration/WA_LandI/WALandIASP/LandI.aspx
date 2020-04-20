<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="LandI.aspx.cs" Inherits="WALandIASP.WebForm1" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>WA L and I XML file creator</title>
</head>
<body>
    <form id="form1" runat="server">
        <br />
        <asp:Image ID="Image1" runat="server" Height="114px" Width="279px"  />
        <br />
        <br /><br />
        <div>
            Optionally you may enter an Intent ID &nbsp &nbsp <asp:TextBox ID="txtBoxIntent" runat="server" ></asp:TextBox>
        </div>
        <br /><br />
        <div>
       <%--    <asp:Calendar ID="startDatePicker" runat="server" Visible="false" OnSelectionChanged="startDatePicker_SelectionChanged"></asp:Calendar>  --%>

            <asp:Calendar ID="startDatePicker" runat="server" Visible="false" OnDayRender="startDatePicker_DayRender" OnSelectionChanged="startDatePicker_SelectionChanged"></asp:Calendar>  
        </div>
        <asp:LinkButton ID="lnkStart" runat="server" OnClick="lnkStart_Click">Select Beginning Payroll End Date</asp:LinkButton>
        <asp:TextBox ID="txtStartDt" runat="server" Width="246px" ></asp:TextBox>
        <br /><br />
        <div>
            <asp:Calendar ID="endDatePicker"  OnSelectionChanged="endDatePicker_SelectionChanged"  runat="server" OnDayRender="endDatePicker_DayRender" Visible="false"></asp:Calendar>

        </div>
        <asp:LinkButton ID="lnkEnd" runat="server" OnClick="lnkEnd_Click">Select Ending Payroll End Date</asp:LinkButton>
        <asp:TextBox ID="txtEndDt" runat="server" Width="248px" ></asp:TextBox>
        <br /><br /> <br />
       Include Intents&nbsp;&nbsp;&nbsp;        <asp:DropDownList ID="IncludeIntents" runat="server">
            <asp:ListItem Selected="True">No</asp:ListItem>
            <asp:ListItem>Yes</asp:ListItem>
        </asp:DropDownList>
        <br /> <br /><br />
        <asp:Button ID="btnCreateXML" runat="server" OnClick="btnCreateXML_Click" Text="Create XML Files" />
    </form>
</body>
</html>
