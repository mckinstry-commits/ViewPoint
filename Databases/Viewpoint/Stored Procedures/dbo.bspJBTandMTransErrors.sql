SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMTransErrors Script Date: 8/28/99 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTandMTransErrors]
   /***********************************************************
   * CREATED BY	: kb 5/10/00
   * MODIFIED BY	: kb 9/26/1 - issue #12377
   *		TJL 04/22/04 - Issue #22838, Use errmsg directly from bspJBTandMGetTemplateSeq proc
   *		TJL 10/29/04 - Issue #25836, Give general 'Category not found' error
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
   
   (@co bCompany, @mth bMonth, @billnum int, @jccdmth bMonth = null,
   	@jccdtrans bTrans = null, @reasoncode tinyint, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @errmsg varchar(255)
   
   select @rcode = 0
   
   select @errmsg =
   	case @reasoncode
       	when 1 then 'Cost Type Undefined'
           when 2 then 'Labor Rate Undefined'
           when 3 then 'Equipment Rate Undefined'
           when 4 then 'Material Undefined'
           when 5 then @msg 							--22838, 'No Template Seq for source/costtype/category'
           when 6 then 'No units or dollars to bill'
           when 7 then 'Category not found'			--25836, 'Labor Category not found'
           when 8 then 'Trans does not apply to Template Seq'
           when 9 then 'Job/Phase/Cost Type set as non-billable'
           when 10 then 'Possibly prebilled on ' + @msg
           when 101 then 'WARNING! Invoiced amount exceeds current contract'
        end
   
   if @reasoncode <100
   	begin
       if not exists(select * from JBJE where JBCo = @co and BillMonth = @mth
         	and BillNumber = @billnum and JCMonth = @jccdmth and JCTrans = @jccdtrans)
           begin
           insert JBJE (JBCo, BillMonth, BillNumber, JCMonth, JCTrans, ErrorDesc)
           select @co, @mth, @billnum, @jccdmth, @jccdtrans, @errmsg
           end
       end
   else
       begin
       if not exists(select * from JBBE where JBCo = @co and BillMonth = @mth
         	and BillNumber = @billnum and BillError = @reasoncode)
           begin
           insert JBBE(JBCo, BillMonth, BillNumber, BillError, ErrorDesc)
           select @co, @mth, @billnum, @reasoncode, @errmsg
           end
       end
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMTransErrors] TO [public]
GO
