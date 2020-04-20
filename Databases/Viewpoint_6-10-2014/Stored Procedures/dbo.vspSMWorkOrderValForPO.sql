SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspSMWorkOrderValForPO]
/******************************************************
* CREATED BY:  Mark H 
* MODIFIED By: Eric V 01/13/11 Closed work orders will raise an error.
*				MarkH - 03/13/11 Modified to get GL based on Service Center's Department
*				Jacob V - 4/19/11 Modified to use vfSMGetAccountingTreatment
*				Jeremiah B - 8/2/11 Work Order no longer defaults GL Accounts, Scope Val does this already
*				Dan So 03/21/2012 - TK-13126 - Added JCCo, Job, and PhaseGroup output parameters
*				ScottAlvey 04/02/2013	TFS-Bug-44151 - Added @ClosedOK flag so that we can 'override' the closed status
*					check when neeeded. Also removed the Service Center val portion as we no longer need that. 
*
*			
* Usage:  Validates SM Work Order and returns a GL Account
*	
*
* Input params:
*	
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/

(
	@SMCo bCompany,
	@SMWorkOrder int, 
	@ClosedOK bYN = 'N',
	@JCCo bCompany = NULL OUTPUT, 
	@Job bJob = NULL OUTPUT, 
	@PhaseGroup bGroup = NULL OUTPUT,
	@msg varchar(100) OUTPUT
)
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode tinyint, @Department bDept, @errmsg varchar(255)
	
	IF (@SMCo IS NULL)
	BEGIN
		SELECT @msg = 'Missing SM Company.'
		RETURN 1
	END
	
	IF (@SMWorkOrder IS NULL)
	BEGIN
		SELECT @msg = 'Missing SM Work Order.'
		RETURN 1
	END

	DECLARE @WOStatus tinyint, @HasServiceCenter bYN

	EXEC @rcode = vspSMWorkOrderVal @SMCo = @SMCo, @WorkOrder = @SMWorkOrder, @IsCancelledOK = 'N', 
								    @WOStatus = @WOStatus OUTPUT, @HasServiceCenter = @HasServiceCenter OUTPUT,  
								    @JCCo = @JCCo OUTPUT, @Job = @Job OUTPUT, @PhaseGroup = @PhaseGroup OUTPUT,
								    @msg = @msg OUTPUT
	
	IF (@rcode <> 0) RETURN @rcode

	-- Validate that the Job can be posted to if the work order is related to a job.
	IF (@JCCo IS NOT NULL AND @Job IS NOT NULL)
	BEGIN
		EXEC @rcode = bspJCJMPostVal @jcco = @JCCo, @job = @Job, @msg = @errmsg OUTPUT
		
		IF (@rcode <> 0)
		BEGIN
			SET @msg = @errmsg
			RETURN @rcode
		END
	END

	-- Validate that the SM Work Order is not closed. If the @ClosedOK == Y then we can ignore this check.
	-- 1 is closed
	IF (@WOStatus = 1) and (@ClosedOK = 'N')
	BEGIN
		SELECT @msg = 'SM Work Order ' + convert(varchar, @SMWorkOrder) + ' is closed. Records cannot be added to a closed Work Order.'
		RETURN 1
	END
	
	RETURN 0
END
	
	




GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderValForPO] TO [public]
GO