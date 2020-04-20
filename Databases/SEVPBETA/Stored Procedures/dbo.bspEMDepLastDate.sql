SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspEMDepLastDate]
   /*******************************************************
   *	Created: TV 03/13/05 26995 - We set the EMCO.DeprLstMnthCalc value even if batch is cleared
   *
   *	modified:
   *
   *	purpose: To reset the DeprLstMnthCalc in bEMCO when Depr  
   *				Batch is cleared.
   *
   *	inputs: 	EMCo 
   *				Mth
   *				BatchID
   *
   *	outputs: errmsg
   *
   *********************************************************/
   (@co bCompany, @mth bMonth, @batchid Int, @errmsg Varchar(255) output)
   
   as
   
   Set nocount on
   
   declare @rcode int, @lastcalcdate bMonth
   
   select @rcode = 0 
   
   If isnull(@co,'') = ''
   	begin 
   	select @errmsg = 'Missing EM Company.', @rcode = 1 
   	goto bspexit
   	end
   
   If isnull(@mth,'') = ''
   	begin 
   	select @errmsg = 'Missing Batch Month.', @rcode = 1 
   	goto bspexit
   	end
   
   If isnull(@batchid,'') = ''
   	begin 
   	select @errmsg = 'Missing Batch ID.', @rcode = 1 
   	goto bspexit
   	end
   
   --Update the Last Date that Depr. was taken in EMCo.
   update bEMCO 
   Set DeprLstMnthCalc = (select max(Month)from bEMDS with (nolock) where EMCo = @co and AmtTaken <> 0)
   where EMCo = @co
   
   
   bspexit:
   
   if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMDepLastDate]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMDepLastDate] TO [public]
GO
