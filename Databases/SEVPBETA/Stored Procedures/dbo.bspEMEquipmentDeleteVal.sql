SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROC [dbo].[bspEMEquipmentDeleteVal] 
   /***********************************************************
    * CREATED BY: GWC 03/18/2004
    *MODIFIED BY: GWC 03/25/2004 Issue 23385 Addressed rejection, by returning correct error messages 
    *             GWC 04/07/2004 Issue 23385 Addressed rejection, EMRH returning incorrect error message
	*			  TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    *USAGE:
    * 	Warns of existing records that would be orphaned in other 
    *	tables if Equipment record is deleted.
    * 
    * 	Current tables being checked:
    *		bEMRH
    *		bEMEP
    *		bEMTE
    *		bEMUE
    *		bEMCD
    *		bEMRD
    *		bEMDP
    *		bEMSH
    *		bEMLH
    *		bEMWI
    *		bEMWF
    *		bEMEM (for components)
    *		bEMMR
    *
    *INPUT PARAMETERS:
    *	emco   		EMCo to validate against 
    *	qquipment   Equipment value to check
    *
    *OUTPUT PARAMETERS:
    *	@errormsg   Error message if error occurs
    *
    *RETURN VALUE:
    *	0			Success
    *	1			Failure
    *****************************************************/ 
   
   @emco bCompany = NULL, 
   @equipment bEquip = NULL,
   @errormsg varchar(255) OUTPUT
   
   
   AS
   
   SET NOCOUNT ON
   
   DECLARE @rcode INT
   
   --Initialize the return code to return a FAILURE
   SELECT @rcode = 1
   
   --Verify Equipment does not exist in Revenue header (bEMRH)
   IF EXISTS(SELECT TOP 1 1 FROM bEMRH WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Revenue Rate(s) exist for this equipment.'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Equipment parts (bEMEP)
   IF EXISTS(SELECT TOP 1 1 FROM bEMEP WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Equipment part(s) exist for this equipment.'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Rev. Template (bEMTE)
   IF EXISTS(SELECT TOP 1 1 FROM bEMTE WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Rev. Template(s) exist for this equipment.'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Auto use template (bEMUE)
   IF EXISTS(SELECT TOP 1 1 FROM bEMUE WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Auto use template(s) exist for this equipment.'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Cost detail transactions (bEMCD)
   IF EXISTS(SELECT TOP 1 1 FROM bEMCD WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Cost detail transaction(s) exist for this equipment.'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Revenue detail transactions (bEMRD)
   IF EXISTS(SELECT TOP 1 1 FROM bEMRD WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Revenue detail transaction(s) exist for this equipment.'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Depreciation records (bEMDP)
   IF EXISTS(SELECT TOP 1 1 FROM bEMDP WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Depreciation record(s) exist for this equipment'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Standard maintenance records (bEMSH)
   IF EXISTS(SELECT TOP 1 1 FROM bEMSH WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Standard maintenance record(s) exist for this equipment'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Location history records (bEMLH)
   IF EXISTS(SELECT TOP 1 1 FROM bEMLH WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Location history record(s) exist for this equipment'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Work order item records (bEMWI)
   IF EXISTS(SELECT TOP 1 1 FROM bEMWI WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Work order item record(s) exist for this equipment'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Warranty file recordns (bEMWF)
   IF EXISTS(SELECT TOP 1 1 FROM bEMWF WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Warranty file record(s) exist for this equipment'
   	GOTO ErrorHandler
   	END
   
	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equipment, @errormsg output
	If @rcode = 1
	begin
		  goto ErrorHandler
	end

   --Verify Equipment does not exist in Components (bEMEM)
   IF EXISTS(SELECT TOP 1 1 FROM bEMEM WITH (NOLOCK) WHERE EMCo = @emco AND CompOfEquip = @equipment)
   	BEGIN
   	SELECT @errormsg = 'Component(s) exist for this equipment'
   	GOTO ErrorHandler
   	END
   
   --Verify Equipment does not exist in Meter Reading History (bEMMR)
   IF EXISTS(SELECT TOP 1 1 FROM bEMMR WITH (NOLOCK) WHERE EMCo = @emco AND Equipment = @equipment 
   AND Source <> 'EMEM Init')
     	BEGIN
   	SELECT @errormsg = 'Meter Reading history record(s) exist for this equipment'
     	GOTO ErrorHandler
   	END
   
   --Create a successful return because no orphaned Equipment entries will be left (that we're currently checking...)
   SELECT @rcode = 0
   
   ExitHandler:
   	RETURN @rcode
   
   
   ErrorHandler:
   	--Set the return code to a failure and construct the Error message.
   	SELECT @rcode = 1
    	SELECT @errormsg = ISNULL(@errormsg,'')
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipmentDeleteVal] TO [public]
GO
