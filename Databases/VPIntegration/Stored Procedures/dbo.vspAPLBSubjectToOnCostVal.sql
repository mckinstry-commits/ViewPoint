SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPLBSubjectToOnCostVal]
/*********************************************
* Created:		CHS	01/31/2012	TK-11874 AP On-Cost Processing
* Modified:		MV	02/14/2012  TK-11874 - restrict where clause by APCo 
*
* Usage:
*  validation for the Subject to On-Cost Checkbox to check for the existance of records in the 
*	APVendorMaster On-Cost table.
*
* Input:
*  @VendorGroup
*  @Vendor
*  @SubjectToOnCost
*
* Output:
*  @errmsg     Error message
*
* Return:
*  0           success
*  1           error
*************************************************/
	(	@APCo Int,
		@VendorGroup bGroup,
		@Vendor bVendor,
		@SubjectToOnCost bYN,
		@Msg VARCHAR(255) OUTPUT)
   
	AS
   
	SET NOCOUNT ON
  
	DECLARE	@Rcode tinyint

			
	SELECT @Rcode = 0, @Msg = ''
  
	IF @VendorGroup IS NULL
	BEGIN
		SELECT @Msg = 'Missing VendorGroup!', @Rcode=1
		RETURN
	END
	
	IF @Vendor IS NULL
	BEGIN
		SELECT @Msg = 'Missing  !', @Rcode=1
		RETURN
	END
	

	IF @SubjectToOnCost = 'Y'
	BEGIN
		IF NOT EXISTS
			(
				SELECT TOP 1 1
				FROM vAPVendorMasterOnCost 
				WHERE APCo=@APCo AND VendorGroup = @VendorGroup AND Vendor = @Vendor
			)
		BEGIN
			SELECT @Msg = 'On-Cost Types are not set up on Vendor: ' + CONVERT(VARCHAR(12),@Vendor,1) + ' '
			SELECT @Rcode=1
			RETURN @Rcode			
		END		
	END

GO
GRANT EXECUTE ON  [dbo].[vspAPLBSubjectToOnCostVal] TO [public]
GO
