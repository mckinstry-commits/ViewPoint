SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVADDTSuserlist    Script Date: 8/28/99 9:35:52 AM ******/
 CREATE                     proc [dbo].[vspVADDTSuserlist] 
 /**************************************************************
 * Object:  Stored Procedure dbo.bspVADDTSuserlist    
 **************************************************************
 * displays tab (DDTS) security for a given form and tab, 
 * ordered by user name 
 * input:  @Company, @Form, @TabTitle,  @msg varchar(60) output 
 * output: username, permission  (None,Full,ReadOnly)
 *  04/24/96 LM
 * Modified 06/16/99 LM - Change for SQL 7.0 to use name instead of id
 * kb 7/10/2 - issue #17858 - added to restrict DDFT to be for t.DetailTabYN = 'N' only
 * danf 1/24/05 - issue #119669 (SQL 9.0 2005)
 **************************************************************/
 (@Company smallint=null, @Form varchar(30)=null, @TabTitle varchar(30), @msg varchar(60) output) as
 
 declare @rcode integer, @Tab tinyint
 select @rcode=0
 
 set nocount on 
 begin
 if (select count(*) from dbo.vDDFH  with (nolock) where  Form=@Form)<>1
 	begin
 	select @msg = 'Invalid Form!', @rcode = 1
 	goto bspexit
 	end
 if (select count(*) from dbo.DDFTShared  with (nolock) where  Title=@TabTitle and Form=@Form)<1
 	begin
 	select @msg = 'Invalid Tab!', @rcode = 1
 	goto bspexit
 	end
 if (select count(*) from dbo.bHQCO  with (nolock) where  HQCo=@Company)<>1
 	begin
 	select @msg = 'Invalid Company!', @rcode = 1
 	goto bspexit
 	end
 if (select count(*) from dbo.vDDFS  with (nolock)
 	where Co=@Company and Form=@Form and Access=1)<1
 	begin
 	select @msg = 'Security is not by tab for this form!', @rcode = 1
 	goto bspexit
 	end
 select @Tab=Tab 
 	from dbo.vDDFT f with (nolock)
         where f.Title=@TabTitle and
         f.Form=@Form
         
 select t.Tab, t.VPUserName, t.SecurityGroup, Access=
 case t.Access
   when 0 then 'Full' 
   when 1 then 'Read Only'
   else 'None'
 end
 from dbo.vDDUP u  with (nolock)
 join dbo.vDDFS f  with (nolock)
 on u.VPUserName=f.VPUserName
 left join dbo.vDDTS t  with (nolock)
 on f.Co = t.Co and f.Form = t.Form and f.VPUserName = t.VPUserName
 where  f.Co=@Company and f.Form=@Form and t.Tab=@Tab and f.Access=1

union

select t.Tab, t.VPUserName, t.SecurityGroup, Access=
 case t.Access
   when 0 then 'Full' 
   when 1 then 'Read Only'
   else 'None'
 end
 from dbo.vDDSG s  with (nolock)
 join dbo.vDDFS f  with (nolock)
 on s.SecurityGroup=f.SecurityGroup
 left join dbo.vDDTS t  with (nolock)
 on f.Co = t.Co and f.Form = t.Form and f.SecurityGroup = t.SecurityGroup
 where  f.Co=@Company and f.Form=@Form and t.Tab=@Tab and f.Access=1
 --order by t.SecurityGroup


/*left join dbo.vDDSG s  with (nolock)
 on s.SecurityGroup=f.SecurityGroup
or f.SecurityGroup = t.SecurityGroup*/

 bspexit:
 	return @rcode    
 end

GO
GRANT EXECUTE ON  [dbo].[vspVADDTSuserlist] TO [public]
GO
