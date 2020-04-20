SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspMSGetNextQuote]
   /***********************************************************
    * Created By:  GF 05/05/2000
    * Modified By:
    *
    * USAGE:
    * looks at the MSCO AutoQuote flag to get the next Quote.
    * If AutoQuote flag is Y then use LastQuote increment it
    * by one and write it back out.
    *
    * INPUT PARAMETERS
    *   MSCo   MS Company to get next quote from
    *
    * OUTPUT PARAMETERS
    *   @quote The next quote number to use, if AutoQuote is N then ''
    * RETURN VALUE
    *   0         success
    *   1         Failure
   
    *****************************************************/
   (@msco bCompany = 0, @quote varchar(10) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int, @lastquote varchar(10), @nextquote varchar(10)
   
   select @rcode=0, @quote=''
   
   -- If AutoQuote is Yes, get last quote from MSCO
   select @lastquote=isnull(LastQuote,0) from bMSCO with (nolock) where MSCo=@msco and AutoQuote='Y'
   if @@rowcount = 0 goto bspexit
   
   if isnumeric(@lastquote) = 1
       begin
       select @nextquote = convert(char(10),(convert(int, @lastquote)) + 1)
       end
   else
       begin
       select @nextquote = '1'
       end
   
   -- check if next quote is already in use, if not update MSCo and exit
   -- else add one and try again
   NextQuote_Check:
   select @validcnt=count(*) from bMSQH with (nolock) where MSCo=@msco and Quote=@nextquote
   if @validcnt = 0
       begin
       update bMSCO set LastQuote = @nextquote
       where MSCo=@msco
       select @quote=@nextquote
       goto bspexit
       end
   
   -- add one and try again
   select @lastquote = @nextquote
   select @nextquote = convert(char(10),(convert(int, @lastquote)) + 1)
   goto NextQuote_Check
   
   bspexit:
       return

GO
GRANT EXECUTE ON  [dbo].[bspMSGetNextQuote] TO [public]
GO
