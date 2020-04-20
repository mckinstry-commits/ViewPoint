SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE  procedure [dbo].[vspSMWorkOrderScopeVal]
/******************************************************
	* CREATED BY:	Eric V 
	* MODIFIED By:  Eric V 07/26/11 Don't considered WorkCompleted with Provisional=1 when setting @HasWorkCompleted
	*				JG	01/24/2012 - TK-11971 - Returning JCCo, Job, Phase and PhaseGroup
	* Usage:  Validates a Work Order Scope
	*	
	*
	* Input params:
	*
	*	@SMCo         - SM Company
	*	@WorkOrder	  - Work Order
	*   @Scope		  - Work Order Scope number
	*	@MustExist    - Flag to control validation behavior
	*	
	*
	* Output params:
	*	@HasWorkCompleted	- 'Y' if the work order scope has related work completed, otherwise, 'N'.
	*	@Status				- Scope Status
	*	@msg				- Work Scope description or error message.
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
(
   	@SMCo bCompany,
   	@WorkOrder int,
   	@Scope int,
   	@MustExist bYN = 'N',
   	@BillToARCustomer bCustomer = NULL OUTPUT,
   	@RateTemplate varchar(10) = NULL OUTPUT,
   	@HasWorkCompleted bYN='N' OUTPUT,
   	@IsComplete bYN = NULL OUTPUT,
   	@CustomerPOSetting char(1) = NULL OUTPUT,
   	@JCCo dbo.bCompany = NULL OUTPUT,
   	@Job dbo.bJob = NULL OUTPUT,
   	@Phase dbo.bPhase = NULL OUTPUT,
   	@PhaseGroup dbo.bGroup = NULL OUTPUT,
   	@HasProvisionalWorkCompleted bYN='N' OUTPUT,
   	@HasDeletedWorkCompleted bYN = 'N' OUTPUT,
   	@HasBilledWorkCompleted bYN = 'N' OUTPUT,
   	@msg varchar(100) = NULL OUTPUT)
	
AS
BEGIN
	SET NOCOUNT ON
	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company.'
		RETURN 1
	END
	
	IF @WorkOrder IS NULL
	BEGIN
		SET @msg = 'Missing Work Order.'
		RETURN 1
	END
	
	IF @Scope IS NULL
	BEGIN
		SET @msg = 'Missing Work Order Scope.'
		RETURN 1
	END
	
	SELECT @IsComplete = IsComplete, 
			@msg = [Description],
			@JCCo = JCCo,
			@Job = Job,
			@Phase = Phase,
			@PhaseGroup = PhaseGroup
	FROM dbo.SMWorkOrderScope
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder and Scope = @Scope
	
	IF @@rowcount <> 1 AND @MustExist = 'Y'
	BEGIN
		SET @msg = 'Work Order Scope does not exist in SMWorkOrderScope.'
		RETURN 1
	END
	
	SELECT 
            @RateTemplate = CASE WHEN ServiceRT.Active = 'Y' THEN ServiceRT.RateTemplate
                  WHEN CustomerRT.Active = 'Y' THEN CustomerRT.RateTemplate
                  ELSE NULL
            END,
            @BillToARCustomer = COALESCE(SMServiceSite.BillToARCustomer, SMCustomer.BillToARCustomer, SMCustomer.Customer),
            @CustomerPOSetting = ISNULL(SMServiceSite.CustomerPOSetting, SMCustomer.CustomerPOSetting)
      FROM dbo.SMWorkOrder
      LEFT JOIN dbo.SMServiceSite 
            ON SMServiceSite.SMCo = SMWorkOrder.SMCo
            AND SMServiceSite.ServiceSite = SMWorkOrder.ServiceSite
      LEFT JOIN dbo.SMCustomer 
            ON SMCustomer.SMCo = SMWorkOrder.SMCo
            AND SMCustomer.Customer = SMWorkOrder.Customer
      LEFT JOIN dbo.SMRateTemplate ServiceRT
            ON ServiceRT.SMCo = SMServiceSite.SMCo AND ServiceRT.RateTemplate = SMServiceSite.RateTemplate
      LEFT JOIN dbo.SMRateTemplate CustomerRT
            ON CustomerRT.SMCo = SMCustomer.SMCo AND CustomerRT.RateTemplate = SMCustomer.RateTemplate
      WHERE SMWorkOrder.SMCo = @SMCo AND SMWorkOrder.WorkOrder = @WorkOrder


	SELECT @HasWorkCompleted = 'N', @HasProvisionalWorkCompleted='N', @HasDeletedWorkCompleted='N',@HasBilledWorkCompleted='N'
	-- Determine whethere or not this work order scope has work completed
	IF EXISTS (SELECT 1 FROM dbo.SMWorkCompletedDetail
				INNER JOIN dbo.vSMWorkCompleted
					ON SMWorkCompletedDetail.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
				WHERE SMWorkCompletedDetail.SMCo = @SMCo 
					AND SMWorkCompletedDetail.WorkOrder = @WorkOrder 
					AND SMWorkCompletedDetail.Scope = @Scope
					AND vSMWorkCompleted.Provisional = 0
				)
	BEGIN
		SET @HasWorkCompleted = 'Y'
	END
	
	IF EXISTS (SELECT 1 FROM dbo.SMWorkCompletedDetail
				INNER JOIN dbo.vSMWorkCompleted
					ON SMWorkCompletedDetail.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
				WHERE SMWorkCompletedDetail.SMCo = @SMCo 
					AND SMWorkCompletedDetail.WorkOrder = @WorkOrder 
					AND SMWorkCompletedDetail.Scope = @Scope
					AND vSMWorkCompleted.Provisional = 1
				)
	BEGIN
		SET @HasProvisionalWorkCompleted = 'Y'
	END

	IF EXISTS (SELECT 1 FROM dbo.SMWorkCompletedAllCurrent
				WHERE SMCo = @SMCo 
					AND WorkOrder = @WorkOrder 
					AND Scope = @Scope
					AND IsDeleted = 1
				)
	BEGIN
		SET @HasDeletedWorkCompleted = 'Y'
	END
	
	IF EXISTS (SELECT 1 FROM dbo.SMWorkCompletedDetail
				INNER JOIN dbo.vSMWorkCompleted
					ON SMWorkCompletedDetail.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
				WHERE SMWorkCompletedDetail.SMCo = @SMCo 
					AND SMWorkCompletedDetail.WorkOrder = @WorkOrder 
					AND SMWorkCompletedDetail.Scope = @Scope
					AND SMWorkCompletedDetail.SMInvoiceID IS NOT NULL
					AND vSMWorkCompleted.Provisional = 0
				)
	BEGIN
		SET @HasBilledWorkCompleted = 'Y'
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderScopeVal] TO [public]
GO
