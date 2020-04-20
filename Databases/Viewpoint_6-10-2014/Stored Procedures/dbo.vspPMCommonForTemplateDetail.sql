SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[vspPMCommonForTemplateDetail]

  /*************************************
  * CREATED BY:		GP 04/08/2009
  * Modified By:
  *
  *		Returns values needed by PM Import Template Detail
  *		during form load.
  *
  *		Input Parameters:
  *			Template
  *  
  *		Output Parameters:
  *			rcode - 0 Success
  *					1 Failure
  *			msg - Return Message
  *		
  **************************************/
	(@Template varchar(10) = null, @FileType char(1) output, @ImportRoutine varchar(20) output, 
	@msg varchar(256) output)
	as
	set nocount on

	declare @rcode int
	set @rcode = 0

	select top 1 1 from PMUT with (nolock) where Template = @Template
	if @@rowcount = 0
	begin
		set @msg = 'Missing Template.'
	end

	select @FileType = FileType, @ImportRoutine = ImportRoutine from PMUT with (nolock) where Template = @Template


	vspexit:
   		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCommonForTemplateDetail] TO [public]
GO
