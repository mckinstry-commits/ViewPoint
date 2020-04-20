SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPSeqVal    Script Date: 8/28/99 9:33:39 AM ******/
   /****** Object:  Stored Procedure dbo.bspRPSeqVal    Script Date: 3/28/99 12:00:39 AM ******/
   CREATE  PROCEDURE [dbo].[bspRPSeqVal] 
   (@sequence tinyint= null, @msg varchar(60) output)
   AS
   /* validates Report Criteria_Seq exits in RPRT */
   /* pass Sequence */
   /* returns error message if error */
   set nocount on
   declare @rcode int
   select @rcode=0
   
   if @sequence is null
   
   	begin
   	select @msg='Missing criteria sequence!',@rcode=1
   	goto bspexit
   	end
   if @sequence not between 0 and 99
   	begin
   	select @msg='Sequence must be between 0 and 99.',@rcode=1
   	goto bspexit
   	end
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRPSeqVal] TO [public]
GO
