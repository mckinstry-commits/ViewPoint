SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspUtilAPChangeBanks]
   @apco bCompany, @oldaccount bCMAcct, @newaccount bCMAcct, @createbackup bYN,
    @msg varchar(255) = null output
   /*********************************************
    * Created: JE 2/6/02
    * Modified: 
    *
    * Usage:
    *  Changes Bank Accounts on AP Transactions
    *
    * Input:
    *  @apco               ap Co#
    *  @oldacct            old cm account
    *  @newacct            new cm account
    *  @createbackup       if Y then create bAPTH
    *
    * Output:
    *  @msg                Error message
    *
    * Return:
    *  0                   success
    *  1                   error
    *************************************************/
   as
   
   set nocount on
   
   declare @rcode int, @oldcnt int, @newcount int, @SQLString nvarchar(1000),
   	@backuptablename varchar(30)
   select @rcode = 0, @oldcnt =0, @newcount =0, @SQLString=''
   
   /* check APCo */
   if not exists (select APCo from bAPTH where APCo=@apco)
   begin
     select @rcode=0, @msg='No APTH records exist for this company'
     goto bspexit
   end
   
   /* check old account */
   select @oldcnt=count(*) from bAPTH where APCo=@apco and CMAcct=@oldaccount and exists(
   	select * from bAPTD d where bAPTH.APCo=d.APCo and bAPTH.Mth=d.Mth and bAPTH.APTrans=d.APTrans
   	and d.APCo=@apco and d.PaidDate is null) 
   if isnull(@oldcnt,0)=0
   begin
     select @rcode=0, @msg='No APTH records exist for this company and bank account. No update required.'
     goto bspexit
   end
   
   /* check new account */
   if not exists(select h.CMAcct from bAPTH h
     join bCMAC c on c.CMCo=h.CMCo and c.CMAcct=@newaccount
     where h.APCo=@apco and h.CMAcct=@oldaccount)
   begin
     select @rcode=0, @msg='No APTH records exist for this company and bank account. No update required.'
     goto bspexit
   end
   
   /* create backup table */
   select @backuptablename='boldAPTH'+convert(varchar(8),getdate(),112) 
   
   if isnull(@createbackup,'')='Y'
   begin
   select @SQLString =N'if not exists(select name from sysobjects where name="'+@backuptablename+'") select * into '+@backuptablename+' from bAPTH'
   EXECUTE sp_executesql @SQLString
   end
   
   begin tran
   Update bAPTH
   Set CMAcct=@newaccount
   from bAPTH 
   join bAPTD d on bAPTH.APCo=d.APCo and bAPTH.Mth=d.Mth and bAPTH.APTrans=d.APTrans
   where bAPTH.APCo=@apco and bAPTH.CMAcct=@oldaccount and d.APCo=@apco and d.PaidDate is null 
   
   select @newcount=@@rowcount
   
   if @newcount<>@oldcnt 
   begin
   	rollback tran
   	select @rcode=1, @msg='Should update '+convert(varchar(10),@oldcnt)+
      ' rows, only '+convert(varchar(10),@newcount)+' were updated. Rolling back transaction.'
   	goto bspexit
   end
   commit tran
   
   select @msg=convert(varchar(10),@newcount)+' rows were updated'
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspUtilAPChangeBanks] TO [public]
GO
