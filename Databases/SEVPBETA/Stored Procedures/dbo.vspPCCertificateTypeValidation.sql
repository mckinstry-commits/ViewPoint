SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPCCertificateTypeValidation]
/***********************************************************
* Created By:		CHS	01/22/2010	- Issue #135831
* Modified By: 
*
* USAGE:
* Validates Certificate Type and returns a Description

* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
    *****************************************************/
(@vendorgroup bGroup, @vendor bigint, @certificatetype VARCHAR(20) = NULL, @msg VARCHAR(100) OUTPUT)

   as
   set nocount on

	declare @rcode INT, @active char(1)

	select @rcode = 0, @active = ''
	
	
	if @vendorgroup IS NULL
	begin
		select @msg = 'Vendor Group is a required parameter!', @rcode = 1
		goto vspExit
	end	
	
	if @vendor IS NULL
	begin
		select @msg = 'Vendor is a required parameter!', @rcode = 1
		goto vspExit
	end	
	
	if @certificatetype IS NULL
		begin
			select @msg = 'Certificate Type is a required parameter!', @rcode = 1
			goto vspExit
		end	
	
	

	select @msg = Description, @active = Active
	from PCCertificateTypes with (nolock)
	where VendorGroup = @vendorgroup AND @certificatetype = CertificateType

	-- Check for existance
	if @@rowcount = 0
		begin
		select @msg = 'Certificate Type ' + @certificatetype + ' needs to be setup in PC Certificate Types!', @rcode = 1
		goto vspExit
		end	
	
	
	--if @active <> 'Y'
	--	begin
	--	select @msg = 'Certificate Type ' + @certificatetype + ' has been marked as Inactive!', @rcode = 1
	--	goto vspExit		
	--	end		
		
	select top 1 1 from PCCertificates where VendorGroup = @vendorgroup AND Vendor = @vendor AND @certificatetype = CertificateType
	-- Check for existance
	if @@rowcount <> 0
		begin
		select @msg = 'Certificate Type ' + @certificatetype + ' has already been selected!', @rcode = 1
		end
		

		
			
	vspExit:
	
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPCCertificateTypeValidation] TO [public]
GO
