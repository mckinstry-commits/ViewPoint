SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspWFDocReviewReturnToVal]
/*************************************
 * Created By:		GPT 5/4/12 - TK-000000
 * Modified By:
 *
 * Validates that the ReturnTo step exists on the process detail  
 * or is specified as the originator of the process detail.
 *
 * Pass:
 * @ProcessDetailID - ProcessDetailID
 * @Step - Step 
 *
 * Returns:
 * 0 - Success
 * 1 - Failure
 * @Msg - Error Message
 **************************************/
(@ProcessDetailID bigint, @Step varchar(140), @Msg varchar(255) output)
AS
SET NOCOUNT ON

--Check that the step exists for the process detail
--or is the originator
IF Not exists(SELECT 1 FROM 
				( SELECT 'Originator - ' + InitiatedBy AS Step, KeyID FROM WFProcessDetail
				  UNION
				  SELECT 'Step - ' + cast(s.Step AS VARCHAR) AS Step, WFProcessDetail.KeyID FROM WFProcessDetail
				  JOIN WFProcessDetailStep s ON s.ProcessDetailID=WFProcessDetail.KeyID) a 
			  WHERE a.KeyID = @ProcessDetailID and a.Step = @Step )
BEGIN
	SELECT @Msg = 'Step does not exist on Process Detail.'
	RETURN 1
END

--Return 0 if successful
RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspWFDocReviewReturnToVal] TO [public]
GO
