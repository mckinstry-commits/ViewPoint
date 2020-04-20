SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspAPCommonInfoGetforSLWks]
/********************************************************
* CREATED BY: 	DC  5/22/07  - I need to get SLTotYN when SL Worksheet loads
* MODIFIED BY:	
         
* USAGE:
* 	Retrieves common info from AP Company for use in SL Worksheet
*	 
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
* OUTPUT PARAMETERS:
*	@jcco				JC Co#
*	@emco				EM Co#
*	@inco				IN Co#
*	@glco				GL Co#
*	@cmco				CM Co#
*	@cmacct				CM Account
*	@paycategoryyn		Pay Categories option
*	@netamtoptyn		Net Amount to Subledgers options
*	@icrptyn			IC Reporting option
*	@vendorgroup		Vendor Group
*	@custgroup			Customer Group
*	@taxgroup			Tax Group
*	@apupdatepm			Update PM option
*	@apretholdcode		Retainage Hold Code
*	@apretpaytype		Retainage Pay Type
*	@appcretpaytypes	Pay Category Retainage Pay Types (comma separated string)
*	@phasegrp			Phase Group
*	@checkreportId		Check Report ID
*	@overflowreportId	Overflow Stub Report ID
*	@usetaxdiscyn		UseTaxDisc
*	@sltotalyn			SLTotYN
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
 (@co bCompany=0,
	@jcco bCompany =null output,
	@emco bCompany =null output,
	@inco bCompany =null output,
	@glco bCompany =null output,
	@cmco bCompany =null output,
	@cmacct bCMAcct =null output,
	@paycategoryyn bYN = null output,
	@netamtoptyn bYN = null output,
	@icrptyn bYN = null output,
	@vendorgroup bGroup = null output,
	@custgroup bGroup = null output,
	@taxgroup bGroup =  null output,
	@apupdatepm bYN = null output,
	@apretholdcode bHoldCode = null output,
	@apretpaytype int = null output,
	@appcretpaytypes varchar(200) = null output,
	@phasegrp bGroup = null output,
	@checkreportId int output,
	@overflowreportId int output,
	@usetaxdiscyn bYN output,
	@allallowpayyn bYN output,
	@poallowpayyn bYN output,
	@slallowpayyn bYN output,
	@sltotalyn bYN output)

  as 
set nocount on
declare @rcode int, @opencursor int, @retpaytype int,@checkreporttitle varchar(40),@overflowreporttitle varchar(40)
select @rcode = 0, @opencursor = 0

-- Get info from APCO
select @jcco=JCCo, @emco=EMCo, @inco=INCo, @glco=GLCo,
	@cmco=CMCo, @cmacct = CMAcct,@paycategoryyn=PayCategoryYN,
	@netamtoptyn=NetAmtOpt, @icrptyn = ICRptYN, @apretholdcode=RetHoldCode,
	@apretpaytype=RetPayType, @checkreporttitle = CheckReportTitle,
	@overflowreporttitle=OverFlowReportTitle, @usetaxdiscyn = UseTaxDiscountYN,
	@allallowpayyn=AllAllowPayYN, @poallowpayyn=POAllowPayYN ,@slallowpayyn=SLAllowPayYN
from bAPCO with (nolock)
where APCo=@co

select @sltotalyn = SLTotYN 
from bAPCO with (nolock)
where APCo = @co and JCCo = APCo

-- report numbers from bRPRT
if isnull(@checkreporttitle,'') <> ''
	begin
	select @checkreportId=ReportID
	from RPRTShared where Title= rtrim(@checkreporttitle)
	end
else
	begin
	select @checkreportId=ReportID from RPRTShared where Title='AP Check Print'
	end
	
if isnull(@overflowreporttitle,'') <> ''
	begin
	select @overflowreportId=ReportID
	from RPRTShared where Title= rtrim(@overflowreporttitle)
	end
else
	begin
	select @overflowreportId=ReportID from RPRTShared where Title= 'AP Check OverFlow' 
	end
 
-- Get info from HQCO
select  @vendorgroup =VendorGroup, @custgroup = CustGroup, @taxgroup=TaxGroup, @phasegrp = PhaseGroup
from bHQCO with (nolock)
where HQCo = @co 

-- Get APUpdatesPM flag from PMCO - per Carol get the first one where APCo=@co
select @apupdatepm = (select top 1 APVendUpdYN from bPMCO where APCo=@co order by PMCo asc)
if @@rowcount=0	select @apupdatepm = 'N'

	-- Create list of Pay Category Retainage PayTypes for APHoldRel
	/*declare vcAPPCRetPayType cursor LOCAL FAST_FORWARD for
	  select distinct RetPayType from bAPPC WITH (NOLOCK)
	  where APCo = @co and RetPayType is not null
	
		open vcAPPCRetPayType
	  select @opencursor = 1
	  
	  APPCRetPayType_loop:      -- loop through each line
	  	fetch next from vcAPPCRetPayType into @retpaytype
		
		if @@fetch_status <> 0 goto End_APPCRetPayType
	
		select @appcretpaytypes = isnull(@appcretpaytypes,'') + convert(varchar(3),@retpaytype) + ','
	
		goto APPCRetPayType_loop 
	 
	End_APPCRetPayType:
	
		if @opencursor = 1
	              begin
	              close vcAPPCRetPayType
	              deallocate vcAPPCRetPayType
	              end*/

-- cursor not needed to get list of retainage pay types  
set @appcretpaytypes = ''

select @appcretpaytypes = @appcretpaytypes + ',' + convert(varchar, RetPayType)
from bAPPC (nolock) where APCo = @co and RetPayType is not null
group by RetPayType	-- group by to eliminate duplicates

--strip leading character (,) from string of retainage pay types
if len(@appcretpaytypes)>0 select @appcretpaytypes = substring(@appcretpaytypes,2,len(@appcretpaytypes))
  
bspexit:
return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspAPCommonInfoGetforSLWks] TO [public]
GO
