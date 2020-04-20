SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[bspHRCompAssetGetLastAssign]
   /************************************************************************
   * CREATED:	mh 5/19/04    
   * MODIFIED: mh 2/10/05 - Change HRRMName.Name to HRRMName.FullName   
   *
   * Purpose of Stored Procedure
   *
   *	Get the info about who the Asset is currently assigned to or if not assigned
   *	the last Asset Assignment    
   *    
   *           
   * Notes about Stored Procedure
   *
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @asset varchar(20), @msg varchar(8000) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	select @msg = 'Assigned To: ' + convert(varchar(20),isnull(c.Assigned,'')) + 
   	' ' + isnull(e.FullName,'') + ' ' + 'on ' + convert(varchar(11),isnull(a.DateOut,'')) + '.  Out Memo: ' + isnull(a.MemoOut,'')
   	from dbo.HRTA a with (nolock) 
   	join dbo.HRRMName e with (nolock) on 
   	a.HRCo = e.HRCo and
   	a.HRRef = e.HRRef
   	join dbo.HRCA c with (nolock) on a.HRCo = c.HRCo and a.HRRef = c.Assigned and a.Asset = c.Asset
   	where a.HRCo = @hrco and a.Asset = @asset and a.DateOut = (select max(DateOut) from dbo.HRTA with (nolock)
   		where HRCo = @hrco and Asset = @asset and DateIn is null)
   
   	if @msg is null
   
   		select @msg = 'Last Assigned To: ' + convert(varchar(20),isnull(c.Assigned,'')) + ' ' + isnull(e.FullName,'') + 
   		' on ' + convert(varchar(11),isnull(a.DateOut,'')) + '.  Returned ' + convert(varchar(11),isnull(a.DateIn,'')) + 
   		'.  In Memo: ' + isnull(a.MemoIn, '')
   		from dbo.HRTA a with (nolock) 
   		join dbo.HRRMName e with (nolock) on 
   		a.HRCo = e.HRCo and
   		a.HRRef = e.HRRef
   		join dbo.HRCA c with (nolock) on a.HRCo = c.HRCo and a.HRRef = c.Assigned and a.Asset = c.Asset
   		where a.HRCo = @hrco and a.Asset = @asset and a.DateOut = (select max(DateOut) from dbo.HRTA with (nolock)
   		where HRCo = @hrco and Asset = @asset and DateIn is not null)
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetGetLastAssign] TO [public]
GO
