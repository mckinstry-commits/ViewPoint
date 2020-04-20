SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRDLTypeDescVal]
/************************************************************************
* CREATED:	MH    
* MODIFIED:	MH 2/5/2008 Issue 23347
*			MH 12/15/2008	Issue 131377
*			MH 02/15/2009 - Issue 138018
*
* Purpose of Stored Procedure
*
*    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

  	(@hrco bCompany, @hrref bHRRef, @bencode varchar(10), @prco bCompany = null, 
  	@dlcode bEDLCode, @dltype char(1) output, @dlinstcnt int output, 
	@rateamt1 bUnitCost output, @benefitoption smallint output, @freq bFreq output, 
	@vendorgroup bGroup output, @msg varchar(60) output)

as
set nocount on

    declare @rcode int, @description bDesc 

    select @rcode = 0, @dlinstcnt = 0
  
  	if @hrco is null
  	begin
  		select @msg = 'Missing HR Company', @rcode = 1
  		goto vspexit
  	end
  
  	if @prco is null
  	begin
  		select @msg = 'Missing PR Company', @rcode = 1
  		goto vspexit
  	end
  
  	if @dlcode is null
  	begin
  		select @msg = 'Missing Code', @rcode = 1
  		goto vspexit
  	end
  
  	exec @rcode = bspPRDLTypeDescVal @prco, @dlcode, @dltype output, @description output, @rateamt1 output, @msg output
  
  	if @rcode <> 0 goto vspexit
  
	select @msg = @description

  	select @dlinstcnt = count(HRCo) from dbo.HRBL with (nolock)
  	where HRCo = @hrco and HRRef = @hrref and BenefitCode <> @bencode and DependentSeq = 0 and
  	DLCode = @dlcode and DLType = @dltype

	if (select count(1) from dbo.HRBI where HRCo = @hrco and BenefitCode = @bencode and EDLCode = @dlcode and
	EDLType = @dltype) = 1
	begin
		select @benefitoption = BenefitOption, @freq = Frequency  
		from dbo.HRBI (nolock)
		where HRCo = @hrco and BenefitCode = @bencode and EDLCode = @dlcode and
		EDLType = @dltype
	end

	--Issue 138018.  Need to return VendorGroup off validation of DL Code to be used as default value.
	--Null value ok.  Not all DL codes are set up to update AP.  Lack of Vendor Group will only cause
	--Vendor lookup and setup to not return anything.  Does not effect DL Code processing.
	
	select @vendorgroup= h.VendorGroup 
	from dbo.bPRCO p with (nolock)
	Join dbo.bHQCO h with (nolock) on p.APCo = h.HQCo
	where p.PRCo = @prco
	

	
vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRDLTypeDescVal] TO [public]
GO
