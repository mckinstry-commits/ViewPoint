<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Control Language="C#" AutoEventWireup="false" Codebehind="InfinitePaginationMobile.ascx.cs" Inherits="VPLookup.UI.InfinitePaginationMobile" %>
<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table class="mobileHeaderPagination"><tr><td class="mobilePaginationAreaFirst"><asp:ImageButton runat="server" id="_FirstPage" alt="&lt;%# GetResourceValue(&quot;Btn:FirstPage&quot;, &quot;VPLookup&quot;) %>" causesvalidation="False" commandname="FirstPage" imageurl="../Images/MobileButtonFirst.png" onclientclick="return SubmitHRefOnce(this, &quot;&quot;);" tooltip="&lt;%# GetResourceValue(&quot;Btn:FirstPage&quot;, &quot;VPLookup&quot;) %>" visible="False" style="visibility:hidden;display:none">		
	</asp:ImageButton></td><td class="mobilePaginationAreaPrevious"><asp:ImageButton runat="server" id="_PreviousPage" alt="&lt;%# GetResourceValue(&quot;Btn:PreviousPage&quot;, &quot;VPLookup&quot;) %>" causesvalidation="False" commandname="PreviousPage" imageurl="../Images/MobileButtonPrevious.png" onclientclick="return SubmitHRefOnce(this, &quot;&quot;);" tooltip="&lt;%# GetResourceValue(&quot;Btn:PreviousPage&quot;, &quot;VPLookup&quot;) %>" style="visibility:hidden;display:none">		
	</asp:ImageButton></td><td class="mobilePaginationAreaCurrentPage" nowrap="nowrap">
<asp:Label runat="server" id="_CurrentPage" visible="False">	</asp:Label>
</td><td class="mobilePaginationAreaNext"><asp:ImageButton runat="server" id="_NextPage" alt="&lt;%# GetResourceValue(&quot;Btn:NextPage&quot;, &quot;VPLookup&quot;) %>" causesvalidation="False" commandname="NextPage" imageurl="../Images/MobileButtonNext.png" onclientclick="return SubmitHRefOnce(this, &quot;&quot;);" tooltip="&lt;%# GetResourceValue(&quot;Btn:NextPage&quot;, &quot;VPLookup&quot;) %>" style="visibility:hidden;display:none">		
	</asp:ImageButton></td><td class="mobilePaginationAreaLast"><asp:ImageButton runat="server" id="_LastPage" alt="&lt;%# GetResourceValue(&quot;Btn:LastPage&quot;, &quot;VPLookup&quot;) %>" causesvalidation="False" commandname="LastPage" imageurl="../Images/MobileButtonLast.png" onclientclick="return SubmitHRefOnce(this, &quot;&quot;);" tooltip="&lt;%# GetResourceValue(&quot;Btn:LastPage&quot;, &quot;VPLookup&quot;) %>" visible="False" style="visibility:hidden;display:none">		
	</asp:ImageButton></td><td class="prbggo"><asp:LinkButton runat="server" id="_PageSizeButton" causesvalidation="False" commandname="PageSize" cssclass="button_link" text="&lt;%# GetResourceValue(&quot;Txt:PageSize&quot;, &quot;VPLookup&quot;) %>" style="visibility:hidden;display:none">		
	</asp:LinkButton></td><td class="prbg"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControl("_PageSizeButton")) %><asp:TextBox runat="server" id="_PageSize" cssclass="Pagination_Input" maxlength="5" onchange="ISD_InfiScrollHandler(this)" text="20" style="visibility:hidden;display:none">	</asp:TextBox><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControl("_PageSizeButton")) %></td><td class="prbg"><asp:TextBox runat="server" id="_Summary" text="Infinite Pagination" style="visibility:hidden;display:none">	</asp:TextBox></td></tr></table><div><iframe id="Infiniteframe" runat="server" style="width:0px;height:0px;visibility:hidden"></iframe></div>
