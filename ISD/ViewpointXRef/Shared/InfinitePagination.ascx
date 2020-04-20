<%@ Control Language="C#" AutoEventWireup="false" Codebehind="InfinitePagination.ascx.cs" Inherits="ViewpointXRef.UI.InfinitePagination" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table cellspacing="0" cellpadding="0" border="0" style="visibility:hidden;display:none"><tr><td class="prbggo"><table><tr><td><asp:ImageButton runat="server" id="_FirstPage" causesvalidation="False" commandname="FirstPage" imageurl="../Images/ButtonBarFirst.gif" onclientclick="return SubmitHRefOnce(this, &quot;&quot;);" onmouseout="this.src='../Images/ButtonBarFirst.gif'" onmouseover="this.src='../Images/ButtonBarFirstOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:FirstPage&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td><td><asp:ImageButton runat="server" id="_PreviousPage" causesvalidation="False" commandname="PreviousPage" imageurl="../Images/ButtonBarPrevious.gif" onclientclick="return SubmitHRefOnce(this, &quot;&quot;);" onmouseout="this.src='../Images/ButtonBarPrevious.gif'" onmouseover="this.src='../Images/ButtonBarPreviousOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:PreviousPage&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td><td class="prbg"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControl("_PageSizeButton")) %><asp:TextBox runat="server" id="_CurrentPage" cssclass="Pagination_Input" maxlength="10" size="5" visible="False">	</asp:TextBox><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControl("_PageSizeButton")) %></td><td><asp:ImageButton runat="server" id="_NextPage" causesvalidation="False" commandname="NextPage" imageurl="../Images/ButtonBarNext.gif" onclientclick="return SubmitHRefOnce(this, &quot;&quot;);" onmouseout="this.src='../Images/ButtonBarNext.gif'" onmouseover="this.src='../Images/ButtonBarNextOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:NextPage&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td><td><asp:ImageButton runat="server" id="_LastPage" causesvalidation="False" commandname="LastPage" imageurl="../Images/ButtonBarLast.gif" onclientclick="return SubmitHRefOnce(this, &quot;&quot;);" onmouseout="this.src='../Images/ButtonBarLast.gif'" onmouseover="this.src='../Images/ButtonBarLastOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:LastPage&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td></tr></table>
</td><td class="prbggo"><asp:LinkButton runat="server" id="_PageSizeButton" causesvalidation="False" commandname="PageSize" cssclass="button_link" text="&lt;%# GetResourceValue(&quot;Txt:PageSize&quot;, &quot;ViewpointXRef&quot;) %>" style="visibility:hidden;display:none">		
	</asp:LinkButton></td><td class="prbg"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControl("_PageSizeButton")) %><asp:TextBox runat="server" id="_PageSize" cssclass="Pagination_Input" maxlength="5" onchange="ISD_InfiScrollHandler(this)" text="10" style="visibility:hidden;display:none">	</asp:TextBox><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControl("_PageSizeButton")) %></td><td class="prbg"><asp:TextBox runat="server" id="_Summary" text="Infinite Pagination" style="visibility:hidden;display:none">	</asp:TextBox></td></tr></table><div><iframe id="Infiniteframe" runat="server" style="width:0px;height:0px;visibility:hidden;position:fixed;top:500px;left:0px"></iframe></div>
