SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLRefVal_GLJE    Script Date: 1/20/2004 8:17:44 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspGLRefVal_GLJE    Script Date: 1/9/2004 12:14:07 PM ******/
   
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
    /****** Object:  Stored Procedure dbo.bspGLRefVal    Script Date: 8/28/99 9:34:46 AM ******/
    CREATE     proc [dbo].[bspGLRefVal_GLJE]
    /**************************************************************
     * Created: DC 5/15/03 #20464 - Description no longer defaults from GL Journal Reference description
     * Modified: DC 1/20/2004  #23545 - Default on description - doesn't default to previous if in GLRef
     *
     * Usage:
     *  Called from GLJE.  References
     *  may be setup in bGLRF prior to posting journal entries, or they will
     *  be added via the bGLAS insert trigger.
     *
     * Input:
     *  @glco       GL Co#
     *  @mth        Month
     *  @jrnl       Journal
     *  @adjust     Adjustment period - Y or N
     *
     * Output:
     *  @msg        Reference description or errro message
     *
     * Return code:
     *  @rcode      0 = success, 1 = error
     ************************************************************/
        (@glco bCompany = null, @mth bMonth = null, @jrnl bJrnl = null, @ref bGLRef= null,
    	 @adjust bYN, @batchid bBatchID, @seq int, @msg varchar(60) output)
    as
    set nocount on
    
    declare @rcode int, @adj bYN
   
    select @rcode = 0, @msg = null
    
    if @glco is null
    	begin
    	select @msg = 'Missing GL Company!', @rcode = 1
    	goto bspexit
    	end
    if @mth is null
    	begin
    	select @msg = 'Mising Month!', @rcode = 1
        	goto bspexit
    	end
    if @jrnl is null
    	begin
    	select @msg = 'Missing Journal!', @rcode = 1
    	goto bspexit
    	end
    if @ref is null
    	begin
    	select @msg = 'Missing GL Reference!', @rcode = 1
    	goto bspexit
    	end
    if @batchid is null
    	begin
    	select @msg = 'Missing Batch ID!', @rcode = 1
    	goto bspexit
    	end 
    if @seq is null
    	begin
    	select @msg = 'Missing Batch ID!', @rcode = 1
    	goto bspexit
    	end 
   
    -- We only want to get the description if the user just entered the same Ref #  If they are not continuing 
   -- the same reference number then we want to start the process of getting the description over.
    select @seq = @seq - 1
   
    select @msg = isnull(Description,'')
    from bGLDB WITH (NOLOCK)
    where Co = @glco and @mth = Mth and @jrnl = Jrnl and @ref = GLRef AND @batchid = BatchId and @seq = BatchSeq
    if @@rowcount = 0 --DC Issue 20464  Get Description from GLRF
    	BEGIN
    	select @msg = isnull(Description,''), @adj = Adjust
    	from bGLRF WITH (NOLOCK)
   	where GLCo = @glco and @mth = Mth and @jrnl = Jrnl and @ref = GLRef
    	IF @@rowcount = 0 
   		BEGIN
   		goto bspexit  -- return 0 if Reference not on file
   		END
   	ELSE
    		BEGIN
   	 	if @adj <> @adjust
    			begin
    			select @msg = 'Reference exists and the adjustment flags don''t match.', @rcode = 1
   	 		end
    		END
   
    	END
   
    select @adj = isnull(Adjust,'')
    from bGLRF WITH (NOLOCK)
    where GLCo = @glco and @mth = Mth and @jrnl = Jrnl and @ref = GLRef
    IF @@rowcount > 0 
    BEGIN
    	if @adj <> @adjust
   		begin
   		select @msg = 'Reference exists and the adjustment flags don''t match.', @rcode = 1
   		end
    END
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLRefVal_GLJE] TO [public]
GO
