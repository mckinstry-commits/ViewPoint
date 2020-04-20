SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSQHCopyDestVerify]
   /*************************************
   * Created By:   GF 05/08/2000
   * Modified By:
   *
   * verify destination quote uniqueness for copy
   *
   * Pass:
   *   MSCo,QuoteType,Customer,CustJob,CustPO,JCCo,Job,INCo,Loc
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @quotetype varchar(1) = null, @customer bCustomer = null,
    @custjob varchar(20) = null, @custpo varchar(20) = null, @jcco bCompany = null,
    @job bJob = null, @inco bCompany = null, @loc bLoc = null, @errmsg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0, @errmsg = ''
   
   if @msco is null
       begin
       select @errmsg = 'Missing MS Company!', @rcode=1
       goto bspexit
       end
   
   if @quotetype not in ('C','J','I')
       begin
       select @errmsg = 'Invalid quote type!', @rcode=1
       goto bspexit
       end
   
   if @quotetype='C' and @customer is null
       begin
       select @errmsg = 'Invalid Customer!', @rcode = 1
       goto bspexit
       end
   
   -- check quote uniqueness for customer type
   if @quotetype='C'
       begin
       select @validcnt=count(*) from bMSQH
       where MSCo=@msco and Customer=@customer and CustJob=@custjob and CustPO=@custpo
       if @validcnt > 0
           begin
           select @errmsg = 'This Customer/Job/PO combination is used on a quote!', @rcode=1
           goto bspexit
           end
       else
           goto bspexit
       end
   
   -- check quote uniqueness for job type
   if @quotetype='J'
       begin
       select @validcnt=count(*) from bMSQH
       where MSCo=@msco and JCCo=@jcco and Job=@job
       if @validcnt > 0
           begin
           select @errmsg = 'This JC Company/Job combination is used on a quote!', @rcode=1
           goto bspexit
           end
       else
           goto bspexit
       end
   
   -- check quote uniqueness for inventory type
   if @quotetype='I'
       begin
       select @validcnt=count(*) from bMSQH
       where MSCo=@msco and INCo=@inco and Loc=@loc
       if @validcnt > 0
           begin
           select @errmsg = 'This IN Company/Location combination is used on a quote!', @rcode=1
           goto bspexit
           end
       else
           goto bspexit
       end
   
   bspexit:
       if @rcode<>0 select @errmsg=isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQHCopyDestVerify] TO [public]
GO
