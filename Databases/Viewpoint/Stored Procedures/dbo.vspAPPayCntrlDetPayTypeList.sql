SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPPayCntrlDetPayTypeList]
  /************************************************************************
  * CREATED: 	MV 01/25/07   
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	To return a list of paytypes and descriptions
  *									associated with a Transaction to fill the
  *									PayType ListBox in APPayCntrlDet 
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
          
      (@apco int, @mth bMonth, @aptrans bTrans)
  
  as
  set nocount on
  
    declare @rcode int
    select @rcode = 0
  
Select distinct h.PayType, d.Description 
from bAPTD h join bAPPT d on h.APCo=d.APCo AND h.PayType=d.PayType
   Where h.APCo=@apco AND h.Mth=@mth AND h.APTrans=@aptrans 
  	  	if @@rowcount = 0
		begin
		select @rcode=1
		end

  bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPayCntrlDetPayTypeList] TO [public]
GO
