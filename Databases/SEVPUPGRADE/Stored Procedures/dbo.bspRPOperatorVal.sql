SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPOperatorVal    Script Date: 8/28/99 9:33:38 AM ******/
   /****** Object:  Stored Procedure dbo.bspRPOperatorVal    Script Date: 3/28/99 12:00:39 AM ******/
   CREATE  PROCEDURE [dbo].[bspRPOperatorVal]
   (@operator varchar(10)= null,
    @msg varchar(60) output)
   AS
   /* validates Report Criteria operators  */
   /* pass Operator */
   /* returns error message if error */
   set nocount on
   declare @rcode int
   select @rcode=0
   if @operator in ('=','<=','>=','<>','<','>','in','not on')
   		goto bspexit
   
   select @msg='Invalid operator',@rcode=1
   		goto bspexit
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRPOperatorVal] TO [public]
GO
