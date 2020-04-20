SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspPMSubmittalRegisterUpdate]
/***********************************************************
* Created By:	  TRL 12/06/2012 TK-20015  create procedure
* Modified By:   TRL 01/07/2013 TK-20616  modify procedure to update datas when record is being reopened or closed and with Status changes not having a value.
*				
*Procedure is used by the PM Submittal Register Update form to update Dates and Status Code.
*		
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
( @PMCo bCompany, @Project bJob, @KeyIDString varchar(max), @Status bStatus = NULL, @ActivityDate bDate = NULL, 
@DueToResponsibleFirm bDate = NULL, @SentToResponsibleFirm bDate = NULL, @DueFromResponsibleFirm bDate = NULL, @ReceivedFromResponsibleFirm bDate = NULL, @ReturnedToResponsibleFirm bDate = NULL, 
@DueToApprovingFirm bDate = NULL, @SentToApprovingFirm bDate = NULL, @DueFromApprovingFirm bDate = NULL, @ReceivedFromApprovingFirm bDate = NULL,
@errormsg VARCHAR(255) OUTPUT)

AS

SET NOCOUNT ON
   
DECLARE @SubmittalReviewDaysResponsibleFirm INT, @SubmittalReviewDaysApprovingFirm INT, @SubmittalReviewDaysRequestingFirm INT, @SubmittalDaysAutoCalc bYN,
@CurrentKeyID varchar(10), @LeadDays1 INT, @LeadDays2 INT, @LeadDays3 INT, @CloseItem bYN, @ActivityDateVar1 INT, @ActivityDateVar2 INT, @IsRegisterItemClosed bYN

/*@CloseItem set to null, only has value on Status Code change*/
select @CloseItem=NULL,  @ActivityDateVar1 =0, @ActivityDateVar2 = 0

IF @PMCo is null
	BEGIN
		SELECT @errormsg = 'Missing PM Company!'
		RETURN 1
	END

IF @KeyIDString is null
	BEGIN
		SELECT @errormsg = 'No register items to update. Missing KeyID string'
		RETURN 1
	END

--Get Validate and get Project info
SELECT  @SubmittalReviewDaysResponsibleFirm = ISNULL(SubmittalReviewDaysResponsibleFirm,0), 
@SubmittalReviewDaysApprovingFirm = ISNULL(SubmittalReviewDaysApprovingFirm,0),
@SubmittalReviewDaysRequestingFirm = ISNULL(SubmittalReviewDaysRequestingFirm,0), 
@SubmittalDaysAutoCalc = ISNULL(SubmittalReviewDaysAutoCalcYN,'N')
FROM dbo.JCJMPM WHERE PMCo=@PMCo and Project = @Project
IF @@rowcount = 0
BEGIN
	SELECT @errormsg = 'Missing or Invalid Project.'
	RETURN  1 
END

--This code only needs to run once for all the record keyID's being updated.
IF @Status IS NOT NULL 
	BEGIN
	--Based on Code Type is Register Item being closed or re-opened
	SELECT @CloseItem = CASE WHEN CodeType = 'F' THEN 'Y' ELSE 'N' END 
	FROM dbo.PMSC WHERE [Status]=@Status
END

