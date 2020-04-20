SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQPayTermsVal    Script Date: 8/28/99 9:32:48 AM ******/
   CREATE  PROC [dbo].[bspHQPayTermsVal]
   /***********************************************************
    * CREATED BY: JRE   10/20/96
    * MODIFIED By : GG 11/7/96
    *             : GR 04/21/00 added an input param due option check
    *               to check for due option
    *
    *
    * USAGE:
    * 	validates Payment Terms in HQPT
    *
    * INPUT PARAMETERS
    *   PayTerms Terms to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      Description or error message
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   
   (@payterms bPayTerms = null, @dueoptcheck bYN = null, @discrate bPct output, @msg varchar(60) output)
   as
   
   set nocount on
   declare @rcode int, @dueopt tinyint
   select @rcode = 0
   
   if @payterms is null
   	begin
   	select @msg = 'Missing Payment Terms code!', @rcode = 1
   	goto bspexit
   	end
   
   if @payterms is not null
   	begin
     	select @discrate=DiscRate, @dueopt=DueOpt, @msg = Description from HQPT where PayTerms = @payterms
   
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
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQPayTermsVal] TO [public]
GO