<script type="text/javascript">
    var bool = "False";
    if (window != top) {
        if (window.parent.bool == "True") {
            window.parent.bool == "False"
        }
    }
    var NewRecords = "True";
    var index = 0;
    var id = "";
    var OrgPageSize = 0;
    var ScrollFlag = "True";
    var rowfetch = 0;
    var i = 0;
    var j = 0;
    var CurrPageinfo = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
    if (OrgPageSize == 0) {
        OrgPageSize = parseInt(CurrPageinfo.value);
    }
    var currpagesize = OrgPageSize;

    //Function is invoked when the page is scrolled down
    $(window).scroll(function() {
        if ((($(window).scrollTop() + 10) >= $(document).height() - $(window).height()) || (($(window).scrollTop() + 10) >= $(document).height() - window.innerHeight)) {
            var olddiv = document.getElementById('loadgif');
			var t = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
            if (olddiv == null) {
                if (NewRecords == "True") {
                ScrollFlag = "False";
                $('#' + '<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>').after('<div id=\"loadgif\" align=\"center\"><img id=\"loading-image\" src=\"../Images/Mobile.ajax-loader.gif\"></img></div>');
                }
            }
            if (bool == "True" && t.contentWindow.document.readyState == 'complete') {
                onScroll();
                ScrollFlag = "True";
            }
        }
    });

    //Function invoked when the page is refreshed
    window.onbeforeunload = function() {
        if (sessionStorage.getItem("is_reloaded") != "true") {
                sessionStorage.setItem("is_reloaded", true);
            }
                }
    window.onunload = function() {
        if (sessionStorage.getItem("is_reloaded") != "true") {
                    sessionStorage.setItem("is_reloaded", true);
        }
    }

    window.onload = function() {
        try {
            var IfraNam = "";
            if (window != top) {
                IfraNam = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
            }
            if (sessionStorage.getItem("is_scroll") == "true" && window != top && IfraNam.name == "PostbackIframe") {
                var olddiv = window.parent.document.getElementById('loadgif');
                olddiv.outerHTML = "";
                delete olddiv;
                var x = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                var ParentTable = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                var xx = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                var iFrameBody = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
                var ParentVS = window.parent.document.getElementById('__VIEWSTATE');
                var a = [];
                var IframeVSCode = document.getElementById("__VIEWSTATE");
                j = 0;
                if (iFrameBody != "null") {
                    var rowLength = iFrameBody.rows.length;
                    var parentrowlength = ParentTable.rows.length;
                    for (i = 0; i < rowLength; i++) {
                        if (i >= window.parent.rowfetch) {
                            a[j] = iFrameBody.rows.item(i).outerHTML;
                            j += 1;
                        }
                    }
                    for (i = (parentrowlength - 1); i >= (parentrowlength - window.parent.counter); i--) {
                        ParentTable.deleteRow(i);
                    }
                    if (rowLength == window.parent.rowfetch) { window.parent.NewRecords = "False"; }
                    if (window == top) {
                        initialframe.contentWindow.rowfetch = rowLength - window.parent.counter;
                        rowfetch = rowLength - window.parent.counter;
                    }
                    if (window != top) {
                        window.parent.rowfetch = rowLength - window.parent.counter;
                        rowfetch = rowLength - window.parent.counter;
                    }
                    for (var i = 0; i < a.length; i++) { window.parent.$('#' + x.id + ' > tbody:last').append(a[i]); }
                    if (a.length > 0) { ParentVS.value = IframeVSCode.value; }
                }
                window.parent.bool = "True";
                sessionStorage.setItem("is_scroll", null);
            }
            else {
                if (window == top) {
                    var infinitecheck = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
                    if (infinitecheck != null) {
                        var MyCurrForm = document.getElementById('aspnetForm');
                        var initialframe = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
                        var mystring = document.documentElement.outerHTML;
                        var ind1 = mystring.indexOf("action=\"", mystring.indexOf("<form"));
                        var ind2 = mystring.indexOf("\"", (ind1 + 8));
                        var replace = mystring.substring(ind1, (ind2));
                        mystring = mystring.replace(replace, "action = \"" + MyCurrForm.action + "?Index=" + index)
                        var index1 = mystring.indexOf("<iframe id=\"" + '<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
                        var index2 = mystring.indexOf("</iframe>");
                        if (index1 != -1) {
                            var outerstuff = mystring.substring(0, index1) + mystring.substring((index2 + 9), mystring.length);
                        } else {
                            var outerstuff = mystring
                        }
                        var dstDoc = initialframe.contentWindow.document;
                        dstDoc.open();
                        dstDoc.write(outerstuff);
                        dstDoc.close();
                        bool = "False";
                        initialframe.name = "PostbackIframe";
                        sessionStorage.setItem("is_reloaded", false);
                        var CurrPagBut = initialframe.contentWindow.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
                        if (CurrPagBut != null) {
                            CurrPagBut.onchange();
                        }
                    }
                }
            }
        }
        catch (err) {
        }
        try {
        var iframtable = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
        var parenttframe = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
        if (window == top) {
            rowfetch = CalculateRowFetch();
            parenttframe.contentWindow.rowfetch = rowfetch;
            parenttframe.contentWindow.counter = counter
            if (bool == "True" && ScrollFlag == "False") {
                ScrollFlag = "True";
                onScroll();
            }
        } else {
                if (IfraNam.name == "PostbackIframe") {
            rowfetch = CalculateRowFetch();
            window.parent.rowfetch = rowfetch;
            window.parent.counter = counter;
            if (window.parent.ScrollFlag == "False") {
                window.parent.ScrollFlag = "True";
                window.parent.onScroll();
            } else {
                ScrollBarCheck();
                    }
                    window.parent.bool = "True";
                }
            }
        }
        catch (err) {
        }
    }
    $(document).ready(function() {
        if (window != top) {
            var parenttframe = window.parent.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
            var infinitecheck = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
            if (parenttframe.name == "PostbackIframe" && infinitecheck == null) {
                var CurrPagBut = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
				 if (CurrPagBut != null) {
                CurrPagBut.onchange();
                 }
            }
        }
    });
    
    //Called When The Scroll Bar Reaches The Bottom
    function onScroll() {
        var t = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("Infiniteframe")) %>');
        if (t != null) {
            var iFrameBod = t.contentWindow.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
            var rowLengt = iFrameBod.rows.length;
            var IframePageSize = t.contentWindow.document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSize")) %>');
            if (NewRecords == "True") {
                currpagesize = parseInt(IframePageSize.value) + parseInt(OrgPageSize);
                IframePageSize.value = currpagesize;
                IframePageSize.onchange();
                sessionStorage.setItem("is_scroll", true);
            }
            bool = "False";
        }
   }
    function CalculateRowFetch() {
        var iframtable = document.getElementById('<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>');
        var rowLength = iframtable.rows.length;
        var bolCheck = "False";
        rowfetch = iframtable.rows.length;
        counter = 0;
        for (i = (rowLength - 1); i >= 0; i--) {
            if (iframtable.rows[i].attributes.length != 0 && bolCheck == "False") {
                for (j = 0; j < iframtable.rows[i].attributes.length; j++) {
                    bolCheck = "True";
                    if (iframtable.rows[i].attributes[j].value == "Footer") {
                        counter = counter + 1;
                        bolCheck = "False";
                    }
                }
            }
            else {
                break;
            }
        }
        rowfetch = rowfetch - counter;
        return rowfetch;
    }
    function ScrollBarCheck() {
        if ($(window.parent).scrollTop() == 0) {
            $(window.parent).scrollTop(10);
        }
        sessionStorage.setItem("is_reloaded", false);
        var Height = document.body.scrollHeight;
        var Top = $(window.parent).scrollTop();
        var CHeight = document.body.scrollHeight;
        if (Height == (Top + CHeight) && window.parent.NewRecords == "True") {
            if ($(window.parent).scrollTop() == 0) {
                $(window.parent).scrollTop(10);
            }
            window.parent.$('#' + '<%= SystemUtils.InfinitePagination(FindControl("_PageSizeButton")) %>').after('<div id=\"loadgif\" align=\"center\"><img id=\"loading-image\" src=\"../Images/Mobile.ajax-loader.gif\"></img></div>');
            window.parent.ScrollFlag = "True";
            window.parent.bool = "True"
            window.parent.onScroll();
        }
    }
</script>