SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDMOVal    Script Date: 8/28/99 9:34:21 AM ******/
CREATE   proc [dbo].[vspStoredProcedureVal]
/***********************************************************
* CREATED: 1/22/09 AL
* Usage:
*	validates Stored procedure
*
* INPUT PARAMETERS
*   @storedproc       Stored procedure to validate
*	*
* INPUT PARAMETERS
*   @msg        error message if something went wrong, otherwise description
*
* RETURN VALUE
*   0 Success
*   1 fail
************************************************************************/
  	(@storedproc varchar (255) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int
select @rcode = 0

if @storedproc is null
	begin
	select @msg = 'Missing Stored Procedure!', @rcode = 1
	goto vspexit
	end

  
if not exists (select * from sys.procedures where name = @storedproc)
  	begin
  	select @msg = 'Stored procedure not on file!', @rcode = 1
  	end

   
vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspStoredProcedureVal] TO [public]
GO
