SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMCreateBatch    Script Date: 6/7/2002 11:26:37 AM ******/
   
   CREATE    procedure [dbo].[bspIMCreateBatch]
   
   /**************************************************
   *
   *Created By     :MH 10/4/99
   *Modified By    :RT 05/16/03 - Added "OUTPUT" keyword to bspHQBCInsert call so error
   *					message can be returned.  Changed @batchid to be output variable, and
   *					changed procedure to return 0 for success and 1 for failure.
   *	          DANF 12/21/04 - Issue #26577: Changed reference from DDFH to DDFH
   *
   *USAGE:
   *
   *Create batches required by Import routines
   *
   *INPUT PARAMETERS
   * Company, Month, ImportForm, Source, Restrict, Adjust, PRGroup, PREndDate
   *
   *RETURN PARAMETERS
   *
   * Error Message
   *
   *None
   *
   *************************************************/
   
   --Params
   
       (@co bCompany, @mth bMonth, @importform varchar(30), @source varchar(10),
       @restrict bYN, @adjust bYN, @prgroup bGroup,  @prenddate bDate, 
       @batchid int output, @errmsg varchar(255) output)
   
   as 
   
   set nocount on
   
   --Locals
   declare @formtype int, @tablename varchar(20), @rc int
   
   select @rc = 0
   
   if @co is null
       begin
       select @errmsg = 'Missing Company', @rc = 1
       goto bspexit
       end
   
   if @mth is null
       begin 
       select @errmsg = 'Missing Month', @rc = 1
       goto bspexit
       end
   
   if @importform is null
       begin
       select @errmsg = 'Missing Import Form', @rc = 1
       goto bspexit
       end
   
   if @source is null
       begin 
       select @errmsg = 'Missing Source', @rc = 1
       goto bspexit
       end
   
   --Verify batch is required
   select @formtype = FormType, @tablename = ViewName from dbo.vDDFH where Form = @importform
   
   if @@rowcount <> 1
       begin
       select @rc = 1
       --could not find in DDFH or this is not a batch form.  Exit with error
       end
   
   exec @batchid = bspHQBCInsert @co, @mth, @source, @tablename, @restrict, @adjust, @prgroup, @prenddate, @errmsg output
   
   if @batchid = 0
       begin
       select @errmsg = 'Could not create batch', @rc = 1
       goto bspexit
       end
   else
       begin
       select @rc = 0
       goto bspexit
       end
   
   bspexit:
   
       return @rc

GO
GRANT EXECUTE ON  [dbo].[bspIMCreateBatch] TO [public]
GO
