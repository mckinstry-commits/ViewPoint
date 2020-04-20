SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************CREATED ON 03/01/2004 *************************/
CREATE   proc [dbo].[bspPMSUBItemDocMergeBuild]
/*************************************
 * Created By:   GF 03/01/2004 - issue #18841 - build items query dynamically. allowing user changes
 * Modified By:	GF 07/07/2004 - issue #25041 - RecordType not needed in query for PMSL by SL.
 *				DANF 09/14/2004 - Issue 19246 added new login
 *				GF 11/03/2004 - issue #21546 add total original SL amount to merge fields.
 *				GF 06/07/2005 - issue #27224 missed adding this line. Added order by SLItem to query.
 *				GF 09/15/2005 - issue #29833 need to verify SLItem in select list before adding the order by
 *				GF 02/26/2007 - issue #123966 replace SubCO with '' when union to SLIT. does not exist in table.
 *				DC 06/29/10 - #135813 - expand subcontract number
 *
 *
 * Build merge header list and query statement for use in PM Subcontract w/items documents.
 *
 *
 * Pass:
 * @pmco				PM Company
 * @apco             AP Company
 * @project          PM Project
 * @sl               Subcontract
 * @vendorgroup      VendorGroup
 * @template			PM Document Template
 * @user				Current user
 *
 **************************************/
(@pmco bCompany, @apco bCompany, @project bJob, @sl VARCHAR(30), --bSL, DC #135813
 @vendorgroup bGroup, @template varchar(40), @lastuser bVPUserName, @headerstring varchar(2000) output,
 @querystring varchar(8000) output, @itemsquery varchar(8000) output, @msg varchar(255) output)
as
set nocount on
   
declare @rcode int, @sltotal bDollar, @sltotalstring varchar(20), @vfirm bVendor, @vcontact bEmployee,
           @vfirstname varchar(30), @vlastname varchar(30), @vfax bPhone, @vemail varchar(60),
           @vprefmethod varchar(1), @ourfirm bVendor, @ocontact bEmployee, @ofirstname varchar(30),
           @olastname varchar(30), @vfirmstring varchar(10), @ourfirmstring varchar(10),
   		@strvalue varchar(30), @itemsheader varchar(2000), @slitemsquery varchar(8000)
   
