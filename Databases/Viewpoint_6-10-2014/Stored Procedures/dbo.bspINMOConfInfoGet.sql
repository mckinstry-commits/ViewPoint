SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       Proc [dbo].[bspINMOConfInfoGet]
    /*************************************************
    	Created: 04/25/02 RM
       Modified: 08/07/02 RM - Removed BatchSeq parameter, as its not needed or used.
     Modified: 02/21/07 TRL - Added INLM.Description to final select statement.
	 Modified: 10/09/07 TRL - Added colmun when Remain Units are positive.

    	Usage: Gets info to display in display-only fields on MOEntry Form
    
    	Input:
    		@co			IN Company
    		@mo			Material Order
    		@moitem 	Material Order Item
    	
    	Output:
    		@msg		Error message if any
    		@rcode		Return Code, 1 if error, 0 if success
    		
    		Returns Recordset
    *************************************************/
    ( @co tinyint = null,@mo varchar(20)  = null,@moitem int = null, @msg varchar(255) output) 
    as
    
declare @rcode int , @confirmed bUnits,@remain bUnits, @remainADD bUnits
   
select @rcode = 0, @confirmed=0, @remain=0, @remainADD=0

If IsNull(@co,0)=0
begin
   	select @msg = 'Missing IN Company.',@rcode = 1
   	goto bspexit
end
   
if IsNull(@mo,'') = ''
begin
   	select @msg = 'Missing MO.',@rcode = 1
   	goto bspexit
end
   
If IsNull(@moitem,0)= 0 
begin
   	select @msg = 'Missing MO Item.',@rcode = 1
   	goto bspexit
end

Begin
Select @confirmed=isnull(sum(ConfirmUnits),0),
	   --@remain=isnull(sum(RemainUnits),0)
	   @remain=isnull(sum(case When RemainUnits <= 0 then RemainUnits else (-1 * ConfirmUnits) end),0),
	   @remainADD=isnull(sum(case When RemainUnits > 0 then RemainUnits else 0 end),0)
from dbo.INCB with(nolock) 
where MO=@mo and MOItem = @moitem and Co=@co and BatchTransType In ('A','C')--<>'D'
End

Begin
select @confirmed = @confirmed - isnull(sum(ConfirmUnits),0),
   	   @remain = @remain - isnull(sum(RemainUnits),0)
from dbo.INCB with(nolock) 
where INTrans in (select INTrans from INCB where Co=@co and MO=@mo and MOItem=@moitem and BatchTransType = 'D')--<>'A')
End
   

select OrderedUnits,
	   @confirmed + ConfirmedUnits as ConfirmUnits,
	   @remain + RemainUnits as RemainUnits,
	   @remainADD as RemainAddUnits,
   UnitPrice,ECM,TotalPrice,TaxAmt,
   INMI.Description,INMI.Loc,INMI.JCCo,INMI.Job,Phase,JCCType,INMI.TaxCode,case isnull(TotalPrice,0) when 0 then 0 else (isnull(TaxAmt,0)/TotalPrice) end as TaxRate,
   (@confirmed + ConfirmedUnits + @remain + RemainUnits + @remainADD) as TotalUnits
from dbo.INMI with(nolock)
where MO=@mo and MOItem=@moitem and INMI.INCo=@co
If @@rowcount = 0
begin
   	select @msg = 'Missing MO Item in INMI.',@rcode = 1
   	goto bspexit
end
    
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOConfInfoGet] TO [public]
GO
