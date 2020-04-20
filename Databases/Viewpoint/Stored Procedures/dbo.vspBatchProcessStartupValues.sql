SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPVendorGrpGet    Script Date: 8/28/99 9:34:06 AM ******/
CREATE  proc dbo.vspBatchProcessStartupValues
  /********************************************************
  * CREATED BY: 	kb 6/23/4
  * MODIFIED BY:	
  *
  * USAGE:
  * 	This routine is called when the SL Entry form is loaded up and retrieves 
	various values used for that form 
  *
  * INPUT PARAMETERS:
  *	AP Company number
  *
  * OUTPUT PARAMETERS:
  *	Vendor Group from bHQCO
  *	Error message
  *
  * RETURN VALUE:
  * 	0 	    Success
  *	1 & message Failure
  *
  **********************************************************/
  
  	(@co bCompany = 0, @mth bMonth, @batchid bBatchID, @source varchar(20) output, 
	@tablename varchar(20) output, @datecreated bDate output, @createdby varchar(20) output, 
	@cmtddetailtojc bYN output, @status tinyint output, @dateposted bDate output, 
	@msg varchar(60) output)
  as 
  
  	set nocount on
  	declare @rcode int
  	select @rcode = 0
  	
  if @co= 0
  	begin
  	select @msg = 'Missing Company#', @rcode = 1
  	goto bspexit
  	end

SELECT @source = Source, @tablename = TableName, @datecreated = DateCreated, 
  @createdby = CreatedBy, @status = Status, @dateposted =DatePosted 
  FROM HQBC WHERE Co = @co AND Mth = @mth AND BatchId = @batchid
  
if @source = 'SL Entry'
	begin
	select @cmtddetailtojc = CmtdDetailToJC from bSLCO where SLCo = @co
	if @@rowcount = 1 
		select @rcode=0
	else
		select @msg='SL Company does not exist.', @rcode=1, @cmtddetailtojc='N'
		goto bspexit
  
  	end
  bspexit:

  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspBatchProcessStartupValues] TO [public]
GO
