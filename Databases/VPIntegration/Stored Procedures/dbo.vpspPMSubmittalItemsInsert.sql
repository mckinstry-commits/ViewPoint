SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMSubmittalItemsInsert]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Insert a submittal item.
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@Submittal bDocument,
	@SubmittalType bDocType,
	@Rev TINYINT,
	@Item VARCHAR(10),
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
	@UniqueAttchID UNIQUEIDENTIFIER
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

	--Item Validation
	SET @Item = (SELECT ISNULL(MAX(Item), 0) + 1 FROM PMSI WHERE PMCo = @PMCo AND Project = @Project AND Submittal = @Submittal AND SubmittalType = @SubmittalType)

	INSERT INTO PMSI
		( PMCo
		, Project
		, Submittal
		, SubmittalType
		, Rev
		, Item
		, Description
		, Status
		, Send
		, DateReqd
		, DateRecd
		, ToArchEng
		, DueBackArch
		, RecdBackArch
		, DateRetd
		, ActivityDate
		, CopiesRecd
		, CopiesSent
		, CopiesReqd
		, CopiesRecdArch
		, CopiesSentArch
		, Notes
		, UniqueAttchID
		)

	VALUES
		( @PMCo
		, @Project
		, @Submittal
		, @SubmittalType
		, @Rev
		, @Item
		, @Description
		, @Status
		, @Send
		, @DateReqd
		, @DateRecd
		, @ToArchEng
		, @DueBackArch
		, @RecdBackArch
		, @DateRetd
		, @ActivityDate
		, @CopiesRecd
		, @CopiesSent
		, @CopiesReqd
		, @CopiesRecdArch
		, @CopiesSentArch
		, @Notes
		, @UniqueAttchID
		)

	DECLARE @KeyID BIGINT
	SET @KeyID = SCOPE_IDENTITY()
	EXECUTE vpspPMSubmittalItemsGet @PMCo, @Project, @Submittal, @Rev, @SubmittalType, @KeyID
	
	vspExit:
END
GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalItemsInsert] TO [VCSPortal]
GO