declare @templatetype varchar(10), @joinstring varchar(4000), @usedlast smalldatetime, 
   		@totalorigsl bDollar, @status tinyint
   
   select @rcode = 0, @sltotal = 0, @templatetype = 'SUBITEM', @usedlast = Getdate()
   
   -- get template type for template  - 'SUB' OR 'SUBITEM'
   select @templatetype=TemplateType
   from bHQWD with (nolock) where TemplateName=@template
   if @@rowcount = 0 select @templatetype='SUBITEM'
   
   
   -- -- -- get SL status from SLHD
   select @status = Status from bSLHD where SLCo=@apco and SL=@sl
   if isnull(@status, 3) = 3
   	begin
   	-- -- -- total current SL for pending
   	select @querystring = 'select (select isnull(sum(Amount),0) from PMSL with (nolock)'
   			+ ' where SLCo= ' + convert(varchar(3),@apco) + ' and SL= ' + CHAR(39) + @sl + CHAR(39)
   			+ ' and SendFlag= ' + CHAR(39) + 'Y' + CHAR(39)
   			+ ' and InterfaceDate is null and SLItemType in (1,2,4) and ((RecordType=' + CHAR(39) + 'O' + CHAR(39)
   			+ ' and ACO is null) or (RecordType=' + CHAR(39) + 'C' + CHAR(39) + ' and ACO is not null))),'
   	-- -- -- total original SL for pending
   	select @querystring = @querystring + ' (select isnull(sum(Amount),0) from PMSL with (nolock)'
   			+ ' where SLCo= ' + convert(varchar(3),@apco) + ' and SL= ' + CHAR(39) + @sl + CHAR(39)
   			+ ' and SendFlag= ' + CHAR(39) + 'Y' + CHAR(39)
   			+ ' and InterfaceDate is null and SLItemType in (1,4) and ((RecordType=' + CHAR(39) + 'O' + CHAR(39)
   			+ ' and ACO is null) or (RecordType=' + CHAR(39) + 'C' + CHAR(39) + ' and ACO is not null and SubCO is null)))'
   	end
   else
   	begin
   	-- -- -- total current SL for interfaced
   	select @querystring = 'select (select isnull(SLTotal,0) + isnull(PMSLAmt,0) from PMSLTotal'
   			+ ' where SLCo= ' + convert(varchar(3),@apco) + ' and SL= ' + CHAR(39) + @sl + CHAR(39) + '),'
   	-- -- -- total original SL for interfaced
   	select @querystring = @querystring + ' (select isnull(SLTotalOrig,0) + isnull(PMSLAmtOrig,0) from PMSLTotal'
   			+ ' where SLCo= ' + convert(varchar(3),@apco) + ' and SL= ' + CHAR(39) + @sl + CHAR(39) + ')'
   	end
   
   
   -- -- -- -- get Subcontract Total Amount
   -- -- -- exec @rcode = dbo.bspPMSLTotalGet @pmco, @project, @apco, @sl, @sltotal output, @msg output
   -- -- -- if @rcode <> 0 goto bspexit
   -- -- -- 
   -- -- -- if @sltotal is null select @sltotal = 0
   -- -- -- select @sltotalstring = convert(varchar(20),@sltotal)
   
   -- start headerstring and querystring with fixed value fields
   select @headerstring = 'TotalSubcontract, TotalOrigSL'
   -- -- -- select @querystring = 'select ' + CHAR(39) + @sltotalstring + CHAR(39)
   
   -- build header string and column string from HQWF for template
   exec @rcode = dbo.bspHQWFMergeFieldBuild @template, @headerstring output, @querystring output, @msg output
   if @rcode <> 0 goto bspexit
   
   -- build join clause from HQWO for template type
   exec @rcode = dbo.bspHQWDJoinClauseBuild @templatetype, 'N', 'Y', 'N', @joinstring output, @msg output
   if @rcode <> 0 goto bspexit
   
   select @querystring = @querystring + @joinstring
   
   select @querystring = @querystring + ' where a.SLCo = ' + convert(varchar(3),@apco)
   select @querystring = @querystring + ' and a.SL = ' + char(39) + @sl + CHAR(39)
   select @querystring = @querystring + ' and a.VendorGroup = ' + convert(varchar(3),@vendorgroup)
   
   
   -- now build the mergefield, join clause for the Subcontract Items
   exec @rcode = dbo.bspHQWFMergeFieldBuildForTables @template, @itemsheader output, @itemsquery output, @msg output
   if @rcode <> 0 goto bspexit
   
   -- create items query for SLIT and replace values
   set @slitemsquery = @itemsquery
   select @slitemsquery = REPLACE(@slitemsquery,'a.SLCo', 'i.SLCo')
   select @slitemsquery = REPLACE(@slitemsquery,'a.SL', 'i.SL')
   select @slitemsquery = REPLACE(@slitemsquery,'a.SLItemType', 'i.ItemType')
   select @slitemsquery = REPLACE(@slitemsquery,'a.SLItemDescription', 'i.Description')
   select @slitemsquery = REPLACE(@slitemsquery,'a.Units', 'i.OrigUnits')
   select @slitemsquery = REPLACE(@slitemsquery,'a.UnitCost', 'i.OrigUnitCost')
   select @slitemsquery = REPLACE(@slitemsquery,'a.Amount','i.OrigCost')
   select @slitemsquery = REPLACE(@slitemsquery,'a.PMCo','i.JCCo')
   select @slitemsquery = REPLACE(@slitemsquery,'a.Project','i.Job')
   select @slitemsquery = REPLACE(@slitemsquery,'a.SLAddon', 'i.Addon')
   select @slitemsquery = REPLACE(@slitemsquery,'a.SLAddonPct', 'i.AddonPct')
   select @slitemsquery = REPLACE(@slitemsquery,'a.PhaseGroup', 'i.PhaseGroup')
   select @slitemsquery = REPLACE(@slitemsquery,'a.Phase', 'i.Phase')
   select @slitemsquery = REPLACE(@slitemsquery,'a.CostType', 'i.JCCType')
   select @slitemsquery = REPLACE(@slitemsquery,'a.VendorGroup', 'i.VendorGroup')
   select @slitemsquery = REPLACE(@slitemsquery,'a.Supplier', 'i.Supplier')
   select @slitemsquery = REPLACE(@slitemsquery,'a.WCRetgPct', 'i.WCRetPct')
   select @slitemsquery = REPLACE(@slitemsquery,'a.SMRetgPct', 'i.SMRetPct')
   select @slitemsquery = REPLACE(@slitemsquery,'a.UM', 'i.UM')
   select @slitemsquery = REPLACE(@slitemsquery,'a.Notes', 'i.Notes')
   select @slitemsquery = REPLACE(@slitemsquery,'a.ud', 'i.ud')

 select @slitemsquery = REPLACE(@slitemsquery,'i.SLItemDescription', 'i.Description')
 select @slitemsquery = REPLACE(@slitemsquery,'a.SubCO','''''')
 select @slitemsquery = REPLACE(@slitemsquery,'PMSL a', 'SLIT i')
 select @slitemsquery = REPLACE(@slitemsquery,'a.','i.')
   
   select @itemsquery = @itemsquery + ' where a.PMCo = ' + convert(varchar(3),@pmco)
   select @itemsquery = @itemsquery + ' and a.SLCo = ' + convert(varchar(3),@apco)
   select @itemsquery = @itemsquery + ' and a.SL = ' + CHAR(39) + @sl + CHAR(39)
   -- -- -- select @itemsquery = @itemsquery + ' and a.RecordType = ' + CHAR(39) + 'O' + CHAR(39)
   select @itemsquery = @itemsquery + ' and a.SLItemType in (1,4)'
   select @itemsquery = @itemsquery + ' and a.SendFlag = ' + CHAR(39) + 'Y' + CHAR(39)
   select @itemsquery = @itemsquery + ' and not exists(select * from bSLIT c with (nolock)'
   select @itemsquery = @itemsquery + ' where c.SLCo=a.SLCo and c.SL=a.SL and c.SLItem=a.SLItem)'
   select @itemsquery = @itemsquery + ' UNION '
   
   select @itemsquery = @itemsquery + @slitemsquery
   select @itemsquery = @itemsquery + ' where i.SLCo = ' + convert(varchar(3),@apco)
   select @itemsquery = @itemsquery + ' and i.SL = ' + CHAR(39) + @sl + CHAR(39)
   select @itemsquery = @itemsquery + ' and i.ItemType in (1,4)'
   -- -- -- order by SLitem if found in query #29833
   if CHARINDEX('SLItem,',@slitemsquery) <> 0
   	begin
   	select @itemsquery = @itemsquery + ' order by SLItem'
   	end
   
   -- update HQWD with LastUser and DateTime
   if SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs'
   	update bHQWD set UsedBy = @lastuser, UsedLast = @usedlast
   	where TemplateName=@template
   
   
   
   
   bspexit:
   	if @rcode<>0 select @msg = isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSUBItemDocMergeBuild] TO [public]
GO
