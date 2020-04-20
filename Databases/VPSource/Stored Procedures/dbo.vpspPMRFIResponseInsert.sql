SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMRFIResponseInsert]
-- =============================================
-- Author:		Jeremiah Barkley
-- Modified by: GP	4/7/2011	Added Type and DateReceived
-- Create date: 8/19/09
-- Description:	Gets an RFI response or response list
-- =============================================
(@KeyID BIGINT = NULL, @Seq BIGINT, @DisplayOrder BIGINT, @Send CHAR, @DateRequired bDate, @VendorGroup bVendor, @RespondFirm bFirm, @RespondContact bEmployee, @Notes VARCHAR(MAX), @LastDate SMALLDATETIME, @LastBy bVPUserName, @RFIID BIGINT, @PMCo bCompany, @Project bJob, @RFIType bDocType, @RFI bDocument, @UniqueAttchID UNIQUEIDENTIFIER, @VPUserName bVPUserName, @Type varchar(10), @DateReceived bDate)
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
	
	SELECT @DisplayOrder = ISNULL(@DisplayOrder, ISNULL(MAX(DisplayOrder), 0) + 1), @Seq = ISNULL(MAX(Seq), 0) + 1 FROM PMRFIResponse WITH (NOLOCK) WHERE RFIID = @RFIID
	SELECT @VPUserName = ISNULL(@VPUserName, SUSER_SNAME())
	
	INSERT INTO [dbo].[PMRFIResponse]
		([Seq]
		,[DisplayOrder]
		,[Send]
		,[DateRequired]
		,[VendorGroup]
		,[RespondFirm]
		,[RespondContact]
		,[Notes]
		,[LastDate]
		,[LastBy]
		,[RFIID]
		,[PMCo]
		,[Project]
		,[RFIType]
		,[RFI]
		,[UniqueAttchID]
		,[Type]
		,[DateReceived])
	VALUES
		(@Seq
		,@DisplayOrder
		,@Send
		,@DateRequired
		,@VendorGroup
		,@RespondFirm
		,@RespondContact
		,@Notes
		,GETDATE()
		,@VPUserName
		,@RFIID
		,@PMCo
		,@Project
		,@RFIType
		,@RFI
		,@UniqueAttchID
		,@Type
		,@DateReceived)
           
           
	SET @KeyID = SCOPE_IDENTITY()
	EXECUTE vpspPMRFIResponseGet @RFIID, @KeyID, @VPUserName
 		
 	vspExit:
 	
END

GO
GRANT EXECUTE ON  [dbo].[vpspPMRFIResponseInsert] TO [VCSPortal]
GO
