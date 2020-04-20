SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMSubmittalItemsUpdate]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Update a submittal item.
************************************************************/

(
	@PMCo bCompany,
	@Project bJob,
	@Submittal bDocument,
	@SubmittalType bDocType,
	@Rev TINYINT,
	@Item SMALLINT,
	@Description bItemDesc,
	@Status bStatus,
	@Send bYN,
	@DateReqd bDate,
	@DateRecd bDate,
	@ToArchEng bDate,
	@DueBackArch bDate,
	@RecdBackArch bDate,
	@DateRetd bDate,
	@ActivityDate bDate,
	@CopiesRecd TINYINT,
	@CopiesSent TINYINT,
	@CopiesReqd TINYINT,
	@CopiesRecdArch TINYINT,
	@CopiesSentArch TINYINT,
	@Notes bNotes,
	@UniqueAttchID UNIQUEIDENTIFIER,
	@KeyID BIGINT,

	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_Submittal bDocument,
	@Original_SubmittalType bDocType,
	@Original_Rev TINYINT,
	@Original_Item SMALLINT,
	@Original_Description bItemDesc,
	@Original_Status bStatus,
	@Original_Send bYN,
	@Original_DateReqd bDate,
	@Original_DateRecd bDate,
	@Original_ToArchEng bDate,
	@Original_DueBackArch bDate,
	@Original_RecdBackArch bDate,
	@Original_DateRetd bDate,
	@Original_ActivityDate bDate,
	@Original_CopiesRecd TINYINT,
	@Original_CopiesSent TINYINT,
	@Original_CopiesReqd TINYINT,
	@Original_CopiesRecdArch TINYINT,
	@Original_CopiesSentArch TINYINT,
	@Original_Notes bNotes,
	@Original_UniqueAttchID UNIQUEIDENTIFIER,
	@Original_KeyID BIGINT
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @DocCat VARCHAR(10), @msg VARCHAR(255)
	SET @DocCat = 'SUBMIT'

	--Status Code Validation
	IF ([dbo].vpfPMValidateStatusCode(@Status, @DocCat)) = 0
	BEGIN
		SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '') + ' is not valid for Document Category: ' + ISNULL(@DocCat, '') + '.'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END
	
	--Update the submittal item
	UPDATE PMSI SET
		Description = @Description,
		Status = @Status,
		Send = @Send,
		DateReqd = @DateReqd,
		DateRecd = @DateRecd,
		ToArchEng = @ToArchEng,
		DueBackArch = @DueBackArch,
		RecdBackArch = @RecdBackArch,
		DateRetd = @DateRetd,
		ActivityDate = @ActivityDate,
		CopiesRecd = @CopiesRecd,
		CopiesSent = @CopiesSent,
		CopiesReqd = @CopiesReqd,
		CopiesRecdArch = @CopiesRecdArch,
		CopiesSentArch = @CopiesSentArch,
		Notes = @Notes,
		UniqueAttchID = @UniqueAttchID
		
	WHERE PMCo = @Original_PMCo
		AND Project = @Original_Project
		AND Submittal = @Original_Submittal
		AND SubmittalType = @Original_SubmittalType
		AND Rev = @Original_Rev
		AND Item = @Original_Item
		
	--Get an update for the current record.
	EXECUTE vpspPMSubmittalItemsGet @PMCo, @Project, @Submittal, @Rev, @SubmittalType, @KeyID

	vspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalItemsUpdate] TO [VCSPortal]
GO
