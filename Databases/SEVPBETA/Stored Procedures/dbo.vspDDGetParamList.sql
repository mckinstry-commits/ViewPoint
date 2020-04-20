SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************
* CREATED:		11/5/07  CC
* USAGE:
*   Returns a parameter names, data type, and input/output for a given stored procedures paramters
*
* CALLED FROM:
*	DDFH & DDFI  
*
* INPUT PARAMETERS:
*    Stored procedure object name
*
************************************************************/
CREATE PROCEDURE [dbo].[vspDDGetParamList] 
	-- Add the parameters for the stored procedure here
	@objname varchar(250) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT param.name AS [ParamName], ISNULL(baset.name, '') AS [SystemType], param.is_output AS [IsOutputParameter] FROM sys.all_objects AS sp INNER JOIN sys.all_parameters AS param ON param.object_id=sp.object_id LEFT OUTER JOIN sys.types AS baset ON baset.user_type_id = param.system_type_id and baset.user_type_id = baset.system_type_id WHERE sp.name=@objname
END

GO
GRANT EXECUTE ON  [dbo].[vspDDGetParamList] TO [public]
GO
