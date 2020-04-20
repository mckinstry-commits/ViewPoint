SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLWorksheetReadyVal    Script Date: 8/28/99 9:33:43 AM ******/   
CREATE    proc [dbo].[bspSLWorksheetReadyVal]
/***********************************************************
* CREATED BY	: kb 1/23/99
* MODIFIED BY	: kb 2/10/00 added CMRef check
*				  MV 06/08/04 - #24731 - fix error message
*					DC 4/1/09 - #129889 - AUS SL - Track Claimed  and Certified amounts
*					DC 6/29/10 - #135813 - expand subcontract number
*					GF 11/13/2012 TK-19330 SL Claim cleanup
*				
* USAGE:
*
* USED IN:
*
* INPUT PARAMETERS
* 
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0         success
*   1         Failure 
*****************************************************/    
(@co bCompany, @sl VARCHAR(30), --bSL, DC #135813
 @readyyn bYN,  @msg varchar(300) output )
as
set nocount on

DECLARE @rcode int, @inusemth bMonth, @source bSource, @slitem bItem, @inusebatchid bBatchID


SELECT @rcode = 0
   	
IF @readyyn <> 'N' and @readyyn <> 'Y' 
	begin
   	select @msg = 'Ready flag must be (Y or N).', @rcode = 1
   	goto bspexit
   	end
   		

	if @readyyn ='Y'
   		begin
   		SELECT @inusemth = InUseMth, @inusebatchid=InUseBatchId
   		FROM SLHD 
   		WHERE SLCo = @co and SL = @sl 
   		IF @inusemth is not null or @inusebatchid is not null
   			begin
   			select @source = Source 
   			from HQBC 
   			where Co = @co and Mth = @inusemth and BatchId = @inusebatchid   
   			if @@rowcount = 0
   				begin
   				select @msg = 'SL already in use by ' +
   				'another batch.  After posting it is recommended that the subcontract be cleared ' +
   				'from the worksheet and then re-initialized to bring in current values.', @rcode = 1
   				goto bspexit
   				end
   			else
   				begin
   				select @msg = 'SL already in use by ' +
   			      convert(varchar(2),DATEPART(month, @inusemth)) + '/' + 
   			      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) + 
   				' batch #' + convert(varchar(6),@inusebatchid) + ' - ' + 
   				'Batch Source: ' + @source + '.  After posting this batch, it is recommended that the ' +
   				'subcontract be cleared from the worksheet and then re-initialized to bring in current values.', @rcode = 1
   				end
   			END

   		
   		SELECT @slitem = min(i.SLItem), @inusemth = InUseMth, @inusebatchid=InUseBatchId 
   		FROM SLIT i 
   		join SLWI w on i.SLCo = w.SLCo and i.SL = w.SL and 
   			i.SLItem = w.SLItem where i.SLCo = @co and i.SL = @sl and InUseMth is not null and InUseBatchId is not null
   		group by InUseMth, InUseBatchId
   		if @slitem is not null
   			begin
   			if @inusemth is not null or @inusebatchid is not null
   				begin
   				select @source = Source from HQBC where Co = @co and Mth = @inusemth and 
   					BatchId = @inusebatchid
   				if @@rowcount = 0
   					begin
   					select @msg = 'SL Item:' + convert(varchar(10),@slitem) + ' already in use by ' +
   					'another batch.  After posting this batch it is recommended that the ' +
   					'subcontract be cleared from the worksheet and then re-initialized to bring in current values.', @rcode = 1
   					goto bspexit
   					end
   				else
   					begin
   					select @msg = 'SL Item:' + convert(varchar(10),@slitem) + ' already in use by ' +
   				      convert(varchar(2),DATEPART(month, @inusemth)) + '/' + 
   				      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) + 
   					' batch #' + convert(varchar(6),@inusebatchid) + ' - ' + 
   					'Batch Source: ' + @source + '. After posting this batch, it is recommended that the' +
   					' subcontract be cleared from the worksheet and then re-initialized to bring in current values.', @rcode = 1
   					end
   				end
   			end	
   		end	



bspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspSLWorksheetReadyVal] TO [public]
GO
