SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPOVal    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE  proc [dbo].[vspAPPOItemLineVal]
   /***********************************************************
    * CREATED BY	: 08/29/11	MV - TK-07820 AP Project to use POItemLine
    * MODIFIED BY	: 
    *             
    *
    * USED IN:
    *   APEntry
    *   APUnapprovedEntry
    *
    * USAGE:
    * validates POItemLine.
    *
    * INPUT PARAMETERS
    *   POCo  	PO Co to validate against
    *   PO    	to validate
    *	POItem
    *	POItemLine
    *   Batch      Batch we're currently in
    *   Month      Month of batch
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PO
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
    (@POCo bCompany = 0, @PO varchar(30) = null, @POItem INT, @POItemLine INT,  @BatchMth bMonth=null, @BatchId bBatchID=null,
		@Msg varchar(100) output)
    
   AS
   
   SET NOCOUNT ON
   
   DECLARE @rcode int,
    @InUse bBatchID,
    @InUseMth bMonth,
    @inuseby bVPUserName,
    @Source varchar(10)
       
   select @rcode = 0
   select @InUse = NULL
   
   
   SELECT @InUse=InUseBatchId, @InUseMth=InUseMth
   FROM dbo.vPOItemLine (NOLOCK)
   WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
   IF @@ROWCOUNT=0
   	BEGIN
   	SELECT @Msg = 'PO Item Distribution not on file!', @rcode = 1
   	GOTO bspexit
   	END
   
	IF @BatchId IS NOT NULL
	BEGIN
		IF @InUse IS NOT NULL
		BEGIN   
			IF (@InUse<>@BatchId) OR (@InUseMth <> @BatchMth)
   			SELECT @Source=Source
   			FROM dbo.HQBC (NOLOCK)
   			WHERE Co=@POCo AND Mth=@InUseMth AND BatchId=@InUse 
   			IF @@ROWCOUNT<>0
   			BEGIN
   				SELECT @Msg = 'PO already in use by ' +
   				  CONVERT(VARCHAR(2),DATEPART(month, @InUseMth)) + '/' +
   				  SUBSTRING(CONVERT(VARCHAR(4),DATEPART(year, @InUseMth)),3,4) +
   				' batch # ' + CONVERT(VARCHAR(6),@InUse) + ' - ' + 'Batch Source: ' + @Source, @rcode = 1
   				GOTO bspexit
   			END
   		 END
	 END
	
   
   
   
   bspexit:
   	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspAPPOItemLineVal] TO [public]
GO
