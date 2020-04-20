SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/14/10
-- Description:	Validation for SM call types
-- Modified: 07/16/10 - Switched @SMCompanyID to @SMCo.  Added @MustExist param.
--           01/10/11 - Added WorkOrder, Scope and HasWorkCompleted params. Only the current value of 
--						CallType on a work order that HasWorkCompleted is valid.
--			 03/11/11 - MarkH - Added null defaults to @WorkOrder and @Scope
--			 04/14/11 - LaneG - Added @IsTrackingWIP to params, and returns it for defaulting.
-- =============================================

CREATE PROCEDURE [dbo].[vspSMCallTypeVal]
	@SMCo AS bCompany, @CallType AS varchar(10), @WorkOrder int = null, @Scope int = null, @HasWorkCompleted bYN, @IsTrackingWIP bYN = NULL OUTPUT, @msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF @CallType IS NULL
	BEGIN
		SET @msg = 'Missing SM Call Type!'
		RETURN 1
	END
	
	IF @HasWorkCompleted = 'Y'
	BEGIN
		-- Only validate the current value of the CallType.
		IF NOT EXISTS(Select 1 from SMWorkOrderScope where SMCo = @SMCo AND WorkOrder = @WorkOrder
						AND Scope = @Scope AND CallType = @CallType)
		BEGIN
			SET @msg = 'Cannot change Call Type when Work Completed records exists!'
			RETURN 1
		END
	END
	
	DECLARE @IsActive bYN
	
	SELECT @msg = [Description], @IsActive = Active, @IsTrackingWIP = IsTrackingWIP
    FROM dbo.SMCallType
    WHERE SMCo = @SMCo AND CallType = @CallType
    
    IF @@rowcount = 0
    BEGIN
		SET @msg = 'Call Type has not been setup in SM Call Types.'
		RETURN 1
    END
    
    IF @IsActive <> 'Y'
    BEGIN
		SET @msg = ISNULL(@msg,'') + ' - Inactive Call Type.'
		RETURN 1
    END
    
    RETURN 0
END



GO
GRANT EXECUTE ON  [dbo].[vspSMCallTypeVal] TO [public]
GO
