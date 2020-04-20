SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[bspHQPayTermsValForMS]
   /***********************************************************
    * Created By:  GF 03/05/2001
    * Modified By:
    *
    *
    * USAGE:
    * 	validates Payment Terms in HQPT
    *
    * INPUT PARAMETERS
    *   PayTerms Terms to validate
    *
    * OUTPUT PARAMETERS
    *   @discopt  Discount Option
    *   @msg      Description or error message
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   (@payterms bPayTerms = null, @dueoptcheck bYN = null, @discrate bPct output,
    @discopt tinyint output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @dueopt tinyint
   
   select @rcode = 0, @discopt=3
   
   if @payterms is null
   	begin
   	select @msg = 'Missing Payment Terms code!', @rcode = 1
   	goto bspexit
   	end
   
   if @payterms is not null
   	begin
     	select @discrate=DiscRate, @discopt=DiscOpt, @dueopt=DueOpt, @msg=Description
       from HQPT where PayTerms = @payterms
   
     	if @@rowcount = 0
        		begin
         		select @msg = 'Payment Terms not valid!', @rcode = 1
         		goto bspexit
   		    end
   
       if @dueoptcheck='Y' and @dueopt=3
           begin
           select @msg = 'Payment terms due option cannot be none', @rcode=1
           goto bspexit
           end
   
   	end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQPayTermsValForMS] TO [public]
GO
