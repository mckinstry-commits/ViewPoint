SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMGLPostingMiscSetInUse]
   /***********************************************************
    * Created:  ECV 03/31/11
    * Modified: 
    *
    *
    * Deletes a batch of GL records created for Work Completed 
    * Miscellaneous records located in the vSMMiscellaneousBatch
    * table.
    *
    * INPUT PARAMETERS
    *   @Co           SM Co#
    *   @mth            Posting Month
    *   @BatchId		Batch ID
    *   @InUse			Y or N
    *   @InUseBy        User the batch is currently in use by
    *   @Source         Batch Source
    *
    * OUTPUT PARAMETERS
    *   @msg            error message if something went wrong
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    *****************************************************/
(@Co bCompany, @mth bMonth, @BatchId int, @InUse bYN, @InUseBy bVPUserName, @Source varchar(10), @msg varchar(255)=NULL OUTPUT)
AS
SET NOCOUNT ON

SET @msg=NULL
BEGIN TRANSACTION

BEGIN TRY
	/* Remove InUse Flag from batch */
	DECLARE @rcode int
	
	IF(@InUse='Y')
	BEGIN
		UPDATE HQBC SET InUseBy=suser_name() WHERE Co=@Co AND Mth=@mth AND BatchId=@BatchId AND Source=@Source
		IF (@@ROWCOUNT=1)
			SET @rcode=0
		ELSE
		BEGIN
			SELECT @rcode=1, @msg = 'Cannot set InUseBy in HQBC.'
		END
	END
	ELSE
	BEGIN
		UPDATE HQBC SET InUseBy=NULL WHERE Co=@Co AND Mth=@mth AND BatchId=@BatchId AND InUseBy=@InUseBy AND Source=@Source
		IF (@@ROWCOUNT=1)
			SET @rcode=0
		ELSE
		BEGIN
			SELECT @rcode=1, @msg = 'Cannot remove InUseBy in HQBC.'
		END
	END
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
	SET @msg = 'Set InUse failed: ' + ERROR_MESSAGE()	
	RETURN 1
END CATCH

IF (@rcode=1)
BEGIN
	ROLLBACK TRANSACTION
END
ELSE
	COMMIT TRANSACTION
RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspSMGLPostingMiscSetInUse] TO [public]
GO
