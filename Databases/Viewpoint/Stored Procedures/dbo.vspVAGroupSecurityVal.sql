SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspVAGroupSecurityVal]

/************************************************************************
* CREATED BY:    Jonathan Paullin 02/19/07
* MODIFIED BY:    
*
* Purpose of Stored Procedure:
*
*	Validates Group Security
*           
* Notes about Stored Procedure:
* 
*	This stored procedure was adapated from bspVAGrouptSecuityVal
*
* Paramters:
*
*	@SecurityGroup - The security group to be validated.
*	@ErrorMessage - Will hold an error message if an error occurs.
*
* Returns:
*	0 if successful.
*	1 and an error message if failed.
*
*************************************************************************/

   	(@SecurityGroup int = null, @ErrorMessage varchar(60) output)

AS
SET NOCOUNT ON

	--Create the return code and set it to zero.
   	declare @ReturnCode int
   	select @ReturnCode = 0
   
	if @SecurityGroup is null
   		begin
   		select @ErrorMessage = 'Missing Security Group', @ReturnCode = 1
   		goto ExitLabel
   	end
   
	--Check if the security group exists in the table.
	select @ErrorMessage = Name from dbo.vDDSG with (nolock)
		where SecurityGroup=@SecurityGroup and GroupType = 0

	-- If no records are returned, then that security group does not exist.
   	if @@rowcount = 0
   		begin
   		select @ErrorMessage = 'Not a valid Security Group', @ReturnCode = 1
   		end
   
ExitLabel:
	return @ReturnCode

GO
GRANT EXECUTE ON  [dbo].[vspVAGroupSecurityVal] TO [public]
GO
