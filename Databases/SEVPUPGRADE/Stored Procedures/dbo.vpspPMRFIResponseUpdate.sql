SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPMRFIResponseUpdate]
-- =============================================
-- Author:		Jeremiah Barkley
-- Modified by:	GP	4/7/2011	Added Type and DateReceived
-- Create date: 8/19/09
-- Description:	Update an RFI response
-- =============================================
(@KeyID BIGINT = NULL, @Seq BIGINT, @DisplayOrder BIGINT, @Send CHAR, @DateRequired bDate, @VendorGroup bVendor, @RespondFirm bFirm, @RespondContact bEmployee, @Notes VARCHAR(MAX), @LastDate SMALLDATETIME, @LastBy bVPUserName, @RFIID BIGINT, @PMCo bCompany, @Project bJob, @RFIType bDocType, @RFI bDocument, @Type varchar(10), @DateReceived bDate, @UniqueAttchID UNIQUEIDENTIFIER, @VPUserName bVPUserName,
@Original_KeyID BIGINT = NULL, @Original_Seq BIGINT, @Original_DisplayOrder BIGINT, @Original_Send CHAR, @Original_DateRequired bDate, @Original_VendorGroup bVendor, @Original_RespondFirm bFirm, @Original_RespondContact bEmployee, @Original_Notes VARCHAR(MAX), @Original_LastDate SMALLDATETIME, @Original_LastBy bVPUserName, @Original_RFIID BIGINT, @Original_PMCo bCompany, @Original_Project bJob, @Original_RFIType bDocType, @Original_RFI bDocument, @Original_Type varchar(10), @Original_DateReceived bDate, @Original_UniqueAttchID UNIQUEIDENTIFIER, @Original_VPUserName bVPUserName)
AS
BEGIN
	SET NOCOUNT ON;
	
	IF (@RespondFirm = -1)
		BEGIN
		SELECT @RespondFirm = NULL
		END
	
	IF (@RespondContact = -1)
		BEGIN
		SELECT @RespondContact = NULL
		END
	
	SELECT @DisplayOrder = ISNULL(@DisplayOrder, ISNULL(MAX(DisplayOrder), 0) + 1) FROM PMRFIResponse WITH (NOLOCK) WHERE RFIID = @Original_RFIID
	SELECT @VPUserName = ISNULL(@VPUserName, SUSER_SNAME())
	
	UPDATE [PMRFIResponse] SET
		[Seq] = @Seq
		,[DisplayOrder] = @DisplayOrder
		,[Send] = @Send
		,[DateRequired] = @DateRequired
		,[VendorGroup] = @VendorGroup
		,[RespondFirm] = @RespondFirm
		,[RespondContact] = @RespondContact
		,[Notes] = @Notes
		,[LastDate] = GETDATE()
		,[LastBy] = @VPUserName
		,[RFIID] = @RFIID
		,[PMCo] = @PMCo
		,[Project] = @Project
		,[RFIType] = @RFIType
		,[RFI] = @RFI
		,[Type] = @Type
		,[DateReceived] = @DateReceived
		,[UniqueAttchID] = @UniqueAttchID

	WHERE 
		[KeyID] = @Original_KeyID
           
 
	EXECUTE vpspPMRFIResponseGet @Original_RFIID, @Original_KeyID, @VPUserName
 		
 	vspExit:
 	
END


GO
GRANT EXECUTE ON  [dbo].[vpspPMRFIResponseUpdate] TO [VCSPortal]
GO
