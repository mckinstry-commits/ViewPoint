SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspVADDTStablist    Script Date: 8/28/99 9:35:52 AM ******/
 CREATE          proc [dbo].[vspVADDTStablistsecgroup]
 /************************************************************************
 * Object:  Stored Procedure dbo.vspVADDTStablist
 *************************************************************************
 * displays security set up in DDTS for a given user, ordered by tab
 * input:  company, form, username, msg
 * output: Tab, TabGrant(None,Full,ReadOnly),SecLvl(0,1)
 * 04/24/96 LM
 * Modified 06/16/99 LM - Change for SQL 7.0 to use name instead of id
 * Modified 08/17/00 DANF - remove reference to system user id
 *			kb 7/10/2 - issue #17858 - added to restrict DDFT to be for t.DetailTabYN = 'N' only
 * 			danf 1/24/05 - issue #119669 (SQL 9.0 2005)
 **************************************************************************/
 	(@Company smallint=null, @Form char(30)=null, @secgroup int,
 	 @msg varchar(60) output) as
 
 set nocount on
 declare @validcnt integer
 declare @rcode integer
 select @rcode=0
 
 begin
 
 /* displays security set up in DDFS
  * for a given form, ordered by user name */
 
 if (select count(*) from DDFHShared with (nolock) where  Form=@Form)<>1
 	begin
 	select @msg = 'Form not in DDFH!', @rcode = 1
 	goto bspexit
 	end
 if (select count(*) from dbo.bHQCO with (nolock) where  HQCo=@Company)<>1
 	begin
 	select @msg = 'Company not in HQCO!', @rcode = 1
 	goto bspexit
 	end
 select @validcnt = count(*) from dbo.vDDSG with (nolock) where SecurityGroup = @secgroup
 if @validcnt = 0
 	begin
 	select @msg = 'User not in DDSG!', @rcode = 1
 	goto bspexit
 	end
 
 if (select count(*) from dbo.vDDFS with (nolock)
 	where Co=@Company and Form=@Form and SecurityGroup=@secgroup and Access=1)<>1
 	begin
 	select @msg = 'Security is not by tab for this form!', @rcode = 1
 	goto bspexit
 	end
 
  select h.Tab, h.Title, Access=
    case t.Access
      when 0 then 'Full'
      when 1 then 'Read Only'
      else 'None'
    end,
    f.Access
    from dbo.DDFTShared h with (nolock)
	left join dbo.vDDTS t with (nolock)
	on t.Form = h.Form and t.Tab = h.Tab and t.Co = @Company and t.SecurityGroup = @secgroup 
	join dbo.vDDFS f with (nolock)
	on f.Form = h.Form and f.Co =@Company and f.Access = @Company
        where h.Form = @Form and f.SecurityGroup = @secgroup AND h.[Tab] <> 0
 
     return @rcode
 bspexit:
 	return @rcode
 end
GO
GRANT EXECUTE ON  [dbo].[vspVADDTStablistsecgroup] TO [public]
GO
