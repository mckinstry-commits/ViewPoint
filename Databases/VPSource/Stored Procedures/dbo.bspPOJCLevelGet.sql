SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOJCLevelGet    Script Date: 8/28/99 9:35:26 AM ******/
   CREATE      proc [dbo].[bspPOJCLevelGet]
   /********************************************************
   * CREATED BY: 	kf 4/29/97
   * MODIFIED BY:  Dan F 04/12/03 - Add Receipt Expense Interface level.
   *				MV 08/08/03 - #21456 get interface levels from bPORH if
   *					calling form is POReceiptExpInit
   *				DC 10/22/08 - #128052 Remove Committed Cost Flag
   *				GF 06/27/2012 TK-16073 clean up @@rowcount code was left behind but select had been remmed out
   *
   * USAGE:
   * 	Retrieves the CmtdDetailToJC flag from POCO - This flag
   	determines whether JC detail is updated
   *
   * INPUT PARAMETERS:
   *	PO Company number
   *	SOURCE 'R' = receipts batch, 'C' = any other type of batch
   *	MONTH = batch month
   *	BATCHID = batch id #
   *
   * OUTPUT PARAMETERS:
   *	CmtdDetailToJC
   *   RecJCInterfacelvl
   *   RecEMInterfacelvl
   *   RecINInterfacelvl
   *   GLRecExpInterfacelvl
   *   
   *	Error message
   * ReceiptUpdate
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   	(@poco bCompany, @mth bMonth = NULL, @batchid INT = NULL, @source varchar (1) = NULL,
   	 -- @cmtddetailtojc bYN output, DC #128052
   	 @recjclvl varchar(10) output,
   	 @recemlvl varchar(10) output, @recinlvl varchar(10) output, @recgllvl varchar(10) output,
   	 @msg varchar(60) output)
   as 
   
   	set nocount on
   	declare @rcode int,
       @RecJCInterfacelvl int,
       @RecEMInterfacelvl int,
       @RecINInterfacelvl int, 
       @GLRecExpInterfacelvl int,
       @ReceiptUpdate bYN
       
   	SET @rcode = 0
   
   if @poco is null
   	begin
   	select @msg = 'Missing PO Company#', @rcode = 1
   	goto bspexit
   	end
   
   -- get interface levels from PO Receipts 
   if @source = 'R'
   	begin
   	select @RecJCInterfacelvl = RecJCInterfacelvl,
   	    @RecEMInterfacelvl = RecEMInterfacelvl,
   	    @RecINInterfacelvl = RecINInterfacelvl, 
   	    @GLRecExpInterfacelvl = GLRecExpInterfacelvl,
   	    @ReceiptUpdate = ReceiptUpdate
   	 from bPORH WITH (NOLOCK) where Co = @poco and Mth=@mth and BatchId=@batchid
   	----TK-16073
   	if @@rowcount <> 1 
		BEGIN
		select @msg='PO Receipts Initialize Batch does not exist.', @rcode=1  --@cmtddetailtojc='N'  --DC #128052
		GOTO bspexit
		END
   	END
   	
   	/* DC #128052
   	-- get cmtddetailtojc flag
   	select @cmtddetailtojc = CmtdDetailToJC 
   	 from bPOCO WITH (NOLOCK) where POCo = @poco
   	*/
   ----TK-16073
   --	if @@rowcount = 1 
   --	   select @rcode=0
   --	else
   --	   select @msg='PO Company does not exist.', @rcode=1  --@cmtddetailtojc='N'  --DC #128052
   --	end
   --else
   	-- get interface levels from PO Company
   	--begin
   	select --@cmtddetailtojc = CmtdDetailToJC,
   	    @RecJCInterfacelvl = RecJCInterfacelvl,
   	    @RecEMInterfacelvl = RecEMInterfacelvl,
   	    @RecINInterfacelvl = RecINInterfacelvl, 
   	    @GLRecExpInterfacelvl = GLRecExpInterfacelvl,
   	   @ReceiptUpdate = ReceiptUpdate
   	 from bPOCO WITH (NOLOCK) where POCo = @poco
   	----TK-16073
   	if @@rowcount <> 1 
		BEGIN
		select @msg='PO Company does not exist.', @rcode=1 --@cmtddetailtojc='N'  --DC #128052
		END
   
   
   -- Set Interface Level Description for Receipt's   
   select 	@recjclvl = case @RecJCInterfacelvl WHEN 1 THEN 'Detail'
                                  				ELSE 'None' END,
   		@recemlvl = case @RecEMInterfacelvl WHEN 1 THEN  'Detail'
                                  				ELSE 'None' END,
   		@recinlvl = case @RecINInterfacelvl WHEN 1 THEN  'Detail'
                                  				ELSE 'None' END,
   		@recgllvl = case @GLRecExpInterfacelvl WHEN 2 THEN 'Detail'
                              					WHEN 1 THEN 'Summary'
                              					ELSE 'None' END
   
   if @ReceiptUpdate = 'N' select @recjclvl = 'None', @recemlvl= 'None', @recinlvl= 'None', @recgllvl = 'None'
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOJCLevelGet] TO [public]
GO
