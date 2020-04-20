SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPCCertificateValBidderSelect]
/***********************************************************
* Created By:		JG	12/09/2010
* Modified By: 
*
* USAGE:
*	returns a Description

* OUTPUT PARAMETERS
*   @errmsg    = Description
*
* RETURN VALUE
*   0   success
*   1   fail
    *****************************************************/
(@vendorgroup bGroup, @vendor bigint = null, @certificatetype VARCHAR(20) = NULL, @msg VARCHAR(100) OUTPUT)

   as
   set nocount on

	declare @rcode INT, @active char(1)

	select @rcode = 0, @active = ''
	
	
	if @vendorgroup IS NULL
	begin
		select @msg = 'Vendor Group is a required parameter!', @rcode = 1
		goto vspExit
	end	
	
	if @certificatetype IS NULL
		begin
			select @msg = 'Certificate Type is a required parameter!', @rcode = 1
			goto vspExit
		end	
	
	IF (@certificatetype = 'Multiple')
	BEGIN
		SELECT @msg = 'Pulled from Bid Package'
	END
	ELSE
	BEGIN
	
		if not exists (select top 1 1 from PCCertificateTypes with (nolock)	where VendorGroup = @vendorgroup AND @certificatetype = CertificateType)
		begin
			select @msg = 'Certificate Type ' + @certificatetype + ' is not valid!', @rcode = 1
			goto vspExit
		end
		
		
		select @msg = Description
		from PCCertificateTypes with (nolock)
		where VendorGroup = @vendorgroup AND @certificatetype = CertificateType
	
	END

			
	vspExit:
	
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPCCertificateValBidderSelect] TO [public]
GO
