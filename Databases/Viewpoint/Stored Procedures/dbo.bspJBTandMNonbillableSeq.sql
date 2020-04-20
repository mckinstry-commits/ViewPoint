SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMNonbillableSeq    Script Date: 8/28/99 9:32:34 AM ******/
     CREATE proc [dbo].[bspJBTandMNonbillableSeq]
     /***********************************************************
      * CREATED BY	: kb 9/28/00
      * MODIFIED BY	:
      *
      * USED IN:
      *
      * USAGE:
      *
      * INPUT PARAMETERS
      *
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs
      * RETURN VALUE
      *   0         success
      *   1         Failure
      *****************************************************/
   
         (@co bCompany, @billmonth bMonth, @billnum int,
         @jcmonth bMonth, @jctrans bTrans, @msg varchar(255) output)
     as
   
     set nocount on
   
     declare @rcode int
   
     select @rcode = 0
   
     insert bJBIJ (JBCo,BillMonth,BillNumber,Line,Seq,JCMonth,JCTrans,BillStatus,
       Hours,Units,Amt)
     select @co, @billmonth, @billnum, null, null, @jcmonth, @jctrans, 2,
       0,0,0

     bspexit:
     	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBTandMNonbillableSeq] TO [public]
GO