WHILE @KeyIDString IS NOT NULL
BEGIN
	--Get next KeyID
	IF CHARINDEX(CHAR(44), @KeyIDString) <> 0
		BEGIN
			SELECT @CurrentKeyID = SUBSTRING(@KeyIDString, 1, CHARINDEX(CHAR(44), @KeyIDString) - 1)
		END
	ELSE
		BEGIN
			SELECT @CurrentKeyID = @KeyIDString	
		END	

     --Remove current keyid from keystring
	SELECT @KeyIDString = SUBSTRING(@KeyIDString, LEN(@CurrentKeyID) + 2, (LEN(@KeyIDString) - LEN(@CurrentKeyID) + 1))

	--Check to see if Project is auto calculating dates
	IF @SubmittalDaysAutoCalc = 'Y'
	BEGIN
		--Reset LeadDay values for new KeyID and @CloseItem var
		SELECT @LeadDays1 = NULL, @LeadDays2 = NULL, @LeadDays3 = NULL

		--GET LeadDay values for new KeyID
		SELECT  @LeadDays1 = ISNULL(LeadDays1,0), @LeadDays2 = ISNULL(LeadDays2,0), @LeadDays3 = ISNULL(LeadDays3,0) ,@IsRegisterItemClosed = ISNULL(Closed,'N') 
		FROM dbo.PMSubmittal WHERE KeyID=@CurrentKeyID
	
		SELECT @ActivityDateVar1 = @SubmittalReviewDaysResponsibleFirm + @SubmittalReviewDaysApprovingFirm + @SubmittalReviewDaysRequestingFirm + @LeadDays1 + @LeadDays2 + @LeadDays3
		SELECT @ActivityDateVar2 = @SubmittalReviewDaysApprovingFirm + @SubmittalReviewDaysRequestingFirm + @LeadDays1 + @LeadDays2 + @LeadDays3
		
		/*Date calculations must be in this order 	based input from the form
		If ActivityDate has a value then, DueToApprovingFirm and DueFromResponsibleFirm can't have a value
		Keeping calc in this order prevents calcuation from being run twice.*/
		IF @DueToApprovingFirm IS NOT NULL  
		BEGIN
			IF @DueFromApprovingFirm IS  NULL 
			BEGIN
				SELECT @DueFromApprovingFirm = DATEADD(DAY,-@SubmittalReviewDaysApprovingFirm,@DueToApprovingFirm)
			END
		END		

		IF @DueFromResponsibleFirm IS NOT NULL 
		BEGIN
				IF @DueToApprovingFirm IS NULL  
				BEGIN
					SELECT @DueToApprovingFirm = DATEADD(DAY,-@SubmittalReviewDaysRequestingFirm,@DueFromResponsibleFirm)
				END		
				
				IF @DueFromApprovingFirm IS  NULL 
				BEGIN
					SELECT @DueFromApprovingFirm = DATEADD(DAY,-@SubmittalReviewDaysApprovingFirm,@DueToApprovingFirm)
				END	
		END

		IF @ActivityDate IS NOT NULL 
		BEGIN
				IF @DueToResponsibleFirm IS  NULL 
				BEGIN
					SELECT @DueToResponsibleFirm  = DATEADD(DAY,-@ActivityDateVar1,@ActivityDate)
				END

				IF @DueFromResponsibleFirm IS NULL 
				BEGIN
					SELECT @DueFromResponsibleFirm  = DATEADD(DAY,-@ActivityDateVar2,@ActivityDate)
				END
				
				IF @DueToApprovingFirm IS NULL  
				BEGIN
					SELECT @DueToApprovingFirm  = DATEADD(DAY,@SubmittalReviewDaysRequestingFirm,@DueFromResponsibleFirm)
				END		
				
				IF @DueFromApprovingFirm IS  NULL 
				BEGIN
					SELECT @DueFromApprovingFirm = DATEADD(DAY,@SubmittalReviewDaysApprovingFirm,@DueToApprovingFirm)
				END	
		END
	END

	--Update Submittal Register Record for current KeyID
	--Columns updated only if they have a parameter value input
	---Always update Status when @Status has a value
	IF @Status IS NOT NULL 
	BEGIN
		UPDATE dbo.PMSubmittal
		SET [Status] = @Status, Closed=@CloseItem
		WHERE KeyID=@CurrentKeyID
	END
	--Once a Register Item has been closed, it is locked down and no changes can be made until after the record has been reopend.
	--This prevents Dates being changed when switching different closed Status's (@IsRegisterItemClosed = 'Y' AND @CloseItem = 'Y')
	IF (@IsRegisterItemClosed = 'N' AND ISNULL(@CloseItem,'N')='N' /*Register Item Open/No Status changes but doesn't close record.*/) 
		OR (@IsRegisterItemClosed = 'Y' AND @CloseItem = 'N'/*Register Item closed/Status change opens record*/) 
		OR (@IsRegisterItemClosed = 'N' AND @CloseItem = 'Y'/*Register Item Open/Status change closes record*/)
	BEGIN
		UPDATE dbo.PMSubmittal
		SET ActivityDate = ISNULL(@ActivityDate,ActivityDate), 
		DueToResponsibleFirm = ISNULL(@DueToResponsibleFirm, DueToResponsibleFirm), 
		SentToResponsibleFirm = ISNULL(@SentToResponsibleFirm, SentToResponsibleFirm), 
		DueFromResponsibleFirm = ISNULL(@DueFromResponsibleFirm, DueFromResponsibleFirm), 
		ReceivedFromResponsibleFirm = ISNULL(@ReceivedFromResponsibleFirm, ReceivedFromResponsibleFirm), 
		ReturnedToResponsibleFirm = ISNULL(@ReturnedToResponsibleFirm, ReturnedToResponsibleFirm), 
		DueToApprovingFirm = ISNULL(@DueToApprovingFirm, DueToApprovingFirm), 
		SentToApprovingFirm = ISNULL(@SentToApprovingFirm, SentToApprovingFirm), 
		DueFromApprovingFirm = ISNULL(@DueFromApprovingFirm, DueFromApprovingFirm), 
		ReceivedFromApprovingFirm = ISNULL(@ReceivedFromApprovingFirm,ReceivedFromApprovingFirm) 
		WHERE KeyID=@CurrentKeyID
	END
	
	--Get the final KeyID value
	IF CHARINDEX(CHAR(44), @KeyIDString) = 0	
	BEGIN
		SET @KeyIDString = @KeyIDString + CHAR(44)
	END

	--Set KeyIDstring to null if no values left
	IF LEN(@KeyIDString) < 2		
	BEGIN
		SET @KeyIDString = null
	END

--End While
END

RETURN 0



GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalRegisterUpdate] TO [public]
GO
