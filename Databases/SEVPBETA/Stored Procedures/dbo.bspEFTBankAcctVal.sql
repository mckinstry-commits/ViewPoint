SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    Procedure [dbo].[bspEFTBankAcctVal]
 /***********************************************************
  * CREATED BY: MV 12/11/03 - #22960 and 22961
  *	Modified by: mh 1/1/2006 - #119581.
  *				MV 11/11/08 - #129234 - validate for US	length
  *				MV 12/30/08 - #127222 - validate for CA length
  *
  * USAGE:
  * Validates AP EFT Bank Account Number. For US it can be no longer than
  * 17 digits and can contain nothing but 0-9 and hyphen.
  *
  * INPUT PARAMETERS
  *   @bankacct	DFI Bank Account
  *
  * OUTPUT PARAMETERS
  *   @msg If Error
  * RETURN VALUE
  *   0   success
  *   1   fail
  *****************************************************/
 	(@bankacct char(35) = null,@country varchar(2) = null, @msg varchar(80) = null output)
 as
 
 set nocount on
 
 
 declare @rcode int, @i int, @acctlen int, @a char(1)
 select @rcode = 0

--validate length for US Bank Acct 
if isnull(@country,'') = '' or @country='US'
	begin
	 if len(@bankacct) > 17 
 		begin
 		select @msg = 'Bank Account # cannot be longer than 17 digits.', @rcode = 1
 		goto bspexit
 		end
	end 
--validate length for Canada Bank Acct
if @country='CA'
	begin
	if len(@bankacct) > 12
 		begin
 		select @msg = 'Bank Account # cannot be longer than 12 digits.', @rcode = 1
 		goto bspexit
 		end
	end

 select @i = 1, @acctlen = len(@bankacct)
	while @i <= @acctlen
		begin	
		select @a = substring(@bankacct,@i,1)
	--Issue 119581 - Need to allow alpha characters.  mh 1/2/2006	
	-- 	if (ascii(@a) < 48 and ascii(@a)<> 45) or ascii(@a) > 57 
		if (ascii(@a) < 48 and ascii(@a)<> 45) or (ascii(@a) > 57 and ascii(@a) < 65) or (ascii(@a) > 90 and ascii(@a) < 97) or ascii(@a) > 123
			begin
				--select @msg = 'Invalid character.'''+ @a + ''' Only 0-9 and hyphen are allowed. ', @rcode=1
				select @msg = 'Invalid character.'''+ @a + ''' Only alphas, 0-9 and hyphen characters are allowed. ', @rcode=1
				goto bspexit
			end
		select @i = @i + 1
		end
	
 
 
 bspexit:
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEFTBankAcctVal] TO [public]
GO
