SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   Procedure [dbo].[vspAPUnappReviewCheck]
  /***********************************************************
   * CREATED BY: MV 09/13/06
   * MODIFIED By:	MV 08/07/08 - #129186 return line # for message
   *				MV 11/18/09 - #136259 check for reviewers if current
   *				user is the same as invoice originator 
   *				GF 07/24/2012 TK-16602 expand originator to bVPUserName
   *
   * USAGE:
   * called from APUnappInv, checks that at least one reviewer has been added to
   * the Unapproved Item before closing the form or starting a new header. 
   * 
   * INPUT PARAMETERS
   *   APCo, UIMth, UISeq, Line  

   * OUTPUT PARAMETERS
   *    @msg If Error

   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@apco bCompany = null , @uimth bMonth= null, @uiseq int = null,
  	----TK-16602
  	 @currentuserid bVPUserName,
	 @line int output, @msg varchar(200)output)
  as
  set nocount on
  
  
  declare @rcode int, @opencursor int ,
		  ----TK-16602
		  @invoriginator bVPUserName
  select @rcode = 0, @opencursor = 0, @msg=''
  	

declare vcAPURcheck cursor for
    select Line
    from bAPUL
    where APCo = @apco and UIMth = @uimth and UISeq = @uiseq
    
    /* open cursor */
    open vcAPURcheck
    select @opencursor = 1
    
    APUL_loop:
    	fetch next from vcAPURcheck into @line
    
    	if @@fetch_status <> 0 goto bspexit

	select @invoriginator = InvOriginator 
	from APUL 
	where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line=@line
	If @invoriginator = @currentuserid
		begin
			if not exists(select 1 from APUR where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line=@line)
			begin
			select @rcode = 1
			goto bspexit
			end	  
		end

	goto APUL_loop

  bspexit:
	close vcAPURcheck
    deallocate vcAPURcheck
  	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspAPUnappReviewCheck] TO [public]
GO
