SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE procedure [dbo].[vspSMWorkOrderChangeStatus]
	/******************************************************
	* CREATED BY:  Eric Vaterlaus
	* MODIFIED By: 
	*
	* Usage:  Close or Re-Open a Service Management Work Order
	*
	* Input params:
	*	
	*	@SMCo        SM Company
	*	@WorkOrder   Work Order Number
	*   @CloseFlag   1 = to close Work order,
	*				 0 = Re-Open a closed work order.
	*   @DeleteOpenTrips
	*				 1 =  Delete Work Order Trips with a status of Open.
	*
	* Output params:
	*   @TripCount    Number of trips that are open.
	*	@msg		  Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@SMCo bCompany, @WorkOrder int, @WOStatus tinyint, @DeleteOpenTrips bit=0, @TripCount int output, @msg varchar(255) output
   	
	AS 
	SET NOCOUNT ON
	
	BEGIN TRANSACTION
	
	IF (@WOStatus <> 0)
	BEGIN
		SELECT @TripCount = SUM(1) FROM SMTrip WHERE SMCo = @SMCo and WorkOrder = @WorkOrder AND Status = 0
		IF @TripCount > 0
		BEGIN
			IF @DeleteOpenTrips = 1
				-- Delete any open trips.	
				DELETE SMTrip WHERE SMCo = @SMCo and WorkOrder = @WorkOrder AND Status = 0
			ELSE
			BEGIN
				SET @msg = 'Open Trips exist.'
				ROLLBACK TRANSACTION
				RETURN 1
			END
		END
	END
	IF (@WOStatus = 2)
	BEGIN
		/* A Work Order cannot be canceled if Work Completed records exist. */
		IF EXISTS(SELECT 1 FROM dbo.SMWorkCompleted WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder)
		BEGIN
			SET @msg = 'Work Completed records exist.'
			ROLLBACK TRANSACTION
			RETURN 1
		END
		
		/* A Work Order cannot be canceled if POs are associated with it. */
		IF EXISTS(SELECT 1 FROM dbo.SMPurchaseOrderList WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder)
		BEGIN
			SET @msg = 'Associated Purchase Order records exist.'
			ROLLBACK TRANSACTION
			RETURN 1
		END
	END
		
	-- Set the value of the WOStatus field in the WorkOrder table if it has not already been changed.
	UPDATE SMWorkOrder SET WOStatus=@WOStatus WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND NOT WOStatus=@WOStatus
	
	IF @@ROWCOUNT = 0
	BEGIN
		-- Check to see why it did not update to provide a meaningful error message.
		IF EXISTS(SELECT 1 FROM SMWorkOrder WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WOStatus=1 AND @WOStatus=1)
			SET @msg = 'Work order has already been closed.';
		ELSE IF EXISTS(SELECT 1 FROM SMWorkOrder WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WOStatus=2 AND @WOStatus=2)
			SET @msg = 'Work order has already been canceled.';
		ELSE IF EXISTS(SELECT 1 FROM SMWorkOrder WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WOStatus=0 AND @WOStatus=0)
			SET @msg = 'Work order has already been re-openned.';
		ELSE IF NOT EXISTS(SELECT 1 FROM SMWorkOrder WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder)
			SET @msg = 'Work order does not exist.';
		ELSE
			SET @msg = 'Work order was not updated.';
		ROLLBACK TRANSACTION
		RETURN 1
	END
	ELSE
	BEGIN
		COMMIT TRANSACTION
		RETURN 0
	END


GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderChangeStatus] TO [public]
GO
