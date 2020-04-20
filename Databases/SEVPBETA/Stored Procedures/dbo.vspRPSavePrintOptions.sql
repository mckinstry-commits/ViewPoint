SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspRPSavePrintOptions]
  /***********************************************************
     * CREATED BY: TRL 08/24/06
	 *
     * MODIFIED BY: George Clingerman 05/01/2008 #127634 Report settings were not being saved. Wrapped statements
     *                                           in ISNULLs so they wouldn't get wiped. 
     * NOTE: 04/19/2011: In the Report Refactor Branch, this Stored Proc is no longer being used
     8 When it gets merged in, this will become obsolete, and we can remove it. (6.4.0)
     *
     *USAGE:
     * Called from Report Class
     * 
     * INPUT PARAMETERS
     *    @username         VPUserName
     *    @reportid			ReportID
     *    @printername		
     *    @papersource
     *    @papersize
     *    @duplex
     *	   @orientation
	 *
     * OUTPUT PARAMETERS
     *    @msg           error message from
     *
     * RETURN VALUE
     *    none
     *****************************************************/
(@username varchar(128)=null,@reportid int =null,@printername varchar(256)=null,@papersource int =null,
@papersize int = null, @duplex smallint = null, @orientation smallint=null, @lastaccessdate smalldatetime = null, 
@zoom int = null, @viewerwidth int = null, @viewerheight int = null, @msg varchar(255) output) 

as 

set nocount off

declare @rcode int

select @rcode = 0


If @username is null
	Begin
		select @msg = 'Missing VP User Name', @rcode = 1
		goto vspexit
	End

If @reportid is null or @reportid = 0
	Begin
		select @msg = 'Missing ReportID', @rcode = 1
		goto vspexit
	End

If @reportid >0 
	begin
		If (select count(*) from RPRTShared Where ReportID = @reportid) =0
			Begin
				select @msg = 'VP User:  ' + @username + 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + 'doesnot exist!', @rcode = 1
				goto vspexit
			End
	End

If (select count(*) from dbo.vRPUP Where VPUserName = @username and ReportID = @reportid)= 0
		Begin
			Insert Into vRPUP  (VPUserName, ReportID, PrinterName, PaperSource, PaperSize, Duplex, Orientation, LastAccessed,Zoom,ViewerWidth,ViewerHeight)
			Values( @username, @reportid, @printername, @papersource, @papersize, @duplex, @orientation, @lastaccessdate,@zoom, @viewerwidth, @viewerheight)
			If @@rowcount =0
				Begin
					select @msg = 'VP User:  ' + @username + 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' didnot insert!', @rcode = 1
					goto vspexit
				End
		End
Else
	Begin
			
		Update dbo.vRPUP
		Set PrinterName = ISNULL(@printername, PrinterName), 
		PaperSource = ISNULL(@papersource, PaperSource), 
		PaperSize = ISNULL(@papersize, PaperSize), 
		Duplex = ISNULL(@duplex, Duplex), 
		Orientation= ISNULL(@orientation, Orientation),
		LastAccessed = ISNULL(@lastaccessdate, LastAccessed), 
		Zoom= ISNULL(@zoom, Zoom), 
		ViewerWidth= ISNULL(@viewerwidth, ViewerWidth), 
		ViewerHeight= ISNULL(@viewerheight, ViewerHeight)
		From dbo.vRPUP  Where VPUserName = @username and ReportID = @reportid

		If @@rowcount =0
		Begin
			select @msg = 'VP User:  ' + @username + 'Report ID: ' + convert(varchar,Isnull(@reportid,0)) + ' didnot update!', @rcode = 1
			goto vspexit
		End
	End

vspexit:
	If @rcode <> 0
	select @msg =  @msg + char(13) + char(10) + '[vspRPSavePrintOptions]'	
	Return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspRPSavePrintOptions] TO [public]
GO
