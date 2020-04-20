SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspAPSeqValForAPWD]
   /***********************************************************
    * CREATED BY: MV 11/28/01
    * MODIFIED By:	 kb 10/29/2 - issue #18878 - fix double quotes
    *				MV 01/03/07 - #28268 6X recode - remove @desc
	*				MV 01/09/07 - #122337 - return LineType from APTL
    *
    * USAGE:
    * Validates AP Seq # for AP Workfile Detail.
    *
    * INPUT PARAMETERS
    *   @apco	AP Company
    *   @mth	Month for transaction
    *   @aptrans	AP Transaction
    *   @apline	AP Line number
    *   @apseq
    *
    * OUTPUT PARAMETERS
    *   @holdyn	hold code
    *   @payyn     Y if status = 1, N if status > 1
    *   @discoffered  discount offered
    *   @disctaken    discount taken, if any
    *   @duedate   date payment is due
    *   @supplier  Supplier, if any
    *   @msg 	If Error, return error message.
    * RETURN VALUE
    *   0   success
    *   1   fail
    ****************************************************************************************/
    (@apco bCompany, @mth bDate, @aptrans bTrans, @apline int,@apseq int,
   	@payyn bYN output,@paytype tinyint output,@jcco tinyint output,@job bJob output,
   	@amount bDollar output,@discoffered bDollar output,@disctaken bDollar output,
   	@duedate bDate output,@supplier bVendor output, @holdyn bYN output, @linetype int output,
	@compliedyn bYN output, @msg varchar(90) output)
   as
   
   set nocount on
   
   declare @rcode int, @status int,@DontAllowPaySL bYN, @DontAllowPayPO bYN,
	@DontAllowPayAllinv bYN, @userid varchar (30)
   
   select @rcode = 0
   
   if @apco = 0
   	begin
   	select @msg = 'Missing AP Company#', @rcode=1
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @msg = 'Missing Expense Month' , @rcode=1
   	goto bspexit
   	end
   if @aptrans = 0
   	begin
   	select @msg = 'Missing AP Trans #', @rcode=1
   	goto bspexit
   	end
   
   if @apline = 0
   	begin
   	select @msg = 'Missing AP Line #', @rcode=1
   	goto bspexit
   	end
   if @apseq = 0
   	begin
   	select @msg = 'Missing AP seq #', @rcode=1
   	goto bspexit
   	end
   
   /* validate seq # */
   select @status = Status from APTD where APCo = @apco and Mth = @mth and APTrans = @aptrans
     and APLine = @apline and APSeq = @apseq
   if @@rowcount = 0
       begin
       select @msg = 'Invalid sequence!', @rcode=1
       goto bspexit
       end
   
   if @status > 2 
   	begin
   	select @msg = 'Sequence status is not open or on hold!', @rcode=1
   	goto bspexit
   	end
   
   /* get values to return */
   select distinct @msg=l.Description,@paytype=d.PayType,@jcco=l.JCCo,@job=l.Job,@amount=d.Amount,
   	@duedate=DueDate, @supplier=d.Supplier,@discoffered=DiscOffer, @disctaken=DiscTaken,@status=d.Status,
	@linetype = l.LineType
   	from APTL l join APTD d ON l.APCo=d.APCo and l.Mth=d.Mth and l.APTrans=d.APTrans and l.APLine=d.APLine
   	where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.APLine=@apline and d.APSeq=@apseq
   
	--set payyn flag and holdyn based on hold status
	if @status=1 select @payyn='Y',@holdyn='N'
	if @status=2 select @payyn='N', @holdyn='Y'
	
	--get apco flags for setting payyn
	select @DontAllowPaySL = SLAllowPayYN, @DontAllowPayPO = POAllowPayYN, @DontAllowPayAllinv=AllAllowPayYN
	from APCO with (nolock) where APCo = @apco
	--get userid
	select @userid=UserId from APWH with (nolock) where APCo=@apco and Mth=@mth and APTrans=@aptrans
	-- set complied flag
	select @compliedyn = 'Y'
	select @compliedyn = dbo.vfAPWDCompliedYN(@apco,@mth,@aptrans,@userid,@apline)
	-- set payyn flag based on complied status
	if (@compliedyn = 'N' and (@linetype <> 6 and @linetype<>7 ) and @DontAllowPayAllinv = 'Y') or
		(@compliedyn = 'N' and @linetype = 6 and @DontAllowPayPO = 'Y') or
		(@compliedyn = 'N' and @linetype = 7 and @DontAllowPaySL = 'Y')
		begin
		select @payyn='N'
		end
		
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPSeqValForAPWD] TO [public]
GO
