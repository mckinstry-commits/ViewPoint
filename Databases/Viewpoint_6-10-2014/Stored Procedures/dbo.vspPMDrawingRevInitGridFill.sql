SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPMDrawingRevInitGridFill]
   
   /***********************************************************
    * CREATED BY:	GP	07/27/2009 - Issue #134115
    * MODIFIED BY:	
    *
    * USAGE:
    * Return dataset to fill grid in PMDrawingLogsRevInit
    *
    *
    * INPUT PARAMETERS
    *	@PMCo
    *   @Project
    *
    * OUTPUT PARAMETERS
    *	Dataset containing Drawing Type, Drawing No, and Description.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@PMCo bCompany = null, @Project bJob = null, @msg varchar(255) output)
   as
   set nocount on
   
	declare @rcode tinyint

	select @rcode = 0

	--Get drawings by PMCo and Project
	select DrawingType as [Drawing Type], Drawing as [Drawing No], Description as [Description]
	from dbo.PMDG with (nolock) 
	where PMCo=@PMCo and Project=@Project


	vspexit:
		return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMDrawingRevInitGridFill] TO [public]
GO
