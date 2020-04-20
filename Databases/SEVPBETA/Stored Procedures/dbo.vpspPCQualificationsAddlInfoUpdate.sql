SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:			Jeremiah Barkley
-- Create date:		
-- Description:		<PC Certificates Get Script>
-- Modifications:	2/1/10 - Removed Minority type and info provided by fields.
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCQualificationsAddlInfoUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @OrganizationType VARCHAR(20), @OrganizationCountry VARCHAR(2), @OrganizationState VARCHAR(4), @OrganizationDate bDate, @TIN VARCHAR(20), @OfficeType CHAR(1), @ParentName VARCHAR(60), @ParentAddress1 VARCHAR(60), @ParentCity VARCHAR(30), @ParentState VARCHAR(4), @ParentZip bZip, @ParentCountry CHAR(2), @ParentAddress2 VARCHAR(60), @OtherNames VARCHAR(200), @TradeAssociations VARCHAR(60))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @rcode INT
	
	-- Validation
	EXEC @rcode = vpspPCValidateStateCountry @OrganizationState, @OrganizationCountry
	IF @rcode != 0
	BEGIN
		GOTO vpspExit
	END
	
	EXEC @rcode = vpspPCValidateStateCountry @ParentState, @ParentCountry
	IF @rcode != 0
	BEGIN
		GOTO vpspExit
	END
	

	-- Validation successful
	UPDATE PCQualifications
	SET
		OrganizationType = @OrganizationType,
		OrganizationCountry = @OrganizationCountry,
		OrganizationState = @OrganizationState,
		OrganizationDate = @OrganizationDate,
		TIN = @TIN,
		OfficeType = @OfficeType,
		ParentName = @ParentName,
		ParentAddress1 = @ParentAddress1,
		ParentCity = @ParentCity,
		ParentState = @ParentState,
		ParentZip = @ParentZip,
		ParentCountry = @ParentCountry,
		ParentAddress2 = @ParentAddress2,
		OtherNames = @OtherNames,
		TradeAssociations = @TradeAssociations
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
	
vpspExit:
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsAddlInfoUpdate] TO [VCSPortal]
GO
