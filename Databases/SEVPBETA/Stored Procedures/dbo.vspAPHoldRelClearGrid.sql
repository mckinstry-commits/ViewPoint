SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPHoldRelClearGrid]
/***********************************************************
* CREATED: MV 02/23/10 - #136500 
* MODIFIED: 
*
* USAGE:
* Clears all transaction detail in APHR 
* 
*  INPUT PARAMETERS
*   @apco	AP company number
*	@userid user login
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************/
	(@apco bCompany = 0,@userid bVPUserName, @DeleteAll bYN, @Mth bMonth = null, @APTrans int = null,
	 @APLine int = null, @APSeq int = null, @msg varchar(200) output)
          
as
set nocount on

declare @rcode int
select @rcode = 0

if @DeleteAll = 'N'
	begin
	if @Mth <> '' and @APTrans is not null and @APLine is not null and @APSeq is not null
		begin
		delete from APHR where APCo=@apco and UserId=@userid and @Mth=Mth and APTrans=@APTrans
		 and APLine=@APLine and APSeq=@APSeq
		if @@rowcount = 0
			begin
			select @msg = 'Error occurred while trying to delete from the Selection Display Grid.', @rcode=1
			goto vspExit
			end
		end
	end
if @DeleteAll = 'Y'
	begin
	--Delete transaction detail from APHR.
	Delete from APHR 
	where APCo=@apco and UserId=@userid
	end



vspExit:
	return @rcode


      


GO
GRANT EXECUTE ON  [dbo].[vspAPHoldRelClearGrid] TO [public]
GO
