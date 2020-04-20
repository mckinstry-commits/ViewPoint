SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspMSQuoteUniqueness]
   /*************************************
   * Created By:   GF 03/30/2000
   * Modified By:  GG 07/03/01 - added isnull to Customer Quote validation
   *				GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
   *
   *
   * checks bMSQH for quote uniqueness by quote type.
   *
   * Pass:
   *   MSCo,Quote,QuoteType,Customer,CustJob,CustPO,JCCo,Job,INCo,Loc
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @quote varchar(10) = null, @quotetype varchar(1) = null,
    @customer bCustomer = null, @custjob varchar(20) = null, @custpo varchar(20) = null,
    @jcco bCompany = null, @job bJob = null, @inco bCompany = null, @loc bLoc = null,
    @errmsg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0, @errmsg = ''
   
   if @msco is null
       begin
       select @errmsg = 'Missing MS Company!', @rcode=1
       goto bspexit
       end
   
   if @quote is null
       begin
       select @errmsg = 'Missing Quote!', @rcode=1
       goto bspexit
       end
   
   if @quotetype not in ('C','J','I')
       begin
       select @errmsg = 'Invalid quote type!', @rcode=1
       goto bspexit
       end
   
   if @quotetype='C' and @customer is null
       goto bspexit
   
   -- validate quote is unique for customer
   if @quotetype='C'
       begin
       select @validcnt=count(*)
       from bMSQH with (nolock)
       where MSCo=@msco and Customer=@customer and isnull(CustJob,'') = isnull(@custjob,'')
           and isnull(CustPO,'') = isnull(@custpo,'') and Quote<>@quote
       if @validcnt > 0
           begin
           select @errmsg = 'Quote must be unique for Customer/Job/PO combination!', @rcode=1
           goto bspexit
           end
       else
           goto bspexit
       end
   
   -- validate quote is unique for job type
   if @quotetype='J'
       begin
       select @validcnt=count(*) from bMSQH with (nolock) 
       where MSCo=@msco and JCCo=@jcco and Job=@job and Quote<>@quote
       if @validcnt > 0
           begin
           select @errmsg = 'Quote must be unique for JC Company/Job combination!', @rcode=1
           goto bspexit
           end
       else
           goto bspexit
       end
   
   -- validate quote is unique for inventory type
   if @quotetype='I'
       begin
       select @validcnt=count(*) from bMSQH with (nolock) 
       where MSCo=@msco and INCo=@inco and Loc=@loc and Quote<>@quote
       if @validcnt > 0
           begin
           select @errmsg = 'Quote must be unique for IN Company/Location combination!', @rcode=1
           goto bspexit
           end
       else
           goto bspexit
       end
   
   
   bspexit:
       if @rcode<>0 select @errmsg=isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQuoteUniqueness] TO [public]
GO
