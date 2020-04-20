SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMStatusCodeVal    Script Date: 8/28/99 9:35:19 AM ******/
   CREATE  proc [dbo].[bspPMStatusCodeVal]
   /*************************************
   * CREATED BY    : SAE  11/9/97
   * LAST MODIFIED : SAE  11/9/97
   *				  GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
   *				DAN SO /06/29/2009 - #134018 - Validate DocCat against form
   *
   *
   * validates PM Firm Types
   *
   * Pass:
   *	PM StatusCode
   *
   * Returns:
   *       CodeType
   *       Status Description
   *
   
   * Success returns:
   *	0 and Description from FirmType
   *
   * Error returns:
   
   *	1 and error message
   *******
   *******************************/
   (@status bStatus, @DocCat VARCHAR(10) = NULL, 
	@codetype varchar(1)=null output, @msg varchar(255) output)
   as
   set nocount on
   
   declare	@ActiveAllYN bYN,
			@TableDocCat VARCHAR(10),
			@rcode int
   
   select @rcode = 0
   
   if @status is null
   	begin
   	select @msg = 'Missing Status!', @rcode = 1
   	goto bspexit
   	end
   
   select @codetype=CodeType, @ActiveAllYN = ActiveAllYN, @TableDocCat = DocCat, @msg = Description 
   from dbo.PMSC with (nolock) where Status = @status
   if @@rowcount = 0
   	begin
   	select @msg = 'PM Status ' + isnull(@status,'') + ' not on file!', @rcode = 1
   	end
   

	--------------------------------------------------------
	-- VERIFY DOCUMENT CATEGORY IS ACTIVE FOR THIS STATUS --
	--------------------------------------------------------
	-- #134018 --
	-------------
	IF @ActiveAllYN = 'N'
		BEGIN
			IF @DocCat <> @TableDocCat
				BEGIN
					SET @msg = 'PM Status ' + isnull(ltrim(rtrim(@status)),'') + ' is not active for Document Category: ' + ISNULL(@DocCat,'') + '. Please review settings in PM Status Codes.'
					SET @rcode = 1
					GOTO bspexit
								
				END
		END
		
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMStatusCodeVal] TO [public]
GO
