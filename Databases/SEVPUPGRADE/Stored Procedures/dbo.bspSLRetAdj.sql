SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLRetAdj    Script Date: 8/28/99 9:33:41 AM ******/
   CREATE  proc [dbo].[bspSLRetAdj]         
   /***********************************************************
    * CREATED BY: kf 6/14/97
    * MODIFIED By : kf 6/14/97
    *				DC 6/25/10 - #135813 - expand subcontract number
   *
    *
    * USAGE:
    * updates SLWI WC Retainage % and/or Stored Materials Retainage Pct
    * an error is returned if any goes wrong.             
    * 
    *  INPUT PARAMETERS
    *   @jcco	|_Only subcontracts assigned to this jcco
    *   @job	| and job will be affected
    *
    *   @beginsl   |_Only SL's in this range will be 
    *   @endsl	| update
    *
    *   @allsubs   - If Y then set begin/endsl's to include all
    *   @rettype   - If W then only update WCRetPct, If S then only
    *		  update SMRetPct. If B then do both
    *
    *   @allitems  - If 'Y' then update all items specified above. 
    * 		  else restrict based on their retainage pct
    *
    *   @retpct    - If @allitems is 'N' then the rettype % must equal this
    *		  to be updated
    *
    *   @newretpct - This is the new ret pct that you are updating to.
    *
    * OUTPUT PARAMETERS
    *   @rowsaffected - Number of SL items affected
    *   @msg      error message if error occurs 
    * RETURN VALUE
    *   0         success
    *   1         Failure
    **************************************************************************/ 
   (@slco bCompany, @jcco bCompany, @job bJob, 
   @beginsl VARCHAR(30), --bSL,  DC #135813
   @endsl VARCHAR(30), --bSL,  DC #135813
   	@allsubs bYN, @rettype char(1), @allitems bYN, @retpct bPct, 
   	@newretpct bPct, @rowsaffected int output, @msg varchar(90) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rowsaffected=0
   
   if @allsubs='Y' 
   	begin
   	select @endsl='~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'  --DC #135813
   	select @beginsl=''
   	end
      
   select @rcode=0 	, @msg='No SLs meet this criteria for JC Co#' + convert(varchar(3),@jcco)
   			 + ' and Job ' + @job + '.'
   
   if @allitems='N'
   	begin
   	if @rettype='W'
   		begin
   		update SLIT set SLIT.WCRetPct=@newretpct from SLIT a, SLHD b where b.SLCo=a.SLCo and 
   			b.SL=a.SL and b.JCCo=@jcco and b.Job=@job and a.SL>=@beginsl and a.SL<=@endsl and 
   			a.WCRetPct=@retpct
   		select @rowsaffected=@@rowcount
   		end
   	if @rettype='S'
   		begin
   		update SLIT set SLIT.SMRetPct=@newretpct from SLIT a, SLHD b where b.SLCo=a.SLCo and 
   			b.SL=a.SL and b.JCCo=@jcco and b.Job=@job and a.SL>=@beginsl and a.SL<=@endsl and 
   			a.SMRetPct=@retpct
   		select @rowsaffected=@@rowcount
   
   		end
   	if @rettype='B' 
   
   		begin
   		update SLIT set SLIT.WCRetPct=@newretpct, SLIT.SMRetPct=@newretpct from SLIT a, SLHD b 
   			where b.SLCo=a.SLCo and b.SL=a.SL and b.JCCo=@jcco and b.Job=@job and 
   			a.SL>=@beginsl and a.SL<=@endsl and a.WCRetPct=@retpct and a.SMRetPct=@retpct
   		select @rowsaffected=@@rowcount
   		end
   	end
   else
   	begin
   	if @rettype='W'
   		begin
   		update SLIT set SLIT.WCRetPct=@newretpct from SLIT a, SLHD b where b.SLCo=a.SLCo and 
   			b.SL=a.SL and b.JCCo=@jcco and b.Job=@job and a.SL>=@beginsl and a.SL<=@endsl 
   
   		select @rowsaffected=@@rowcount
   		end
   	if @rettype='S'
   		begin
   		update SLIT set SLIT.SMRetPct=@newretpct from SLIT a, SLHD b where b.SLCo=a.SLCo and 
   			b.SL=a.SL and b.JCCo=@jcco and b.Job=@job and a.SL>=@beginsl and a.SL<=@endsl 
   		select @rowsaffected=@@rowcount
   		end
   	if @rettype='B' 
   		begin
   		update SLIT set SLIT.WCRetPct=@newretpct, SLIT.SMRetPct=@newretpct from SLIT a, SLHD b 
   			where b.SLCo=a.SLCo and b.SL=a.SL and b.JCCo=@jcco and b.Job=@job and 
   			a.SL>=@beginsl and a.SL<=@endsl
   		select @rowsaffected=@@rowcount
   		end
   	/*select @rcode=1, @msg='hi there  -' + @rettype
   		goto bspexit*/
   	end
   
   if @rowsaffected=0 goto bspexit
   
   select @msg=null, @rcode=0
   
   bspexit:
   
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLRetAdj] TO [public]
GO
