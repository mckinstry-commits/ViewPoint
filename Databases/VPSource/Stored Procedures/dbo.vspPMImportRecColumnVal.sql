SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[vspPMImportRecColumnVal]

  /*************************************
  * CREATED BY:		GP 02/27/2009
  * Modified By:
  *
  *		Validates RecColumn to make sure multiple columns 
  *		don't exist with the same value.
  *
  *		Input Parameters:
  *			Template
  *			RecordType
  *			RecColumn
  *  
  *		Output Parameters:
  *			rcode - 0 Success
  *					1 Failure
  *			msg - Return Message
  *		
  **************************************/
	(@Template varchar(10) = null, @RecordType varchar(20) = null, @RecColumn int = null,
	@msg varchar(256) output)
	as
	set nocount on

	declare @rcode int
	set @rcode = 0

	if exists(select top 1 1 from PMUD with (nolock) where Template=@Template and RecordType=@RecordType and RecColumn=@RecColumn)
	begin
		select @msg = 'Record Column value already exists, please enter another. ', @rcode = 1
		goto vspexit
	end
	
	vspexit:
   		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportRecColumnVal] TO [public]
GO
