SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspAPBeginCheckDflt]
  /***********************************************************
  * CREATED: SE 10/2/97
  * MODIFIED: kb 3/19/99
  *           GG 03/27/00 - fixed CMRef conversion, removed numeric check of rightmost char in CMRef
  *	      	GH 10/11/00 - added datalength check to only look at check numbers below 10 digits, to avoid numeric to int conversion error
  *			kb 8/12/2 - issue #18262 - needs to check CMDT too when getting default check #
  * 			MV 9/23/02 - #18262 rej1 fix - limit CMDT to TransType = 1, remove 9 digit limitation
  *			MV 10/18/02 - 18878 quoted identifier cleanup
  *			GG 12/10/02 - #19608 - remove bCMDT lookup, caused problems with shared CM Accounts
  *			MV 02/18/03 - #20373 - if max check # reached, don't add 1, return max #
  *			MV 07/13/05 - #29137 - eliminate voided check numbers from starting chck number.
  *			MV 11/05/07 - #126072 - ltrim leading spaces from CMRef for comparison with @begcheck
  * USAGE:
  *   Called from AP Check Print form to provide a beginning
  *   check number default.  Gets max check # from bAPPB and bAPPD
  *   and adds one.
  *
  * INPUT PARAMETERS
  *   @cmco        CM Company
  *   @cmacct      CM Account
  *
  * OUTPUT PARAMETERS
  *   @begcheck    Beginning check number to be used
  *   @msg         Error message
  *
  * RETURN VALUE
  *   0         success
  *   1         failure
  *****************************************************/
  
        (@cmco bCompany, @cmacct bCMAcct, @begcheck bigint output, @msg varchar(255) output)
  as
  
  set nocount on
  
  declare @rcode int, @check1 bigint, @check2 bigint, @checkused int
  
  select @check1 = 0, @check2 = 0, @rcode = 0, @msg = 'Error finding check numbers.'
  
  -- AP Payment Batch
  select @check1=isnull(max(convert(numeric,CMRef)),0)
  from bAPPB
  where PayMethod='C' and CMCo = @cmco and CMAcct = @cmacct and isNumeric(CMRef) = 1
  	--and (VoidYN='N' or (VoidYN='Y' and ReuseYN='Y'))
  
  -- AP Payment Detail
	select @check2=isnull(max(convert(numeric,CMRef)),0)
    from APPH where PayMethod='C' and CMCo = @cmco and CMAcct=@cmacct and isNumeric(CMRef) = 1 

  -- select @check2=isnull(max(convert(numeric,d.CMRef)),0)
  --  from APPD d join APPH h on d.APCo=h.APCo and d.CMCo=h.CMCo and d.CMAcct=h.CMAcct and d.PayMethod=h.PayMethod
  -- 	 and d.CMRef=h.CMRef and d.CMRefSeq=h.CMRefSeq
  --  where d.PayMethod='C' and d.CMCo = @cmco and d.CMAcct=@cmacct and isNumeric(d.CMRef) = 1 and h.VoidYN='N'
   -- select @check2=isnull(max(convert(numeric,CMRef)),0)
   -- from bAPPD
   -- where PayMethod='C' and CMCo = @cmco and CMAcct=@cmacct and isNumeric(CMRef) = 1 
   
  
  select @begcheck = @check1
  if @check2 > @begcheck 
 	begin
 	select @begcheck = @check2
 	select @checkused=2
 	end
  else
 	begin
 	select @checkused=1
 	end
  
 -- loop until incremented check# is not a voided check --#29137
 Check_Increment:
  if @begcheck < 9999999999	--#20373
  	begin
 	 select @begcheck = @begcheck + 1
 	 if @checkused = 1
 		begin
 		if exists (select 1 from bAPPB where PayMethod='C' and CMCo = @cmco 
 			and CMAcct = @cmacct and ltrim(CMRef)=convert(varchar(10),@begcheck)  and (VoidYN='Y' and ReuseYN='N'))
 			goto Check_Increment
 		end 
 	 if @checkused = 2
 		begin
 		if exists ( select 1 from bAPPH where PayMethod='C' and CMCo = @cmco
 			and CMAcct=@cmacct and ltrim(CMRef) = convert(varchar(10),@begcheck) and VoidYN='Y')
 			goto Check_Increment
 		end
  	end
   else
 	begin
 	select @msg = 'All available starting check numbers have been voided and cannot be used.',@rcode=1
 	end
  
  return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPBeginCheckDflt] TO [public]
GO
