SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRProcedureVal    Script Date: 8/28/99 9:33:33 AM ******/
   CREATE  proc [dbo].[bspPRProcedureVal]
   /***********************************************************
    * CREATED BY: GG 07/06/99
    * MODIFIED BY :	EN 10/9/02 - issue 18877 change double quotes to single
    *
    * Usage:
    *	Used by PR Routine Maintenance to validate procedures.
    *
    * Input params:
    *	@procname    Procedure to validate
    *
    * Output params:
    *	@msg		error message if procedure does not exist
    *
    * Return code:
    *	0           success
    *  1           failure
    ************************************************************/
       (@procname varchar(30), @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   /* check required input params */
   
   if @procname is null
   	begin
   	select @msg = 'Missing Procedure.', @rcode = 1
   	goto bspexit
   	end
   
   if not exists(select * from sysobjects where name = @procname and type = 'P')
       begin
       select @msg = 'Invalid procedure.', @rcode = 1
       goto bspexit
       end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcedureVal] TO [public]
GO
