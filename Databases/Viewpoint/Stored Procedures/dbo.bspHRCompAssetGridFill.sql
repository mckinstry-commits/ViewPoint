SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRCompAssetGridFill]
   /************************************************************************
   * CREATED:  mh 6/22/04    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Fills Asset grid in HRResourceMaster
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @hrref bHRRef)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	select t.Asset, a.AssetDesc, t.DateOut, t.MemoOut 
   	from dbo.HRTA t with (nolock) join dbo.HRCA a with (nolock) on
   	t.HRCo = a.HRCo and
   	t.Asset = a.Asset
   	where t.HRCo = @hrco and t.HRRef = @hrref and DateIn is null
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRCompAssetGridFill] TO [public]
GO
