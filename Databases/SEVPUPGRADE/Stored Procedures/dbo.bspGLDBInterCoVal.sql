SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspGLDBInterCoVal]
    
      /***********************************************************
       * CREATED BY:    sr 08/07/02
       * MODIFIED By :	MV 01/31/03 - #20246 dbl quote cleanup.  
       *
       * USAGE:
       *
       *	Make sure that there are valid GLIA and GLRF records for intercompany Jrnl Entries
       *
       * INPUT PARAMETERS
       *	@ARGLCo			GL Company batch is being posted from - Recievable (Co in GLDB)
       *	@APGLCo			GL Company batch is being posted to - Payable (InterCo in GLDB)
       *	@batchmth		Month batch is in
       *	@jrnl			Journal
       *	@ref			GL Reference
       *
       *
       * OUTPUT PARAMETERS
       *	APGLAcct 	APGLAcct
       *	Debit		
       *	Source
        **********************************************************/
    
      (@co bCompany, @batchmth bMonth, @jrnl bJrnl, @ref bGLRef, @interco bCompany, 
    	@errmsg varchar(255) output)
    
    
      as
      set nocount on
      
     declare @rcode int, @lastglmth bMonth, @lastsubmth bMonth, @fy bMonth, @adj bYN, @maxopen tinyint, @unbal bYN
    
      select @rcode = 0
    
      if @co is null
      	begin
      	select @errmsg = 'Missing GL Company!', @rcode = 1
      	goto bspexit
      	end
    
      if @batchmth is null
    	begin
      	select @errmsg = 'Missing Batch Month!', @rcode = 1
      	goto bspexit
      	end 
    
      if @interco is null
      	begin
      	select @errmsg = 'Missing GL Inter Company!', @rcode = 1
      	goto bspexit
      	end
    
    /* validate GL Company and Month */
      select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
      	 from bGLCO where GLCo = @interco
      if @@rowcount = 0
      	begin
      	select @errmsg = 'Invalid GL Company', @rcode = 1
      	goto bspexit
      	end
      if @batchmth <= @lastglmth or @batchmth > dateadd(month, @maxopen, @lastsubmth)
      	begin
      	select @errmsg = 'Not an open month', @rcode = 1
      	goto bspexit
      	end
     
      /* validate Fiscal Year */
      select @fy = FYEMO from bGLFY
      	where GLCo = @interco and @batchmth >= BeginMth and @batchmth <= FYEMO
      if @@rowcount = 0
      	begin
      	select @errmsg = 'Must first add Fiscal Year for To Company', @rcode = 1
      	goto bspexit
      	end
     
      if @adj = 'Y' and @batchmth <> @fy
      	begin
      	select @errmsg = 'Adjustment entries must be made in a Fiscal Year ending month', @rcode = 1
      	goto bspexit
      	end
    
    
    
    If @co<>@interco
    begin
    select @co=ARGLCo from GLIA where ARGLCo=@co and APGLCo=@interco
    if @@rowcount = 0
    	begin
    		select @errmsg = 'An intercompany account is not setup for company ' + convert(varchar(10),@interco)
    			+ ' within company ' + convert(varchar(10),@co), @rcode = 1
    		goto bspexit
    	end
    select @interco=ARGLCo from GLIA where ARGLCo=@interco and APGLCo=@co
    if @@rowcount = 0
    	begin
    		select @errmsg = 'An intercompany account is not setup for company ' + convert(varchar(10),@co)
    			+ ' within company ' + convert(varchar(10),@interco), @rcode = 1
    		goto bspexit
    	end
    end
    
    
    bspexit:
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLDBInterCoVal] TO [public]
GO
