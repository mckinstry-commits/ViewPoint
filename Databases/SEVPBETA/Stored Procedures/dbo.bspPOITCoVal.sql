SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPOITCoVal    Script Date: 8/28/99 9:35:26 AM ******/
CREATE     proc [dbo].[bspPOITCoVal]
/************************************************
* Created By SAE  4/24/97
* Modified by kb  4/20/98
* Modified by GR  2/01/00  added an output parameter to return burden unit cost flag from INCo
* Modified by GR  3/28/00  added an output param to return allowcostcodechange flag from EMCo
*		MV	08/18/03 - 22001  return Inventory GLCostOveride flag
*		MV  10/23/03 - 22001 set glcostoverride flag to 'Y' for exp type
*		DC	5/19/06 - Re-code for 6.x.  Added EMGroup to the output for Equipment 
*					and Work Order types. 
*		TJL 01/29/08 - Issue #126814:  Return EMCO.MatlLastUsedYN value.  Modified params for all DDFI ValProcs using this.
* 
* validates Company number in a POIT Record, Also used in SLEntry, APEntry,
* APRecurInv
*  The validation is based on type, makes sure its a valid CO and that
*  the batch month is open
*
* USED IN
*    PO Entry
*    SL Entry
*    AP Entry
*
* PASS IN
*   Company#

*   BatchMonth
*   POType
*
* RETURN PARAMETERS
*   GLCO     the GL Company based on the type
*   GLCostOverride
*   MatGrp   Material group for this company
*   PhaseGrp if Type is Job then Phase Group for JobCostCompany
*   TaxGrp   Tax Group from this post to company
*   BurdenYN Burden Unit Cost flag from IN Company
*   msg     Company Description from HQCO
*
*
* RETURNS
*   0 on Success
*   1 on ERROR and places error message in msg

**********************************************************/
(@co bCompany = 0, @batchmth bMonth = null, @potype tinyint,
	@glco bCompany output, @glcostoveride bYN output, @matlgroup bGroup output,
	@phasegrp bGroup output, @taxgrp bGroup output, @burdenyn bYN output, @allowcostcodechg bYN = null output,
	@emgroup bGroup = null output, @emcomatllastusedyn bYN output,
	@msg varchar(60) output)
as
set nocount on

declare @rcode int
    
select @rcode = 0, @phasegrp=null, @taxgrp=null
    
select @msg = Name, 
	@taxgrp=TaxGroup, 
	@matlgroup=MatlGroup, 
	@phasegrp=PhaseGroup
from bHQCO WITH (NOLOCK)
where @co = HQCo
if @@rowcount = 0
   begin
   select @msg = 'Not a valid HQ Company!', @rcode = 1
   goto bspexit
   end
    
if @potype = 1 /*job type */
   begin
   select @glco=GLCo, 
		@glcostoveride=GLCostOveride 
   from JCCO WITH (NOLOCK)
   where @co=JCCo
   if @@rowcount = 0
     begin
	 select @msg = 'Not a valid Job Cost Company!', @rcode = 1
     goto bspexit
     end
   end
    
if @potype = 2 /*inventory type */
	begin
	--select @glcostoveride='Y'
	select @glco=GLCo, 
	@burdenyn = BurdenCost, 
	@glcostoveride = OverrideGL
	from INCO WITH (NOLOCK)
	where @co=INCo
	if @@rowcount = 0
		begin
		select @msg = 'Not a valid Inventory Company!', @rcode = 1
		goto bspexit
		end
	end
    
if @potype = 3  /*expense type */
     /* not handled */
	begin
	select @glcostoveride='Y'
	end
    
if @potype = 4 or @potype = 5 /*Equipment or Work Order type */
begin
select @glco=GLCo, 
	@glcostoveride=GLOverride, 
	@allowcostcodechg=WOCostCodeChg,
	@emgroup = EMGroup,
	@emcomatllastusedyn = MatlLastUsedYN 
from EMCO WITH (NOLOCK)
where @co=EMCo
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Equipment Company!', @rcode = 1
	goto bspexit
	end
end
    
/*
* if we've made it this far then we have a valid GLCompay
* so make sure batch is in an open month
*/
if @batchmth is not null /*Dont validate if open month if month is passed in as null (like in APRecurInv) */
	begin
	exec @rcode = bspHQBatchMonthVal @glco, @batchmth, 'AP Entry', @msg output
	end
	    
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOITCoVal] TO [public]
GO
