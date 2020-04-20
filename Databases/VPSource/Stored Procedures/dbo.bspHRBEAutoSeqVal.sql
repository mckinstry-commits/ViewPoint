SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRBEAutoSeqVal]
   /************************************************************************
   * CREATED:	mh 10/4/01    
   * MODIFIED:    
   *
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@autoearnseq int, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @autoearnseq is null
   		select @msg = 'Auto Earning Sequence required.', @rcode = 1
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBEAutoSeqVal] TO [public]
GO
