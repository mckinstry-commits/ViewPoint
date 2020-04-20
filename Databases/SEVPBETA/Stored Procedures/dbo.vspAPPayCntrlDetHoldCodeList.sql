SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPPayCntrlDetHoldCodeList]
  /************************************************************************
  * CREATED: 	MV 01/25/07   
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	To return a list of Hold codes
  *									associated with a Transaction to fill the
  *									Assigned and Unassigned HoldCodes list boxes
  *									in APPayCntrlDet 
  * @level = 'E' entire transaction or 'S'selected line and seq
  * @assign = 'A' assigned holdcodes or 'U' unassigned holdcodes 
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
          
      (@apco int, @mth bMonth, @aptrans bTrans, @line int = null, @seq int = null,@level varchar(1),
		@assigned varchar(1))
  
  as
  set nocount on
  
    declare @rcode int
    select @rcode = 0
-- Select entire transacation  
if @level='E'
	begin
		-- select assigned holdcodes
		if @assigned = 'A'
			begin
			Select distinct h.HoldCode, d.Description from bAPHD h
			   join bHQHC d on h.HoldCode=d.HoldCode
			   Where h.APCo=@apco AND h.Mth=@mth AND h.APTrans=@aptrans 
			end
		-- select unassigned holdcodes
		if @assigned = 'U'
			begin
			Select HoldCode, Description From bHQHC 
			Where HoldCode not in (Select h.HoldCode 
						from bAPHD h join bHQHC d on h.HoldCode=d.HoldCode
						Where h.APCo=@apco AND h.Mth=@mth AND h.APTrans=@aptrans)
			end
	end
-- Select by line and seq 
if @level='S'
	begin
		-- select assigned holdcodes
		if @assigned = 'A'
			begin
			Select distinct h.HoldCode, d.Description from bAPHD h
			   join bHQHC d on h.HoldCode=d.HoldCode
			   Where h.APCo=@apco AND h.Mth=@mth AND 
				h.APTrans=@aptrans and h.APLine=@line and h.APSeq=@seq 
			end
		--select unassigned holdcodes
		if @assigned = 'U'
			begin
			Select HoldCode, Description From bHQHC 
			Where HoldCode not in (Select h.HoldCode 
						from bAPHD h join bHQHC d on h.HoldCode=d.HoldCode
						Where h.APCo=@apco AND h.Mth=@mth AND h.APTrans=@aptrans
						 AND h.APLine=@line AND h.APSeq=@seq)
			end
	end

  bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPayCntrlDetHoldCodeList] TO [public]
GO