<script type="text/javascript">   
    var ScrollRegionName = "";
    var innerpage = ""
    var bool = "False";
    var NewRecords = "True";
    var RecordsRowCount = 0;
    var RowCount = 0;
    var index = 0;
    var done = "True"
    var id = "";
    var postbackSucess = "True";
    var OrgPageSize = 0;
    var OrgRowLenght = 0;
    var counter = 0;
    var rowfetch = 0;
    var check = 0;
    var i = 0;
    var j = 0;
    var CurrPageinfo = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>')
    if (OrgPageSize == 0) {
        OrgPageSize = parseInt(CurrPageinfo.value);
    }
    var currpagesize = OrgPageSize;
    var initialframe = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
    var parenttframe = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
    
    //Sets URL for the Iframe
    if ((document.forms[0].action.indexOf("InfiIframe") == -1)) {
        if (parenttframe != undefined) {
            if (parenttframe.src == "" && parenttframe.name != "PostbackIframe") {
                popthechild()
            }
        } else {
            popthechild()
        }
    } 
    //Function is invoked when the page is scrolled down
    function pageLoad() {
        try {
            ScrollRegionName = ScrollRegName();
            if (window.frameElement == null && ScrollRegionName == "scrollRegion") {
                innerpage = "False";
                $(window).scroll(function() {
                    if (($(window).scrollTop() + 10) >= $(document).height() - $(window).height()) {
                        if (bool == "True" && done == "True" && postbackSucess == "True") {
                            onScroll();
                        }
                    }
                });
            } else {
                innerpage = "True";
                $('#' + ScrollRegionName).scroll(function() {
                    if ($(this)[0].scrollHeight - $(this).outerHeight() <= ($(this).scrollTop() + 10)) {
                        if (bool == "True") {
                            onScroll();
                        }
                    }
                });
            }
        } catch (err) {
        }
    }
    
    //Invoked when all the DOM Elements are ready.
    $(document).ready(function() {
        try {
            if ((document.forms[0].action.indexOf("InfiIframe") != -1)) {
                var parenttframe = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
                if (parenttframe.name == "PostbackIframe" && window.parent.done == "False" && navigator.appName != 'Microsoft Internet Explorer') {
                    var IframePageSize = parenttframe.contentDocument.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
                    IframePageSize.value = window.parent.currpagesize;
                    IframePageSize.onchange();
                    window.parent.done = "True";
                    window.parent.postbackSucess = "False";
                }
            }
        } catch (err) {
        }
    });

    //Event Is Invoked after Postback Completes
    var prm = Sys.WebForms.PageRequestManager.getInstance();
	prm.add_initializeRequest(InitializeRequestHandler);
    
    function InitializeRequestHandler(sender, args) {
        if (document.readyState != "complete") {
              var iframeName = "";
              if (window.frameElement != null) {
                    iframeName = window.frameElement.id;
              }
              if (iframeName.indexOf("Infiniteframe") == -1) {
                    args.set_cancel(true);
              }
        }
    }
    prm.add_endRequest(function(s, e) {
        try {
            var parenttframe = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
            if (document.forms[0].action.indexOf("InfiIframe") != -1) {
                if (parenttframe.src != "" || parenttframe.name == "PostbackIframe") {
                    var initialframe = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
                    window.parent.bool = "True";
                    var olddiv = window.parent.document.getElementById('loadgif');
                    olddiv.outerHTML = "";
                    delete olddiv.parentNode;
                    var t = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
                    var ParentTable = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                    var iFrameBody = t.contentDocument.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                    //Parent ViewState
                    var ParentVS = window.parent.document.getElementById('__VIEWSTATE');
                    var a = [];
                    //Iframe ViewState
                    var IframeVSCode = document.getElementById("__VIEWSTATE");
                    var check = 0;
                    j = 0;

                    if (iFrameBody != "null") {

                        //Number of rows in the iFrame Table
                        var rowLength = iFrameBody.rows.length;
                        var parentrowlength = ParentTable.rows.length;
                        for (i = 0; i < rowLength; i++) {
                            if (i >= rowfetch) {
                                a[j] = iFrameBody.rows.item(i).outerHTML;
                                j += 1;
                            }
                        }
                        for (i = (parentrowlength - 1); i >= (parentrowlength - window.parent.counter); i--) {
                            ParentTable.deleteRow(i);
                        }
                        if (rowLength == (rowfetch + counter)) { window.parent.NewRecords = "False"; }

                        if ((document.forms[0].action.indexOf("InfiIframe") == -1)) {
                            initialframe.contentWindow.rowfetch = rowLength - window.parent.counter;
                            rowfetch = rowLength - window.parent.counter;
                        }
                        if ((document.forms[0].action.indexOf("InfiIframe") != -1)) {
                            window.parent.rowfetch = rowLength - window.parent.counter;
                            rowfetch = rowLength - window.parent.counter;
                        }
                        for (var i = 0; i < a.length; i++) {

                            //Appends the new rows to the parent table
                            window.parent.$('#' + ParentTable.id + ' > tbody:last').append(a[i]);

                        }
                        //Replace the Parent ViewState with the Child Viewstate
                        if (a.length > 0) {
                            ParentVS.value = IframeVSCode.value;
                        }
                        ScrollBarCheck()
                    }
                    window.parent.submitcount = 0;
                }
            }
            else {
                bool = "True";
                NewRecords = "True";
                postback = "True";
                var parentid = "";
                var ParentTable = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                var parentrowlength = ParentTable.rows.length - counter;
                if (parentrowlength == OrgRowLenght) {
                    currpagesize = OrgPageSize;
                }
                var MyCurrForm = document.getElementById('aspnetForm');
                var initialframe = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
                var mystring = document.documentElement.outerHTML;
                var ind1 = mystring.indexOf("action=\"", mystring.indexOf("<form"));
                var ind2 = mystring.indexOf("\"", (ind1 + 8));
                var replace = mystring.substring(ind1, (ind2));
                if (MyCurrForm.action.indexOf("?") == -1) {
                    mystring = mystring.replace(replace, "action = \"" + MyCurrForm.action + "?InfiIframe");
                } else {
                    mystring = mystring.replace(replace, "action = \"" + MyCurrForm.action + "&InfiIframe")
                }
                var index1 = mystring.indexOf("<iframe id=\"" + '<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
                var index2 = mystring.indexOf("</iframe>", index1);
                var outerstuff = mystring
                if (index1 != -1) {
                    outerstuff = mystring.substring(0, index1) + mystring.substring((index2 + 9), mystring.length);
                }
                var dstDoc = initialframe.contentWindow.document;
                dstDoc.open();
                dstDoc.write(outerstuff);
                dstDoc.close();
                initialframe.name = "PostbackIframe";
                done = "False";
                if (innerpage == "False") {
                    $(window).scrollTop(0);
                } else {
                    if (innerpage == "True") {
                        $('#' + ScrollRegionName).scrollTop(0);
                    }
                }
                submitcount = 0;
                if (navigator.appName == 'Microsoft Internet Explorer') {
                    var IframePageSize = initialframe.contentDocument.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
                    IframePageSize.value = currpagesize;
                    IframePageSize.onchange();
                }
            }
        }
        catch (err) {
            if ((document.forms[0].action.indexOf("InfiIframe") != -1)) {
                if (parenttframe.name == "PostbackIframe" && window.parent.done == "True" && navigator.appName != 'Microsoft Internet Explorer') {
                    rowfetch = CalculateRowFetch();
                }
                if (window.parent.postbackSucess == "False") {
                    window.parent.postbackSucess = "True";
                    ScrollBarCheck()
                }
            }
        }
    });
    //Called When The Page Is Completely Loaded
    window.onload = function() {
        try {
            var initialframe = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
            var parenttframe = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
            var table = document.getElementsByTagName("table");
            rowfetch = CalculateRowFetch();
            if (OrgRowLenght == 0) {
                OrgRowLenght = rowfetch;
            }
            if ((document.forms[0].action.indexOf("InfiIframe") != -1)) {
                if (window.parent.done = "False") {
                    window.parent.done = "True";
                }
                ScrollBarCheck()
            }
        } catch (err) {
        }
    }
    //Called The Browser Doesnt Have A Scroll Bar Due to Few Records 
    function onScrollNoSbar() {
        if (rowfetch > 0) {
            try {
                var Form = document.forms['aspnetForm'];
                var Loc = Form.action;
                var z = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                var iFrameBod = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                var rowLengt = iFrameBod.rows.length;
                var PageSize = document.getElementsByClassName('panelPaginationC');
                var ParentPageSize = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
                var IframePageSize = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
                if (PageSize != null) {
                    if (window.parent.NewRecords == "True") {
                        window.parent.currpagesize = parseInt(IframePageSize.value) + parseInt(OrgPageSize);
                        IframePageSize.value = window.parent.currpagesize;
                        IframePageSize.onchange();
                        window.parent.$('#' + '<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>').after('<div id=\"loadgif\" align=\"center\"><img id=\"loading-image\" src=\"../Images/ajax-loader.gif\"></img></div>');
                    }
                }
                window.parent.bool = "False";
            } catch (err) {
            }
        }
    }
    
    //Called When The Scroll Bar Reaches The Bottom
    function onScroll() {
        try {
            var t = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
            if (t != null && t.contentWindow.rowfetch > 0) {
                var Form = document.forms['aspnetForm'];
                var Loc = Form.action;
                var z = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                var iFrameBod = t.contentDocument.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                var rowLengt = iFrameBod.rows.length;
                var PageSize = t.contentDocument.getElementsByClassName('panelPaginationC');
                var ParentPageSize = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
                var IframePageSize = t.contentDocument.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
                if (PageSize != null) {
                    if (NewRecords == "True") {
                        currpagesize = parseInt(IframePageSize.value) + parseInt(OrgPageSize);
                        IframePageSize.value = currpagesize;
                        IframePageSize.onchange();
                        $('#' + '<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>').after('<div id=\"loadgif\" align=\"center\"><img id=\"loading-image\" src=\"../Images/ajax-loader.gif\"></img></div>');
                    }
                }
                bool = "False";
            }
        } catch (err) {
        }
    }
    function ScrollRegName() {
        try {
            var parent = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
            var stop = "False"
            var divid = parent.className;
            while (stop != "True") {
                if (divid != undefined) {
                    if (divid == "scrollRegion" || divid == "QSscrollRegion" || divid == "tableContainer") {
                        stop = "True";
                        return divid
                    } else {
                        parent = parent.parentNode;
                        if (parent != undefined) {
                            divid = parent.className;
                        } else {
                            return;
                        }
                    }
                } else {
                    return;
                }
            }
        } catch (err) {
        }
    }
    
    //Check if ScrollBar Exists. If not load records till scrollbar appears
    function ScrollBarCheck() {
        try {
            if (ScrollRegionName == "") {
                ScrollRegionName = window.parent.ScrollRegionName;
            }
            if ((window.parent.frameElement == null && ScrollRegionName == "scrollRegion") || (window.parent.frameElement == null && ScrollRegionName == "")) {
                if ($(window.parent).scrollTop() == 0) {
                    $(window.parent).scrollTop(10);
                }
                window.parent.bool = "True"
                var Height = document.body.scrollHeight;
                var Top = $(window.parent).scrollTop();
                var CHeight = document.body.scrollHeight;
                if (Height == (Top + CHeight)) {
                    if ($(window.parent).scrollTop() == 0) {
                        $(window.parent).scrollTop(10);
                    }
                    if (window.parent.postbackSucess == "True") {
                        onScrollNoSbar();
                    }
                }
            } else {
                if (window.parent.$('#' + ScrollRegionName).scrollTop() == 0) {
                    window.parent.$('#' + ScrollRegionName).scrollTop(1);
                }
                window.parent.bool = "True"
                var Height = window.parent.$('#' + ScrollRegionName)[0].scrollHeight;
                var Top = window.parent.$('#' + ScrollRegionName).scrollTop();
                var CHeight = window.parent.$('#' + ScrollRegionName)[0].scrollHeight;
                if (Height == (Top + CHeight)) {
                    if (window.parent.$('#' + ScrollRegionName).scrollTop() == 0) {
                        window.parent.$('#' + ScrollRegionName).scrollTop(1);
                    }
                    if (window.parent.postbackSucess == "True") {
                        onScrollNoSbar();
                    }
                }
            }
        } catch (err) {
        }
    }
    //Calculate Number of rows to fetch from the Iframe
    function CalculateRowFetch() {
        try {
            var iframtable = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
            var rowLength = iframtable.rows.length;
            rowfetch = iframtable.rows.length;
            counter = 0;
            for (i = (rowLength - 1); i >= 0; i--) {
                if (iframtable.rows[i].attributes.length != 0) {
                    if (iframtable.rows[i].attributes[0].value == "Footer") {
                        counter = counter + 1;
                    }
                }
                else {
                    break;
                }
            }
            rowfetch = rowfetch - counter;
            return rowfetch;
        } catch (err) {
        }
    }
    function popthechild() {
        try {
            var Form = document.forms['aspnetForm'];
            var Loc = Form.action;
            if (Loc.indexOf("?") == -1) {
                initialframe.src = "" + Loc + "?InfiIframe";
            }
            else {
                initialframe.src = "" + Loc + "&InfiIframe";
            }
        } catch (err) {
        }
    }
</script>